import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/network/dio_client.dart';
import '../../core/constants/app_constants.dart';
import '../../core/errors/failures.dart';
import '../../domain/entities/trip.dart';
import '../../domain/entities/chat_message.dart';
import 'web_search_service.dart';

class AIAgentService {
  final DioClient _dioClient;
  final String _apiKey;
  final WebSearchService _webSearchService;

  AIAgentService(this._dioClient, this._apiKey, this._webSearchService);

  Future<Trip> generateItinerary(String userPrompt, {Trip? existingTrip}) async {
    try {
      final messages = _buildMessages(userPrompt, existingTrip);
      final functions = _getFunctionDefinitions();
      
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

      return _parseItineraryResponse(response.data);
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

Always respond with the generate_itinerary function call containing the complete itinerary in the specified JSON format.
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
    final days = (json['days'] as List).map((day) {
      final items = (day['items'] as List).map((item) {
        return ItineraryItem(
          time: item['time'],
          activity: item['activity'],
          location: item['location'],
        );
      }).toList();
      
      return DayItinerary(
        date: DateTime.parse(day['date']),
        summary: day['summary'],
        items: items,
      );
    }).toList();
    
    return Trip(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: json['title'],
      startDate: DateTime.parse(json['startDate']),
      endDate: DateTime.parse(json['endDate']),
      days: days,
      createdAt: DateTime.now(),
    );
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
        }).toList(),
      }).toList(),
    };
  }
}

// Provider for AIAgentService
final aiAgentServiceProvider = Provider<AIAgentService>((ref) {
  final dioClient = ref.read(dioClientProvider);
  final webSearchService = ref.read(webSearchServiceProvider);
  // API key - load from environment variables for security
  const apiKey = String.fromEnvironment('OPENAI_API_KEY', defaultValue: 'your-api-key-here');
  return AIAgentService(dioClient, apiKey, webSearchService);
});