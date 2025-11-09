import 'package:flutter/material.dart';

class ChatPlatform {
  static const String iMessage = 'iMessage';
  static const String instagram = 'Instagram';
  static const String whatsapp = 'WhatsApp';
  static const String wechat = 'WeChat';
  static const String telegram = 'Telegram';
  static const String discord = 'Discord';
  
  // Get platform icon
  static IconData getPlatformIcon(String platform) {
    switch (platform) {
      case iMessage:
        return Icons.message;
      case instagram:
        return Icons.camera_alt;
      case whatsapp:
        return Icons.chat;
      case wechat:
        return Icons.forum;
      case telegram:
        return Icons.send;
      case discord:
        return Icons.gamepad;
      default:
        return Icons.chat_bubble;
    }
  }
  
  // Get platform color
  static Color getPlatformColor(String platform) {
    switch (platform) {
      case iMessage:
        return const Color(0xFF007AFF); // iOS Blue
      case instagram:
        return const Color(0xFFE1306C); // Instagram Pink
      case whatsapp:
        return const Color(0xFF25D366); // WhatsApp Green
      case wechat:
        return const Color(0xFF09B83E); // WeChat Green
      case telegram:
        return const Color(0xFF0088CC); // Telegram Blue
      case discord:
        return const Color(0xFF5865F2); // Discord Blurple
      default:
        return Colors.grey;
    }
  }
}

class ChatMessage {
  final String id;
  final String text;
  final bool isUser;
  final DateTime timestamp;

  ChatMessage({
    required this.id,
    required this.text,
    required this.isUser,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();
}

class Conversation {
  final String id;
  final String contactName;
  final String platform;
  final String avatarUrl;
  final List<ChatMessage> messages;
  final DateTime lastMessageTime;
  final bool hasUnread;

  Conversation({
    required this.id,
    required this.contactName,
    required this.platform,
    required this.avatarUrl,
    required this.messages,
    DateTime? lastMessageTime,
    this.hasUnread = false,
  }) : lastMessageTime = lastMessageTime ?? DateTime.now();

  String get lastMessage => messages.isNotEmpty ? messages.last.text : '';
  
  // Get time since last message
  String getTimeSinceLastMessage() {
    final now = DateTime.now();
    final difference = now.difference(lastMessageTime);
    
    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inDays < 1) {
      return '${difference.inHours}h ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else if (difference.inDays < 30) {
      final weeks = (difference.inDays / 7).floor();
      return '${weeks}w ago';
    } else if (difference.inDays < 365) {
      final months = (difference.inDays / 30).floor();
      return '${months}mo ago';
    } else {
      final years = (difference.inDays / 365).floor();
      return '${years}y ago';
    }
  }
  
  String getFullChatLog() {
    return messages.map((msg) {
      return '${msg.isUser ? "You" : contactName}: ${msg.text}';
    }).join('\n');
  }
}
