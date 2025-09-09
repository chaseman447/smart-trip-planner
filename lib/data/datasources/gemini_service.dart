import 'dart:convert';
import 'package:http/http.dart' as http;

class GeminiService {
  static const String _apiKey = String.fromEnvironment('GEMINI_API_KEY', defaultValue: '');
  static const String _baseUrl = 'https://generativelanguage.googleapis.com/v1beta';
  
  static bool get isConfigured => _apiKey.isNotEmpty && _apiKey != 'your-api-key-here';
  
  static Future<String> generateContent({
    required String text,
    String model = 'gemini-2.0-flash',
    Duration timeout = const Duration(seconds: 30),
  }) async {
    if (!isConfigured) {
      throw Exception('Gemini API key not configured. Please set GEMINI_API_KEY environment variable.');
    }
    
    final client = http.Client();
    try {
      final response = await client.post(
        Uri.parse('$_baseUrl/models/$model:generateContent'),
        headers: {
          'Content-Type': 'application/json',
          'X-goog-api-key': _apiKey,
        },
        body: jsonEncode({
          'contents': [
            {
              'parts': [
                {
                  'text': text,
                }
              ]
            }
          ]
        }),
      ).timeout(timeout);
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['candidates'][0]['content']['parts'][0]['text'];
      } else {
        throw Exception('Failed to get response from Gemini: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      if (e.toString().contains('TimeoutException') || e.toString().contains('SocketException')) {
        throw Exception('Network timeout or connectivity issue. Please check your internet connection.');
      }
      rethrow;
    } finally {
      client.close();
    }
  }

  
  static Future<String> chatCompletion({
    required List<Map<String, dynamic>> messages,
    String model = 'gemini-2.0-flash',
    Duration timeout = const Duration(seconds: 30),
  }) async {
    if (!isConfigured) {
      throw Exception('Gemini API key not configured. Please set GEMINI_API_KEY environment variable.');
    }
    
    // Convert chat messages to Gemini format
    final contents = messages.map((message) => {
      'parts': [
        {
          'text': message['content'] ?? message['text'] ?? '',
        }
      ]
    }).toList();
    
    final client = http.Client();
    try {
      final response = await client.post(
        Uri.parse('$_baseUrl/models/$model:generateContent'),
        headers: {
          'Content-Type': 'application/json',
          'X-goog-api-key': _apiKey,
        },
        body: jsonEncode({
          'contents': contents,
        }),
      ).timeout(timeout);
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['candidates'][0]['content']['parts'][0]['text'];
      } else {
        throw Exception('Failed to get response from Gemini: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      if (e.toString().contains('TimeoutException') || e.toString().contains('SocketException')) {
        throw Exception('Network timeout or connectivity issue. Please check your internet connection.');
      }
      rethrow;
    } finally {
      client.close();
    }
  }
}