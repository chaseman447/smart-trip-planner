import 'dart:convert';
import 'package:logger/logger.dart';

/// Utility class for extracting and formatting JSON from AI responses
class JsonExtractor {
  static final Logger _logger = Logger();

  /// Extracts JSON from a text response that may contain other content
  /// Returns the parsed JSON object or null if no valid JSON is found
  static Map<String, dynamic>? extractJson(String response) {
    if (response.isEmpty) return null;

    try {
      // First, try to parse the entire response as JSON
      final decoded = jsonDecode(response);
      if (decoded is Map<String, dynamic>) {
        _logger.d('Successfully parsed entire response as JSON');
        return decoded;
      }
    } catch (e) {
      // Continue to extract JSON from mixed content
    }

    // Look for JSON blocks in the response
    final jsonBlocks = _findJsonBlocks(response);
    
    for (final block in jsonBlocks) {
      try {
        final decoded = jsonDecode(block);
        if (decoded is Map<String, dynamic>) {
          _logger.d('Successfully extracted JSON from response block');
          return decoded;
        }
      } catch (e) {
        continue;
      }
    }

    _logger.w('No valid JSON found in response');
    return null;
  }

  /// Formats JSON object into a pretty-printed string
  static String formatJson(Map<String, dynamic> json) {
    try {
      const encoder = JsonEncoder.withIndent('  ');
      return encoder.convert(json);
    } catch (e) {
      _logger.e('Error formatting JSON: $e');
      return json.toString();
    }
  }

  /// Extracts and formats JSON from response in one step
  static String? extractAndFormat(String response) {
    final json = extractJson(response);
    if (json != null) {
      return formatJson(json);
    }
    return null;
  }

  /// Validates if a string contains valid JSON
  static bool isValidJson(String jsonString) {
    try {
      jsonDecode(jsonString);
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Finds potential JSON blocks in text using various patterns
  static List<String> _findJsonBlocks(String text) {
    final blocks = <String>[];
    
    // Pattern 1: JSON wrapped in code blocks
    final codeBlockPattern = RegExp(r'```(?:json)?\s*({[\s\S]*?})\s*```', multiLine: true);
    final codeMatches = codeBlockPattern.allMatches(text);
    for (final match in codeMatches) {
      if (match.group(1) != null) {
        blocks.add(match.group(1)!);
      }
    }

    // Pattern 2: Standalone JSON objects (looking for balanced braces)
    final jsonPattern = RegExp(r'{[^{}]*(?:{[^{}]*}[^{}]*)*}', multiLine: true);
    final jsonMatches = jsonPattern.allMatches(text);
    for (final match in jsonMatches) {
      final candidate = match.group(0)!;
      if (_hasBalancedBraces(candidate)) {
        blocks.add(candidate);
      }
    }

    // Pattern 3: JSON between specific markers
    final markerPatterns = [
      RegExp(r'```json\s*([\s\S]*?)\s*```', multiLine: true),
      RegExp(r'<json>([\s\S]*?)</json>', multiLine: true),
      RegExp(r'JSON:\s*({[\s\S]*?})(?=\n\n|\n[A-Z]|$)', multiLine: true),
    ];

    for (final pattern in markerPatterns) {
      final matches = pattern.allMatches(text);
      for (final match in matches) {
        if (match.group(1) != null) {
          blocks.add(match.group(1)!);
        }
      }
    }

    return blocks;
  }

  /// Checks if a string has balanced braces
  static bool _hasBalancedBraces(String text) {
    int count = 0;
    for (int i = 0; i < text.length; i++) {
      if (text[i] == '{') {
        count++;
      } else if (text[i] == '}') {
        count--;
        if (count < 0) return false;
      }
    }
    return count == 0;
  }

  /// Extracts specific field from JSON response
  static T? extractField<T>(String response, String fieldName) {
    final json = extractJson(response);
    if (json != null && json.containsKey(fieldName)) {
      return json[fieldName] as T?;
    }
    return null;
  }

  /// Extracts nested field from JSON response using dot notation
  /// Example: extractNestedField(response, 'trip.itinerary.day1')
  static dynamic extractNestedField(String response, String fieldPath) {
    final json = extractJson(response);
    if (json == null) return null;

    final parts = fieldPath.split('.');
    dynamic current = json;

    for (final part in parts) {
      if (current is Map<String, dynamic> && current.containsKey(part)) {
        current = current[part];
      } else {
        return null;
      }
    }

    return current;
  }

  /// Cleans up common AI response artifacts from JSON strings
  static String cleanJsonString(String jsonString) {
    String cleaned = jsonString;
    
    // Remove common prefixes/suffixes
    cleaned = cleaned.replaceAll(RegExp(r'^[\s\S]*?(?=\{)'), '');
    cleaned = cleaned.replaceAll(RegExp(r'}[\s\S]*?$'), '}');
    
    // Fix common formatting issues
    cleaned = cleaned.replaceAll(RegExp(r'\\n'), '\n');
    cleaned = cleaned.replaceAll(RegExp(r'\\"'), '"');
    
    // Remove trailing commas
    cleaned = cleaned.replaceAll(RegExp(r',\s*}'), '}');
    cleaned = cleaned.replaceAll(RegExp(r',\s*]'), ']');
    
    return cleaned.trim();
  }
}