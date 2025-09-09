import 'dart:convert';
import 'package:dio/dio.dart';
import '../../core/network/dio_client.dart';
import '../../core/errors/failures.dart';
import '../../core/constants/app_constants.dart';
import '../../core/utils/json_extractor.dart';

class DeepSeekService {
  final DioClient _dioClient;
  final String _apiKey;

  DeepSeekService({
    required DioClient dioClient,
    required String apiKey,
  }) : _dioClient = dioClient,
       _apiKey = apiKey;

  /// Generate content using DeepSeek API
  Future<String> generateContent({
    required String text,
    double temperature = 0.7,
    double topP = 0.7,
    double frequencyPenalty = 1.0,
    int maxTokens = 1000,
    int topK = 50,
    Duration? timeout,
  }) async {
    try {
      final response = await _dioClient.post(
        AppConstants.deepSeekApiUrl,
        data: {
          'model': AppConstants.deepSeekModel,
          'messages': {
            'role': 'user',
            'content': text,
          },
          'temperature': temperature,
          'top_p': topP,
          'frequency_penalty': frequencyPenalty,
          'max_tokens': maxTokens,
          'top_k': topK,
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
          message: 'Invalid response format from DeepSeek API',
          statusCode: 500,
        );
      }
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) {
        throw const Failure.server(
          message: 'Invalid API key for DeepSeek',
          statusCode: 401,
        );
      } else if (e.response?.statusCode == 429) {
        throw const Failure.server(
          message: 'Rate limit exceeded for DeepSeek API',
          statusCode: 429,
        );
      } else {
        throw Failure.server(
          message: e.message ?? 'DeepSeek API error',
          statusCode: e.response?.statusCode,
        );
      }
    } catch (e) {
      throw Failure.unknown(message: 'DeepSeek service error: $e');
    }
  }

  /// Generate structured content for trip planning
  Future<Map<String, dynamic>> generateStructuredContent({
    required String prompt,
    required Map<String, dynamic> functionSchema,
    double temperature = 0.7,
    int maxTokens = 2000,
  }) async {
    try {
      // Create a prompt that encourages JSON output
      final structuredPrompt = '''
$prompt

Please respond with a valid JSON object that matches this schema:
${jsonEncode(functionSchema)}

Ensure your response is valid JSON that can be parsed directly.''';

      final response = await generateContent(
        text: structuredPrompt,
        temperature: temperature,
        maxTokens: maxTokens,
      );

      // Use JsonExtractor to handle various AI response formats
      final json = JsonExtractor.extractJson(response);
      
      if (json != null) {
        return json;
      } else {
        throw const Failure.server(
          message: 'Could not extract valid JSON from DeepSeek response. The AI may have provided an incomplete or malformed response.',
          statusCode: 500,
        );
      }
    } catch (e) {
      if (e is Failure) {
        rethrow;
      }
      throw Failure.unknown(message: 'Failed to generate structured content: $e');
    }
  }

  /// Generate chat completion with conversation history
  Future<String> chatCompletion({
    required List<Map<String, String>> messages,
    double temperature = 0.7,
    int maxTokens = 1000,
  }) async {
    try {
      final response = await _dioClient.post(
        AppConstants.deepSeekApiUrl,
        data: {
          'model': AppConstants.deepSeekModel,
          'messages': messages,
          'temperature': temperature,
          'max_tokens': maxTokens,
          'top_p': 0.7,
          'frequency_penalty': 1,
          'top_k': 50,
        },
        options: Options(
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $_apiKey',
          },
          sendTimeout: const Duration(seconds: 30),
          receiveTimeout: const Duration(seconds: 30),
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
          message: 'Invalid response format from DeepSeek API',
          statusCode: 500,
        );
      }
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) {
        throw const Failure.server(
          message: 'Invalid API key for DeepSeek',
          statusCode: 401,
        );
      } else if (e.response?.statusCode == 429) {
        throw const Failure.server(
          message: 'Rate limit exceeded for DeepSeek API',
          statusCode: 429,
        );
      } else {
        throw Failure.server(
          message: e.message ?? 'DeepSeek API error',
          statusCode: e.response?.statusCode,
        );
      }
    } catch (e) {
      throw Failure.unknown(message: 'DeepSeek chat completion error: $e');
    }
  }
}