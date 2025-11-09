import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import '../models/conversation.dart';
import '../theme/ios_theme.dart';
import '../widgets/ios_widgets.dart';
import '../widgets/message_effects.dart';
import '../services/voice_booking_service.dart';
import '../widgets/meeting_booking_animation.dart';
import '../widgets/key_dates_widget.dart';
import '../widgets/key_dates_modal.dart';
import '../widgets/smart_reply_widget.dart';
import '../widgets/relationship_health_widget.dart';
import '../widgets/conversation_insights_nvidia.dart';
import '../widgets/conversation_starter_widget.dart';
import '../widgets/relationship_forecast_widget.dart';

class IOSConversationDetailScreen extends StatefulWidget {
  final Conversation conversation;

  const IOSConversationDetailScreen({
    super.key,
    required this.conversation,
  });

  @override
  State<IOSConversationDetailScreen> createState() =>
      _IOSConversationDetailScreenState();
}

class _IOSConversationDetailScreenState
    extends State<IOSConversationDetailScreen>
    with TickerProviderStateMixin {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final VoiceBookingService _voiceService = VoiceBookingService();
  
  late AnimationController _sendButtonController;
  bool _isTyping = false;
  bool _isListening = false;
  String _voiceTranscript = '';
  bool _showBookingAnimation = false;
  bool _showingOptions = false;

  @override
  void initState() {
    super.initState();
    _sendButtonController = AnimationController(
      vsync: this,
      duration: IOSTheme.quickDuration,
    );

    _messageController.addListener(() {
      if (_messageController.text.isNotEmpty && !_isTyping) {
        setState(() => _isTyping = true);
        _sendButtonController.forward();
      } else if (_messageController.text.isEmpty && _isTyping) {
        setState(() => _isTyping = false);
        _sendButtonController.reverse();
      }
    });

    // Auto-scroll to bottom
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
      }
    });
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    _sendButtonController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: IOSTheme.iosSystemBackground,
      body: Stack(
        children: [
          Column(
            children: [
              _buildNavigationBar(),
              Expanded(
                child: _buildMessagesList(),
              ),
              _buildSimplifiedInputBar(),
            ],
          ),
          if (_showBookingAnimation)
            MeetingBookingAnimation(
              contactName: widget.conversation.contactName,
              meetingType: 'General Meeting',
              meetingTime: DateTime.now().add(const Duration(days: 1)),
              onComplete: () {
                setState(() => _showBookingAnimation = false);
              },
            ),
        ],
      ),
    );
  }

  Widget _buildNavigationBar() {
    final colors = IOSTheme.systemColors;
    final color = colors[widget.conversation.contactName.length % colors.length];

    return Container(
      decoration: BoxDecoration(
        color: IOSTheme.iosSystemBackground.withOpacity(0.95),
        border: Border(
          bottom: BorderSide(
            color: IOSTheme.iosGray5.withOpacity(0.3),
            width: 0.5,
          ),
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: 8,
            vertical: 8,
          ),
          child: Row(
            children: [
              // Back button
              IOSNavButton(
                icon: CupertinoIcons.back,
                color: IOSTheme.iosBlue,
                onPressed: () => Navigator.pop(context),
              ),
              const SizedBox(width: 12),
              // Avatar
              IOSTapEffect(
                onTap: () {
                  HapticFeedback.mediumImpact();
                  setState(() => _showingOptions = !_showingOptions);
                },
                child: IOSAvatar(
                  name: widget.conversation.contactName,
                  color: color,
                  size: 36,
                ),
              ),
              const SizedBox(width: 12),
              // Name
              Expanded(
                child: IOSTapEffect(
                  onTap: () {
                    HapticFeedback.mediumImpact();
                    setState(() => _showingOptions = !_showingOptions);
                  },
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        widget.conversation.contactName,
                        style: const TextStyle(
                          fontSize: 17,
                          fontWeight: IOSTheme.semibold,
                          color: IOSTheme.iosLabel,
                          letterSpacing: -0.408,
                        ),
                      ),
                      const Text(
                        'Available',
                        style: TextStyle(
                          fontSize: 13,
                          color: IOSTheme.iosSecondaryLabel,
                          letterSpacing: -0.08,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              // Action buttons
              IOSNavButton(
                icon: CupertinoIcons.calendar,
                color: Colors.purple,
                onPressed: () {
                  HapticFeedback.mediumImpact();
                  _showKeyDatesModal();
                },
              ),
              const SizedBox(width: 8),
              IOSNavButton(
                icon: CupertinoIcons.video_camera_solid,
                color: IOSTheme.iosGreen,
                onPressed: () {
                  HapticFeedback.mediumImpact();
                },
              ),
              const SizedBox(width: 8),
              IOSNavButton(
                icon: CupertinoIcons.phone_fill,
                color: IOSTheme.iosBlue,
                onPressed: () {
                  HapticFeedback.mediumImpact();
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBackgroundGradient() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            IOSTheme.iosSystemBackground,
            IOSTheme.iosGray6.withOpacity(0.3),
            IOSTheme.iosSystemBackground,
          ],
        ),
      ),
    );
  }

  Widget _buildMessagesList() {
    // Show only last 10 messages in UI, but full history exists for health score
    final displayMessages = widget.conversation.messages.length > 10
        ? widget.conversation.messages.sublist(widget.conversation.messages.length - 10)
        : widget.conversation.messages;
    
    return ListView.builder(
      controller: _scrollController,
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(
        horizontal: 12,
        vertical: 12,
      ),
      itemCount: displayMessages.length + 7, // +1 header, +1 health, +1 key dates, +1 smart reply, +3 new agents
      itemBuilder: (context, index) {
        // Show info header at top
        if (index == 0) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: IOSTheme.iosGray5.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  'Last 10 messages • ${widget.conversation.messages.length} total • 10 AI Agents Active',
                  style: TextStyle(
                    fontSize: 11,
                    color: IOSTheme.iosGray,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
          );
        }
        
        // Show Relationship Health Score
        if (index == 1) {
          return RelationshipHealthWidget(
            contactName: widget.conversation.contactName,
            messageCount: widget.conversation.messages.length,
            daysSinceLastMessage: DateTime.now().difference(widget.conversation.lastMessageTime).inDays,
            avgResponseTimeHours: 12.0,
            conversationHistory: widget.conversation.getFullChatLog(),
          );
        }
        
        // Show Key Dates Widget (Purple Icon)
        if (index == 2) {
          return KeyDatesWidget(
            contactName: widget.conversation.contactName,
            recentMessages: widget.conversation.messages
                .map((msg) => {
                      'text': msg.text,
                      'timestamp': msg.timestamp.toIso8601String(),
                      'isUser': msg.isUser,
                    })
                .toList(),
          );
        }

        // Show Smart Reply Suggestions
        if (index == 3) {
          return SmartReplyWidget(
            contactName: widget.conversation.contactName,
            lastMessage: widget.conversation.messages.last.text,
            conversationHistory: widget.conversation.getFullChatLog(),
            platform: widget.conversation.platform,
            onReplySelected: (reply) {
              setState(() {
                _messageController.text = reply;
              });
            },
          );
        }

        // NEW: Conversation Insights Widget (Agent 8)
        if (index == 4) {
          return ConversationInsightsWidget(
            contactName: widget.conversation.contactName,
            recentMessages: widget.conversation.messages
                .map((msg) => {
                      'text': msg.text,
                      'timestamp': msg.timestamp.toIso8601String(),
                      'isUser': msg.isUser,
                    })
                .toList(),
          );
        }

        // NEW: Conversation Starter Widget (Agent 9)
        if (index == 5) {
          return ConversationStarterWidget(
            contactName: widget.conversation.contactName,
            daysSinceLastMessage: DateTime.now().difference(widget.conversation.lastMessageTime).inDays,
            recentMessages: widget.conversation.messages
                .map((msg) => {
                      'text': msg.text,
                      'isUser': msg.isUser,
                    })
                .toList(),
            onStarterSelected: (message) {
              setState(() {
                _messageController.text = message;
              });
            },
          );
        }

        // NEW: Relationship Forecast Widget (Agent 10)
        if (index == 6) {
          return RelationshipForecastWidget(
            contactName: widget.conversation.contactName,
            healthHistory: [
              {
                'date': DateTime.now().subtract(const Duration(days: 7)).toIso8601String(),
                'score': 78,
              },
              {
                'date': DateTime.now().toIso8601String(),
                'score': widget.conversation.messages.length > 20 ? 75 : 68,
              },
            ],
            recentMessages: widget.conversation.messages
                .map((msg) => {
                      'text': msg.text,
                      'isUser': msg.isUser,
                    })
                .toList(),
          );
        }

        // Show actual messages
        final messageIndex = index - 7; // Adjusted for header + health + key dates + smart reply + 3 new agents
        return SlideInMessage(
          index: messageIndex,
          fromRight: displayMessages[messageIndex].isUser,
          child: _buildMessageBubble(
            displayMessages[messageIndex],
            messageIndex,
          ),
        );
      },
    );
  }

  Widget _buildMessageBubble(ChatMessage message, int index) {
    final isMe = message.isUser;
    final showAvatar = !isMe && (index == 0 ||
        widget.conversation.messages[index - 1].isUser);

    return Padding(
      padding: EdgeInsets.only(
        bottom: 4,
        top: showAvatar ? 8 : 0,
      ),
      child: Row(
        mainAxisAlignment:
            isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          // Avatar for received messages
          if (!isMe)
            Padding(
              padding: const EdgeInsets.only(right: 8, bottom: 2),
              child: showAvatar
                  ? IOSAvatar(
                      name: widget.conversation.contactName,
                      color: IOSTheme.systemColors[
                          widget.conversation.contactName.length %
                              IOSTheme.systemColors.length],
                      size: 28,
                    )
                  : const SizedBox(width: 28),
            ),
          // Message bubble
          Flexible(
            child: MessageBubbleEffect(
              isMe: isMe,
              onLongPress: () {
                HapticFeedback.selectionClick();
                _showMessageOptions(message);
              },
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  gradient: isMe
                      ? const LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            Color(0xFF007AFF),
                            Color(0xFF0051D5),
                          ],
                        )
                      : null,
                  color: isMe ? null : IOSTheme.iosGray5,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: (isMe ? IOSTheme.iosBlue : Colors.black)
                          .withOpacity(0.1),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Text(
                  message.text,
                  style: TextStyle(
                    fontSize: 16,
                    color: isMe ? Colors.white : IOSTheme.iosLabel,
                    letterSpacing: -0.32,
                    height: 1.3,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInputBar() {
    return AnimatedContainer(
      duration: IOSTheme.standardDuration,
      curve: IOSTheme.iosCurve,
      decoration: BoxDecoration(
        color: IOSTheme.iosSystemBackground.withOpacity(0.95),
        border: Border(
          top: BorderSide(
            color: IOSTheme.iosGray5.withOpacity(0.3),
            width: 0.5,
          ),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 8,
                vertical: 8,
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  // Voice booking button (ElevenLabs)
                  IOSTapEffect(
                    onTap: () {
                      HapticFeedback.mediumImpact();
                      _showVoiceBookingModal();
                    },
                    child: Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            Color(0xFF8B5CF6),
                            Color(0xFF6366F1),
                          ],
                        ),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.purple.withOpacity(0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: const Icon(
                        CupertinoIcons.mic_fill,
                        color: Colors.white,
                        size: 18,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Message input
                  Expanded(
                    child: Container(
                      constraints: const BoxConstraints(maxHeight: 100),
                      decoration: BoxDecoration(
                        color: IOSTheme.iosGray6,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _messageController,
                              maxLines: null,
                              textCapitalization: TextCapitalization.sentences,
                              style: const TextStyle(
                                fontSize: 16,
                                color: IOSTheme.iosLabel,
                                letterSpacing: -0.32,
                              ),
                              decoration: const InputDecoration(
                                hintText: 'iMessage',
                                hintStyle: TextStyle(
                                  color: IOSTheme.iosTertiaryLabel,
                                  letterSpacing: -0.32,
                                ),
                                border: InputBorder.none,
                                contentPadding: EdgeInsets.symmetric(
                                  horizontal: 14,
                                  vertical: 8,
                                ),
                              ),
                            ),
                          ),
                          // Emoji button
                          Padding(
                            padding: const EdgeInsets.only(right: 4, bottom: 4),
                            child: IOSTapEffect(
                              onTap: () {
                                HapticFeedback.selectionClick();
                              },
                              child: Container(
                                width: 28,
                                height: 28,
                                decoration: const BoxDecoration(
                                  shape: BoxShape.circle,
                                ),
                                child: const Center(
                                  child: Text(
                                    '😊',
                                    style: TextStyle(fontSize: 20),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Send button
                  AnimatedBuilder(
                    animation: _sendButtonController,
                    builder: (context, child) {
                      return Transform.scale(
                        scale: 0.8 + (_sendButtonController.value * 0.2),
                        child: IOSTapEffect(
                          onTap: _isTyping
                              ? () {
                                  _sendMessage();
                                }
                              : () {},
                          child: Container(
                            width: 32,
                            height: 32,
                            decoration: BoxDecoration(
                              gradient: _isTyping
                                  ? const LinearGradient(
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                      colors: [
                                        Color(0xFF007AFF),
                                        Color(0xFF0051D5),
                                      ],
                                    )
                                  : null,
                              color: _isTyping
                                  ? null
                                  : IOSTheme.iosGray5.withOpacity(0.5),
                              shape: BoxShape.circle,
                              boxShadow: _isTyping
                                  ? [
                                      BoxShadow(
                                        color: IOSTheme.iosBlue.withOpacity(0.3),
                                        blurRadius: 8,
                                        offset: const Offset(0, 2),
                                      ),
                                    ]
                                  : null,
                            ),
                            child: Icon(
                              CupertinoIcons.arrow_up,
                              color: _isTyping
                                  ? Colors.white
                                  : IOSTheme.iosGray3,
                              size: 18,
                            ),
                          ),
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

  Widget _buildSimplifiedInputBar() {
    return AnimatedContainer(
      duration: IOSTheme.standardDuration,
      curve: IOSTheme.iosCurve,
      decoration: BoxDecoration(
        color: IOSTheme.iosSystemBackground.withOpacity(0.95),
        border: Border(
          top: BorderSide(
            color: IOSTheme.iosGray5.withOpacity(0.3),
            width: 0.5,
          ),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Center(
            child: IOSTapEffect(
              onTap: () {
                HapticFeedback.mediumImpact();
                _showVoiceBookingModal();
              },
              child: Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Color(0xFF8B5CF6),
                      Color(0xFF6366F1),
                    ],
                  ),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.purple.withOpacity(0.4),
                      blurRadius: 20,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: const Icon(
                  CupertinoIcons.mic_fill,
                  color: Colors.white,
                  size: 32,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _showVoiceBookingModal() {
    showCupertinoModalPopup(
      context: context,
      builder: (context) => Container(
        height: 300,
        decoration: const BoxDecoration(
          color: IOSTheme.iosSystemBackground,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            const SizedBox(height: 16),
            Container(
              width: 36,
              height: 5,
              decoration: BoxDecoration(
                color: IOSTheme.iosGray4,
                borderRadius: BorderRadius.circular(3),
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              '🎙️ Voice Booking',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w600,
                color: IOSTheme.iosLabel,
                letterSpacing: -0.44,
              ),
            ),
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Text(
                'Say something like "Schedule lunch with ${widget.conversation.contactName} tomorrow at noon"',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 15,
                  color: IOSTheme.iosSecondaryLabel,
                  letterSpacing: -0.24,
                ),
              ),
            ),
            const Spacer(),
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color(0xFF8B5CF6),
                    Color(0xFF6366F1),
                  ],
                ),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.purple.withOpacity(0.3),
                    blurRadius: 20,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: const Icon(
                CupertinoIcons.mic_fill,
                color: Colors.white,
                size: 36,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Tap to start',
              style: TextStyle(
                fontSize: 13,
                color: IOSTheme.iosTertiaryLabel,
                letterSpacing: -0.08,
              ),
            ),
            const Spacer(),
            Padding(
              padding: const EdgeInsets.all(16),
              child: IOSTapEffect(
                onTap: () => Navigator.pop(context),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  decoration: BoxDecoration(
                    color: IOSTheme.iosGray6,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Text(
                    'Cancel',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w600,
                      color: IOSTheme.iosBlue,
                      letterSpacing: -0.41,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _sendMessage() {
    if (_messageController.text.trim().isEmpty) return;

    HapticFeedback.lightImpact();
    
    // TODO: Send message logic
    _messageController.clear();
    
    // Scroll to bottom
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: IOSTheme.standardDuration,
          curve: IOSTheme.iosCurve,
        );
      }
    });
  }

  void _showKeyDatesModal() {
    // Prepare recent messages for the modal
    final recentMessages = widget.conversation.messages
        .skip(widget.conversation.messages.length > 20
            ? widget.conversation.messages.length - 20
            : 0)
        .map((msg) => {
              'text': msg.text,
              'timestamp': msg.timestamp.toIso8601String(),
              'isUser': msg.isUser,
            })
        .toList();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => SizedBox(
        height: MediaQuery.of(context).size.height * 0.9,
        child: KeyDatesModal(
          contactName: widget.conversation.contactName,
          recentMessages: recentMessages,
        ),
      ),
    );
  }

  void _showMessageOptions(ChatMessage message) {
    showCupertinoModalPopup(
      context: context,
      builder: (context) => CupertinoActionSheet(
        actions: [
          CupertinoActionSheetAction(
            onPressed: () {
              Navigator.pop(context);
              HapticFeedback.selectionClick();
            },
            child: const Text('Copy'),
          ),
          CupertinoActionSheetAction(
            onPressed: () {
              Navigator.pop(context);
              HapticFeedback.selectionClick();
            },
            child: const Text('Forward'),
          ),
          CupertinoActionSheetAction(
            onPressed: () {
              Navigator.pop(context);
              HapticFeedback.selectionClick();
            },
            child: const Text('React'),
          ),
        ],
        cancelButton: CupertinoActionSheetAction(
          onPressed: () => Navigator.pop(context),
          isDefaultAction: true,
          child: const Text('Cancel'),
        ),
      ),
    );
  }
}
