import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import '../theme/ios_theme.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';

class SmartReplyWidget extends StatefulWidget {
  final String contactName;
  final String lastMessage;
  final String conversationHistory;
  final String platform; // iMessage, Instagram, WhatsApp, WeChat
  final Function(String) onReplySelected;

  const SmartReplyWidget({
    super.key,
    required this.contactName,
    required this.lastMessage,
    required this.conversationHistory,
    required this.platform,
    required this.onReplySelected,
  });

  @override
  State<SmartReplyWidget> createState() => _SmartReplyWidgetState();
}

class _SmartReplyWidgetState extends State<SmartReplyWidget> {
  List<Map<String, dynamic>> _replies = [];
  bool _isLoading = true;
  bool _isExpanded = false;

  @override
  void initState() {
    super.initState();
    _loadSmartReplies();
  }

  Future<void> _loadSmartReplies() async {
    try {
      final response = await http.post(
        Uri.parse('http://localhost:5000/agent/smart_reply'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'contact_name': widget.contactName,
          'last_message': widget.lastMessage,
          'conversation_history': widget.conversationHistory,
          'user_name': 'Heet',
        }),
      ).timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (mounted && data['success'] == true) {
          setState(() {
            _replies = List<Map<String, dynamic>>.from(data['replies']);
            _isLoading = false;
          });
          return;
        }
      }
    } catch (e) {
      print('Smart reply error: $e');
    }
    
    // INTELLIGENT FALLBACK based on conversation context
    if (mounted) {
      setState(() {
        _replies = _generateContextualReplies();
        _isLoading = false;
      });
    }
  }

  List<Map<String, dynamic>> _generateContextualReplies() {
    final lastMsg = widget.lastMessage.toLowerCase();
    final name = widget.contactName;
    
    // Check for questions
    if (lastMsg.contains('?')) {
      if (lastMsg.contains('down') || lastMsg.contains('interested') || lastMsg.contains('want to')) {
        return [
          {'text': 'Definitely! Let\'s do it 🚀', 'tone': 'enthusiastic', 'emoji': '🚀'},
          {'text': 'Yeah I\'m down, when works for you?', 'tone': 'positive', 'emoji': '�'},
          {'text': 'Let me check my schedule and get back to you', 'tone': 'neutral', 'emoji': ''},
        ];
      } else if (lastMsg.contains('when') || lastMsg.contains('time')) {
        return [
          {'text': 'How about this weekend?', 'tone': 'positive', 'emoji': '📅'},
          {'text': 'I\'m free tomorrow afternoon if that works', 'tone': 'helpful', 'emoji': '✅'},
          {'text': 'Let me check and I\'ll let you know', 'tone': 'neutral', 'emoji': ''},
        ];
      }
    }
    
    // Check for urgency
    if (lastMsg.contains('???') || lastMsg.contains('!!!')) {
      return [
        {'text': 'Sorry for the delay! Been super busy 😅', 'tone': 'apologetic', 'emoji': '😅'},
        {'text': 'Hey! Just saw this, what\'s up?', 'tone': 'responsive', 'emoji': '👋'},
        {'text': 'My bad, let\'s catch up soon!', 'tone': 'friendly', 'emoji': '🙏'},
      ];
    }
    
    // Check for greetings/check-ins
    if (lastMsg.contains('hey') || lastMsg.contains('hi') || lastMsg.contains('sup') || lastMsg.contains('long time')) {
      return [
        {'text': 'Hey $name! How have you been? 😊', 'tone': 'friendly', 'emoji': '😊'},
        {'text': 'What\'s good! Long time no talk', 'tone': 'casual', 'emoji': '�'},
        {'text': 'Yo! Sorry for being MIA, been crazy busy', 'tone': 'apologetic', 'emoji': '�'},
      ];
    }
    
    // Project/collaboration mentions
    if (lastMsg.contains('project') || lastMsg.contains('build') || lastMsg.contains('collab')) {
      return [
        {'text': 'Love the idea! When can we discuss details?', 'tone': 'enthusiastic', 'emoji': '🚀'},
        {'text': 'I\'m interested! Tell me more', 'tone': 'engaged', 'emoji': '💡'},
        {'text': 'Sounds cool, let\'s set up a call', 'tone': 'professional', 'emoji': '📞'},
      ];
    }
    
    // Default intelligent responses
    return [
      {'text': 'Thanks for reaching out! Let\'s catch up soon 😊', 'tone': 'friendly', 'emoji': '😊'},
      {'text': 'Hey! Sorry for the late reply, been swamped lately', 'tone': 'apologetic', 'emoji': '😅'},
      {'text': 'Appreciate you! Let\'s definitely connect', 'tone': 'warm', 'emoji': '🙏'},
    ];
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const SizedBox.shrink();
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: IOSTheme.iosSystemBackground,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          InkWell(
            onTap: () => setState(() => _isExpanded = !_isExpanded),
            child: Row(
              children: [
                Icon(
                  Icons.auto_awesome,
                  size: 18,
                  color: IOSTheme.iosBlue,
                ),
                const SizedBox(width: 8),
                Text(
                  'Smart Replies',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: IOSTheme.iosLabel,
                  ),
                ),
                const Spacer(),
                Icon(
                  _isExpanded ? Icons.expand_less : Icons.expand_more,
                  color: IOSTheme.iosSecondaryLabel,
                  size: 20,
                ),
              ],
            ),
          ),

          // Replies
          if (_isExpanded) ...[
            const SizedBox(height: 12),
            ..._replies.map((reply) => _buildReplyChip(reply)).toList(),
          ],
        ],
      ),
    );
  }

  Widget _buildReplyChip(Map<String, dynamic> reply) {
    final tone = reply['tone'] ?? 'neutral';
    final emoji = reply['emoji'] ?? '';
    final replyText = reply['text'] ?? '';
    
    Color chipColor;
    switch (tone) {
      case 'enthusiastic':
      case 'positive':
        chipColor = Colors.green.withOpacity(0.1);
        break;
      case 'brief':
        chipColor = Colors.grey.withOpacity(0.1);
        break;
      default:
        chipColor = IOSTheme.iosBlue.withOpacity(0.1);
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _showSendOptions(replyText),
          borderRadius: BorderRadius.circular(20),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: chipColor,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: Colors.grey.withOpacity(0.3),
                width: 0.5,
              ),
            ),
            child: Row(
              children: [
                if (emoji.isNotEmpty) ...[
                  Text(emoji, style: const TextStyle(fontSize: 16)),
                  const SizedBox(width: 8),
                ],
                Expanded(
                  child: Text(
                    replyText,
                    style: TextStyle(
                      fontSize: 14,
                      color: IOSTheme.iosLabel,
                    ),
                  ),
                ),
                Icon(
                  _getPlatformIcon(),
                  size: 16,
                  color: IOSTheme.iosSecondaryLabel,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  IconData _getPlatformIcon() {
    switch (widget.platform.toLowerCase()) {
      case 'instagram':
        return Icons.camera_alt;
      case 'whatsapp':
        return Icons.chat;
      case 'wechat':
        return Icons.forum;
      case 'imessage':
      default:
        return Icons.message;
    }
  }

  void _showSendOptions(String message) {
    showCupertinoModalPopup(
      context: context,
      builder: (BuildContext context) => CupertinoActionSheet(
        title: Text('Send Reply'),
        message: Text(message),
        actions: <CupertinoActionSheetAction>[
          // Platform-specific send option
          CupertinoActionSheetAction(
            onPressed: () {
              Navigator.pop(context);
              _sendViaPlatform(message);
            },
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(_getPlatformIcon(), size: 20),
                const SizedBox(width: 8),
                Text(_getSendButtonText()),
              ],
            ),
          ),
          // Copy to clipboard
          CupertinoActionSheetAction(
            onPressed: () {
              Navigator.pop(context);
              _copyToClipboard(message);
            },
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.copy, size: 20),
                SizedBox(width: 8),
                Text('Copy to Clipboard'),
              ],
            ),
          ),
          // Add to UI only (for testing)
          CupertinoActionSheetAction(
            onPressed: () {
              Navigator.pop(context);
              widget.onReplySelected(message);
              setState(() => _isExpanded = false);
            },
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.message, size: 20),
                SizedBox(width: 8),
                Text('Show in UI (Demo Mode)'),
              ],
            ),
          ),
        ],
        cancelButton: CupertinoActionSheetAction(
          isDestructiveAction: true,
          onPressed: () {
            Navigator.pop(context);
          },
          child: const Text('Cancel'),
        ),
      ),
    );
  }

  String _getSendButtonText() {
    switch (widget.platform.toLowerCase()) {
      case 'instagram':
        return 'Open in Instagram';
      case 'whatsapp':
        return 'Open in WhatsApp';
      case 'wechat':
        return 'Open in WeChat';
      case 'imessage':
        return 'Open in Messages';
      default:
        return 'Send Message';
    }
  }

  Future<void> _sendViaPlatform(String message) async {
    try {
      Uri? uri;
      
      switch (widget.platform.toLowerCase()) {
        case 'instagram':
          // Instagram doesn't have a direct message URL scheme
          // Open Instagram app instead
          uri = Uri.parse('instagram://');
          // Show instructions after opening
          _showInstagramInstructions(message);
          break;
          
        case 'whatsapp':
          // WhatsApp uses phone numbers - you'd need to store contact phone
          // For now, open WhatsApp
          uri = Uri.parse('whatsapp://');
          _showWhatsAppInstructions(message);
          break;
          
        case 'wechat':
          // WeChat URL scheme
          uri = Uri.parse('weixin://');
          _showWeChatInstructions(message);
          break;
          
        case 'imessage':
          // iMessage/SMS (requires phone number)
          // For now, copy and show instructions
          await _copyToClipboard(message);
          _showMessagesInstructions();
          break;
          
        default:
          await _copyToClipboard(message);
          return;
      }

      if (uri != null && await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        // Fallback: copy to clipboard
        await _copyToClipboard(message);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('${widget.platform} not installed. Message copied to clipboard!'),
              backgroundColor: Colors.orange,
            ),
          );
        }
      }
    } catch (e) {
      await _copyToClipboard(message);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Message copied to clipboard! Paste in ${widget.platform}'),
            backgroundColor: IOSTheme.iosBlue,
          ),
        );
      }
    }
  }

  Future<void> _copyToClipboard(String message) async {
    await Clipboard.setData(ClipboardData(text: message));
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('📋 Message copied to clipboard!'),
          duration: Duration(seconds: 2),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  void _showInstagramInstructions(String message) {
    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.camera_alt, color: Colors.pink),
            SizedBox(width: 8),
            Text('Instagram'),
          ],
        ),
        content: Column(
          children: [
            const SizedBox(height: 12),
            const Text(
              'Instagram is opening...\n\nMessage copied to clipboard!',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Next steps:',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text('1. Find ${widget.contactName} in Instagram'),
                  const Text('2. Tap to open chat'),
                  const Text('3. Paste message (long-press text field)'),
                  const Text('4. Tap Send!'),
                ],
              ),
            ),
          ],
        ),
        actions: [
          CupertinoDialogAction(
            child: const Text('Got it!'),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }

  void _showWhatsAppInstructions(String message) {
    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.chat, color: Colors.green),
            SizedBox(width: 8),
            Text('WhatsApp'),
          ],
        ),
        content: Column(
          children: [
            const SizedBox(height: 12),
            const Text(
              'WhatsApp is opening...\n\nMessage copied to clipboard!',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Next steps:',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text('1. Find ${widget.contactName}'),
                  const Text('2. Open chat'),
                  const Text('3. Paste and send!'),
                ],
              ),
            ),
          ],
        ),
        actions: [
          CupertinoDialogAction(
            child: const Text('Got it!'),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }

  void _showWeChatInstructions(String message) {
    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.forum, color: Colors.green),
            SizedBox(width: 8),
            Text('WeChat'),
          ],
        ),
        content: Column(
          children: [
            const SizedBox(height: 12),
            const Text(
              'WeChat is opening...\n\nMessage copied to clipboard!',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Next steps:',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text('1. Find ${widget.contactName}'),
                  const Text('2. Open chat'),
                  const Text('3. Paste message'),
                  const Text('4. Send!'),
                ],
              ),
            ),
          ],
        ),
        actions: [
          CupertinoDialogAction(
            child: const Text('Got it!'),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }

  void _showMessagesInstructions() {
    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.message, color: Colors.blue),
            SizedBox(width: 8),
            Text('Messages'),
          ],
        ),
        content: Column(
          children: [
            const SizedBox(height: 12),
            const Text(
              'Message copied to clipboard!',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Next steps:',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  const Text('1. Open Messages app'),
                  Text('2. Find ${widget.contactName}'),
                  const Text('3. Paste and send!'),
                ],
              ),
            ),
          ],
        ),
        actions: [
          CupertinoDialogAction(
            child: const Text('Got it!'),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }
}
