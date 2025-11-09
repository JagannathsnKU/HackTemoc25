import 'dart:convert';
import 'dart:ui';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:workmanager/workmanager.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import '../models/conversation.dart';
import '../services/mock_data_service.dart';

class NotificationService {
  static final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();
  static const String baseUrl = 'http://localhost:5000';

  // Initialize notifications
  static Future<void> initialize() async {
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );
    
    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _notifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onNotificationTap,
    );

    // Request permissions
    await _requestPermissions();
    
    // Initialize background worker (only on mobile platforms)
    if (!kIsWeb) {
      await Workmanager().initialize(callbackDispatcher, isInDebugMode: true);
      
      // Register periodic task to check for unread messages
      await Workmanager().registerPeriodicTask(
        'atlas-notification-check',
        'checkUnreadMessages',
        frequency: const Duration(minutes: 15), // Check every 15 minutes
        constraints: Constraints(
          networkType: NetworkType.connected,
        ),
      );
    }
  }

  static Future<void> _requestPermissions() async {
    final androidImplementation =
        _notifications.resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();
    await androidImplementation?.requestNotificationsPermission();
    
    final iosImplementation =
        _notifications.resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin>();
    await iosImplementation?.requestPermissions(
      alert: true,
      badge: true,
      sound: true,
    );
  }

  // Handle notification tap
  static void _onNotificationTap(NotificationResponse response) {
    // Navigate to conversation (implement navigation logic)
    print('Notification tapped: ${response.payload}');
  }

  // Show notification with AI-generated follow-up suggestion
  static Future<void> showFollowUpNotification({
    required String contactName,
    required String lastMessage,
    required int hoursSinceMessage,
    String? suggestedReply,
  }) async {
    const androidDetails = AndroidNotificationDetails(
      'atlas_followup',
      'Follow-up Reminders',
      channelDescription: 'AI-powered reminders to follow up with contacts',
      importance: Importance.high,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
      styleInformation: BigTextStyleInformation(''),
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    final title = '💬 Follow up with $contactName';
    final body = suggestedReply ?? 
        'It\'s been ${hoursSinceMessage}h since "$lastMessage". Atlas suggests reaching out.';

    await _notifications.show(
      contactName.hashCode, // Unique ID per contact
      title,
      body,
      details,
      payload: contactName,
    );
  }

  // AI-powered follow-up prediction
  static Future<Map<String, dynamic>> predictFollowUp({
    required String contactName,
    required String chatLog,
    required String lastMessage,
    required int hoursSinceMessage,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/predict_followup'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'contact_name': contactName,
          'chat_log': chatLog,
          'last_message': lastMessage,
          'hours_since_message': hoursSinceMessage,
        }),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
    } catch (e) {
      print('Error predicting follow-up: $e');
    }

    // Fallback prediction
    return {
      'should_follow_up': hoursSinceMessage > 24,
      'urgency': hoursSinceMessage > 48 ? 'high' : 'medium',
      'suggested_message': 'Hey! Just wanted to check in. How are you?',
      'reasoning': 'It\'s been ${hoursSinceMessage} hours since your last message.',
    };
  }

  // Check all conversations for follow-ups
  static Future<void> checkAllConversationsForFollowUps() async {
    final prefs = await SharedPreferences.getInstance();
    final conversations = MockDataService.getMockConversations();
    
    for (final conversation in conversations) {
      // Get last message time from preferences
      final lastCheckKey = 'last_check_${conversation.contactName}';
      final lastCheck = prefs.getInt(lastCheckKey) ?? 0;
      final hoursSince = (DateTime.now().millisecondsSinceEpoch - lastCheck) ~/ (1000 * 60 * 60);
      
      // Skip if checked recently (within 12 hours)
      if (hoursSince < 12) continue;
      
      // Get AI prediction
      final prediction = await predictFollowUp(
        contactName: conversation.contactName,
        chatLog: conversation.getFullChatLog(),
        lastMessage: conversation.lastMessage,
        hoursSinceMessage: hoursSince,
      );

      // Show notification if AI suggests follow-up
      if (prediction['should_follow_up'] == true) {
        await showFollowUpNotification(
          contactName: conversation.contactName,
          lastMessage: conversation.lastMessage,
          hoursSinceMessage: hoursSince,
          suggestedReply: prediction['suggested_message'],
        );
        
        // Update last check time
        await prefs.setInt(lastCheckKey, DateTime.now().millisecondsSinceEpoch);
      }
    }
  }

  // Manual check for a specific conversation
  static Future<void> checkConversationForFollowUp(Conversation conversation) async {
    final prefs = await SharedPreferences.getInstance();
    final lastMessageKey = 'last_msg_time_${conversation.contactName}';
    final lastMessageTime = prefs.getInt(lastMessageKey) ?? 
        DateTime.now().subtract(const Duration(days: 1)).millisecondsSinceEpoch;
    
    final hoursSince = (DateTime.now().millisecondsSinceEpoch - lastMessageTime) ~/ (1000 * 60 * 60);
    
    // Get AI prediction
    final prediction = await predictFollowUp(
      contactName: conversation.contactName,
      chatLog: conversation.getFullChatLog(),
      lastMessage: conversation.lastMessage,
      hoursSinceMessage: hoursSince,
    );

    // Show notification if suggested
    if (prediction['should_follow_up'] == true && hoursSince > 12) {
      await showFollowUpNotification(
        contactName: conversation.contactName,
        lastMessage: conversation.lastMessage,
        hoursSinceMessage: hoursSince,
        suggestedReply: prediction['suggested_message'],
      );
    }
  }

  // Update last message time for a conversation
  static Future<void> updateLastMessageTime(String contactName) async {
    final prefs = await SharedPreferences.getInstance();
    final key = 'last_msg_time_$contactName';
    await prefs.setInt(key, DateTime.now().millisecondsSinceEpoch);
  }

  // Show instant notification for urgent messages
  static Future<void> showUrgentFollowUp({
    required String contactName,
    required String reason,
    required String suggestedAction,
  }) async {
    const androidDetails = AndroidNotificationDetails(
      'atlas_urgent',
      'Urgent Alerts',
      channelDescription: 'Urgent AI-detected relationship alerts',
      importance: Importance.max,
      priority: Priority.max,
      icon: '@mipmap/ic_launcher',
      color: Color(0xFF6A1B9A),
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
      interruptionLevel: InterruptionLevel.critical,
    );

    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _notifications.show(
      999, // High priority ID
      '🚨 Urgent: $contactName',
      '$reason\n\n💡 $suggestedAction',
      details,
      payload: contactName,
    );
  }

  // Cancel all notifications
  static Future<void> cancelAll() async {
    await _notifications.cancelAll();
  }

  // Cancel notification for specific contact
  static Future<void> cancelForContact(String contactName) async {
    await _notifications.cancel(contactName.hashCode);
  }
}

// Background task callback
@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    try {
      // Check for follow-ups in background
      await NotificationService.checkAllConversationsForFollowUps();
      return Future.value(true);
    } catch (e) {
      print('Background task error: $e');
      return Future.value(false);
    }
  });
}
