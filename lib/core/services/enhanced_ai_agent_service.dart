import 'dart:convert';
import 'dart:async';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:logger/logger.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/trip.dart';
import '../../domain/entities/chat_message.dart';
import '../network/dio_client.dart';
import 'weather_service.dart';
import 'currency_service.dart';
import 'vector_store_service.dart';
import 'pathfinding_service.dart';
import '../../data/datasources/gemini_service.dart';
import '../../data/datasources/ai_agent_service.dart';
import '../../data/datasources/web_search_service.dart';
import '../../data/datasources/openrouter_service.dart';
import '../errors/failures.dart';
import '../constants/app_constants.dart';
import 'token_tracking_service.dart';
import 'location_service.dart';
import '../utils/json_extractor.dart';

class ToolCall {
  final String name;
  final Map<String, dynamic> arguments;
  final String id;

  ToolCall({
    required this.name,
    required this.arguments,
    required this.id,
  });
}

class ToolResult {
  final String toolCallId;
  final String result;
  final bool success;

  ToolResult({
    required this.toolCallId,
    required this.result,
    required this.success,
  });
}

class EnhancedAIAgentService {
  final DioClient _dioClient;
  final WeatherService _weatherService;
  final CurrencyService _currencyService;
  final VectorStoreService _vectorStoreService;
  final PathfindingService _pathfindingService;
  final TokenTrackingService _tokenTrackingService;
  final LocationService _locationService;
  final Logger _logger = Logger();
  final String _apiKey;
  
  // Simple response cache to avoid repeated API calls
  final Map<String, String> _responseCache = {};
  final Map<String, DateTime> _cacheTimestamps = {};
  static const Duration _cacheValidDuration = Duration(minutes: 10);

  EnhancedAIAgentService({
    required DioClient dioClient,
    required WeatherService weatherService,
    required CurrencyService currencyService,
    required VectorStoreService vectorStoreService,
    required PathfindingService pathfindingService,
    required TokenTrackingService tokenTrackingService,
    required LocationService locationService,
    required String apiKey,
  }) : _dioClient = dioClient,
       _weatherService = weatherService,
       _currencyService = currencyService,
       _vectorStoreService = vectorStoreService,
       _pathfindingService = pathfindingService,
       _tokenTrackingService = tokenTrackingService,
       _locationService = locationService,
        _apiKey = apiKey;

  /// Enhanced chat with function calling capabilities
  Stream<String> chatWithTools(List<ChatMessage> messages) async* {
    try {
      // First, try to understand if the user needs any tools
      final lastMessage = messages.isNotEmpty ? messages.last.content : '';
      final toolsNeeded = _identifyNeededTools(lastMessage);

      if (toolsNeeded.isNotEmpty) {
        yield '🔧 Analyzing your request and gathering information...\n\n';
        
        // Execute tools with individual timeouts for better performance
        final toolResults = <ToolResult>[];
        for (final tool in toolsNeeded) {
          yield '• Using ${tool.name}...\n';
          try {
            final result = await _executeTool(tool).timeout(const Duration(seconds: 30));
            toolResults.add(result);
          } catch (e) {
            _logger.w('Tool ${tool.name} timed out or failed: $e');
            toolResults.add(ToolResult(
              toolCallId: tool.id,
              result: 'Service temporarily unavailable',
              success: false,
            ));
          }
        }

        yield '\n📊 Information gathered, generating response...\n\n';
        
        // Generate response with tool results
        final enhancedPrompt = _buildPromptWithToolResults(messages, toolResults);
        yield* _generateResponseWithFallback(enhancedPrompt, requestType: 'chat_with_tools');
      } else {
        // Check vector store for relevant cached information with timeout
        try {
          final cachedInfo = await _searchVectorStore(lastMessage)
              .timeout(const Duration(seconds: 3));
          if (cachedInfo.isNotEmpty) {
            yield '💾 Found relevant cached information...\n\n';
            final enhancedPrompt = _buildPromptWithCachedInfo(messages, cachedInfo);
            yield* _generateResponseWithFallback(enhancedPrompt);
          } else {
            // Regular chat response
            final prompt = _buildChatPrompt(messages);
            yield* _generateResponseWithFallback(prompt, requestType: 'chat');
          }
        } catch (timeoutError) {
          // Skip cache search if it takes too long
          final prompt = _buildChatPrompt(messages);
          yield* _generateResponseWithFallback(prompt);
        }
      }
    } catch (e) {
      _logger.e('Error in chatWithTools: $e');
      yield 'I encountered an error while processing your request. Please try again.';
    }
  }

  /// Generate trip itinerary with enhanced capabilities
  Future<Trip> generateEnhancedItinerary(String userPrompt, {Trip? existingTrip}) async {
    try {
      // Extract location and dates from prompt
      final locationInfo = _extractLocationInfo(userPrompt);
      final dateInfo = _extractDateInfo(userPrompt);
      
      // Gather contextual information
      final contextualInfo = <String>[];
      
      // Add improvisation context for missing information
      final missingInfo = <String>[];
      if (locationInfo.isEmpty) {
        missingInfo.add('destination');
        contextualInfo.add('No specific destination mentioned - will suggest popular destinations or use context clues');
      }
      if (dateInfo.isEmpty) {
        missingInfo.add('dates');
        contextualInfo.add('No dates specified - will create itinerary starting from tomorrow');
      }
      
      // Extract additional context for better improvisation
      final tripDuration = _extractDuration(userPrompt);
      final budget = _extractBudget(userPrompt);
      final preferences = _extractPreferences(userPrompt);
      
      if (tripDuration.isEmpty) {
        missingInfo.add('duration');
        contextualInfo.add('No duration specified - will default to 2-3 days');
      }
      if (budget.isEmpty) {
        contextualInfo.add('No budget mentioned - will assume mid-range options');
      }
      if (preferences.isEmpty) {
        contextualInfo.add('No specific preferences - will include balanced mix of activities');
      }
      
      // Add user location context
      try {
        final userLocation = await _locationService.getCurrentLocationString();
        if (userLocation != null) {
          contextualInfo.add('User current location: $userLocation');
          contextualInfo.add('Consider proximity to user location when suggesting destinations and transportation');
          
          final userCity = await _locationService.getCurrentCity();
          if (userCity != null) {
            contextualInfo.add('User current area: $userCity');
          }
        } else {
          contextualInfo.add('User location not available - will provide general recommendations');
        }
      } catch (e) {
        _logger.w('Could not get user location for itinerary: $e');
        contextualInfo.add('User location not available - will provide general recommendations');
      }
      
      // Add smart defaults based on what's missing
      if (missingInfo.isNotEmpty) {
        contextualInfo.add('Missing information detected: ${missingInfo.join(', ')}');
        contextualInfo.add('AI will intelligently fill gaps with appropriate defaults and suggestions');
      }
      
      // Get weather information if location is specified
      if (locationInfo.isNotEmpty) {
        final weather = await _weatherService.getCurrentWeatherByCity(locationInfo);
        if (weather != null) {
          contextualInfo.add('Current weather in $locationInfo: ${weather.description}, ${weather.temperatureCelsius}°C');
          contextualInfo.add('Weather recommendation: ${_weatherService.getWeatherRecommendation(weather)}');
        }
      }
      
      // Get currency information if international travel is detected
      if (_isInternationalTravel(userPrompt)) {
        final currencyTip = _currencyService.getCurrencyTips(_extractCountryCode(userPrompt));
        contextualInfo.add('Currency tip: ${currencyTip.tip}');
      }
      
      // Search vector store for similar trips
      final similarTrips = await _vectorStoreService.search(
        query: userPrompt,
        limit: 3,
        threshold: 0.7,
      );
      
      if (similarTrips.isNotEmpty) {
        contextualInfo.add('Similar trip experiences: ${similarTrips.map((r) => r.document.content).join('; ')}');
      }
      
      // Build enhanced prompt with improvisation context
      final enhancedPrompt = _buildEnhancedItineraryPrompt(
        userPrompt,
        existingTrip,
        contextualInfo,
      );
      
      // Use direct AI generation with fallback chain
      // Priority: Gemini -> OpenAI -> Offline fallback
      try {
        final responseStream = _generateResponseWithFallback(enhancedPrompt, requestType: 'itinerary');
        final responseBuffer = StringBuffer();
        
        await for (final chunk in responseStream) {
          responseBuffer.write(chunk);
        }
        
        final response = responseBuffer.toString();
        final trip = _parseItineraryResponse(response);
        
        // Cache the trip in vector store for future reference
        await _cacheTrip(trip, userPrompt);
        
        return trip;
      } catch (e) {
        _logger.e('AI generation failed: $e');
        
        // Create a basic offline trip as final fallback
        return _createBasicOfflineTrip(userPrompt, existingTrip);
      }
    } catch (e) {
      _logger.e('Error generating enhanced itinerary: $e');
      // Return basic offline trip as final fallback
      return _createBasicOfflineTrip(userPrompt, null);
    }
  }

  /// Optimize trip route using pathfinding
  Future<String> optimizeTripRoute(Trip trip) async {
    try {
      if (trip.days.isEmpty) return 'No itinerary to optimize.';
      
      final allPOIs = <GeoPoint>[];
      GeoPoint? startPoint;
      
      // Extract POIs from trip
      for (final day in trip.days) {
        for (final item in day.items) {
          if (item.location != null && item.location!.isNotEmpty) {
            final coords = item.location!.split(',');
            if (coords.length == 2) {
              final lat = double.tryParse(coords[0]);
              final lng = double.tryParse(coords[1]);
              if (lat != null && lng != null) {
                final poi = GeoPoint(
                  latitude: lat,
                  longitude: lng,
                  name: item.activity,
                  id: item.activity.hashCode.toString(),
                );
                
                if (startPoint == null) {
                  startPoint = poi;
                } else {
                  allPOIs.add(poi);
                }
              }
            }
          }
        }
      }
      
      if (startPoint == null || allPOIs.isEmpty) {
        return 'Unable to optimize route - insufficient location data.';
      }
      
      // Optimize route
      final optimizedRoute = _pathfindingService.optimizeRoute(
        startPoint: startPoint,
        waypoints: allPOIs,
      );
      
      // Generate optimization report
      final stats = _pathfindingService.getRouteStatistics(optimizedRoute);
      final report = StringBuffer();
      report.writeln('🗺️ Route Optimization Results:');
      report.writeln('• Total Distance: ${stats['totalDistance']}');
      report.writeln('• Walking Time: ${stats['totalWalkingTime']}');
      report.writeln('• Route Efficiency: ${stats['efficiency']}');
      report.writeln('• Waypoints: ${stats['totalWaypoints']}');
      report.writeln();
      report.writeln('📍 Optimized Visit Order:');
      
      for (int i = 0; i < optimizedRoute.waypoints.length; i++) {
        final waypoint = optimizedRoute.waypoints[i];
        report.writeln('${i + 1}. ${waypoint.name ?? "Location ${i + 1}"}');
      }
      
      return report.toString();
    } catch (e) {
      _logger.e('Error optimizing trip route: $e');
      return 'Failed to optimize route: ${e.toString()}';
    }
  }

  /// Identify which tools are needed based on user input
  List<ToolCall> _identifyNeededTools(String input) {
    final tools = <ToolCall>[];
    final lowerInput = input.toLowerCase();
    
    // Trip generation tool - check for trip planning keywords
    if (_isTripPlanningRequest(lowerInput)) {
      tools.add(ToolCall(
        name: 'generate_trip_itinerary',
        arguments: {'query': input},
        id: 'trip_${DateTime.now().millisecondsSinceEpoch}',
      ));
    }
    
    // Weather tool
    if (lowerInput.contains('weather') || lowerInput.contains('temperature') || 
        lowerInput.contains('rain') || lowerInput.contains('sunny')) {
      final location = _extractLocationFromText(input);
      if (location.isNotEmpty) {
        tools.add(ToolCall(
          name: 'get_weather',
          arguments: {'location': location},
          id: 'weather_${DateTime.now().millisecondsSinceEpoch}',
        ));
      }
    }
    
    // Currency tool
    if (lowerInput.contains('currency') || lowerInput.contains('exchange') || 
        lowerInput.contains('money') || lowerInput.contains('budget')) {
      final currencies = _extractCurrenciesFromText(input);
      if (currencies.length >= 2) {
        tools.add(ToolCall(
          name: 'get_exchange_rate',
          arguments: {
            'from_currency': currencies[0],
            'to_currency': currencies[1],
          },
          id: 'currency_${DateTime.now().millisecondsSinceEpoch}',
        ));
      }
    }
    
    // Route optimization tool
    if (lowerInput.contains('optimize') || lowerInput.contains('route') || 
        lowerInput.contains('distance') || lowerInput.contains('walking')) {
      tools.add(ToolCall(
        name: 'optimize_route',
        arguments: {'query': input},
        id: 'route_${DateTime.now().millisecondsSinceEpoch}',
      ));
    }
    
    return tools;
  }

  /// Check if the input is requesting trip planning
  bool _isTripPlanningRequest(String lowerInput) {
    final tripKeywords = [
      'trip', 'travel', 'vacation', 'holiday', 'itinerary', 'plan',
      'visit', 'go to', 'tour', 'journey', 'destination', 'schedule',
      'activities', 'things to do', 'places to see', 'attractions',
      'restaurants', 'hotels', 'accommodation', 'sightseeing',
      'day trip', 'weekend', 'days in', 'week in', 'month in'
    ];
    
    return tripKeywords.any((keyword) => lowerInput.contains(keyword));
  }

  /// Execute a specific tool
  Future<ToolResult> _executeTool(ToolCall toolCall) async {
    try {
      switch (toolCall.name) {
        case 'get_weather':
          final location = toolCall.arguments['location'] as String;
          final weather = await _weatherService.getCurrentWeatherByCity(location);
          if (weather != null) {
            final result = 'Weather in $location: ${weather.description}, ${weather.temperatureCelsius}. ${_weatherService.getWeatherRecommendation(weather)}';
            return ToolResult(toolCallId: toolCall.id, result: result, success: true);
          } else {
            return ToolResult(toolCallId: toolCall.id, result: 'Weather data not available for $location', success: false);
          }
          
        case 'get_exchange_rate':
          final fromCurrency = toolCall.arguments['from_currency'] as String;
          final toCurrency = toolCall.arguments['to_currency'] as String;
          final rate = await _currencyService.getExchangeRate(fromCurrency, toCurrency);
          if (rate != null) {
            final result = 'Exchange rate: ${rate.formatConversion(1.0)}. ${await _currencyService.getBudgetRecommendation(fromCurrency, toCurrency, 100.0)}';
            return ToolResult(toolCallId: toolCall.id, result: result, success: true);
          } else {
            return ToolResult(toolCallId: toolCall.id, result: 'Exchange rate not available', success: false);
          }
          
        case 'generate_trip_itinerary':
          final query = toolCall.arguments['query'] as String;
          try {
            final trip = await generateEnhancedItinerary(query);
            // Convert trip to JSON string for the response
            final tripJson = {
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
              'totalTokensUsed': trip.totalTokensUsed,
            };
            return ToolResult(
              toolCallId: toolCall.id, 
              result: 'Generated detailed itinerary with time-based activities:\n\n${jsonEncode(tripJson)}', 
              success: true
            );
          } catch (e) {
            return ToolResult(
              toolCallId: toolCall.id, 
              result: 'Failed to generate itinerary: ${e.toString()}', 
              success: false
            );
          }
          
        case 'optimize_route':
          // This would need trip data - simplified for now
          return ToolResult(toolCallId: toolCall.id, result: 'Route optimization requires specific trip data', success: false);
          
        default:
          return ToolResult(toolCallId: toolCall.id, result: 'Unknown tool', success: false);
      }
    } catch (e) {
      _logger.e('Error executing tool ${toolCall.name}: $e');
      return ToolResult(toolCallId: toolCall.id, result: 'Tool execution failed: ${e.toString()}', success: false);
    }
  }

  /// Search vector store for relevant cached information with enhanced RAG
  Future<List<String>> _searchVectorStore(String query) async {
    try {
      // Multi-level search for better RAG results
      final results = <String>[];
      
      // 1. Direct semantic search
      final directResults = await _vectorStoreService.search(
        query: query,
        limit: 3,
        threshold: 0.7,
      );
      results.addAll(directResults.map((r) => r.document.content));
      
      // 2. Search for similar locations if location is detected
      final location = _extractLocationInfo(query);
      if (location.isNotEmpty) {
        final locationResults = await _vectorStoreService.search(
          query: 'travel $location attractions activities',
          limit: 2,
          threshold: 0.6,
        );
        results.addAll(locationResults.map((r) => r.document.content));
      }
      
      // 3. Search for similar trip types
      final tripType = _extractTripType(query);
      if (tripType.isNotEmpty) {
        final typeResults = await _vectorStoreService.search(
          query: '$tripType trip itinerary',
          limit: 2,
          threshold: 0.6,
        );
        results.addAll(typeResults.map((r) => r.document.content));
      }
      
      // Remove duplicates and return top results
      final uniqueResults = results.toSet().take(5).toList();
      
      return uniqueResults;
    } catch (e) {
      _logger.e('Error searching vector store: $e');
      return [];
    }
  }

  /// Enhanced trip caching with detailed RAG information
  Future<void> _cacheTrip(Trip trip, String originalQuery) async {
    try {
      // Cache main trip summary
      final tripSummary = '${trip.title}: ${trip.days.length} days trip. ${trip.days.map((d) => d.summary).join(' ')}';
      await _vectorStoreService.addDocument(
        id: 'trip_${trip.id}',
        content: tripSummary,
        metadata: {
          'type': 'trip',
          'title': trip.title,
          'duration': trip.days.length,
          'query': originalQuery,
          'created': DateTime.now().toIso8601String(),
        },
      );
      
      // Cache individual day activities for better granular search
      for (int i = 0; i < trip.days.length; i++) {
        final day = trip.days[i];
        final dayContent = 'Day ${i + 1} of ${trip.title}: ${day.summary}. Activities: ${day.items.map((item) => item.activity).join(', ')}';
        
        await _vectorStoreService.addDocument(
          id: 'trip_${trip.id}_day_${i + 1}',
          content: dayContent,
          metadata: {
            'type': 'day_itinerary',
            'trip_id': trip.id,
            'day_number': i + 1,
            'date': day.date.toIso8601String(),
            'activities_count': day.items.length,
          },
        );
      }
      
      // Cache location-specific information
      final locations = <String>{};
      for (final day in trip.days) {
        for (final item in day.items) {
          if (item.location != null && item.location!.isNotEmpty) {
            locations.add(item.location!);
          }
        }
      }
      
      if (locations.isNotEmpty) {
        final locationContent = 'Locations visited in ${trip.title}: ${locations.join(', ')}';
        await _vectorStoreService.addDocument(
          id: 'trip_${trip.id}_locations',
          content: locationContent,
          metadata: {
            'type': 'trip_locations',
            'trip_id': trip.id,
            'locations_count': locations.length,
          },
        );
      }
      
    } catch (e) {
      _logger.e('Error caching trip: $e');
    }
  }

  /// Helper methods for text extraction
  String _extractLocationFromText(String text) {
    // Simple regex to find location patterns
    final locationRegex = RegExp(r'\b([A-Z][a-z]+(?:\s+[A-Z][a-z]+)*(?:,\s*[A-Z][a-z]+)?)\b');
    final match = locationRegex.firstMatch(text);
    return match?.group(1) ?? '';
  }

  List<String> _extractCurrenciesFromText(String text) {
    final currencyRegex = RegExp(r'\b([A-Z]{3})\b');
    final matches = currencyRegex.allMatches(text);
    return matches.map((m) => m.group(1)!).toList();
  }

  String _extractLocationInfo(String prompt) {
    // Extract location information from prompt
    final locationKeywords = ['to', 'in', 'visit', 'travel', 'trip'];
    final words = prompt.toLowerCase().split(' ');
    
    // First try to find location after keywords
    for (int i = 0; i < words.length - 1; i++) {
      if (locationKeywords.contains(words[i])) {
        final location = words[i + 1].replaceAll(RegExp(r'[^a-zA-Z]'), '');
        if (location.isNotEmpty) {
          return location;
        }
      }
    }
    
    // Try to find common city/country names in the prompt
    final commonDestinations = [
      'paris', 'london', 'tokyo', 'new york', 'rome', 'barcelona', 'amsterdam',
      'berlin', 'prague', 'vienna', 'budapest', 'istanbul', 'dubai', 'singapore',
      'bangkok', 'sydney', 'melbourne', 'los angeles', 'san francisco', 'chicago',
      'miami', 'las vegas', 'seattle', 'boston', 'washington', 'toronto', 'vancouver'
    ];
    
    for (final destination in commonDestinations) {
      if (prompt.toLowerCase().contains(destination)) {
        return destination;
      }
    }
    
    // If no location found, return empty (will be handled by improvisation)
    return '';
  }

  /// Add user location context to prompt if available
  void _addUserLocationContext(StringBuffer buffer) {
    try {
      // Try to get user location synchronously from cache or last known location
      // This is a non-blocking approach to avoid delays in prompt generation
      _locationService.getCurrentLocationString().then((locationString) {
        if (locationString != null) {
          _logger.i('User location available for context: $locationString');
        }
      }).catchError((e) {
        _logger.w('Could not get user location for context: $e');
      });
      
      // Add location context instruction
      buffer.writeln('\nUser Location Context:');
      buffer.writeln('• If user location is needed for recommendations, consider their current position');
      buffer.writeln('• Provide location-aware suggestions when relevant (nearby attractions, local transportation, etc.)');
      buffer.writeln('• If planning trips, consider distance from user\'s current location');
    } catch (e) {
      _logger.w('Error adding location context: $e');
    }
  }

  String _extractDateInfo(String prompt) {
    // Try multiple date formats
    final datePatterns = [
      RegExp(r'\b\d{1,2}[/-]\d{1,2}[/-]\d{2,4}\b'), // MM/DD/YYYY or DD/MM/YYYY
      RegExp(r'\b\d{4}-\d{1,2}-\d{1,2}\b'), // YYYY-MM-DD
      RegExp(r'\b(january|february|march|april|may|june|july|august|september|october|november|december)\s+\d{1,2}', caseSensitive: false), // Month DD
      RegExp(r'\b(jan|feb|mar|apr|may|jun|jul|aug|sep|oct|nov|dec)\s+\d{1,2}', caseSensitive: false), // Mon DD
    ];
    
    for (final pattern in datePatterns) {
      final match = pattern.firstMatch(prompt);
      if (match != null) {
        return match.group(0)!;
      }
    }
    
    // Look for relative dates
    final relativeDates = {
      'tomorrow': DateTime.now().add(const Duration(days: 1)).toString().split(' ')[0],
      'next week': DateTime.now().add(const Duration(days: 7)).toString().split(' ')[0],
      'next month': DateTime.now().add(const Duration(days: 30)).toString().split(' ')[0],
      'this weekend': _getNextWeekend().toString().split(' ')[0],
    };
    
    for (final entry in relativeDates.entries) {
      if (prompt.toLowerCase().contains(entry.key)) {
        return entry.value;
      }
    }
    
    return ''; // Will be handled by improvisation with default dates
  }
  
  DateTime _getNextWeekend() {
    final now = DateTime.now();
    final daysUntilSaturday = (6 - now.weekday) % 7;
    return now.add(Duration(days: daysUntilSaturday == 0 ? 7 : daysUntilSaturday));
  }
  
  String _extractDuration(String prompt) {
    // Look for duration indicators
    final durationPatterns = [
      RegExp(r'(\d+)\s*(day|days)', caseSensitive: false),
      RegExp(r'(\d+)\s*(week|weeks)', caseSensitive: false),
      RegExp(r'(\d+)\s*(night|nights)', caseSensitive: false),
    ];
    
    for (final pattern in durationPatterns) {
      final match = pattern.firstMatch(prompt);
      if (match != null) {
        return match.group(0)!;
      }
    }
    
    // Look for common duration phrases
    final durationPhrases = {
      'weekend': '2 days',
      'long weekend': '3 days',
      'week': '7 days',
      'short trip': '2 days',
      'quick trip': '1 day',
    };
    
    for (final entry in durationPhrases.entries) {
      if (prompt.toLowerCase().contains(entry.key)) {
        return entry.value;
      }
    }
    
    return '';
  }
  
  String _extractBudget(String prompt) {
    // Look for budget indicators
    final budgetKeywords = {
      'budget': 'budget-friendly',
      'cheap': 'budget-friendly',
      'affordable': 'budget-friendly',
      'luxury': 'luxury',
      'expensive': 'luxury',
      'premium': 'luxury',
      'mid-range': 'mid-range',
      'moderate': 'mid-range',
    };
    
    for (final entry in budgetKeywords.entries) {
      if (prompt.toLowerCase().contains(entry.key)) {
        return entry.value;
      }
    }
    
    // Look for currency amounts
    final currencyPattern = RegExp(r'\$\d+|€\d+|£\d+|¥\d+');
    final match = currencyPattern.firstMatch(prompt);
    if (match != null) {
      return 'specific budget: ${match.group(0)}';
    }
    
    return '';
  }
  
  String _extractPreferences(String prompt) {
    final preferences = <String>[];
    
    // Activity preferences
    final activityKeywords = {
      'adventure': ['adventure', 'hiking', 'climbing', 'outdoor', 'extreme', 'sports'],
      'cultural': ['cultural', 'museum', 'history', 'heritage', 'art', 'architecture'],
      'relaxation': ['relaxation', 'spa', 'beach', 'resort', 'peaceful', 'calm'],
      'nightlife': ['nightlife', 'bars', 'clubs', 'party', 'entertainment'],
      'food': ['food', 'restaurant', 'cuisine', 'dining', 'culinary', 'local food'],
      'shopping': ['shopping', 'markets', 'boutiques', 'souvenirs'],
      'nature': ['nature', 'parks', 'wildlife', 'scenic', 'landscape'],
      'family': ['family', 'kids', 'children', 'playground', 'family-friendly'],
    };
    
    for (final category in activityKeywords.entries) {
      for (final keyword in category.value) {
        if (prompt.toLowerCase().contains(keyword)) {
          preferences.add(category.key);
          break;
        }
      }
    }
    
    return preferences.join(', ');
  }

  bool _isInternationalTravel(String prompt) {
    final internationalKeywords = ['international', 'abroad', 'overseas', 'foreign'];
    return internationalKeywords.any((keyword) => prompt.toLowerCase().contains(keyword));
  }

  String _extractCountryCode(String prompt) {
    // Simple country code extraction - in production, use a proper mapping
    final countryMappings = {
      'japan': 'JP',
      'usa': 'US',
      'uk': 'GB',
      'france': 'FR',
      'germany': 'DE',
      'italy': 'IT',
      'spain': 'ES',
    };
    
    for (final entry in countryMappings.entries) {
      if (prompt.toLowerCase().contains(entry.key)) {
        return entry.value;
      }
    }
    return 'US';
  }

  String _extractTripType(String query) {
    final tripTypes = {
      'adventure': ['adventure', 'hiking', 'climbing', 'outdoor', 'extreme'],
      'cultural': ['cultural', 'museum', 'history', 'heritage', 'art'],
      'relaxation': ['relaxation', 'spa', 'beach', 'resort', 'peaceful'],
      'business': ['business', 'conference', 'meeting', 'work'],
      'family': ['family', 'kids', 'children', 'playground'],
      'romantic': ['romantic', 'honeymoon', 'couple', 'date'],
      'food': ['food', 'culinary', 'restaurant', 'cuisine', 'dining'],
      'shopping': ['shopping', 'mall', 'market', 'boutique'],
    };
    
    final lowerQuery = query.toLowerCase();
    for (final entry in tripTypes.entries) {
      if (entry.value.any((keyword) => lowerQuery.contains(keyword))) {
        return entry.key;
      }
    }
    return '';
  }

  String _buildChatPrompt(List<ChatMessage> messages) {
    final buffer = StringBuffer();
    buffer.writeln('You are an intelligent travel planning assistant with algorithmic problem-solving capabilities.');
    buffer.writeln('\nThinking Framework:');
    buffer.writeln('• DECOMPOSE: Break complex requests into manageable components');
    buffer.writeln('• PRIORITIZE: Rank options by user preferences and practical constraints');
    buffer.writeln('• SYNTHESIZE: Combine multiple data sources for comprehensive recommendations');
    buffer.writeln('• ITERATE: Refine suggestions based on user feedback');
    
    // Add user location context if available
    _addUserLocationContext(buffer);
    
    buffer.writeln('\nPrevious conversation:');
    
    for (final message in messages) {
      final sender = message.type == ChatMessageType.user ? "User" : "Assistant";
      buffer.writeln('$sender: ${message.content}');
    }
    
    buffer.writeln('\nApply systematic thinking to provide the most helpful and optimized travel advice.');
    
    return buffer.toString();
  }

  String _buildPromptWithToolResults(List<ChatMessage> messages, List<ToolResult> toolResults) {
    final buffer = StringBuffer();
    buffer.writeln(_buildChatPrompt(messages));
    buffer.writeln('\nTool Results:');
    
    bool hasTripItinerary = false;
    String? tripJson;
    
    for (final result in toolResults) {
      buffer.writeln('• ${result.result}');
      
      // Check if this is a trip itinerary result with JSON
      if (result.result.contains('Generated detailed itinerary') && result.result.contains('{')) {
        hasTripItinerary = true;
        final jsonStart = result.result.indexOf('{');
        final jsonEnd = result.result.lastIndexOf('}') + 1;
        if (jsonStart != -1 && jsonEnd > jsonStart) {
          tripJson = result.result.substring(jsonStart, jsonEnd);
        }
      }
    }
    
    if (hasTripItinerary && tripJson != null) {
      buffer.writeln('\nIMPORTANT: A trip itinerary has been generated. Please return ONLY the JSON data below without any additional text or formatting:');
      buffer.writeln(tripJson);
    } else {
      buffer.writeln('\nPlease provide a helpful response based on the above information.');
    }
    
    return buffer.toString();
  }

  String _buildPromptWithCachedInfo(List<ChatMessage> messages, List<String> cachedInfo) {
    final buffer = StringBuffer();
    buffer.writeln(_buildChatPrompt(messages));
    buffer.writeln('\nRelevant cached information:');
    
    for (final info in cachedInfo) {
      buffer.writeln('• $info');
    }
    
    return buffer.toString();
  }

  String _buildEnhancedItineraryPrompt(String userPrompt, Trip? existingTrip, List<String> contextualInfo) {
    final buffer = StringBuffer();
    buffer.writeln('You are an expert travel planner with algorithmic thinking and optimization capabilities.');
    buffer.writeln('\nAlgorithmic Planning Approach:');
    buffer.writeln('1. ANALYZE: Break down the request into components (duration, preferences, constraints)');
    buffer.writeln('2. OPTIMIZE: Consider travel efficiency, time management, and cost-effectiveness');
    buffer.writeln('3. BALANCE: Distribute activities across days for optimal experience');
    buffer.writeln('4. VALIDATE: Ensure logical flow and realistic timing between activities');
    
    // Add improvisation instructions for missing details
    buffer.writeln('\nIMPROVISATION GUIDELINES:');
    buffer.writeln('When details are missing, intelligently fill in gaps using these defaults:');
    buffer.writeln('• If no destination specified: Use context clues or suggest popular destinations');
    buffer.writeln('• If no dates provided: Create a 3-day itinerary starting from tomorrow');
    buffer.writeln('• If no duration specified: Default to 2-3 days based on destination type');
    buffer.writeln('• If no preferences given: Include a balanced mix of culture, food, and sightseeing');
    buffer.writeln('• If no budget mentioned: Assume mid-range options with both budget and premium alternatives');
    buffer.writeln('• If no accommodation specified: Suggest centrally located mid-range hotels');
    buffer.writeln('• Always provide specific times, locations, and detailed descriptions even if not requested');
    
    if (contextualInfo.isNotEmpty) {
      buffer.writeln('\nReal-time Contextual Data:');
      for (final info in contextualInfo) {
        buffer.writeln('• $info');
      }
    }
    
    if (existingTrip != null) {
      buffer.writeln('\nExisting trip to optimize: ${existingTrip.title}');
      buffer.writeln('Apply incremental improvements while maintaining trip coherence.');
    }
    
    buffer.writeln('\nOptimization Constraints:');
    buffer.writeln('• Minimize travel time between locations');
    buffer.writeln('• Balance activity intensity throughout the day');
    buffer.writeln('• Consider opening hours and seasonal factors');
    buffer.writeln('• Include buffer time for unexpected delays');
    
    buffer.writeln('\nUser request: $userPrompt');
    buffer.writeln('\nGenerate an algorithmically optimized travel itinerary with detailed reasoning for activity sequencing.');
    buffer.writeln('IMPORTANT: Even if the user provides minimal information, create a complete, detailed itinerary by intelligently filling in missing details.');
    
    // Add strict JSON format requirement with detailed examples
    buffer.writeln('\nRESPONSE FORMAT REQUIREMENT:');
    buffer.writeln('You MUST respond with ONLY a valid JSON object in this exact format. Include DETAILED information for each field and do not leave any empty fields:');
    buffer.writeln('\nDo NOT include any explanatory text, markdown formatting, or code blocks. Return ONLY the JSON object no icons.');
    buffer.writeln('{');
    buffer.writeln('  "title": "Descriptive trip title with destination",');
    buffer.writeln('  "startDate": "YYYY-MM-DD",');
    buffer.writeln('  "endDate": "YYYY-MM-DD",');
    buffer.writeln('  "days": [');
    buffer.writeln('    {');
    buffer.writeln('      "date": "YYYY-MM-DD",');
    buffer.writeln('      "summary": "Detailed day summary with main highlights",');
    buffer.writeln('      "items": [');
    buffer.writeln('        {');
        buffer.writeln('          "time": "HH:MM",');
        buffer.writeln('          "activity": "Detailed activity name and what you will do",');
        buffer.writeln('          "location": "Specific location name, address, or landmark",');
        buffer.writeln('          "description": "Detailed description of the activity, what to expect, highlights",');
        buffer.writeln('          "cost": "Estimated cost with currency (e.g., \$25-50 per person)",');
        buffer.writeln('          "notes": "Useful tips, opening hours, booking requirements, what to bring",');
        buffer.writeln('          "latitude": 0.0,');
        buffer.writeln('          "longitude": 0.0');
        buffer.writeln('        }');
    buffer.writeln('      ]');
    buffer.writeln('    }');
    buffer.writeln('  ]');
    buffer.writeln('}');
    buffer.writeln('\nIMPORTANT: Fill ALL fields with detailed, specific information. Do not use generic placeholders.');
    buffer.writeln('- activity: Be specific about what the person will do');
    buffer.writeln('- location: Include specific venue names, addresses, or landmarks');
    buffer.writeln('- description: Provide rich details about the experience');
    buffer.writeln('- cost: Include realistic price estimates');
    buffer.writeln('- notes: Add practical tips and useful information');
    
    // Add example JSON format
    buffer.writeln('\nEXAMPLE JSON FORMAT:');
    buffer.writeln('{');
    buffer.writeln('  "title": "🌟 Magical Paris Adventure",');
    buffer.writeln('  "startDate": "2024-01-15",');
    buffer.writeln('  "endDate": "2024-01-17",');
    buffer.writeln('  "description": "A comprehensive 3-day journey through Paris exploring iconic landmarks, cultural sites, and local cuisine with detailed itinerary and practical information.",');
    buffer.writeln('  "totalCost": "€450-650 per person",');
    buffer.writeln('  "currency": "EUR",');
    buffer.writeln('  "difficulty": "Easy",');
    buffer.writeln('  "tags": ["Culture", "History", "Food", "Architecture", "Romance"],');
    buffer.writeln('  "days": [');
    buffer.writeln('    {');
    buffer.writeln('      "date": "2024-01-15",');
    buffer.writeln('      "summary": "Arrival & Classic Paris - Discover iconic landmarks and get oriented in the City of Light",');
    buffer.writeln('      "totalDayCost": "€150-200",');
    buffer.writeln('      "items": [');
    buffer.writeln('        {');
    buffer.writeln('          "time": "10:00 AM",');
    buffer.writeln('          "activity": "Arrive at Charles de Gaulle Airport",');
    buffer.writeln('          "location": "Charles de Gaulle Airport, Terminal 2E, Paris",');
    buffer.writeln('          "description": "Welcome to the City of Light! Clear customs and immigration. Take the RER B train directly to central Paris - it\'s the most efficient and cost-effective way to reach the city center.",');
    buffer.writeln('          "cost": "€12 per person",');
    buffer.writeln('          "notes": "Buy a Navigo Easy card for convenient metro travel throughout your stay. Journey takes 45-60 minutes to city center.",');
    buffer.writeln('          "duration": "1 hour",');
    buffer.writeln('          "category": "Transportation",');
    buffer.writeln('          "latitude": 49.0097,');
    buffer.writeln('          "longitude": 2.5479');
    buffer.writeln('        },');
    buffer.writeln('        {');
    buffer.writeln('          "time": "2:00 PM",');
    buffer.writeln('          "activity": "Visit the Eiffel Tower",');
    buffer.writeln('          "location": "Champ de Mars, 5 Avenue Anatole France, 75007 Paris",');
    buffer.writeln('          "description": "Iconic 330-meter iron lattice tower and symbol of Paris. Take the elevator to the second floor for breathtaking panoramic views of the city. Perfect for photos and understanding Paris\' layout.",');
    buffer.writeln('          "cost": "€29 per person (elevator to 2nd floor)",');
    buffer.writeln('          "notes": "Book tickets online in advance to skip long queues. Best photo spots are from Trocadéro Gardens across the river. Visit during golden hour for stunning photos.",');
    buffer.writeln('          "duration": "2-3 hours",');
    buffer.writeln('          "category": "Sightseeing",');
    buffer.writeln('          "latitude": 48.8584,');
    buffer.writeln('          "longitude": 2.2945');
    buffer.writeln('        }');
    buffer.writeln('      ]');
    buffer.writeln('    }');
    buffer.writeln('  ],');
    buffer.writeln('  "totalTokensUsed": 0');
    buffer.writeln('}');
    
    buffer.writeln('\nIMPORTANT REQUIREMENTS:');
    buffer.writeln('- Return ONLY the JSON object with detailed information in this exact format');
    buffer.writeln('- DO NOT include any debug items, test entries, or placeholder activities');
    buffer.writeln('- Every activity must be a real, actionable item with specific details');
    buffer.writeln('- Include duration and category fields for each activity item');
    buffer.writeln('- Provide realistic cost estimates with currency symbols');
    buffer.writeln('- Add comprehensive descriptions with practical information');
    buffer.writeln('- Include trip-level metadata: description, totalCost, currency, difficulty, tags');

    
    return buffer.toString();
  }

  Stream<String> _generateResponseWithFallback(String prompt, {String requestType = 'chat'}) async* {
    // Check cache first
    final cacheKey = prompt.hashCode.toString();
    final cachedResponse = _getCachedResponse(cacheKey);
    if (cachedResponse != null) {
      yield '💾 Using cached response...\n\n';
      // Stream cached response in chunks for better UX
      yield* _streamTextInChunks(cachedResponse);
      return;
    }
    
    // Priority: OpenRouter (DeepSeek R1) -> Gemini -> OpenAI -> Offline fallback
    try {
      // Try OpenRouter first (DeepSeek R1)
      final openRouterService = OpenRouterService(
        dioClient: _dioClient,
        apiKey: AppConstants.openRouterApiKey,
      );
      
      final response = await openRouterService.generateContent(
        text: prompt,
        maxTokens: 8000,
        temperature: 0.7,
      );
      
      // Track token usage for OpenRouter
      _tokenTrackingService.trackEstimatedUsage(
        estimatedTokens: (prompt.length / 4).round() + (response.length / 4).round(),
        requestType: requestType,
        model: 'deepseek-r1',
      );
      
      _cacheResponse(cacheKey, response);
      
      // Stream the response in chunks
      yield* _streamTextInChunks(response);
      
    } catch (e) {
      _logger.w('OpenRouter failed, trying Gemini fallback: $e');
      yield 'Switching to backup AI service...\n\n';
      
      try {
        final response = await GeminiService.generateContent(text: prompt)
            .timeout(const Duration(seconds: 20));
        
        // Track token usage (estimated for Gemini)
        _tokenTrackingService.trackEstimatedUsage(
          estimatedTokens: (prompt.length / 4).round() + (response.length / 4).round(),
          requestType: requestType,
          model: 'gemini-2.0-flash',
        );
        
        _cacheResponse(cacheKey, response);
        
        // Stream the response in chunks to simulate real-time typing
        yield* _streamTextInChunks(response);
        
      } catch (geminiError) {
        _logger.w('Gemini failed, using OpenAI fallback: $geminiError');
        
        try {
            // Try OpenAI fallback with proper API key validation
            final openaiApiKey = const String.fromEnvironment('OPENAI_API_KEY', defaultValue: 'your-openai-api-key-here');
            
            if (openaiApiKey.isEmpty || openaiApiKey == 'your-openai-api-key-here') {
              yield 'AI services are temporarily unavailable. Please try again later.';
              return;
            }
            
            // For chat responses, use a simple OpenAI chat completion instead of itinerary generation
            final fallbackResponse = 'I apologize, but I\'m currently experiencing technical difficulties with my primary AI service. However, I can still help you with basic trip planning questions. Please try asking about specific destinations, dates, or activities you\'d like to include in your trip.';
            yield* _streamTextInChunks(fallbackResponse);
            
          } catch (fallbackError) {
            yield 'I\'m currently experiencing technical difficulties. Please try again later.';
          }
      }
    }
  }
  
  /// Stream text in chunks to simulate real-time typing effect
  Stream<String> _streamTextInChunks(String text) async* {
    const chunkSize = 50; // Characters per chunk
    const delayMs = 50; // Milliseconds between chunks
    
    for (int i = 0; i < text.length; i += chunkSize) {
      final end = (i + chunkSize < text.length) ? i + chunkSize : text.length;
      final chunk = text.substring(i, end);
      yield chunk;
      
      // Add small delay between chunks for typing effect
      if (end < text.length) {
        await Future.delayed(const Duration(milliseconds: delayMs));
      }
    }
  }
  
  String? _getCachedResponse(String key) {
    final timestamp = _cacheTimestamps[key];
    if (timestamp != null && DateTime.now().difference(timestamp) < _cacheValidDuration) {
      return _responseCache[key];
    }
    // Clean up expired cache
    _responseCache.remove(key);
    _cacheTimestamps.remove(key);
    return null;
  }
  
  void _cacheResponse(String key, String response) {
    _responseCache[key] = response;
    _cacheTimestamps[key] = DateTime.now();
    
    // Clean up old cache entries if too many
    if (_responseCache.length > 50) {
      final oldestKey = _cacheTimestamps.entries
          .reduce((a, b) => a.value.isBefore(b.value) ? a : b)
          .key;
      _responseCache.remove(oldestKey);
      _cacheTimestamps.remove(oldestKey);
    }
  }

  /// Create a basic offline trip when all AI services fail
  Trip _createBasicOfflineTrip(String userPrompt, Trip? existingTrip) {
    final destination = _extractDestination(userPrompt) ?? 'Your Destination';
    final duration = _extractDurationValue(userPrompt) ?? 3;
    final startDate = DateTime.now().add(const Duration(days: 1));
    
    return Trip(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: 'Basic Trip to $destination',
      startDate: startDate,
      endDate: startDate.add(Duration(days: duration - 1)),
      days: List.generate(duration, (index) => DayItinerary(
        date: startDate.add(Duration(days: index)),
        summary: 'Day ${index + 1} in $destination',
        items: [
          ItineraryItem(
            time: '09:00 AM',
            activity: 'Explore $destination',
            location: destination,
            description: 'AI services are temporarily unavailable. Please manually plan your activities.',
          ),
        ],
      )),
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      totalTokensUsed: 0,
    );
  }

  /// Extract destination from user prompt
  String? _extractDestination(String prompt) {
    final lowerPrompt = prompt.toLowerCase();
    final patterns = [
      RegExp(r'to ([a-zA-Z\s]+?)(?:\s|,|\.|$)'),
      RegExp(r'in ([a-zA-Z\s]+?)(?:\s|,|\.|$)'),
      RegExp(r'visit ([a-zA-Z\s]+?)(?:\s|,|\.|$)'),
    ];
    
    for (final pattern in patterns) {
      final match = pattern.firstMatch(lowerPrompt);
      if (match != null) {
        return match.group(1)?.trim();
      }
    }
    return null;
  }

  /// Extract duration from user prompt
  int? _extractDurationValue(String prompt) {
    final lowerPrompt = prompt.toLowerCase();
    final patterns = [
      RegExp(r'(\d+)\s*days?'),
      RegExp(r'(\d+)\s*day'),
      RegExp(r'for\s*(\d+)'),
    ];
    
    for (final pattern in patterns) {
      final match = pattern.firstMatch(lowerPrompt);
      if (match != null) {
        return int.tryParse(match.group(1) ?? '');
      }
    }
    return null;
  }

  Future<Trip> _generateItineraryWithOpenAI(String prompt, Trip? existingTrip) async {
    final openaiApiKey = const String.fromEnvironment('OPENAI_API_KEY', defaultValue: '');
    
    // Check if OpenAI API key is configured
    if (openaiApiKey.isEmpty || openaiApiKey == 'your-openai-api-key-here') {
      _logger.w('OpenAI API key not configured, using offline fallback');
      throw Exception('OpenAI API key not configured. Please set OPENAI_API_KEY environment variable');
    }
    
    try {
      // Use OpenAI API directly for structured JSON generation
      final response = await _dioClient.post(
        'https://api.openai.com/v1/chat/completions',
        data: {
          'model': 'gpt-4',
          'messages': [
            {'role': 'user', 'content': prompt}
          ],
          'functions': _getFunctionDefinitions(),
          'function_call': {'name': 'generate_itinerary'},
          'stream': false,
        },
        options: Options(
          headers: {
            'Authorization': 'Bearer $openaiApiKey',
            'Content-Type': 'application/json',
          },
        ),
      );
      
      final responseData = response.data['choices'][0]['message']['function_call']['arguments'];
      return _parseItineraryResponse(responseData);
    } catch (e) {
      _logger.e('OpenAI generation failed: $e');
      rethrow;
    }
  }

  /// Parses an AI-generated itinerary response and converts it to a Trip object.
  /// 
  /// This method extracts JSON data from AI responses that may contain additional
  /// text or formatting. It handles responses from both Gemini and OpenAI models
  /// by locating the JSON boundaries and parsing the structured trip data.
  /// 
  /// [response] The raw AI response string that contains JSON trip data
  /// 
  /// Returns a [Trip] object with parsed itinerary information including:
  /// - Trip title and description
  /// - Daily itineraries with activities, times, and locations
  /// - Budget information and travel tips
  /// 
  /// Throws [Failure.validation] if no valid JSON is found in the response
  /// Throws [Failure.server] if JSON parsing or trip conversion fails
  Trip _parseItineraryResponse(String response) {
    try {
      // Use JsonExtractor to handle various AI response formats
      final json = JsonExtractor.extractJson(response);
      
      if (json == null) {
        _logger.w('No valid JSON found in AI response. Response length: ${response.length}');
        _logger.d('Response preview: ${response.length > 200 ? response.substring(0, 200) + '...' : response}');
        throw Failure.validation(message: 'No valid JSON found in AI response. The AI may have provided an incomplete or malformed response.');
      }
      
      _logger.d('Successfully extracted JSON from AI response');
      
      // Convert the parsed JSON to a Trip object using the helper method
      return _jsonToTrip(json);
    } catch (e) {
      // Log the error for debugging purposes
      _logger.e('Failed to parse itinerary response: $e');
      // Throw a user-friendly error that can be handled by the UI
      throw const Failure.server(message: 'Failed to parse AI response', statusCode: 500);
    }
  }

  Trip _jsonToTrip(Map<String, dynamic> json) {
    try {
      // Validate required fields exist and are not null
      if (json['title'] == null || json['startDate'] == null || json['endDate'] == null || json['days'] == null) {
        _logger.e('Missing required fields in JSON: ${json.keys}');
        throw Failure.validation(message: 'Missing required fields in JSON: title, startDate, endDate, or days');
      }
      
      final daysData = json['days'];
      if (daysData is! List) {
        _logger.e('Days field is not a valid list: ${daysData.runtimeType}');
        throw Failure.validation(message: 'Days field is not a valid list');
      }
      
      final days = daysData.map((dayJson) {
        if (dayJson == null || dayJson is! Map<String, dynamic>) {
          _logger.e('Invalid day data structure: $dayJson');
          throw Failure.validation(message: 'Invalid day data structure');
        }
        
        final itemsData = dayJson['items'];
        if (itemsData == null || itemsData is! List) {
          _logger.e('Items field is missing or not a valid list: $itemsData');
          throw Failure.validation(message: 'Items field is missing or not a valid list');
        }
        
        final items = itemsData.map((itemJson) {
          if (itemJson == null || itemJson is! Map<String, dynamic>) {
            _logger.e('Invalid item data structure: $itemJson');
            throw Failure.validation(message: 'Invalid item data structure');
          }
          
          final latitude = itemJson['latitude'] as double?;
          final longitude = itemJson['longitude'] as double?;
          String location = itemJson['location'] as String? ?? '';
          
          // If we have coordinates but location doesn't contain them, use coordinates as location
          if (latitude != null && longitude != null && !location.contains(',')) {
            location = '$latitude,$longitude';
          }
          
          return ItineraryItem(
            time: itemJson['time'] as String? ?? '',
            activity: itemJson['activity'] as String? ?? '',
            location: location,
            description: itemJson['description'] as String?,
            cost: itemJson['cost'] as String?,
            notes: itemJson['notes'] as String?,
            latitude: latitude,
            longitude: longitude,
          );
        }).toList();
        
        return DayItinerary(
          date: DateTime.parse(dayJson['date'] as String? ?? DateTime.now().toIso8601String()),
          summary: dayJson['summary'] as String? ?? '',
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
        totalTokensUsed: json['totalTokensUsed'] as int? ?? 0,
      );
    } catch (e) {
      _logger.e('Failed to convert JSON to Trip: $e');
      _logger.e('JSON data: $json');
      throw Failure.validation(message: 'Invalid trip data format: ${e.toString()}');
    }
  }

  List<Map<String, dynamic>> _getFunctionDefinitions() {
    return [
      {
        'name': 'generate_itinerary',
        'description': 'Generate a structured travel itinerary with detailed activities and locations',
        'parameters': {
          'type': 'object',
          'properties': {
            'title': {
              'type': 'string',
              'description': 'Descriptive title of the trip',
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
                    'description': 'Brief summary of the day\'s theme',
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
                          'description': 'Detailed activity description',
                        },
                        'location': {
                          'type': 'string',
                          'description': 'Location coordinates in lat,lng format or address',
                        },
                        'description': {
                          'type': 'string',
                          'description': 'Optional additional details about the activity',
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
            'totalTokensUsed': {
              'type': 'integer',
              'description': 'Estimated tokens used for this generation',
            },
          },
          'required': ['title', 'startDate', 'endDate', 'days'],
        },
      },
    ];
  }
}

// Provider for EnhancedAIAgentService
final enhancedAIAgentServiceProvider = Provider<EnhancedAIAgentService>((ref) {
  final dioClient = ref.read(dioClientProvider);
  final weatherService = ref.read(weatherServiceProvider);
  final currencyService = ref.read(currencyServiceProvider);
  final vectorStoreService = ref.read(vectorStoreServiceProvider);
  final pathfindingService = ref.read(pathfindingServiceProvider);
  final tokenTrackingService = ref.read(tokenTrackingServiceProvider.notifier);
  final locationService = ref.read(locationServiceProvider);
  
  return EnhancedAIAgentService(
    dioClient: dioClient,
    weatherService: weatherService,
    currencyService: currencyService,
    vectorStoreService: vectorStoreService,
    pathfindingService: pathfindingService,
    locationService: locationService,
    tokenTrackingService: tokenTrackingService,
    apiKey: const String.fromEnvironment('GEMINI_API_KEY', defaultValue: ''),
  );
});