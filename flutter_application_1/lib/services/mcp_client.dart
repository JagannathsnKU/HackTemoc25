import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/conversation.dart';

class MCPClient {
  static const String baseUrl = 'http://localhost:5001';
  
  /// Check if MCP server is running
  static Future<bool> isServerRunning() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/'),
      ).timeout(const Duration(seconds: 2));
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  /// Analyze conversation with Claude AI
  static Future<Map<String, dynamic>> analyzeConversation({
    required String contactName,
    required List<ChatMessage> messages,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/analyze_conversation'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'contact_name': contactName,
          'messages': messages.map((msg) => {
            'text': msg.text,
            'isUser': msg.isUser,
            'timestamp': msg.timestamp.toIso8601String(),
          }).toList(),
        }),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Failed to analyze conversation: ${response.body}');
      }
    } catch (e) {
      print('❌ MCP analyzeConversation error: $e');
      return {
        'sentiment': 'neutral',
        'meeting_needs': 'Unable to determine',
        'action_items': [],
        'context_summary': 'Analysis unavailable - MCP server may be offline'
      };
    }
  }

  /// Get smart scheduling suggestions
  static Future<Map<String, dynamic>> getSmartSchedule({
    required String contactName,
    required String meetingType,
    String context = '',
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/smart_schedule'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'contact_name': contactName,
          'meeting_type': meetingType,
          'context': context,
        }),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Failed to get schedule: ${response.body}');
      }
    } catch (e) {
      print('❌ MCP getSmartSchedule error: $e');
      return {
        'contact_name': contactName,
        'meeting_type': meetingType,
        'suggested_times': ['10:00 AM', '2:00 PM', '3:00 PM'],
        'suggested_dates': ['Tomorrow', 'Next week'],
        'recommendation': 'Schedule at your convenience'
      };
    }
  }

  /// Generate personalized voice response script
  static Future<String> generateVoiceResponse({
    required String userName,
    required String contactName,
    required String meetingType,
    required String time,
    String location = '',
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/generate_voice_response'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'user_name': userName,
          'contact_name': contactName,
          'meeting_type': meetingType,
          'time': time,
          'location': location,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['script'] as String;
      } else {
        throw Exception('Failed to generate voice response: ${response.body}');
      }
    } catch (e) {
      print('❌ MCP generateVoiceResponse error: $e');
      // Fallback to default script
      if (location.isNotEmpty) {
        return "Hi $userName! I heard you want to book a $meetingType with $contactName. I've scheduled it for $time at $location.";
      } else {
        return "Hi $userName! I heard you want to book a $meetingType with $contactName. I've scheduled it for $time.";
      }
    }
  }

  /// Extract action items from conversation
  static Future<List<Map<String, dynamic>>> extractActionItems({
    required String contactName,
    required List<ChatMessage> messages,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/extract_action_items'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'contact_name': contactName,
          'messages': messages.map((msg) => {
            'text': msg.text,
            'isUser': msg.isUser,
            'timestamp': msg.timestamp.toIso8601String(),
          }).toList(),
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return List<Map<String, dynamic>>.from(data['action_items'] ?? []);
      } else {
        throw Exception('Failed to extract action items: ${response.body}');
      }
    } catch (e) {
      print('❌ MCP extractActionItems error: $e');
      return [];
    }
  }

  /// Get conversation summary
  static Future<String> getConversationSummary({
    required String contactName,
    required List<ChatMessage> messages,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/conversation_summary'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'contact_name': contactName,
          'messages': messages.map((msg) => {
            'text': msg.text,
            'isUser': msg.isUser,
            'timestamp': msg.timestamp.toIso8601String(),
          }).toList(),
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['summary'] as String;
      } else {
        throw Exception('Failed to get summary: ${response.body}');
      }
    } catch (e) {
      print('❌ MCP getConversationSummary error: $e');
      return 'Summary unavailable - MCP server may be offline';
    }
  }
}
