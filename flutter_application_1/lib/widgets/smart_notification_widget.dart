import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../services/notification_overlay_service.dart';

class SmartNotificationWidget extends StatefulWidget {
  final String contactName;
  final int messageCount;
  final int daysSinceLastMessage;
  final double avgMessagesPerWeek;
  final String lastMessageFrom; // 'me' or 'them'
  final String conversationHistory;

  const SmartNotificationWidget({
    Key? key,
    required this.contactName,
    required this.messageCount,
    required this.daysSinceLastMessage,
    required this.avgMessagesPerWeek,
    required this.lastMessageFrom,
    required this.conversationHistory,
  }) : super(key: key);

  @override
  State<SmartNotificationWidget> createState() => _SmartNotificationWidgetState();
}

class _SmartNotificationWidgetState extends State<SmartNotificationWidget> {
  bool _shouldNotify = false;
  String _priority = 'low';
  String _notificationMessage = '';
  String _suggestedAction = '';
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadNotificationStatus();
  }

  Future<void> _loadNotificationStatus() async {
    try {
      print('🔔 Loading notification status for ${widget.contactName}');
      print('   Message count: ${widget.messageCount}');
      print('   Days since last: ${widget.daysSinceLastMessage}');
      print('   Avg msgs/week: ${widget.avgMessagesPerWeek}');
      print('   Last from: ${widget.lastMessageFrom}');
      
      final response = await http.post(
        Uri.parse('http://localhost:5000/agent/smart_notifications'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'contact_name': widget.contactName,
          'message_count': widget.messageCount,
          'days_since_last_message': widget.daysSinceLastMessage,
          'avg_messages_per_week': widget.avgMessagesPerWeek,
          'last_message_from': widget.lastMessageFrom,
          'conversation_history': widget.conversationHistory,
        }),
      );

      print('🔔 Response status: ${response.statusCode}');
      print('🔔 Response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          final notifData = data['data'];
          print('🔔 Should notify: ${notifData['should_notify']}');
          setState(() {
            _shouldNotify = notifData['should_notify'] ?? false;
            _priority = notifData['priority'] ?? 'low';
            _notificationMessage = notifData['notification_message'] ?? '';
            _suggestedAction = notifData['suggested_action'] ?? '';
          });
          
          // 🎯 SHOW iOS-STYLE NOTIFICATION if needed
          if (_shouldNotify && mounted) {
            _showIOSNotification();
          }
        } else {
          setState(() {
            _error = 'Backend returned success=false';
          });
        }
      } else {
        setState(() {
          _error = 'Server error: ${response.statusCode}';
        });
      }
    } catch (e) {
      print('🔔 ERROR: $e');
      setState(() {
        _error = e.toString();
      });
    }
  }
  
  /// Show iOS-style notification from the top of the screen
  void _showIOSNotification() {
    NotificationService.show(
      context,
      title: 'Atlas',
      subtitle: widget.contactName,
      message: _notificationMessage,
      icon: _getPriorityIcon(),
      iconColor: _getPriorityColor(),
      duration: const Duration(seconds: 6),
      onTap: () {
        // When tapped, could navigate to the conversation or show actions
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('💡 $_suggestedAction'),
            duration: const Duration(seconds: 3),
          ),
        );
      },
    );
  }

  Color _getPriorityColor() {
    switch (_priority) {
      case 'urgent':
        return Colors.red;
      case 'high':
        return Colors.orange;
      case 'medium':
        return Colors.blue;
      case 'low':
        return Colors.grey;
      default:
        return Colors.grey;
    }
  }

  IconData _getPriorityIcon() {
    switch (_priority) {
      case 'urgent':
        return Icons.notification_important;
      case 'high':
        return Icons.notifications_active;
      case 'medium':
        return Icons.notifications;
      case 'low':
        return Icons.notifications_none;
      default:
        return Icons.notifications_none;
    }
  }

  @override
  Widget build(BuildContext context) {
    // Widget is now invisible - notifications show from the top like iOS!
    // Only show debug info if there's an error
    if (_error != null) {
      return Card(
        margin: const EdgeInsets.all(16),
        color: Colors.orange[50],
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.warning, color: Colors.orange[700], size: 20),
                  const SizedBox(width: 8),
                  const Text(
                    'Smart Notification Debug',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                'Error: $_error',
                style: const TextStyle(fontSize: 12),
              ),
              const SizedBox(height: 6),
              const Text(
                'Make sure backend is running: python main_auto.py',
                style: TextStyle(fontSize: 11, fontStyle: FontStyle.italic),
              ),
            ],
          ),
        ),
      );
    }
    
    // Hide the widget - notifications show as iOS overlays from top!
    return const SizedBox.shrink();
  }
}

