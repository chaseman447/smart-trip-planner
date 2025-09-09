import 'dart:convert';
import 'package:dio/dio.dart';
import '../../core/network/dio_client.dart';
import '../../core/errors/failures.dart';

class GitHubModelsService {
  final DioClient _dioClient;
  final String _apiKey;
  static const String _baseUrl = 'https://models.github.ai/inference';

  GitHubModelsService({
    required DioClient dioClient,
    required String apiKey,
  }) : _dioClient = dioClient,
       _apiKey = apiKey;

  /// Generate content using GitHub Models API
  Future<String> generateContent({
    required String text,
    String model = 'openai/gpt-4o',
    double temperature = 0.7,
    double topP = 1.0,
    int maxTokens = 1000,
    Duration? timeout,
  }) async {
    try {
      final response = await _dioClient.post(
        '$_baseUrl/chat/completions',
        data: {
          'messages': [
            {
              'role': 'system',
              'content': 'You are a helpful AI assistant specialized in travel planning and itinerary creation.',
            },
            {
              'role': 'user',
              'content': text,
            }
          ],
          'temperature': temperature,
          'top_p': topP,
          'max_tokens': maxTokens,
          'model': model,
        },
        options: Options(
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $_apiKey',
          },
          sendTimeout: timeout ?? const Duration(seconds: 30),
          receiveTimeout: timeout ?? const Duration(seconds: 30),
        ),
      );

      final responseData = response.data;
      if (responseData != null && 
          responseData['choices'] != null && 
          responseData['choices'].isNotEmpty) {
        final content = responseData['choices'][0]['message']['content'];
        return content ?? 'No response generated';
      } else {
        throw const Failure.server(
          message: 'Invalid response format from GitHub Models API',
          statusCode: 500,
        );
      }
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) {
        throw const Failure.server(
          message: 'Invalid GitHub token for Models API',
          statusCode: 401,
        );
      } else if (e.response?.statusCode == 429) {
        throw const Failure.server(
          message: 'Rate limit exceeded for GitHub Models API',
          statusCode: 429,
        );
      } else {
        throw Failure.server(
          message: e.message ?? 'GitHub Models API error',
          statusCode: e.response?.statusCode,
        );
      }
    } catch (e) {
      throw Failure.unknown(message: 'GitHub Models service error: $e');
    }
  }

  /// Generate chat completion with conversation history
  Future<String> chatCompletion({
    required List<Map<String, dynamic>> messages,
    String model = 'openai/gpt-4o',
    double temperature = 0.7,
    double topP = 1.0,
    int maxTokens = 1000,
    Duration? timeout,
  }) async {
    try {
      final response = await _dioClient.post(
        '$_baseUrl/chat/completions',
        data: {
          'messages': messages,
          'temperature': temperature,
          'top_p': topP,
          'max_tokens': maxTokens,
          'model': model,
        },
        options: Options(
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $_apiKey',
          },
          sendTimeout: timeout ?? const Duration(seconds: 30),
          receiveTimeout: timeout ?? const Duration(seconds: 30),
        ),
      );

      final responseData = response.data;
      if (responseData != null && 
          responseData['choices'] != null && 
          responseData['choices'].isNotEmpty) {
        final content = responseData['choices'][0]['message']['content'];
        return content ?? 'No response generated';
      } else {
        throw const Failure.server(
          message: 'Invalid response format from GitHub Models API',
          statusCode: 500,
        );
      }
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) {
        throw const Failure.server(
          message: 'Invalid GitHub token for Models API',
          statusCode: 401,
        );
      } else if (e.response?.statusCode == 429) {
        throw const Failure.server(
          message: 'Rate limit exceeded for GitHub Models API',
          statusCode: 429,
        );
      } else {
        throw Failure.server(
          message: e.message ?? 'GitHub Models API error',
          statusCode: e.response?.statusCode,
        );
      }
    } catch (e) {
      throw Failure.unknown(message: 'GitHub Models service error: $e');
    }
  }

  /// Check if the service is properly configured
  bool get isConfigured => _apiKey.isNotEmpty && _apiKey != 'your-github-token-here';
}