import 'dart:convert';
import 'package:http/http.dart' as http;

class XAIService {
  static const String _apiKey = String.fromEnvironment('XAI_API_KEY', defaultValue: 'your-api-key-here');
  static const String _baseUrl = 'https://api.x.ai/v1';
  
  static Future<String> chatCompletion({
    required List<Map<String, String>> messages,
    String model = 'grok-4-latest',
    double temperature = 0.7,
    bool stream = false,
  }) async {
    final response = await http.post(
      Uri.parse('$_baseUrl/chat/completions'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $_apiKey',
      },
      body: jsonEncode({
        'messages': messages,
        'model': model,
        'temperature': temperature,
        'stream': stream,
      }),
    );
    
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['choices'][0]['message']['content'];
    } else {
      throw Exception('Failed to get response from X.AI: ${response.statusCode} - ${response.body}');
    }
  }
}