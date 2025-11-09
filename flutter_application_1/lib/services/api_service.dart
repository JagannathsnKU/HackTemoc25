import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/reachly_summary.dart';

class ApiService {
  // Use localhost backend that calls NVIDIA (avoids CORS issues)
  static const String baseUrl = 'http://localhost:5000';
  
  // Singleton pattern
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;
  ApiService._internal();

  /// Summarize a chat conversation using NVIDIA Nemotron via backend
  Future<ReachlySummary> summarizeChat(String chatLog) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/summarize_chat'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'chat_log': chatLog,
        }),
      ).timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return ReachlySummary.fromJson(data);
      } else {
        throw Exception('Server error: ${response.statusCode}');
      }
    } catch (e) {
      print('API Error: $e');
      rethrow;
    }
  }
}
