import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

/// 📈 Relationship Forecast Widget - Powered by NVIDIA Agent 10
/// Predictive analytics for relationship health trajectory
class RelationshipForecastWidget extends StatefulWidget {
  final String contactName;
  final List<Map<String, dynamic>> healthHistory;
  final List<Map<String, dynamic>> recentMessages;

  const RelationshipForecastWidget({
    super.key,
    required this.contactName,
    required this.healthHistory,
    required this.recentMessages,
  });

  @override
  State<RelationshipForecastWidget> createState() =>
      _RelationshipForecastWidgetState();
}

class _RelationshipForecastWidgetState
    extends State<RelationshipForecastWidget>
    with SingleTickerProviderStateMixin {
  bool _isLoading = false;
  bool _isExpanded = false;
  Map<String, dynamic>? _forecast;
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  Future<void> _generateForecast() async {
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
            Uri.parse('http://localhost:5000/agent/relationship_forecast'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'contact_name': widget.contactName,
              'health_history': widget.healthHistory,
              'recent_messages': widget.recentMessages,
            }),
          )
          .timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          setState(() {
            _forecast = data['data'];
          });
        }
      }
    } catch (e) {
      print('Forecast error: $e');
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
            Colors.indigo.shade50,
            Colors.pink.shade50,
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.indigo.shade200,
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.indigo.withOpacity(0.15),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // Header
          InkWell(
            onTap: _generateForecast,
            borderRadius: BorderRadius.circular(20),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  AnimatedBuilder(
                    animation: _pulseController,
                    builder: (context, child) {
                      return Transform.scale(
                        scale: 1.0 + (_pulseController.value * 0.1),
                        child: Container(
                          width: 50,
                          height: 50,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                Colors.indigo.shade400,
                                Colors.pink.shade400
                              ],
                            ),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.trending_up,
                            color: Colors.white,
                            size: 26,
                          ),
                        ),
                      );
                    },
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Relationship Forecast',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Predict future health',
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
                : _forecast != null
                    ? _buildForecastContent()
                    : _buildEmptyState(),
          ],
        ],
      ),
    );
  }

  Widget _buildLoadingState() {
    return const Padding(
      padding: EdgeInsets.all(24),
      child: Column(
        children: [
          CircularProgressIndicator(),
          SizedBox(height: 16),
          Text(
            'Analyzing relationship trajectory...',
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
        'Could not generate forecast. Need more data.',
        style: TextStyle(
          fontSize: 13,
          color: Colors.grey,
          fontStyle: FontStyle.italic,
        ),
      ),
    );
  }

  Widget _buildForecastContent() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 30-Day Forecast
          if (_forecast!['forecast_30_days'] != null) ...[
            _buildForecastCard(
              '30-Day Forecast',
              _forecast!['forecast_30_days'],
              Colors.blue,
            ),
            const SizedBox(height: 12),
          ],

          // 90-Day Forecast
          if (_forecast!['forecast_90_days'] != null) ...[
            _buildForecastCard(
              '90-Day Forecast',
              _forecast!['forecast_90_days'],
              Colors.purple,
            ),
            const SizedBox(height: 16),
          ],

          // Interventions
          if (_forecast!['interventions'] != null) ...[
            _buildSectionTitle('⚡ Recommended Actions'),
            const SizedBox(height: 8),
            ...(_buildInterventionsList(
                List<Map<String, dynamic>>.from(
                    _forecast!['interventions']))),
            const SizedBox(height: 16),
          ],

          // Risk Factors
          if (_forecast!['risk_factors'] != null) ...[
            _buildSectionTitle('⚠️ Risk Factors'),
            const SizedBox(height: 8),
            ...(_buildRiskFactorsList(
                List<Map<String, dynamic>>.from(_forecast!['risk_factors']))),
            const SizedBox(height: 16),
          ],

          // Summary
          if (_forecast!['summary'] != null) ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.indigo.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.indigo.shade200),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.info_outline,
                      color: Colors.indigo.shade700, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _forecast!['summary'],
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.indigo.shade900,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildForecastCard(
      String title, Map<String, dynamic> forecast, Color color) {
    final predictedScore = forecast['predicted_score'] ?? 70;
    final trajectory = forecast['trajectory'] ?? 'stable';
    final reasoning = forecast['reasoning'] ?? '';

    IconData icon = Icons.trending_flat;
    Color iconColor = Colors.orange;

    if (trajectory.contains('improving') || trajectory.contains('growth')) {
      icon = Icons.trending_up;
      iconColor = Colors.green;
    } else if (trajectory.contains('decline')) {
      icon = Icons.trending_down;
      iconColor = Colors.red;
    }

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: iconColor, size: 24),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
              ),
              Text(
                '$predictedScore',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: iconColor,
                ),
              ),
            ],
          ),
          if (reasoning.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              reasoning,
              style: TextStyle(
                fontSize: 12,
                color: color,
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

  List<Widget> _buildInterventionsList(List<Map<String, dynamic>> interventions) {
    return interventions.take(3).map((intervention) {
      final action = intervention['action'] ?? 'Take action';
      final priority = intervention['priority'] ?? 'medium';
      final expectedImpact = intervention['expected_impact'] ?? '';
      final timing = intervention['timing'] ?? '';

      Color priorityColor = Colors.orange;
      if (priority == 'high') priorityColor = Colors.red;
      if (priority == 'low') priorityColor = Colors.blue;

      return Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: priorityColor.withOpacity(0.3)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: priorityColor.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    priority.toUpperCase(),
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: priorityColor,
                    ),
                  ),
                ),
                if (expectedImpact.isNotEmpty) ...[
                  const SizedBox(width: 8),
                  Text(
                    expectedImpact,
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: Colors.green,
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 6),
            Text(
              action,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
            if (timing.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                '⏰ $timing',
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.grey.shade600,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ],
        ),
      );
    }).toList();
  }

  List<Widget> _buildRiskFactorsList(List<Map<String, dynamic>> risks) {
    return risks.take(3).map((risk) {
      final factor = risk['factor'] ?? 'Unknown risk';
      final severity = risk['severity'] ?? 'medium';

      Color severityColor = Colors.orange;
      if (severity == 'high') severityColor = Colors.red;
      if (severity == 'low') severityColor = Colors.yellow;

      return Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Icons.warning_amber, color: severityColor, size: 18),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                factor,
                style: const TextStyle(
                  fontSize: 13,
                  color: Colors.black87,
                ),
              ),
            ),
          ],
        ),
      );
    }).toList();
  }
}
