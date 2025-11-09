import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

/// 🔍 Conversation Insights Widget - Powered by NVIDIA Agent 8
/// Deep analysis of conversation patterns, topics, and relationship evolution
class ConversationInsightsWidget extends StatefulWidget {
  final String contactName;
  final List<Map<String, dynamic>> recentMessages;

  const ConversationInsightsWidget({
    super.key,
    required this.contactName,
    required this.recentMessages,
  });

  @override
  State<ConversationInsightsWidget> createState() =>
      _ConversationInsightsWidgetState();
}

class _ConversationInsightsWidgetState
    extends State<ConversationInsightsWidget> with SingleTickerProviderStateMixin {
  bool _isLoading = false;
  bool _isExpanded = false;
  Map<String, dynamic>? _insights;
  late AnimationController _expandController;
  late Animation<double> _expandAnimation;

  @override
  void initState() {
    super.initState();
    _expandController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _expandAnimation = CurvedAnimation(
      parent: _expandController,
      curve: Curves.easeInOut,
    );
  }

  @override
  void dispose() {
    _expandController.dispose();
    super.dispose();
  }

  Future<void> _loadInsights() async {
    if (_isLoading) return;

    setState(() {
      _isLoading = true;
      _isExpanded = !_isExpanded;
    });

    if (_isExpanded) {
      _expandController.forward();
    } else {
      _expandController.reverse();
      setState(() {
        _isLoading = false;
      });
      return;
    }

    try {
      final response = await http
          .post(
            Uri.parse('http://localhost:5000/agent/conversation_insights'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'contact_name': widget.contactName,
              'recent_messages': widget.recentMessages,
            }),
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          setState(() {
            _insights = data['data'];
          });
        }
      }
    } catch (e) {
      print('Insights error: $e');
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
            Colors.purple.shade50,
            Colors.blue.shade50,
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.purple.shade200,
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.purple.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // Header - Always visible
          InkWell(
            onTap: _loadInsights,
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
                        colors: [Colors.purple.shade400, Colors.blue.shade400],
                      ),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.psychology,
                      color: Colors.white,
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Conversation Insights',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Deep pattern analysis',
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
          SizeTransition(
            sizeFactor: _expandAnimation,
            child: _insights != null
                ? _buildInsightsContent()
                : _buildLoadingOrEmpty(),
          ),
        ],
      ),
    );
  }

  Widget _buildInsightsContent() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Divider(),
          const SizedBox(height: 12),

          // Topics
          if (_insights!['topics'] != null) ...[
            _buildSectionTitle('📚 Topics'),
            const SizedBox(height: 8),
            _buildTopicsList(_insights!['topics']),
            const SizedBox(height: 16),
          ],

          // Communication Style
          if (_insights!['communication_style'] != null) ...[
            _buildSectionTitle('💬 Communication Style'),
            const SizedBox(height: 8),
            _buildCommunicationStyle(_insights!['communication_style']),
            const SizedBox(height: 16),
          ],

          // Relationship Trajectory
          if (_insights!['relationship_trajectory'] != null) ...[
            _buildSectionTitle('📈 Relationship Trend'),
            const SizedBox(height: 8),
            _buildTrajectory(_insights!['relationship_trajectory']),
            const SizedBox(height: 16),
          ],

          // Recommendations
          if (_insights!['recommendations'] != null) ...[
            _buildSectionTitle('💡 Recommendations'),
            const SizedBox(height: 8),
            _buildRecommendations(
                List<String>.from(_insights!['recommendations'])),
          ],

          // Summary
          if (_insights!['summary'] != null) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.purple.shade50,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                _insights!['summary'],
                style: const TextStyle(
                  fontSize: 13,
                  fontStyle: FontStyle.italic,
                  color: Colors.black87,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 15,
        fontWeight: FontWeight.bold,
        color: Colors.black87,
      ),
    );
  }

  Widget _buildTopicsList(Map<String, dynamic> topics) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        if (topics['primary'] != null)
          ...List<String>.from(topics['primary'])
              .map((topic) => _buildTopicChip(topic, Colors.purple)),
        if (topics['emerging'] != null)
          ...List<String>.from(topics['emerging'])
              .map((topic) => _buildTopicChip(topic, Colors.green)),
      ],
    );
  }

  Widget _buildTopicChip(String topic, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        topic,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }

  Widget _buildCommunicationStyle(Map<String, dynamic> style) {
    return Column(
      children: [
        _buildStyleRow('Formality', style['formality'] ?? 'N/A'),
        _buildStyleRow('Emoji Usage', style['emoji_usage'] ?? 'N/A'),
        _buildStyleRow('Message Length', style['avg_message_length'] ?? 'N/A'),
      ],
    );
  }

  Widget _buildStyleRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(fontSize: 13, color: Colors.grey.shade700),
          ),
          Text(
            value,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTrajectory(Map<String, dynamic> trajectory) {
    final trend = trajectory['trend'] ?? 'stable';
    final strength = trajectory['strength'] ?? 7.0;

    Color trendColor = Colors.green;
    IconData trendIcon = Icons.trending_up;

    if (trend == 'declining') {
      trendColor = Colors.red;
      trendIcon = Icons.trending_down;
    } else if (trend == 'stable') {
      trendColor = Colors.orange;
      trendIcon = Icons.trending_flat;
    }

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: trendColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(trendIcon, color: trendColor, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${trend.toUpperCase()} - Strength: ${strength.toStringAsFixed(1)}/10',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: trendColor,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecommendations(List<String> recommendations) {
    return Column(
      children: recommendations
          .take(3)
          .map((rec) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('• ', style: TextStyle(fontSize: 16)),
                    Expanded(
                      child: Text(
                        rec,
                        style: const TextStyle(
                          fontSize: 13,
                          color: Colors.black87,
                        ),
                      ),
                    ),
                  ],
                ),
              ))
          .toList(),
    );
  }

  Widget _buildLoadingOrEmpty() {
    return const Padding(
      padding: EdgeInsets.all(16),
      child: Center(
        child: Text(
          'Tap to analyze conversation patterns',
          style: TextStyle(
            fontSize: 13,
            color: Colors.grey,
            fontStyle: FontStyle.italic,
          ),
        ),
      ),
    );
  }
}
