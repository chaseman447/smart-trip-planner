import 'dart:convert';
import 'dart:async';
import 'package:dio/dio.dart';
import '../../core/network/dio_client.dart';
import '../../core/errors/failures.dart';

class OpenRouterService {
  final DioClient _dioClient;
  final String _apiKey;
  static const String _baseUrl = 'https://openrouter.ai/api/v1';

  OpenRouterService({
    required DioClient dioClient,
    required String apiKey,
  }) : _dioClient = dioClient,
       _apiKey = apiKey;

  Future<String> generateContent({
    required String text,
    String model = 'deepseek/deepseek-r1-0528:free',
    int maxTokens = 8000,
    double temperature = 0.7,
  }) async {
    try {
      final response = await _dioClient.post(
        '$_baseUrl/chat/completions',
        data: {
          'model': model,
          'messages': [
          {
            'role': 'system',
            'content': 'You are a helpful travel planning assistant. When generating trip itineraries, provide a comprehensive response that includes:\n\n1. A clear, engaging title and overview\n2. Detailed day-by-day descriptions\n3. Complete JSON data with all required fields\n\nEnsure your response is complete and not truncated. Always provide the full itinerary with all days, activities, and JSON structure. The JSON should include title, description, days array with detailed activities, budget information, and travel tips.',
          },
          {
            'role': 'user',
            'content': text,
          },
        ],
        'max_tokens': maxTokens,
        'temperature': temperature,
        },
        options: Options(
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $_apiKey',
          },
        ),
      );

      if (response.statusCode == 200) {
        final data = response.data;
        print('🔍 OpenRouter Raw Response Data: ${jsonEncode(data)}');
        
        if (data['choices'] != null && data['choices'].isNotEmpty) {
          final content = data['choices'][0]['message']['content'] as String;
          print('🔍 OpenRouter Response Content: $content');
          print('🔍 OpenRouter Content Length: ${content.length}');
          print('🔍 OpenRouter Content Type: ${content.runtimeType}');
          return content;
        } else {
          print('❌ OpenRouter Invalid Response: No choices found');
          throw Failure.server(
            message: 'Invalid response format from OpenRouter API',
            statusCode: response.statusCode ?? 500,
          );
        }
      } else {
        throw Failure.server(
          message: 'OpenRouter API error: ${response.statusMessage}',
          statusCode: response.statusCode ?? 500,
        );
      }
    } on DioException catch (e) {
      if (e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.receiveTimeout ||
          e.type == DioExceptionType.sendTimeout) {
        throw Failure.network(
          message: 'OpenRouter API timeout. Please try again.',
        );
      } else if (e.type == DioExceptionType.connectionError) {
        throw Failure.network(
          message: 'Network error connecting to OpenRouter API',
        );
      } else {
        throw Failure.server(
          message: 'OpenRouter API error: ${e.message}',
          statusCode: e.response?.statusCode ?? 500,
        );
      }
    } catch (e) {
      throw Failure.unknown(
        message: 'Unexpected error with OpenRouter API: ${e.toString()}',
      );
    }
  }

  Future<String> generateChatResponse({
    required String text,
    String model = 'deepseek/deepseek-r1-0528:free',
    int maxTokens = 2000,
    double temperature = 0.7,
  }) async {
    return generateContent(
      text: text,
      model: model,
      maxTokens: maxTokens,
      temperature: temperature,
    );
  }
}