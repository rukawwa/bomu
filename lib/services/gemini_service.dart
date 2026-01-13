import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

/// Service to call Firebase Cloud Functions for secure API access
class GeminiService {
  // Firebase Cloud Functions callable URL
  // Project: animejersey-1, Region: us-central1
  // Using Cloud Run URL for callable functions
  static const String _functionsUrl =
      'https://analyzefood-2eta5q5irq-uc.a.run.app';

  /// Analyze food image using Firebase Cloud Function
  /// This keeps the API key secure on the server side
  static Future<List<Map<String, dynamic>>> analyzeFood({
    required String base64Image,
    required String prompt,
  }) async {
    try {
      final response = await http.post(
        Uri.parse(_functionsUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'data': {'imageBase64': base64Image, 'prompt': prompt},
        }),
      );

      if (response.statusCode != 200) {
        throw Exception(
          'Cloud Function error: ${response.statusCode} - ${response.body}',
        );
      }

      debugPrint('Cloud Function Response: ${response.body}');
      final data = jsonDecode(response.body);

      // Firebase callable functions wrap response in 'result'
      final result = data['result'];
      if (result == null) {
        throw Exception('No result from Cloud Function: ${response.body}');
      }

      // If result is a String (common from LLMs), try to parse it
      // If result is a String (common from LLMs), try to parse it
      if (result is String) {
        String cleanResult = result.trim();

        // Try to find JSON array or object pattern
        final int startIndex = cleanResult.indexOf('[');
        final int endIndex = cleanResult.lastIndexOf(']');

        if (startIndex != -1 && endIndex != -1 && endIndex > startIndex) {
          cleanResult = cleanResult.substring(startIndex, endIndex + 1);
        } else {
          // Try object if array not found
          final int startObj = cleanResult.indexOf('{');
          final int endObj = cleanResult.lastIndexOf('}');
          if (startObj != -1 && endObj != -1 && endObj > startObj) {
            cleanResult = cleanResult.substring(startObj, endObj + 1);
          }
        }

        try {
          final parsed = jsonDecode(cleanResult);
          if (parsed is List) {
            return parsed.map((f) => Map<String, dynamic>.from(f)).toList();
          } else if (parsed is Map) {
            return [Map<String, dynamic>.from(parsed)];
          }
        } catch (e) {
          debugPrint('Failed to parse inner JSON string: $e');
          throw Exception('Failed to parse AI response: $cleanResult');
        }
      }

      // If result is already a List
      if (result is List) {
        return result.map((f) => Map<String, dynamic>.from(f)).toList();
      }

      // If result is a Map, it might be nested from Cloud Function (e.g. {"result": [...]})
      if (result is Map) {
        if (result.containsKey('result') && result['result'] is List) {
          final innerList = result['result'] as List;
          return innerList.map((f) => Map<String, dynamic>.from(f)).toList();
        }
        // Otherwise treat as single object
        return [Map<String, dynamic>.from(result)];
      }

      throw Exception('Unexpected response format: $result');
    } catch (e) {
      // Re-throw with more details
      rethrow;
    }
  }

  /// Analyze food from text description using Firebase Cloud Function
  static Future<List<Map<String, dynamic>>> analyzeFoodFromText(
    String text,
  ) async {
    final prompt =
        '''
Kullanıcının yazdığı yemekleri analiz et ve her biri için besin değerlerini tahmin et.

KULLANICI GİRDİSİ: "$text"

Her yemek için JSON formatında döndür:
[
  {
    "name": "Türkçe yemek adı",
    "calories": 300,
    "protein": 25,
    "carbs": 30,
    "fat": 10,
    "type": "healthy"
  }
]

Kurallar:
- calories, protein, carbs, fat değerleri integer olmalı
- type sadece "healthy" veya "unhealthy" olabilir
- Birden fazla yemek varsa hepsini ayrı ayrı listele
- SADECE JSON array döndür, açıklama yazma
''';

    try {
      debugPrint('Calling Cloud Function for text analysis: $text');

      final response = await http.post(
        Uri.parse(_functionsUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'data': {'prompt': prompt, 'textOnly': true},
        }),
      );

      debugPrint('Response status: ${response.statusCode}');
      debugPrint('Response body: ${response.body}');

      if (response.statusCode != 200) {
        throw Exception(
          'Cloud Function error: ${response.statusCode} - ${response.body}',
        );
      }

      final data = jsonDecode(response.body);
      var result = data['result'];

      if (result == null) {
        throw Exception('No result from Cloud Function');
      }

      debugPrint('Result type: ${result.runtimeType}');
      debugPrint('Result: $result');

      // The Cloud Function already parses the JSON, so result should be a List
      if (result is List) {
        return result.map((f) => Map<String, dynamic>.from(f)).toList();
      }

      // If it's a Map with nested result
      if (result is Map && result.containsKey('result')) {
        final innerResult = result['result'];
        if (innerResult is List) {
          return innerResult.map((f) => Map<String, dynamic>.from(f)).toList();
        }
      }

      // If result is a String (shouldn't happen but just in case)
      if (result is String) {
        String cleanResult = result.trim();

        // Remove markdown code blocks if present
        if (cleanResult.contains('```')) {
          cleanResult = cleanResult.replaceAll(RegExp(r'```json\s*'), '');
          cleanResult = cleanResult.replaceAll(RegExp(r'```\s*'), '');
        }

        final int startIndex = cleanResult.indexOf('[');
        final int endIndex = cleanResult.lastIndexOf(']');

        if (startIndex != -1 && endIndex != -1 && endIndex > startIndex) {
          cleanResult = cleanResult.substring(startIndex, endIndex + 1);
          final parsed = jsonDecode(cleanResult);
          if (parsed is List) {
            return parsed.map((f) => Map<String, dynamic>.from(f)).toList();
          }
        }
      }

      throw Exception('Unexpected response format: ${result.runtimeType}');
    } catch (e) {
      debugPrint('Error in analyzeFoodFromText: $e');
      rethrow;
    }
  }
}
