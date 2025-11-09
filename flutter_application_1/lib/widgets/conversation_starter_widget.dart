import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

/// 💬 Conversation Starter Widget - Powered by NVIDIA Agent 9
/// Generates personalized ice-breakers to re-engage relationships
class ConversationStarterWidget extends StatefulWidget {
  final String contactName;
  final List<Map<String, dynamic>> recentMessages;
  final int daysSinceLastMessage;
  final Function(String) onStarterSelected;

  const ConversationStarterWidget({
    super.key,
    required this.contactName,
    required this.recentMessages,
    required this.daysSinceLastMessage,
    required this.onStarterSelected,
  });

  @override
  State<ConversationStarterWidget> createState() =>
      _ConversationStarterWidgetState();
}

class _ConversationStarterWidgetState extends State<ConversationStarterWidget>
    with SingleTickerProviderStateMixin {
  bool _isLoading = false;
  bool _isExpanded = false;
  List<Map<String, dynamic>> _starters = [];
  late AnimationController _shimmerController;

  @override
  void initState() {
    super.initState();
    _shimmerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat();
  }

  @override
  void dispose() {
    _shimmerController.dispose();
    super.dispose();
  }

  Future<void> _generateStarters() async {
    if (_isLoading) return;

    setState(() {
      _isLoading = true;
      _isExpanded = !_isExpanded;
    });

    if (!_isExpanded) {
      setState(() {
        _isLoading = false;
      });
      return;
    }

    try {
      final response = await http
          .post(
            Uri.parse('http://localhost:5000/agent/conversation_starter'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'contact_name': widget.contactName,
              'recent_messages': widget.recentMessages,
              'days_since_last_message': widget.daysSinceLastMessage,
            }),
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true && data['data']['starters'] != null) {
          setState(() {
            _starters =
                List<Map<String, dynamic>>.from(data['data']['starters']);
          });
        }
      }
    } catch (e) {
      print('Starter generation error: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.cyan.shade50,
            Colors.teal.shade50,
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.cyan.shade200,
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.cyan.withOpacity(0.15),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // Header
          InkWell(
            onTap: _generateStarters,
            borderRadius: BorderRadius.circular(20),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Colors.cyan.shade400, Colors.teal.shade400],
                      ),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.chat_bubble_outline,
                      color: Colors.white,
                      size: 26,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Conversation Starters',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Get personalized ice-breakers',
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (_isLoading)
                    const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  else
                    AnimatedRotation(
                      turns: _isExpanded ? 0.5 : 0,
                      duration: const Duration(milliseconds: 300),
                      child: Icon(
                        Icons.keyboard_arrow_down,
                        color: Colors.grey.shade600,
                      ),
                    ),
                ],
              ),
            ),
          ),

          // Expanded content
          if (_isExpanded) ...[
            const Divider(height: 1),
            _isLoading
                ? _buildLoadingState()
                : _starters.isEmpty
                    ? _buildEmptyState()
                    : _buildStartersList(),
          ],
        ],
      ),
    );
  }

  Widget _buildLoadingState() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          AnimatedBuilder(
            animation: _shimmerController,
            builder: (context, child) {
              return Transform.rotate(
                angle: _shimmerController.value * 2 * 3.14159,
                child: const Icon(
                  Icons.psychology,
                  size: 40,
                  color: Colors.cyan,
                ),
              );
            },
          ),
          const SizedBox(height: 16),
          const Text(
            'Analyzing conversation history...',
            style: TextStyle(
              fontSize: 13,
              color: Colors.grey,
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return const Padding(
      padding: EdgeInsets.all(24),
      child: Text(
        'Could not generate starters. Try again.',
        style: TextStyle(
          fontSize: 13,
          color: Colors.grey,
          fontStyle: FontStyle.italic,
        ),
      ),
    );
  }

  Widget _buildStartersList() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Tap any starter to use it:',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade700,
            ),
          ),
          const SizedBox(height: 12),
          ...(_starters.take(5).map((starter) => _buildStarterCard(starter))),
        ],
      ),
    );
  }

  Widget _buildStarterCard(Map<String, dynamic> starter) {
    final message = starter['message'] ?? 'Say something nice';
    final reasoning = starter['reasoning'] ?? '';
    final riskLevel = starter['risk_level'] ?? 'safe';
    final category = starter['category'] ?? 'personal';

    Color riskColor = Colors.green;
    String riskEmoji = '✅';

    if (riskLevel == 'bold') {
      riskColor = Colors.orange;
      riskEmoji = '🔥';
    } else if (riskLevel == 'medium') {
      riskColor = Colors.blue;
      riskEmoji = '💙';
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: riskColor.withOpacity(0.3),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: riskColor.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            widget.onStarterSelected(message);
          },
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Risk level badge
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: riskColor.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            riskEmoji,
                            style: const TextStyle(fontSize: 12),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            riskLevel.toUpperCase(),
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: riskColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        category,
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey.shade600,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ),
                    Icon(
                      Icons.send,
                      size: 16,
                      color: Colors.grey.shade400,
                    ),
                  ],
                ),
                const SizedBox(height: 8),

                // Message text
                Text(
                  message,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                    height: 1.4,
                  ),
                ),

                // Reasoning
                if (reasoning.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Text(
                    'Why: $reasoning',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade600,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
