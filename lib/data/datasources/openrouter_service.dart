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
       _apiKey = apiKey {
    print('🔑 OpenRouter API Key loaded: ${apiKey.isNotEmpty ? "✅ Present (${apiKey.length} chars)" : "❌ Missing"}');
  }

  Future<Map<String, dynamic>> generateContent({
    required String text,
    String model = 'rekaai/reka-flash-3:free',
    int maxTokens = 5000,
    double temperature = 0.7,
  }) async {
    print('🚀 OpenRouter API Request Starting...');
    print('🔗 URL: $_baseUrl/chat/completions');
    print('🤖 Model: $model');
    print('📝 Max Tokens: $maxTokens');
    print('🌡️ Temperature: $temperature');
    print('🔑 API Key: ${_apiKey.substring(0, 20)}...');
    
    final requestData = {
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
      'stream': false,
      'stream_options': {
        'include_usage': true,
      },
    };
    
    print('📤 Request Data: ${jsonEncode(requestData)}');
    
    try {
      final response = await _dioClient.post(
        '$_baseUrl/chat/completions',
        data: requestData,
        options: Options(
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $_apiKey',
          },
        ),
      );

      print('📥 OpenRouter Response Status: ${response.statusCode}');
      print('📥 OpenRouter Response Headers: ${response.headers}');
      
      if (response.statusCode == 200) {
        final data = response.data;
        print('✅ OpenRouter API Success!');
        print('📊 Raw Response Data: ${jsonEncode(data)}');

        if (data['choices'] != null && data['choices'].isNotEmpty) {
          final content = data['choices'][0]['message']['content'] as String;
          final usage = data['usage'] as Map<String, dynamic>?;
          
          print('📝 Response Content Length: ${content.length} characters');
          print('💰 Token Usage Details:');
          if (usage != null) {
            print('  • Prompt Tokens: ${usage['prompt_tokens']}');
            print('  • Completion Tokens: ${usage['completion_tokens']}');
            print('  • Total Tokens: ${usage['total_tokens']}');
            print('  • Cost: \$${usage['cost'] ?? 'N/A'}');
          } else {
            print('  • No usage data provided in response');
          }
          
          return {
            'content': content,
            'usage': usage ?? {
              'prompt_tokens': 0,
              'completion_tokens': 0,
              'total_tokens': 0,
            },
          };
        } else {
          print('❌ OpenRouter Invalid Response: No choices found');
          print('📊 Full Response: ${jsonEncode(data)}');
          throw Failure.server(
            message: 'Invalid response format from OpenRouter API',
            statusCode: response.statusCode ?? 500,
          );
        }
      } else {
        print('❌ OpenRouter API Error: ${response.statusCode}');
        print('❌ Error Message: ${response.statusMessage}');
        print('❌ Response Data: ${response.data}');
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

  Future<Map<String, dynamic>> generateChatResponse({
    required String text,
    String model = 'rekaai/reka-flash-3:free',
    int maxTokens = 5000,
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