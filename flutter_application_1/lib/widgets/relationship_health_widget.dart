import 'package:flutter/material.dart';
import '../theme/ios_theme.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

class RelationshipHealthWidget extends StatefulWidget {
  final String contactName;
  final int messageCount;
  final int daysSinceLastMessage;
  final double avgResponseTimeHours;
  final String conversationHistory;

  const RelationshipHealthWidget({
    super.key,
    required this.contactName,
    required this.messageCount,
    required this.daysSinceLastMessage,
    required this.avgResponseTimeHours,
    required this.conversationHistory,
  });

  @override
  State<RelationshipHealthWidget> createState() =>
      _RelationshipHealthWidgetState();
}

class _RelationshipHealthWidgetState extends State<RelationshipHealthWidget> {
  int _healthScore = 0;
  String _status = 'Loading...';
  List<String> _insights = [];
  List<String> _suggestions = [];
  Map<String, int> _breakdown = {};
  bool _isLoading = true;
  bool _isExpanded = false;

  @override
  void initState() {
    super.initState();
    _loadHealthScore();
  }

  Future<void> _loadHealthScore() async {
    try {
      final response = await http.post(
        Uri.parse('http://localhost:5000/agent/relationship_health'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'contact_name': widget.contactName,
          'message_count': widget.messageCount,
          'days_since_last_message': widget.daysSinceLastMessage,
          'avg_response_time_hours': widget.avgResponseTimeHours,
          'conversation_history': widget.conversationHistory,
        }),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (mounted && data['success'] == true) {
          final healthData = data['data'];
          setState(() {
            _healthScore = healthData['overall_score'] ?? 70;
            _status = healthData['status'] ?? 'good';
            _insights = List<String>.from(healthData['insights'] ?? []);
            _suggestions = List<String>.from(healthData['suggestions'] ?? []);
            if (healthData['breakdown'] != null) {
              _breakdown = Map<String, int>.from(healthData['breakdown']);
            }
            _isLoading = false;
          });
        }
      } else {
        _setFallbackData();
      }
    } catch (e) {
      print('Health score error: $e');
      _setFallbackData();
    }
  }

  void _setFallbackData() {
    if (mounted) {
      // Calculate intelligent fallback score based on activity patterns
      int calculatedScore = _calculateIntelligentScore();
      
      setState(() {
        _healthScore = calculatedScore;
        _status = _getStatusFromScore(calculatedScore);
        _insights = _generateInsights();
        _suggestions = _generateSuggestions();
        _isLoading = false;
      });
    }
  }

  int _calculateIntelligentScore() {
    int score = 100;
    
    // Factor 1: Days since last message (40% weight)
    if (widget.daysSinceLastMessage > 30) {
      score -= 40;
    } else if (widget.daysSinceLastMessage > 14) {
      score -= 30;
    } else if (widget.daysSinceLastMessage > 7) {
      score -= 20;
    } else if (widget.daysSinceLastMessage > 3) {
      score -= 10;
    }
    
    // Factor 2: Message frequency (30% weight)
    if (widget.messageCount < 10) {
      score -= 25;
    } else if (widget.messageCount < 50) {
      score -= 15;
    } else if (widget.messageCount < 100) {
      score -= 5;
    }
    
    // Factor 3: Response time (30% weight)
    if (widget.avgResponseTimeHours > 48) {
      score -= 25;
    } else if (widget.avgResponseTimeHours > 24) {
      score -= 15;
    } else if (widget.avgResponseTimeHours > 12) {
      score -= 10;
    } else if (widget.avgResponseTimeHours > 6) {
      score -= 5;
    }
    
    // Ensure score is within 0-100 range
    return score.clamp(0, 100);
  }

  String _getStatusFromScore(int score) {
    if (score >= 80) return 'excellent';
    if (score >= 60) return 'good';
    if (score >= 40) return 'fair';
    return 'needs attention';
  }

  List<String> _generateInsights() {
    List<String> insights = [];
    
    if (widget.daysSinceLastMessage > 14) {
      insights.add('Haven\'t messaged ${widget.contactName} in ${widget.daysSinceLastMessage} days');
    } else if (widget.daysSinceLastMessage > 7) {
      insights.add('It\'s been over a week since your last conversation');
    }
    
    if (widget.messageCount > 200) {
      insights.add('You have a strong messaging history (${widget.messageCount} messages)');
    } else if (widget.messageCount > 100) {
      insights.add('Good conversation frequency with ${widget.messageCount} messages');
    }
    
    if (widget.avgResponseTimeHours < 2) {
      insights.add('You both respond quickly to each other');
    } else if (widget.avgResponseTimeHours > 24) {
      insights.add('Response times are slower than usual');
    }
    
    if (insights.isEmpty) {
      insights.add('Your friendship is in good standing');
    }
    
    return insights;
  }

  List<String> _generateSuggestions() {
    List<String> suggestions = [];
    
    if (widget.daysSinceLastMessage > 14) {
      suggestions.add('Consider reaching out to catch up');
    } else if (widget.daysSinceLastMessage > 7) {
      suggestions.add('Share an interesting update or meme');
    }
    
    if (widget.avgResponseTimeHours > 24) {
      suggestions.add('Try engaging with more timely responses');
    }
    
    if (widget.messageCount < 50) {
      suggestions.add('Build stronger connections through regular conversations');
    }
    
    if (suggestions.isEmpty) {
      suggestions.add('Keep up the great communication!');
    }
    
    return suggestions;
  }

  Color _getScoreColor() {
    if (_healthScore >= 80) return Colors.green;
    if (_healthScore >= 60) return Colors.orange;
    return Colors.red;
  }

  String _getScoreEmoji() {
    if (_healthScore >= 80) return '🎉';
    if (_healthScore >= 60) return '👍';
    return '⚠️';
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Container(
        margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: IOSTheme.iosSystemBackground,
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      padding: const EdgeInsets.all(16),
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
          // Header with score
          InkWell(
            onTap: () => setState(() => _isExpanded = !_isExpanded),
            child: Row(
              children: [
                // Score circle
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: _getScoreColor(),
                      width: 4,
                    ),
                  ),
                  child: Center(
                    child: Text(
                      '$_healthScore',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: _getScoreColor(),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),

                // Status
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            'Friendship Health',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: IOSTheme.iosLabel,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            _getScoreEmoji(),
                            style: const TextStyle(fontSize: 16),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _status.toUpperCase(),
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: _getScoreColor(),
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                ),

                Icon(
                  _isExpanded ? Icons.expand_less : Icons.expand_more,
                  color: IOSTheme.iosSecondaryLabel,
                ),
              ],
            ),
          ),

          // Expanded details
          if (_isExpanded) ...[
            const SizedBox(height: 20),
            const Divider(),
            const SizedBox(height: 12),

            // Breakdown scores
            if (_breakdown.isNotEmpty) ...[
              Text(
                'Score Breakdown',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: IOSTheme.iosLabel,
                ),
              ),
              const SizedBox(height: 12),
              ..._breakdown.entries.map((entry) => _buildBreakdownBar(entry.key, entry.value)),
              const SizedBox(height: 16),
            ],

            // Insights
            if (_insights.isNotEmpty) ...[
              Text(
                'Insights',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: IOSTheme.iosLabel,
                ),
              ),
              const SizedBox(height: 8),
              ..._insights.map((insight) => _buildInsightItem(insight, Icons.lightbulb_outline, Colors.amber)),
              const SizedBox(height: 16),
            ],

            // Suggestions
            if (_suggestions.isNotEmpty) ...[
              Text(
                'Suggestions',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: IOSTheme.iosLabel,
                ),
              ),
              const SizedBox(height: 8),
              ..._suggestions.map((suggestion) => _buildInsightItem(suggestion, Icons.tips_and_updates, IOSTheme.iosBlue)),
            ],
          ],
        ],
      ),
    );
  }

  Widget _buildBreakdownBar(String label, int score) {
    final displayLabel = label
        .replaceAll('_', ' ')
        .split(' ')
        .map((word) => word[0].toUpperCase() + word.substring(1))
        .join(' ');

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                displayLabel,
                style: TextStyle(
                  fontSize: 13,
                  color: IOSTheme.iosSecondaryLabel,
                ),
              ),
              Text(
                '$score',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: IOSTheme.iosLabel,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: score / 100,
              minHeight: 6,
              backgroundColor: Colors.grey.withOpacity(0.2),
              valueColor: AlwaysStoppedAnimation<Color>(
                score >= 80 ? Colors.green :
                score >= 60 ? Colors.orange : Colors.red,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInsightItem(String text, IconData icon, Color iconColor) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: iconColor.withOpacity(0.05),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: iconColor.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: iconColor),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 13,
                color: IOSTheme.iosLabel,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
