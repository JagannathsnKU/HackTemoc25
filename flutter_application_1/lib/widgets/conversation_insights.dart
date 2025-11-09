import 'package:flutter/material.dart';
import '../theme/ios_theme.dart';
import '../services/mcp_client.dart';
import '../models/conversation.dart';

class ConversationInsights extends StatefulWidget {
  final String contactName;
  final List<ChatMessage> messages;

  const ConversationInsights({
    Key? key,
    required this.contactName,
    required this.messages,
  }) : super(key: key);

  @override
  State<ConversationInsights> createState() => _ConversationInsightsState();
}

class _ConversationInsightsState extends State<ConversationInsights> {
  bool _isLoading = false;
  bool _isExpanded = false;
  Map<String, dynamic>? _analysis;
  List<Map<String, dynamic>>? _actionItems;
  String? _summary;
  bool _mcpAvailable = false;

  @override
  void initState() {
    super.initState();
    _checkMCPServer();
  }

  Future<void> _checkMCPServer() async {
    final available = await MCPClient.isServerRunning();
    setState(() {
      _mcpAvailable = available;
    });
  }

  Future<void> _analyzeConversation() async {
    if (_isLoading || widget.messages.isEmpty) return;

    setState(() {
      _isLoading = true;
    });

    try {
      // Get analysis, action items, and summary in parallel
      final results = await Future.wait([
        MCPClient.analyzeConversation(
          contactName: widget.contactName,
          messages: widget.messages,
        ),
        MCPClient.extractActionItems(
          contactName: widget.contactName,
          messages: widget.messages,
        ),
        MCPClient.getConversationSummary(
          contactName: widget.contactName,
          messages: widget.messages,
        ),
      ]);

      final analysis = results[0] as Map<String, dynamic>;
      
      // Check if API key error
      if (analysis.containsKey('error') && 
          analysis['error'].toString().contains('authentication_error')) {
        setState(() {
          _analysis = {
            'sentiment': 'Configuration Needed',
            'meeting_needs': 'Please configure Google Gemini API key',
            'action_items': [],
            'context_summary': 'To use Gemini AI features, you need to:\n1. Get FREE API key from aistudio.google.com/app/apikey\n2. Add to .env file: GEMINI_API_KEY=your_key\n3. Restart MCP server\n\nGemini is 100% FREE with 1500 requests/day!'
          };
          _actionItems = [];
          _summary = 'Gemini AI features require FREE API key configuration. See setup guide in GET_GEMINI_API_KEY.md';
          _isLoading = false;
          _isExpanded = true;
        });
        return;
      }

      setState(() {
        _analysis = analysis;
        _actionItems = results[1] as List<Map<String, dynamic>>;
        _summary = results[2] as String;
        _isLoading = false;
        _isExpanded = true;
      });
    } catch (e) {
      print('Error analyzing conversation: $e');
      setState(() {
        _isLoading = false;
        _analysis = {
          'sentiment': 'Error',
          'meeting_needs': 'Analysis failed',
          'context_summary': 'Unable to analyze. Check if MCP server is running and API key is configured.'
        };
        _isExpanded = true;
      });
    }
  }

  Color _getSentimentColor(String? sentiment) {
    switch (sentiment?.toLowerCase()) {
      case 'positive':
        return IOSTheme.iosGreen;
      case 'negative':
        return IOSTheme.iosRed;
      case 'configuration needed':
      case 'error':
        return IOSTheme.iosOrange;
      default:
        return IOSTheme.iosSecondaryLabel;
    }
  }

  IconData _getSentimentIcon(String? sentiment) {
    switch (sentiment?.toLowerCase()) {
      case 'positive':
        return Icons.sentiment_satisfied_alt;
      case 'negative':
        return Icons.sentiment_dissatisfied;
      case 'configuration needed':
      case 'error':
        return Icons.settings;
      default:
        return Icons.sentiment_neutral;
    }
  }

  String _getPriorityEmoji(String? priority) {
    switch (priority?.toLowerCase()) {
      case 'high':
        return '🔴';
      case 'medium':
        return '🟡';
      case 'low':
        return '🟢';
      default:
        return '⚪';
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_mcpAvailable) {
      return const SizedBox.shrink();
    }

    return Container(
      margin: const EdgeInsets.all(16),
      decoration: IOSTheme.iosCard(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header
          InkWell(
            onTap: _analysis == null ? _analyzeConversation : () {
              setState(() {
                _isExpanded = !_isExpanded;
              });
            },
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: IOSTheme.iosBlue.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.auto_awesome,
                      color: IOSTheme.iosBlue,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _analysis == null ? 'AI Insights' : 'Conversation Analysis',
                          style: const TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w600,
                            color: IOSTheme.iosLabel,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          _analysis == null
                              ? 'Tap to analyze with Claude AI'
                              : 'Powered by Claude AI',
                          style: const TextStyle(
                            fontSize: 13,
                            color: IOSTheme.iosSecondaryLabel,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (_isLoading)
                    const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  else if (_analysis != null)
                    Icon(
                      _isExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                      color: IOSTheme.iosSecondaryLabel,
                    )
                  else
                    Icon(
                      Icons.arrow_forward_ios,
                      size: 16,
                      color: IOSTheme.iosSecondaryLabel,
                    ),
                ],
              ),
            ),
          ),

          // Expanded Content
          if (_isExpanded && _analysis != null) ...[
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Sentiment
                  if (_analysis!['sentiment'] != null) ...[
                    _buildInsightRow(
                      icon: _getSentimentIcon(_analysis!['sentiment']),
                      iconColor: _getSentimentColor(_analysis!['sentiment']),
                      label: 'Sentiment',
                      value: _analysis!['sentiment'].toString().capitalize(),
                    ),
                    const SizedBox(height: 12),
                  ],

                  // Meeting Needs (only show if detected from chat)
                  if (_analysis!['meeting_needs'] != null &&
                      _analysis!['meeting_needs'].toString().toLowerCase() != 'no' &&
                      _analysis!['meeting_needs'].toString().toLowerCase() != 'none' &&
                      _analysis!['meeting_needs'].toString().toLowerCase() != 'unable to determine') ...[
                    _buildInsightRow(
                      icon: Icons.calendar_today,
                      iconColor: IOSTheme.iosBlue,
                      label: 'Meeting',
                      value: _analysis!['meeting_needs'].toString(),
                    ),
                    const SizedBox(height: 12),
                  ],

                  // Summary
                  if (_summary != null && _summary!.isNotEmpty) ...[
                    _buildSummaryCard(_summary!),
                    const SizedBox(height: 12),
                  ],

                  // Action Items
                  if (_actionItems != null && _actionItems!.isNotEmpty) ...[
                    const Text(
                      'Action Items',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: IOSTheme.iosLabel,
                      ),
                    ),
                    const SizedBox(height: 8),
                    ..._actionItems!.map((action) => _buildActionItem(action)),
                  ],
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildInsightRow({
    required IconData icon,
    required Color iconColor,
    required String label,
    required String value,
  }) {
    return Row(
      children: [
        Icon(icon, color: iconColor, size: 20),
        const SizedBox(width: 8),
        Text(
          '$label: ',
          style: const TextStyle(
            fontSize: 15,
            color: IOSTheme.iosSecondaryLabel,
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: IOSTheme.iosLabel,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSummaryCard(String summary) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: IOSTheme.iosGray6,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.summarize,
                size: 16,
                color: IOSTheme.iosSecondaryLabel,
              ),
              const SizedBox(width: 6),
              Text(
                'Summary',
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: IOSTheme.iosSecondaryLabel,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            summary,
            style: const TextStyle(
              fontSize: 16,
              color: IOSTheme.iosLabel,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionItem(Map<String, dynamic> action) {
    final task = action['task']?.toString() ?? 'Unknown task';
    final priority = action['priority']?.toString() ?? 'medium';
    final deadline = action['deadline']?.toString() ?? 'Not specified';
    final assignedTo = action['assigned_to']?.toString() ?? '';

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: IOSTheme.iosGray6,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: IOSTheme.iosGray4,
          width: 0.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                _getPriorityEmoji(priority),
                style: const TextStyle(fontSize: 14),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  task,
                  style: const TextStyle(
                    fontSize: 16,
                    color: IOSTheme.iosLabel,
                  ),
                ),
              ),
            ],
          ),
          if (deadline != 'Not specified' || assignedTo.isNotEmpty) ...[
            const SizedBox(height: 6),
            Row(
              children: [
                if (deadline != 'Not specified') ...[
                  const Icon(
                    Icons.schedule,
                    size: 12,
                    color: IOSTheme.iosSecondaryLabel,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    deadline,
                    style: const TextStyle(
                      fontSize: 12,
                      color: IOSTheme.iosSecondaryLabel,
                    ),
                  ),
                ],
                if (assignedTo.isNotEmpty) ...[
                  if (deadline != 'Not specified') const SizedBox(width: 12),
                  const Icon(
                    Icons.person_outline,
                    size: 12,
                    color: IOSTheme.iosSecondaryLabel,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    assignedTo,
                    style: const TextStyle(
                      fontSize: 12,
                      color: IOSTheme.iosSecondaryLabel,
                    ),
                  ),
                ],
              ],
            ),
          ],
        ],
      ),
    );
  }
}

extension StringExtension on String {
  String capitalize() {
    if (isEmpty) return this;
    return this[0].toUpperCase() + substring(1);
  }
}
