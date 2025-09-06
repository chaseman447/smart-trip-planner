import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/network/dio_client.dart';
import '../../core/errors/failures.dart';

class WebSearchService {
  final DioClient _dioClient;
  
  WebSearchService(this._dioClient);

  /// Performs web search using DuckDuckGo Instant Answer API
  /// This is a free alternative to Google Custom Search
  Future<String> searchWeb(String query) async {
    try {
      // Use DuckDuckGo Instant Answer API (free, no API key required)
      final response = await _dioClient.get(
        'https://api.duckduckgo.com/',
        queryParameters: {
          'q': query,
          'format': 'json',
          'no_html': '1',
          'skip_disambig': '1',
        },
      );

      final data = response.data;
      final results = <String>[];

      // Extract abstract if available
      if (data['Abstract'] != null && data['Abstract'].toString().isNotEmpty) {
        results.add('Summary: ${data['Abstract']}');
      }

      // Extract definition if available
      if (data['Definition'] != null && data['Definition'].toString().isNotEmpty) {
        results.add('Definition: ${data['Definition']}');
      }

      // Extract answer if available
      if (data['Answer'] != null && data['Answer'].toString().isNotEmpty) {
        results.add('Answer: ${data['Answer']}');
      }

      // Extract related topics
      if (data['RelatedTopics'] != null && data['RelatedTopics'] is List) {
        final topics = data['RelatedTopics'] as List;
        for (int i = 0; i < topics.length && i < 3; i++) {
          final topic = topics[i];
          if (topic['Text'] != null) {
            results.add('Related: ${topic['Text']}');
          }
        }
      }

      if (results.isEmpty) {
        return 'No specific information found for "$query". You may want to search for more general terms or check official tourism websites.';
      }

      return results.join('\n\n');
    } on DioException catch (e) {
      if (e.response?.statusCode == 429) {
        throw const Failure.server(message: 'Search rate limit exceeded', statusCode: 429);
      } else {
        throw Failure.network(message: 'Failed to perform web search: ${e.message}');
      }
    } catch (e) {
      throw Failure.unknown(message: 'Web search error: ${e.toString()}');
    }
  }

  /// Searches for travel-specific information
  Future<String> searchTravelInfo(String destination, String type) async {
    final queries = {
      'attractions': '$destination tourist attractions things to do',
      'restaurants': '$destination best restaurants local food',
      'hotels': '$destination hotels accommodation where to stay',
      'weather': '$destination weather climate best time to visit',
      'transportation': '$destination transportation getting around public transport',
      'culture': '$destination culture customs local traditions',
    };

    final query = queries[type] ?? '$destination $type';
    return await searchWeb(query);
  }

  /// Searches for current events or real-time information
  Future<String> searchCurrentInfo(String location) async {
    final query = '$location current events news today';
    return await searchWeb(query);
  }
}

// Provider for WebSearchService
final webSearchServiceProvider = Provider<WebSearchService>((ref) {
  final dioClient = ref.read(dioClientProvider);
  return WebSearchService(dioClient);
});