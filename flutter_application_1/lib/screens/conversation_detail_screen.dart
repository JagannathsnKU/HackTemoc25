import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import '../models/conversation.dart';
import '../models/reachly_summary.dart';
import '../services/api_service.dart';
import '../services/audio_service.dart';
import '../services/voice_booking_service.dart';
import '../services/google_calendar_service.dart';
import '../widgets/meeting_booking_animation.dart';
import '../widgets/conversation_insights.dart';
import '../widgets/free_time_slots_widget.dart';
import '../widgets/smart_reply_widget.dart';
import '../widgets/relationship_health_widget.dart';
import '../widgets/smart_notification_widget.dart';

class ConversationDetailScreen extends StatefulWidget {
  final Conversation conversation;

  const ConversationDetailScreen({
    super.key,
    required this.conversation,
  });

  @override
  State<ConversationDetailScreen> createState() => _ConversationDetailScreenState();
}

class _ConversationDetailScreenState extends State<ConversationDetailScreen> {
  final ApiService _apiService = ApiService();
  final AudioService _audioService = AudioService();
  final VoiceBookingService _voiceService = VoiceBookingService();
  bool _isAnalyzing = false;
  bool _isListening = false;
  String _voiceTranscript = '';
  ReachlySummary? _autoSummary;
  List<Map<String, dynamic>> _suggestedActions = [];
  
  @override
  void initState() {
    super.initState();
    // AUTO-ANALYZE: Automatically analyze when conversation opens
    _autoAnalyzeConversation();
  }
  
  /// AUTOMATIC: Analyzes conversation in background when opened
  Future<void> _autoAnalyzeConversation() async {
    try {
      final chatLog = widget.conversation.getFullChatLog();
      final response = await http.post(
        Uri.parse('http://localhost:5000/auto_analyze_conversation'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'chat_log': chatLog,
          'contact_name': widget.conversation.contactName,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          _autoSummary = ReachlySummary(
            summary: data['summary_text'] ?? '',
            topics: List<String>.from(data['topics'] ?? []),
            suggestedReply: data['suggested_reply'] ?? '',
            audioUrl: null,
          );
        });
        
        // If booking action detected, show it!
        if (data['action_needed'] == 'booking') {
          _detectActions();
        }
      }
    } catch (e) {
      print('Auto-analyze error: $e');
    }
  }
  
  /// AUTO-DETECT: What actions can user take
  Future<void> _detectActions() async {
    try {
      final chatLog = widget.conversation.getFullChatLog();
      final response = await http.post(
        Uri.parse('http://localhost:5000/detect_actions'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'chat_log': chatLog,
          'contact_name': widget.conversation.contactName,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          _suggestedActions = List<Map<String, dynamic>>.from(data['actions'] ?? []);
        });
      }
    } catch (e) {
      print('Detect actions error: $e');
    }
  }
  
  /// SMART BOOKING: Auto-book with voice confirmation
  Future<void> _autoBookMeeting() async {
    setState(() {
      _isAnalyzing = true;
    });
    
    try {
      final chatLog = widget.conversation.getFullChatLog();
      final response = await http.post(
        Uri.parse('http://localhost:5000/auto_book_meeting'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'contact_name': widget.conversation.contactName,
          'meeting_type': 'lunch',
          'chat_context': chatLog,
        }),
      );

      setState(() {
        _isAnalyzing = false;
      });

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        _showBookingConfirmation(data);
      }
    } catch (e) {
      setState(() {
        _isAnalyzing = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Booking error: $e')),
        );
      }
    }
  }
  
  /// VOICE BOOKING: Start/stop voice recognition
  Future<void> _toggleVoiceBooking() async {
    if (_isListening) {
      await _voiceService.stopListening();
      setState(() {
        _isListening = false;
      });
      return;
    }
    
    // Initialize and start listening
    try {
      final initialized = await _voiceService.initialize();
      if (!initialized) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('❌ Microphone permission denied. Please allow microphone access in your browser settings.'),
              backgroundColor: Colors.red,
              duration: Duration(seconds: 5),
            ),
          );
        }
        return;
      }
      
      setState(() {
        _isListening = true;
        _voiceTranscript = 'Initializing...';
      });
      
      await _voiceService.startListening((transcription) {
        setState(() {
          _voiceTranscript = transcription;
        });
        
        // Check for errors
        if (transcription.startsWith('Error:')) {
          setState(() {
            _isListening = false;
          });
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(transcription),
                backgroundColor: Colors.red,
                duration: const Duration(seconds: 5),
              ),
            );
          }
          return;
        }
        
        // Process command when finalized
        if (transcription.isNotEmpty && !transcription.contains('Initializing')) {
          _processVoiceCommand(transcription);
        }
      });
      
      // Show success feedback
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('🎤 Listening... Speak now!'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
      }
      
    } catch (e) {
      setState(() {
        _isListening = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Voice recognition error: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    }
  }
  
  /// Process voice command through AI
  Future<void> _processVoiceCommand(String command) async {
    if (command.isEmpty) return;
    
    setState(() {
      _isAnalyzing = true;
    });
    
    try {
      final chatLog = widget.conversation.getFullChatLog();
      final result = await _voiceService.processVoiceBooking(
        voiceCommand: command,
        contactName: widget.conversation.contactName,
        chatLog: chatLog,
      );
      
      setState(() {
        _isAnalyzing = false;
        _isListening = false;
      });
      
      if (result['success'] == true) {
        // Play voice response
        final voiceUrl = result['voice_message_url'];
        if (voiceUrl != null && voiceUrl.isNotEmpty) {
          await _audioService.playAudioFromUrl(voiceUrl);
        }
        
        // Show booking details
        _showVoiceBookingConfirmation(result);
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(result['error'] ?? 'Voice booking failed')),
          );
        }
      }
    } catch (e) {
      setState(() {
        _isAnalyzing = false;
        _isListening = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Voice error: $e')),
        );
      }
    }
  }
  
  /// Show voice booking confirmation with beautiful animation
  void _showVoiceBookingConfirmation(Map<String, dynamic> result) {
    final meetingData = result['meeting_data'];
    
    // Extract meeting details
    final String meetingType = meetingData?['meeting_type'] ?? 'Meeting';
    final String suggestedTime = meetingData?['suggested_time'] ?? 'Tomorrow at 2pm';
    
    // Parse suggested time into DateTime (simple parser for demo)
    DateTime meetingTime = _parseMeetingTime(suggestedTime);
    
    // Show animated booking widget
    showMeetingBookingAnimation(
      context: context,
      contactName: widget.conversation.contactName,
      meetingType: meetingType,
      meetingTime: meetingTime,
      onAddToCalendar: () async {
        // Add to Google Calendar
        await _addToGoogleCalendar(
          contactName: widget.conversation.contactName,
          meetingType: meetingType,
          meetingTime: meetingTime,
        );
      },
    );
  }
  
  /// Parse meeting time from string (simple implementation)
  DateTime _parseMeetingTime(String timeString) {
    final now = DateTime.now();
    
    // Check for "tomorrow"
    if (timeString.toLowerCase().contains('tomorrow')) {
      // Extract hour if mentioned (e.g., "tomorrow at 2pm")
      int hour = 14; // Default to 2pm
      if (timeString.contains('2') && timeString.toLowerCase().contains('pm')) {
        hour = 14;
      } else if (timeString.contains('10') && timeString.toLowerCase().contains('am')) {
        hour = 10;
      } else if (timeString.contains('3') && timeString.toLowerCase().contains('pm')) {
        hour = 15;
      }
      
      return DateTime(now.year, now.month, now.day + 1, hour, 0);
    }
    
    // Default: tomorrow at 2pm
    return DateTime(now.year, now.month, now.day + 1, 14, 0);
  }
  
  /// Add meeting to Google Calendar
  Future<void> _addToGoogleCalendar({
    required String contactName,
    required String meetingType,
    required DateTime meetingTime,
  }) async {
    try {
      print('📅 Adding meeting to Google Calendar...');
      
      final success = await googleCalendarService.addQuickMeeting(
        contactName: contactName,
        meetingType: meetingType,
        meetingTime: meetingTime,
      );
      
      if (success) {
        print('✅ Meeting added successfully!');
      } else {
        throw Exception('Failed to add meeting');
      }
    } catch (e) {
      print('❌ Calendar error: $e');
      rethrow; // Let the animation widget handle the error
    }
  }
  
  /// OLD METHOD - Book to Google Calendar (kept for backwards compatibility)
  Future<void> _bookToCalendar(Map<String, dynamic>? meetingData) async {
    if (meetingData == null) return;
    
    try {
      final result = await _voiceService.bookToGoogleCalendar(
        contactName: widget.conversation.contactName,
        contactEmail: '${widget.conversation.contactName.toLowerCase()}@example.com',
        startTime: DateTime.now().add(const Duration(days: 1)),
        endTime: DateTime.now().add(const Duration(days: 1, hours: 1)),
        description: meetingData['meeting_type'] ?? 'Meeting',
      );
      
      if (result['success'] == true && mounted) {
        // Play calendar confirmation voice
        final voiceUrl = result['voice_confirmation_url'];
        if (voiceUrl != null) {
          await _audioService.playAudioFromUrl(voiceUrl);
        }
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✅ Meeting booked! Event ID: ${result['event_id']}'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Calendar error: $e')),
        );
      }
    }
  }
  
  void _showBookingConfirmation(Map<String, dynamic> bookingData) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.calendar_today, size: 48, color: Colors.green),
            const SizedBox(height: 16),
            Text(
              'Meeting Booked!',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.green.shade900,
              ),
            ),
            const SizedBox(height: 16),
            _buildBookingDetail('Time', bookingData['suggested_time'] ?? ''),
            _buildBookingDetail('Type', bookingData['meeting_type'] ?? ''),
            _buildBookingDetail('Location', bookingData['location'] ?? ''),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.mic, color: Colors.blue),
                      const SizedBox(width: 8),
                      const Text(
                        'Voice Message (ElevenLabs)',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    bookingData['voice_script'] ?? 'Voice message generated',
                    style: TextStyle(fontSize: 13, color: Colors.grey.shade700),
                  ),
                  const SizedBox(height: 12),
                  ElevatedButton.icon(
                    onPressed: () {
                      // Play voice message
                      _audioService.playAudioFromUrl(bookingData['voice_message_url'] ?? '');
                    },
                    icon: const Icon(Icons.play_arrow),
                    label: const Text('Play Voice Message'),
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                // Send booking message
                Clipboard.setData(ClipboardData(text: bookingData['message_to_send'] ?? ''));
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Message copied! Send it in the chat.')),
                );
                Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: const Text('Send Booking Message', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildBookingDetail(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          SizedBox(
            width: 80,
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }

  void _showReachlyAnalysis() async {
    setState(() {
      _isAnalyzing = true;
    });

    try {
      // Get the full chat log
      final chatLog = widget.conversation.getFullChatLog();

      // Call NVIDIA API directly
      final summary = await _apiService.summarizeChat(chatLog);
      
      setState(() {
        _isAnalyzing = false;
      });
      
      _showSummaryBottomSheet(summary);
    } catch (e) {
      setState(() {
        _isAnalyzing = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error connecting to NVIDIA AI: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showSummaryBottomSheet(ReachlySummary summary) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.deepPurple.shade100,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.psychology_rounded,
                    color: Colors.deepPurple.shade700,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text(
                    'Reachly Analysis',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Summary
            _buildSection(
              'Summary',
              summary.summary,
              Icons.summarize,
            ),
            const SizedBox(height: 16),

            // Topics
            _buildTopicsSection(summary.topics),
            const SizedBox(height: 16),

            // Suggested Reply
            _buildSuggestedReply(summary.suggestedReply),
            const SizedBox(height: 16),

            // Audio Player (if available)
            if (summary.audioUrl != null)
              _buildAudioPlayer(summary.audioUrl!),

            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(String title, String content, IconData icon) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 20, color: Colors.deepPurple.shade700),
            const SizedBox(width: 8),
            Text(
              title,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.deepPurple.shade900,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.grey.shade100,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            content,
            style: const TextStyle(fontSize: 14, height: 1.4),
          ),
        ),
      ],
    );
  }

  Widget _buildTopicsSection(List<String> topics) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.label, size: 20, color: Colors.deepPurple.shade700),
            const SizedBox(width: 8),
            Text(
              'Key Topics',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.deepPurple.shade900,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: topics.map((topic) {
            return Chip(
              label: Text(topic),
              backgroundColor: Colors.deepPurple.shade50,
              labelStyle: TextStyle(
                color: Colors.deepPurple.shade700,
                fontSize: 12,
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildSuggestedReply(String reply) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.auto_awesome, size: 20, color: Colors.deepPurple.shade700),
            const SizedBox(width: 8),
            Text(
              'Suggested Reply',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.deepPurple.shade900,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.deepPurple.shade50,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.deepPurple.shade200),
          ),
          child: Column(
            children: [
              Text(
                reply,
                style: const TextStyle(fontSize: 14, height: 1.4),
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  OutlinedButton.icon(
                    onPressed: () {
                      Clipboard.setData(ClipboardData(text: reply));
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Copied to clipboard!'),
                          duration: Duration(seconds: 2),
                        ),
                      );
                    },
                    icon: const Icon(Icons.copy, size: 16),
                    label: const Text('Copy'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.deepPurple.shade700,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildAudioPlayer(String audioUrl) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.record_voice_over, size: 20, color: Colors.deepPurple.shade700),
            const SizedBox(width: 8),
            Text(
              'Voice Summary',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.deepPurple.shade900,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ElevatedButton.icon(
          onPressed: () {
            _audioService.playAudio(audioUrl);
          },
          icon: const Icon(Icons.play_arrow),
          label: const Text('Play Summary'),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.deepPurple,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        elevation: 1,
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
        title: Row(
          children: [
            Text(
              widget.conversation.avatarUrl,
              style: const TextStyle(fontSize: 20),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.conversation.contactName,
                  style: const TextStyle(fontSize: 18),
                ),
                Text(
                  widget.conversation.platform,
                  style: const TextStyle(fontSize: 12),
                ),
              ],
            ),
          ],
        ),
        actions: [
          // 🧠 AI Agent Brain Icon
          IconButton(
            icon: const Icon(Icons.psychology),
            tooltip: 'AI Agent Brain',
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('🧠 AI Agent analyzing your conversation...'),
                  duration: Duration(seconds: 2),
                ),
              );
              _autoAnalyzeConversation();
            },
          ),
          // 🎤 Voice Booking Microphone
          IconButton(
            icon: Icon(_isListening ? Icons.mic : Icons.mic_none),
            tooltip: _isListening ? 'Stop listening' : 'Voice booking',
            onPressed: _toggleVoiceBooking,
            color: _isListening ? Colors.red : Colors.white,
          ),
        ],
      ),
      body: Stack(
        children: [
          // Main content with insights and messages
          Column(
            children: [
              // MCP AI Insights
              ConversationInsights(
                contactName: widget.conversation.contactName,
                messages: widget.conversation.messages,
              ),
              
              // Smart Notification Manager (NEW! - Nvidia Nemotron)
              SmartNotificationWidget(
                contactName: widget.conversation.contactName,
                messageCount: widget.conversation.messages.length,
                daysSinceLastMessage: DateTime.now().difference(widget.conversation.lastMessageTime).inDays,
                avgMessagesPerWeek: widget.conversation.messages.length / 4.0, // Rough estimate
                lastMessageFrom: widget.conversation.messages.isNotEmpty 
                    ? (widget.conversation.messages.last.isUser ? 'me' : 'them')
                    : 'them',
                conversationHistory: widget.conversation.getFullChatLog(),
              ),
              
              // Calendar Free Time Slots
              FreeTimeSlotsWidget(
                contactName: widget.conversation.contactName,
                meetingDuration: 30,
              ),
              
              // Relationship Health Score (NEW!)
              RelationshipHealthWidget(
                contactName: widget.conversation.contactName,
                messageCount: widget.conversation.messages.length,
                daysSinceLastMessage: DateTime.now().difference(widget.conversation.lastMessageTime).inDays,
                avgResponseTimeHours: 12.0, // You can calculate this from message timestamps
                conversationHistory: widget.conversation.getFullChatLog(),
              ),
              
              // Smart Reply Suggestions (NEW!)
              if (widget.conversation.messages.isNotEmpty)
                SmartReplyWidget(
                  contactName: widget.conversation.contactName,
                  lastMessage: widget.conversation.messages.last.text,
                  conversationHistory: widget.conversation.getFullChatLog(),
                  platform: widget.conversation.platform, // Pass the platform (Instagram, WhatsApp, etc.)
                  onReplySelected: (reply) {
                    // Send the selected reply
                    setState(() {
                      // Add reply to conversation
                      widget.conversation.messages.add(
                        ChatMessage(
                          id: 'msg_${DateTime.now().millisecondsSinceEpoch}',
                          text: reply,
                          timestamp: DateTime.now(),
                          isUser: true,
                        ),
                      );
                    });
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Reply added to UI: $reply')),
                    );
                  },
                ),
              
              // Messages
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.all(16).copyWith(bottom: 80),
                  itemCount: widget.conversation.messages.length,
                  itemBuilder: (context, index) {
                    final message = widget.conversation.messages[index];
                    return _buildMessageBubble(message);
                  },
                ),
              ),
            ],
          ),

          // 🎤 Voice Recording Indicator
          if (_isListening)
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  border: Border(
                    bottom: BorderSide(color: Colors.red.shade200, width: 2),
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.mic, color: Colors.red),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            '🎤 Listening...',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.red,
                            ),
                          ),
                          if (_voiceTranscript.isNotEmpty)
                            Text(
                              _voiceTranscript,
                              style: const TextStyle(fontSize: 12),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.stop, color: Colors.red),
                      onPressed: _toggleVoiceBooking,
                    ),
                  ],
                ),
              ),
            ),

          // Floating Reachly Button
          Positioned(
            right: 20,
            bottom: 20,
            child: _isAnalyzing
                ? FloatingActionButton.extended(
                    onPressed: null,
                    backgroundColor: Colors.deepPurple.shade300,
                    icon: const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    ),
                    label: const Text('Analyzing...'),
                  )
                : FloatingActionButton.extended(
                    onPressed: _showReachlyAnalysis,
                    backgroundColor: Colors.deepPurple,
                    icon: const Icon(Icons.psychology_rounded),
                    label: const Text('Reachly'),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(ChatMessage message) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment:
            message.isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        children: [
          if (!message.isUser)
            Text(
              widget.conversation.avatarUrl,
              style: const TextStyle(fontSize: 24),
            ),
          if (!message.isUser) const SizedBox(width: 8),
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: message.isUser
                    ? Colors.blue.shade500
                    : Colors.grey.shade200,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                message.text,
                style: TextStyle(
                  color: message.isUser ? Colors.white : Colors.black87,
                  fontSize: 15,
                ),
              ),
            ),
          ),
          if (message.isUser) const SizedBox(width: 8),
          if (message.isUser)
            const Text(
              '👤',
              style: TextStyle(fontSize: 24),
            ),
        ],
      ),
    );
  }
}
