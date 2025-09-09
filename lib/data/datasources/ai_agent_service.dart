import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/network/dio_client.dart';
import '../../core/constants/app_constants.dart';
import '../../core/errors/failures.dart';
import '../../core/utils/json_extractor.dart';
import '../../core/services/location_service.dart';
import '../../domain/entities/trip.dart';
import '../../domain/entities/chat_message.dart';
import 'web_search_service.dart';
import 'openrouter_service.dart';

class AIAgentService {
  final DioClient _dioClient;
  final String _apiKey;
  final WebSearchService _webSearchService;
  final LocationService _locationService;
  final OpenRouterService _openRouterService;

  AIAgentService(this._dioClient, this._apiKey, this._webSearchService, this._locationService)
      : _openRouterService = OpenRouterService(
          dioClient: _dioClient,
          apiKey: AppConstants.openRouterApiKey,
        );

  Future<Trip> generateItinerary(String userPrompt, {Trip? existingTrip}) async {
    print('🚀 Starting trip generation for: $userPrompt');
    
    // Try OpenRouter first
    try {
      print('🔄 Trying OpenRouter API...');
      final prompt = await _buildSimplePrompt(userPrompt, existingTrip);
      print('🔍 OpenRouter Prompt: $prompt');
      
      final response = await _openRouterService.generateContent(
        text: prompt,
        maxTokens: 8000,
        temperature: 0.7,
      );
      print('✅ OpenRouter API call successful');
      return _parseSimpleItineraryResponse(response);
    } catch (e) {
      print('❌ OpenRouter API failed: $e');
      print('❌ OpenRouter Error Type: ${e.runtimeType}');
      
      // Fallback to OpenAI
      try {
        print('🔄 Falling back to OpenAI API...');
        final messages = _buildMessages(userPrompt, existingTrip);
        final functions = _getFunctionDefinitions();
        
        print('🔍 OpenAI Messages: $messages');
        print('🔍 OpenAI Functions: $functions');
        
        final response = await _dioClient.post(
          '${AppConstants.openAiApiUrl}${AppConstants.openAiChatCompletionsEndpoint}',
          data: {
            'model': AppConstants.openAiModel,
            'messages': messages,
            'functions': functions,
            'function_call': {'name': 'generate_itinerary'},
            'max_tokens': AppConstants.maxTokens,
            'temperature': AppConstants.temperature,
          },
          options: Options(
            headers: {
              'Authorization': 'Bearer $_apiKey',
              'Content-Type': 'application/json',
            },
          ),
        );

        print('✅ OpenAI API call successful');
        print('🔍 OpenAI Response: ${response.data}');
        return _parseItineraryResponse(response.data);
      } on DioException catch (openaiError) {
        if (openaiError.response?.statusCode == 401) {
          throw const Failure.server(message: 'Invalid API key for all services', statusCode: 401);
        } else if (openaiError.response?.statusCode == 429) {
          throw const Failure.server(message: 'Rate limit exceeded', statusCode: 429);
        } else {
          throw Failure.server(message: 'All AI services failed. OpenRouter: $e, OpenAI: ${openaiError.message}', statusCode: openaiError.response?.statusCode);
        }
      } catch (openaiError) {
        throw Failure.unknown(message: 'All services failed. OpenRouter: $e, OpenAI: $openaiError');
      }
    }
  }

  Stream<String> generateItineraryStream(String userPrompt, {Trip? existingTrip}) async* {
    try {
      final messages = _buildMessages(userPrompt, existingTrip);
      final functions = _getFunctionDefinitions();
      
      final stream = _dioClient.postStream(
        '${AppConstants.openAiApiUrl}${AppConstants.openAiChatCompletionsEndpoint}',
        data: {
          'model': AppConstants.openAiModel,
          'messages': messages,
          'functions': functions,
          'function_call': {'name': 'generate_itinerary'},
          'max_tokens': AppConstants.maxTokens,
          'temperature': AppConstants.temperature,
          'stream': true,
        },
        options: Options(
          headers: {
            'Authorization': 'Bearer $_apiKey',
            'Content-Type': 'application/json',
          },
        ),
      );

      await for (final chunk in stream) {
        if (chunk.startsWith('data: ')) {
          final data = chunk.substring(6);
          if (data.trim() == '[DONE]') break;
          
          try {
            final json = jsonDecode(data);
            final delta = json['choices']?[0]?['delta'];
            if (delta?['function_call']?['arguments'] != null) {
              yield delta['function_call']['arguments'];
            }
          } catch (e) {
            // Skip malformed chunks
            continue;
          }
        }
      }
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) {
        throw const Failure.server(message: 'Invalid API key', statusCode: 401);
      } else if (e.response?.statusCode == 429) {
        throw const Failure.server(message: 'Rate limit exceeded', statusCode: 429);
      } else {
        throw Failure.server(message: e.message ?? 'Unknown server error', statusCode: e.response?.statusCode);
      }
    } catch (e) {
      throw Failure.unknown(message: e.toString());
    }
  }

  Future<String> searchWeb(String query) async {
    try {
      return await _webSearchService.searchWeb(query);
    } catch (e) {
      throw Failure.network(message: 'Failed to perform web search: ${e.toString()}');
    }
  }

  /// Enhanced chat method that can handle function calls including web search
  Stream<String> chatWithFunctions(List<ChatMessage> messages) async* {
    try {
      final chatMessages = messages.map((msg) => {
        'role': msg.type == ChatMessageType.user ? 'user' : 'assistant',
        'content': msg.content,
      }).toList();

      // Add system message for function calling
      chatMessages.insert(0, {
        'role': 'system',
        'content': '''
You are a helpful travel planning assistant. You can:
1. Generate detailed itineraries using the generate_itinerary function
2. Search for real-time information using the search_web function
3. Answer travel-related questions

When users ask about current information, events, weather, or specific details about places, use the search_web function first to get up-to-date information, then provide a helpful response based on the search results.

For itinerary requests, use the generate_itinerary function to create structured travel plans.
'''
      });

      final functions = _getFunctionDefinitions();
      
      final stream = _dioClient.postStream(
        '${AppConstants.openAiApiUrl}${AppConstants.openAiChatCompletionsEndpoint}',
        data: {
          'model': AppConstants.openAiModel,
          'messages': chatMessages,
          'functions': functions,
          'function_call': 'auto',
          'max_tokens': AppConstants.maxTokens,
          'temperature': AppConstants.temperature,
          'stream': true,
        },
        options: Options(
          headers: {
            'Authorization': 'Bearer $_apiKey',
            'Content-Type': 'application/json',
          },
        ),
      );

      String functionName = '';
      String functionArgs = '';
      bool inFunctionCall = false;

      await for (final chunk in stream) {
        if (chunk.startsWith('data: ')) {
          final data = chunk.substring(6);
          if (data.trim() == '[DONE]') break;
          
          try {
            final json = jsonDecode(data);
            final delta = json['choices']?[0]?['delta'];
            
            // Handle function calls
            if (delta?['function_call'] != null) {
              inFunctionCall = true;
              if (delta['function_call']['name'] != null) {
                functionName = delta['function_call']['name'];
              }
              if (delta['function_call']['arguments'] != null) {
                functionArgs += delta['function_call']['arguments'];
              }
            } else if (inFunctionCall && delta?['content'] == null) {
              // Function call completed, execute it
              if (functionName == 'search_web') {
                try {
                  final args = jsonDecode(functionArgs);
                  final query = args['query'] as String;
                  yield '🔍 Searching for: $query\n\n';
                  final searchResult = await searchWeb(query);
                  yield 'Search Results:\n$searchResult\n\n';
                } catch (e) {
                  yield 'Search failed: ${e.toString()}\n\n';
                }
              }
              // Reset for next function call
              functionName = '';
              functionArgs = '';
              inFunctionCall = false;
            } else if (delta?['content'] != null) {
              // Regular content
              yield delta['content'];
            }
          } catch (e) {
            // Skip malformed chunks
            continue;
          }
        }
      }
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) {
        throw const Failure.server(message: 'Invalid API key', statusCode: 401);
      } else if (e.response?.statusCode == 429) {
        throw const Failure.server(message: 'Rate limit exceeded', statusCode: 429);
      } else {
        throw Failure.server(message: e.message ?? 'Unknown server error', statusCode: e.response?.statusCode);
      }
    } catch (e) {
      throw Failure.unknown(message: e.toString());
    }
  }

  List<Map<String, dynamic>> _buildMessages(String userPrompt, Trip? existingTrip) {
    final messages = <Map<String, dynamic>>[
      {
        'role': 'system',
        'content': _getSystemPrompt(),
      },
    ];

    if (existingTrip != null) {
      messages.add({
        'role': 'assistant',
        'content': 'Here is the current itinerary:',
        'function_call': {
          'name': 'generate_itinerary',
          'arguments': jsonEncode(_tripToJson(existingTrip)),
        },
      });
    }

    messages.add({
      'role': 'user',
      'content': userPrompt,
    });

    return messages;
  }

  String _getSystemPrompt() {
    return '''
You are a smart travel planning assistant. Your job is to create detailed, personalized itineraries based on user requests.

When generating itineraries, you must:
1. Use the generate_itinerary function to return structured JSON
2. Include specific times, activities, and locations with coordinates
3. Consider the user's budget, travel style, and preferences
4. Provide realistic travel times between locations
5. Include dining suggestions and local experiences
6. Use web search when needed for real-time information about places, restaurants, and attractions

Always respond with the generate_itinerary function call containing the complete itinerary in the specified JSON format ONLY, do not include any other text or anything other than json .
''';
  }

  List<Map<String, dynamic>> _getFunctionDefinitions() {
    return [
      {
        'name': 'generate_itinerary',
        'description': 'Generate a structured travel itinerary',
        'parameters': {
          'type': 'object',
          'properties': {
            'title': {
              'type': 'string',
              'description': 'Title of the trip',
            },
            'startDate': {
              'type': 'string',
              'description': 'Start date in YYYY-MM-DD format',
            },
            'endDate': {
              'type': 'string',
              'description': 'End date in YYYY-MM-DD format',
            },
            'days': {
              'type': 'array',
              'items': {
                'type': 'object',
                'properties': {
                  'date': {
                    'type': 'string',
                    'description': 'Date in YYYY-MM-DD format',
                  },
                  'summary': {
                    'type': 'string',
                    'description': 'Brief summary of the day',
                  },
                  'items': {
                    'type': 'array',
                    'items': {
                      'type': 'object',
                      'properties': {
                        'time': {
                          'type': 'string',
                          'description': 'Time in HH:MM format',
                        },
                        'activity': {
                          'type': 'string',
                          'description': 'Description of the activity',
                        },
                        'location': {
                          'type': 'string',
                          'description': 'Location coordinates in lat,lng format',
                        },
                        'description': {
                          'type': 'string',
                          'description': 'Optional detailed description of the activity',
                        },
                        'cost': {
                          'type': 'string',
                          'description': 'Optional estimated cost for the activity',
                        },
                        'notes': {
                          'type': 'string',
                          'description': 'Optional additional notes or tips',
                        },
                        'latitude': {
                          'type': 'number',
                          'description': 'Optional latitude coordinate',
                        },
                        'longitude': {
                          'type': 'number',
                          'description': 'Optional longitude coordinate',
                        },
                      },
                      'required': ['time', 'activity', 'location'],
                    },
                  },
                },
                'required': ['date', 'summary', 'items'],
              },
            },
          },
          'required': ['title', 'startDate', 'endDate', 'days'],
        },
      },
      {
        'name': 'search_web',
        'description': 'Search the web for real-time information about destinations, attractions, restaurants, or current events',
        'parameters': {
          'type': 'object',
          'properties': {
            'query': {
              'type': 'string',
              'description': 'The search query for finding current information',
            },
          },
          'required': ['query'],
        },
      },
    ];
  }

  Trip _parseItineraryResponse(Map<String, dynamic> response) {
    try {
      final choice = response['choices'][0];
      final functionCall = choice['message']['function_call'];
      final arguments = jsonDecode(functionCall['arguments']);
      
      return _jsonToTrip(arguments);
    } catch (e) {
      throw const Failure.validation(message: 'Failed to parse AI response');
    }
  }

  Trip _jsonToTrip(Map<String, dynamic> json) {
    try {
      // Validate required fields exist and are not null
      if (json['title'] == null || json['startDate'] == null || json['endDate'] == null || json['days'] == null) {
        throw Exception('Missing required fields in JSON: title, startDate, endDate, or days');
      }
      
      final daysData = json['days'];
      if (daysData is! List) {
        throw Exception('Days field is not a valid list');
      }
      
      final days = daysData.map((day) {
        if (day == null || day is! Map<String, dynamic>) {
          throw Exception('Invalid day data structure');
        }
        
        final itemsData = day['items'];
        if (itemsData == null || itemsData is! List) {
          throw Exception('Items field is missing or not a valid list');
        }
        
        final items = itemsData.map((item) {
          if (item == null || item is! Map<String, dynamic>) {
            throw Exception('Invalid item data structure');
          }
          
          return ItineraryItem(
            time: item['time'] as String? ?? '',
            activity: item['activity'] as String? ?? '',
            location: item['location'] as String? ?? '',
            description: item['description'] as String?,
            cost: item['cost'] as String?,
            notes: item['notes'] as String?,
            latitude: item['latitude']?.toDouble(),
            longitude: item['longitude']?.toDouble(),
          );
        }).toList();
        
        return DayItinerary(
          date: DateTime.parse(day['date'] as String? ?? DateTime.now().toIso8601String()),
          summary: day['summary'] as String? ?? '',
          items: items,
        );
      }).toList();
      
      return Trip(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        title: json['title'] as String? ?? 'Untitled Trip',
        startDate: DateTime.parse(json['startDate'] as String? ?? DateTime.now().toIso8601String()),
        endDate: DateTime.parse(json['endDate'] as String? ?? DateTime.now().toIso8601String()),
        days: days,
        createdAt: DateTime.now(),
      );
    } catch (e) {
      print('❌ Error in _jsonToTrip (ai_agent_service): $e');
      print('❌ JSON data: $json');
      rethrow;
    }
  }

  Map<String, dynamic> _tripToJson(Trip trip) {
    return {
      'title': trip.title,
      'startDate': trip.startDate.toIso8601String().split('T')[0],
      'endDate': trip.endDate.toIso8601String().split('T')[0],
      'days': trip.days.map((day) => {
        'date': day.date.toIso8601String().split('T')[0],
        'summary': day.summary,
        'items': day.items.map((item) => {
          'time': item.time,
          'activity': item.activity,
          'location': item.location,
          'description': item.description,
          'cost': item.cost,
          'notes': item.notes,
          'latitude': item.latitude,
          'longitude': item.longitude,
        }).toList(),
      }).toList(),
    };
  }

  Future<String> _buildSimplePrompt(String userPrompt, Trip? existingTrip) async {
    const jsonFormat = '''{\n  "title": "string",\n  "startDate": "YYYY-MM-DD",\n  "endDate": "YYYY-MM-DD",\n  "days": [\n    {\n      "date": "YYYY-MM-DD",\n      "summary": "string",\n      "items": [\n        {\n          "time": "HH:MM",\n          "activity": "string",\n          "location": "string",\n          "latitude": 0.0,\n          "longitude": 0.0,\n          "cost": "string",\n          "notes": "string"\n        }\n      ]\n    }\n  ]\n}''';

    // Get user location context
    String locationContext = '';
    try {
      final userLocation = await _locationService.getCurrentLocationString();
      final userCity = await _locationService.getCurrentCity();
      if ((userLocation?.isNotEmpty ?? false) || (userCity?.isNotEmpty ?? false)) {
        locationContext = ' User is currently located at: ${(userCity?.isNotEmpty ?? false) ? userCity! : userLocation!}. Consider this as the starting point for recommendations.';
      }
    } catch (e) {
      print('Could not get user location: $e');
    }
    
    if (existingTrip != null) {
      final existingItinerary = jsonEncode(_tripToJson(existingTrip));
      return '''Create a travel itinerary. Current: $existingItinerary. Request: $userPrompt.$locationContext Return JSON: $jsonFormat''';
    } else {
      return '''Create a travel itinerary for: $userPrompt.$locationContext Return this exact JSON format: $jsonFormat''';
    }
  }

  Trip _parseSimpleItineraryResponse(String response) {
    try {
      print('🔍 Parsing OpenRouter Response:');
      print('🔍 Raw Response: $response');
      print('🔍 Response Length: ${response.length}');
      print('🔍 Response Type: ${response.runtimeType}');
      
      // Use JsonExtractor to handle various AI response formats
      final json = JsonExtractor.extractJson(response);
      
      if (json == null) {
        print('❌ No valid JSON found in OpenRouter response');
        print('❌ Response preview: ${response.length > 200 ? response.substring(0, 200) + '...' : response}');
        throw const Failure.validation(message: 'No valid JSON found in OpenRouter response. The AI may have provided an incomplete or malformed response.');
      }
      
      print('🔍 Successfully extracted JSON using JsonExtractor');
      print('🔍 Parsed JSON: $json');
      print('🔍 JSON Type: ${json.runtimeType}');
      
      final trip = _jsonToTrip(json);
      print('✅ Successfully parsed trip: ${trip.title}');
      return trip;
    } catch (e) {
      print('❌ Failed to parse OpenRouter response: $e');
      print('❌ Error Type: ${e.runtimeType}');
      throw Failure.validation(message: 'Failed to parse OpenRouter response: ${e.toString()}');
    }
  }
}

// Provider for AIAgentService
final aiAgentServiceProvider = Provider<AIAgentService>((ref) {
  final dioClient = ref.read(dioClientProvider);
  final webSearchService = ref.read(webSearchServiceProvider);
  final locationService = ref.read(locationServiceProvider);
  // API key - load from environment variables for security
  const apiKey = String.fromEnvironment('OPENAI_API_KEY', defaultValue: 'your-api-key-here');
  return AIAgentService(dioClient, apiKey, webSearchService, locationService);
});