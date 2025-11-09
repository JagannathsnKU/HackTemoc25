import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/reachly_summary.dart';

/// Pro Multi-Agent API Service
/// Connects to the full Nemotron NIM suite on Brev server
class ApiServicePro {
  // Use localhost for development, or your deployed Gateway URL
  static const String baseUrl = 'http://localhost:5000';
  
  // Singleton pattern
  static final ApiServicePro _instance = ApiServicePro._internal();
  factory ApiServicePro() => _instance;
  ApiServicePro._internal();

  /// 🤖 AGENT 1: Scribe Agent - Chat Summarization
  /// Uses: Orchestrator NIM (Nemotron 340B)
  Future<ReachlySummary> summarizeChat(String chatLog) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/summarize_chat'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'chat_log': chatLog}),
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

  /// 🎯 AGENT 2: Concierge Agent - Event Planning
  /// Uses: Orchestrator NIM with ReAct pattern
  Future<EventPlan> planEvent({
    required String request,
    required List<CalendarEvent> userCalendar,
    required List<CalendarEvent> friendCalendar,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/plan_event'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'request': request,
          'user_calendar': userCalendar.map((e) => e.toJson()).toList(),
          'friend_calendar': friendCalendar.map((e) => e.toJson()).toList(),
        }),
      ).timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return EventPlan.fromJson(data);
      } else {
        throw Exception('Planning error: ${response.statusCode}');
      }
    } catch (e) {
      print('Concierge Error: $e');
      rethrow;
    }
  }

  /// ✍️ AGENT 3: Ghostwriter Agent - Authentic Message Writing
  /// Uses: Orchestrator NIM with Agentic RAG
  Future<String> writeMessage({
    required String messageContent,
    required List<String> writingSamples,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/write_message'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'message': messageContent,
          'writing_samples': writingSamples,
        }),
      ).timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['message'];
      } else {
        throw Exception('Writing error: ${response.statusCode}');
      }
    } catch (e) {
      print('Ghostwriter Error: $e');
      rethrow;
    }
  }

  /// 🔍 AGENT 4: Scout Social Agent - Multi-Modal Analysis
  /// Uses: Scout VLM NIM (Llama 3.1 Nemotron Nano VL)
  Future<SocialTouchpoint> analyzeSocial({
    required String friendName,
    String? photoUrl,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/analyze_social'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'friend_name': friendName,
          'photo_url': photoUrl,
        }),
      ).timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return SocialTouchpoint.fromJson(data);
      } else {
        throw Exception('Scout error: ${response.statusCode}');
      }
    } catch (e) {
      print('Scout Error: $e');
      rethrow;
    }
  }
}

// ============================================================================
// DATA MODELS FOR NEW AGENTS
// ============================================================================

/// Event Plan from Concierge Agent
class EventPlan {
  final String reasoning;
  final String suggestedTime;
  final String suggestedActivity;
  final String suggestedLocation;
  final String confidence;

  EventPlan({
    required this.reasoning,
    required this.suggestedTime,
    required this.suggestedActivity,
    required this.suggestedLocation,
    required this.confidence,
  });

  factory EventPlan.fromJson(Map<String, dynamic> json) {
    return EventPlan(
      reasoning: json['reasoning'] ?? '',
      suggestedTime: json['suggested_time'] ?? '',
      suggestedActivity: json['suggested_activity'] ?? '',
      suggestedLocation: json['suggested_location'] ?? '',
      confidence: json['confidence'] ?? 'medium',
    );
  }
}

/// Calendar Event model
class CalendarEvent {
  final String title;
  final DateTime startTime;
  final DateTime endTime;

  CalendarEvent({
    required this.title,
    required this.startTime,
    required this.endTime,
  });

  Map<String, dynamic> toJson() => {
    'title': title,
    'start': startTime.toIso8601String(),
    'end': endTime.toIso8601String(),
  };
}

/// Social Touchpoint from Scout Agent
class SocialTouchpoint {
  final String touchpointType; // new_photo, life_event, shared_interest
  final String summary;
  final String icebreaker;
  final String priority; // high, medium, low

  SocialTouchpoint({
    required this.touchpointType,
    required this.summary,
    required this.icebreaker,
    required this.priority,
  });

  factory SocialTouchpoint.fromJson(Map<String, dynamic> json) {
    return SocialTouchpoint(
      touchpointType: json['touchpoint_type'] ?? 'general',
      summary: json['summary'] ?? '',
      icebreaker: json['icebreaker'] ?? '',
      priority: json['priority'] ?? 'medium',
    );
  }
}
