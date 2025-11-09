import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/api_service_pro.dart';

/// 🤖 AI Agents Dashboard
/// Shows all available Reachly agents and their capabilities
class AgentsDashboardScreen extends StatelessWidget {
  const AgentsDashboardScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Reachly AI Agents'),
        backgroundColor: Colors.deepPurple,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.deepPurple.shade50,
              Colors.white,
            ],
          ),
        ),
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _buildHeader(),
            const SizedBox(height: 24),
            _buildAgentCard(
              context,
              title: '🤖 Orchestrator',
              subtitle: 'Nemotron 340B - Master Coordinator',
              description: 'The main AI brain that coordinates all other agents',
              color: Colors.deepPurple,
              onTap: () {
                // Already in use for chat summaries
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Active in chat summaries!')),
                );
              },
            ),
            const SizedBox(height: 12),
            _buildAgentCard(
              context,
              title: '🎯 Concierge',
              subtitle: 'Event Planning with ReAct Pattern',
              description: 'Plans events by coordinating calendars and preferences',
              color: Colors.blue,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const ConciergeAgentScreen(),
                  ),
                );
              },
            ),
            const SizedBox(height: 12),
            _buildAgentCard(
              context,
              title: '✍️ Ghostwriter',
              subtitle: 'Agentic RAG - Learns Your Voice',
              description: 'Writes messages in your authentic style',
              color: Colors.green,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const GhostwriterAgentScreen(),
                  ),
                );
              },
            ),
            const SizedBox(height: 12),
            _buildAgentCard(
              context,
              title: '🔍 Scout',
              subtitle: 'Multi-Modal VLM - Photo Analysis',
              description: 'Analyzes social media photos for touchpoints',
              color: Colors.orange,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const ScoutAgentScreen(),
                  ),
                );
              },
            ),
            const SizedBox(height: 12),
            _buildAgentCard(
              context,
              title: '🎤 Voice Interface',
              subtitle: 'Riva ASR/TTS - Coming Soon',
              description: 'Real-time voice conversation with Reachly',
              color: Colors.purple.shade300,
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Voice interface coming soon!')),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const Icon(
              Icons.psychology,
              size: 48,
              color: Colors.deepPurple,
            ),
            const SizedBox(height: 12),
            Text(
              'Multi-Agent System',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.deepPurple.shade900,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Powered by NVIDIA Nemotron NIMs',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAgentCard(
    BuildContext context, {
    required String title,
    required String subtitle,
    required String description,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 4,
                height: 60,
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: color,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey.shade700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      description,
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios,
                size: 16,
                color: Colors.grey.shade400,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// 🎯 Concierge Agent Screen
class ConciergeAgentScreen extends StatefulWidget {
  const ConciergeAgentScreen({Key? key}) : super(key: key);

  @override
  State<ConciergeAgentScreen> createState() => _ConciergeAgentScreenState();
}

class _ConciergeAgentScreenState extends State<ConciergeAgentScreen> {
  final _requestController = TextEditingController();
  final _apiService = ApiServicePro();
  bool _isPlanning = false;
  EventPlan? _plan;

  void _planEvent() async {
    if (_requestController.text.isEmpty) return;

    setState(() {
      _isPlanning = true;
      _plan = null;
    });

    try {
      // Mock calendar data
      final userCalendar = [
        CalendarEvent(
          title: 'Free',
          startTime: DateTime.now().add(const Duration(days: 1, hours: 15)),
          endTime: DateTime.now().add(const Duration(days: 1, hours: 18)),
        ),
      ];

      final friendCalendar = [
        CalendarEvent(
          title: 'Free',
          startTime: DateTime.now().add(const Duration(days: 1, hours: 14)),
          endTime: DateTime.now().add(const Duration(days: 1, hours: 19)),
        ),
      ];

      final plan = await _apiService.planEvent(
        request: _requestController.text,
        userCalendar: userCalendar,
        friendCalendar: friendCalendar,
      );

      setState(() {
        _plan = plan;
        _isPlanning = false;
      });
    } catch (e) {
      setState(() {
        _isPlanning = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('🎯 Concierge Agent'),
        backgroundColor: Colors.blue,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildInfoCard(),
            const SizedBox(height: 24),
            TextField(
              controller: _requestController,
              decoration: InputDecoration(
                labelText: 'Event Request',
                hintText: 'e.g., Plan lunch with John tomorrow',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                prefixIcon: const Icon(Icons.event),
              ),
              maxLines: 2,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _isPlanning ? null : _planEvent,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: _isPlanning
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation(Colors.white),
                      ),
                    )
                  : const Text(
                      'Plan Event with AI',
                      style: TextStyle(fontSize: 16, color: Colors.white),
                    ),
            ),
            if (_plan != null) ...[
              const SizedBox(height: 24),
              _buildPlanCard(_plan!),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCard() {
    return Card(
      color: Colors.blue.shade50,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.lightbulb, color: Colors.blue.shade700),
                const SizedBox(width: 8),
                Text(
                  'How it works',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.blue.shade900,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'The Concierge agent uses the ReAct Pattern:\n'
              '1. REASON: Analyzes what\'s needed\n'
              '2. ACT: Checks calendars & preferences\n'
              '3. OBSERVE: Reviews available data\n'
              '4. SYNTHESIZE: Creates perfect plan',
              style: TextStyle(fontSize: 13, color: Colors.grey.shade700),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlanCard(EventPlan plan) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.green, size: 28),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Event Plan Ready!',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.green.shade900,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: _getConfidenceColor(plan.confidence),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    plan.confidence.toUpperCase(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const Divider(height: 24),
            _buildPlanDetail('⏰ Time', plan.suggestedTime),
            const SizedBox(height: 12),
            _buildPlanDetail('🎯 Activity', plan.suggestedActivity),
            const SizedBox(height: 12),
            _buildPlanDetail('📍 Location', plan.suggestedLocation),
            const Divider(height: 24),
            Text(
              'AI Reasoning:',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.grey.shade700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              plan.reasoning,
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey.shade600,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlanDetail(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 100,
          child: Text(
            label,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade700,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(fontSize: 15),
          ),
        ),
      ],
    );
  }

  Color _getConfidenceColor(String confidence) {
    switch (confidence.toLowerCase()) {
      case 'high':
        return Colors.green;
      case 'medium':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }
}

/// ✍️ Ghostwriter Agent Screen
class GhostwriterAgentScreen extends StatefulWidget {
  const GhostwriterAgentScreen({Key? key}) : super(key: key);

  @override
  State<GhostwriterAgentScreen> createState() => _GhostwriterAgentScreenState();
}

class _GhostwriterAgentScreenState extends State<GhostwriterAgentScreen> {
  final _messageController = TextEditingController();
  final _apiService = ApiServicePro();
  bool _isWriting = false;
  String? _generatedMessage;

  // Mock user writing style samples
  final _writingSamples = [
    "hey man! that sounds sick 🔥",
    "for sure, let's do it",
    "omg yes! 😂",
    "sounds good to me bro",
    "that's awesome dude",
  ];

  void _writeMessage() async {
    if (_messageController.text.isEmpty) return;

    setState(() {
      _isWriting = true;
      _generatedMessage = null;
    });

    try {
      final message = await _apiService.writeMessage(
        messageContent: _messageController.text,
        writingSamples: _writingSamples,
      );

      setState(() {
        _generatedMessage = message;
        _isWriting = false;
      });
    } catch (e) {
      setState(() {
        _isWriting = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  void _copyMessage() {
    if (_generatedMessage != null) {
      Clipboard.setData(ClipboardData(text: _generatedMessage!));
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Message copied to clipboard!')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('✍️ Ghostwriter Agent'),
        backgroundColor: Colors.green,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildInfoCard(),
            const SizedBox(height: 24),
            _buildWritingSamplesCard(),
            const SizedBox(height: 24),
            TextField(
              controller: _messageController,
              decoration: InputDecoration(
                labelText: 'What to say',
                hintText: 'e.g., Ask about weekend plans',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                prefixIcon: const Icon(Icons.chat_bubble_outline),
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _isWriting ? null : _writeMessage,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: _isWriting
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation(Colors.white),
                      ),
                    )
                  : const Text(
                      'Write in My Voice',
                      style: TextStyle(fontSize: 16, color: Colors.white),
                    ),
            ),
            if (_generatedMessage != null) ...[
              const SizedBox(height: 24),
              _buildGeneratedMessageCard(_generatedMessage!),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCard() {
    return Card(
      color: Colors.green.shade50,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.auto_awesome, color: Colors.green.shade700),
                const SizedBox(width: 8),
                Text(
                  'Agentic RAG',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.green.shade900,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'The Ghostwriter agent learns YOUR writing style:\n'
              '• Analyzes your past messages (RAG)\n'
              '• Matches your tone and vocabulary\n'
              '• Uses your typical emojis and slang\n'
              '• Sounds 100% authentic',
              style: TextStyle(fontSize: 13, color: Colors.grey.shade700),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWritingSamplesCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Your Writing Style (RAG Data):',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.grey.shade800,
              ),
            ),
            const SizedBox(height: 12),
            ..._writingSamples.map((sample) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    children: [
                      Icon(Icons.chat, size: 16, color: Colors.grey.shade400),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          sample,
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey.shade600,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ),
                    ],
                  ),
                )),
          ],
        ),
      ),
    );
  }

  Widget _buildGeneratedMessageCard(String message) {
    return Card(
      elevation: 4,
      color: Colors.green.shade50,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.green),
                const SizedBox(width: 8),
                const Text(
                  'Generated Message',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.copy),
                  onPressed: _copyMessage,
                  tooltip: 'Copy to clipboard',
                ),
              ],
            ),
            const Divider(),
            Text(
              message,
              style: const TextStyle(fontSize: 16, height: 1.5),
            ),
          ],
        ),
      ),
    );
  }
}

/// 🔍 Scout Agent Screen
class ScoutAgentScreen extends StatefulWidget {
  const ScoutAgentScreen({Key? key}) : super(key: key);

  @override
  State<ScoutAgentScreen> createState() => _ScoutAgentScreenState();
}

class _ScoutAgentScreenState extends State<ScoutAgentScreen> {
  final _friendNameController = TextEditingController();
  final _photoUrlController = TextEditingController();
  final _apiService = ApiServicePro();
  bool _isAnalyzing = false;
  SocialTouchpoint? _touchpoint;

  void _analyzePhoto() async {
    if (_friendNameController.text.isEmpty) return;

    setState(() {
      _isAnalyzing = true;
      _touchpoint = null;
    });

    try {
      final touchpoint = await _apiService.analyzeSocial(
        friendName: _friendNameController.text,
        photoUrl: _photoUrlController.text.isNotEmpty
            ? _photoUrlController.text
            : null,
      );

      setState(() {
        _touchpoint = touchpoint;
        _isAnalyzing = false;
      });
    } catch (e) {
      setState(() {
        _isAnalyzing = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('🔍 Scout Agent'),
        backgroundColor: Colors.orange,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildInfoCard(),
            const SizedBox(height: 24),
            TextField(
              controller: _friendNameController,
              decoration: InputDecoration(
                labelText: 'Friend Name',
                hintText: 'e.g., Sarah',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                prefixIcon: const Icon(Icons.person),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _photoUrlController,
              decoration: InputDecoration(
                labelText: 'Photo URL (Optional)',
                hintText: 'https://example.com/photo.jpg',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                prefixIcon: const Icon(Icons.image),
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _isAnalyzing ? null : _analyzePhoto,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: _isAnalyzing
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation(Colors.white),
                      ),
                    )
                  : const Text(
                      'Analyze with VLM',
                      style: TextStyle(fontSize: 16, color: Colors.white),
                    ),
            ),
            if (_touchpoint != null) ...[
              const SizedBox(height: 24),
              _buildTouchpointCard(_touchpoint!),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCard() {
    return Card(
      color: Colors.orange.shade50,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.visibility, color: Colors.orange.shade700),
                const SizedBox(width: 8),
                Text(
                  'Multi-Modal Vision',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.orange.shade900,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'The Scout agent uses Vision-Language Model:\n'
              '• Analyzes social media photos\n'
              '• Finds genuine conversation starters\n'
              '• Identifies life events & interests\n'
              '• Suggests perfect icebreakers',
              style: TextStyle(fontSize: 13, color: Colors.grey.shade700),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTouchpointCard(SocialTouchpoint touchpoint) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  _getTouchpointIcon(touchpoint.touchpointType),
                  color: Colors.orange,
                  size: 28,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Touchpoint Found!',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.orange.shade900,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: _getPriorityColor(touchpoint.priority),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    touchpoint.priority.toUpperCase(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const Divider(height: 24),
            Text(
              'Summary:',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.grey.shade700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              touchpoint.summary,
              style: const TextStyle(fontSize: 15),
            ),
            const Divider(height: 24),
            Text(
              'Suggested Icebreaker:',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.grey.shade700,
              ),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orange.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.orange.shade200),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      touchpoint.icebreaker,
                      style: const TextStyle(
                        fontSize: 15,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.copy),
                    onPressed: () {
                      Clipboard.setData(
                        ClipboardData(text: touchpoint.icebreaker),
                      );
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Icebreaker copied to clipboard!'),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  IconData _getTouchpointIcon(String type) {
    switch (type) {
      case 'new_photo':
        return Icons.photo_camera;
      case 'life_event':
        return Icons.celebration;
      case 'shared_interest':
        return Icons.favorite;
      default:
        return Icons.info;
    }
  }

  Color _getPriorityColor(String priority) {
    switch (priority.toLowerCase()) {
      case 'high':
        return Colors.red;
      case 'medium':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }
}
