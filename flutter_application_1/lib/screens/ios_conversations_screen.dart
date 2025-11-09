import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../blocs/auth_bloc.dart';
import '../models/conversation.dart';
import '../services/mock_data_service.dart';
import '../services/widget_service.dart';
import '../theme/ios_theme.dart';
import '../widgets/ios_widgets.dart';
import 'ios_conversation_detail_screen.dart';
import 'agents_dashboard_screen.dart';

class IOSConversationsScreen extends StatefulWidget {
  const IOSConversationsScreen({super.key});

  @override
  State<IOSConversationsScreen> createState() => _IOSConversationsScreenState();
}

class _IOSConversationsScreenState extends State<IOSConversationsScreen> {
  final ScrollController _scrollController = ScrollController();
  bool _isScrolled = false;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(() {
      if (_scrollController.offset > 10 && !_isScrolled) {
        setState(() => _isScrolled = true);
      } else if (_scrollController.offset <= 10 && _isScrolled) {
        setState(() => _isScrolled = false);
      }
    });
    
    // Update iOS home screen widget when screen loads
    WidgetService.updateWidget();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final conversations = MockDataService.getMockConversations();
    
    // Sort by last message time (oldest first - longest without texting)
    conversations.sort((a, b) => a.lastMessageTime.compareTo(b.lastMessageTime));

    return Scaffold(
      backgroundColor: IOSTheme.iosSecondarySystemBackground,
      body: CustomScrollView(
        controller: _scrollController,
        physics: const BouncingScrollPhysics(),
        slivers: [
          // iOS Navigation Bar
          _buildIOSNavigationBar(),

          // Content
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(
                IOSTheme.spacing16,
                IOSTheme.spacing8,
                IOSTheme.spacing16,
                100,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Info Card
                  IOSFadeIn(
                    delay: const Duration(milliseconds: 100),
                    child: _buildInfoCard(),
                  ),

                  const SizedBox(height: IOSTheme.spacing24),

                  // Conversations List
                  ...List.generate(conversations.length, (index) {
                    return IOSFadeIn(
                      delay: Duration(milliseconds: 200 + (index * 50)),
                      child: Padding(
                        padding: const EdgeInsets.only(
                          bottom: IOSTheme.spacing12,
                        ),
                        child: _buildConversationCard(
                          conversations[index],
                          index,
                        ),
                      ),
                    );
                  }),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIOSNavigationBar() {
    return SliverAppBar(
      pinned: true,
      floating: false,
      elevation: 0,
      scrolledUnderElevation: 0,
      expandedHeight: 100,
      backgroundColor: _isScrolled
          ? IOSTheme.iosSecondarySystemBackground.withOpacity(0.9)
          : IOSTheme.iosSecondarySystemBackground,
      flexibleSpace: FlexibleSpaceBar(
        titlePadding: const EdgeInsets.only(left: 20, bottom: 16),
        title: AnimatedOpacity(
          duration: IOSTheme.quickDuration,
          opacity: _isScrolled ? 0 : 1,
          child: const Text(
            'Messages',
            style: TextStyle(
              fontSize: 34,
              fontWeight: IOSTheme.bold,
              color: IOSTheme.iosLabel,
              letterSpacing: 0.374,
            ),
          ),
        ),
      ),
      actions: [
        Padding(
          padding: const EdgeInsets.only(right: 12),
          child: Row(
            children: [
              IOSNavButton(
                icon: CupertinoIcons.sparkles,
                color: IOSTheme.iosIndigo,
                onPressed: () {
                  Navigator.push(
                    context,
                    CupertinoPageRoute(
                      builder: (context) => const AgentsDashboardScreen(),
                    ),
                  );
                },
              ),
              const SizedBox(width: 8),
              IOSNavButton(
                icon: CupertinoIcons.square_arrow_right,
                color: IOSTheme.iosRed,
                onPressed: () {
                  context.read<AuthBloc>().add(Logout());
                },
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildInfoCard() {
    return IOSCard(
      isFrosted: true,
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: IOSTheme.iosBlue.withOpacity(0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              CupertinoIcons.sparkles,
              color: IOSTheme.iosBlue,
              size: 24,
            ),
          ),
          const SizedBox(width: IOSTheme.spacing12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'AI-Powered Insights',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: IOSTheme.semibold,
                    color: IOSTheme.iosLabel,
                    letterSpacing: -0.32,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  'Tap any conversation for analysis',
                  style: TextStyle(
                    fontSize: 14,
                    color: IOSTheme.iosSecondaryLabel,
                    letterSpacing: -0.24,
                  ),
                ),
              ],
            ),
          ),
          const IOSBadge(
            text: 'New',
            color: IOSTheme.iosGreen,
          ),
        ],
      ),
    );
  }

  Widget _buildConversationCard(Conversation conversation, int index) {
    final colors = IOSTheme.systemColors;
    final color = colors[index % colors.length];
    
    // Calculate notification status (simple heuristic)
    final daysSinceMessage = DateTime.now().difference(conversation.lastMessageTime).inDays;
    final shouldNotify = daysSinceMessage >= 7 || (daysSinceMessage >= 3 && conversation.messages.length > 50);

    return IOSCard(
      onTap: () {
        Navigator.push(
          context,
          CupertinoPageRoute(
            builder: (context) => IOSConversationDetailScreen(
              conversation: conversation,
            ),
          ),
        );
      },
      child: Row(
        children: [
          // Avatar with notification badge
          Stack(
            clipBehavior: Clip.none,
            children: [
              IOSAvatar(
                name: conversation.contactName,
                color: color,
                size: 52,
              ),
              // Notification badge indicator
              if (shouldNotify)
                Positioned(
                  right: -2,
                  top: -2,
                  child: Container(
                    width: 16,
                    height: 16,
                    decoration: BoxDecoration(
                      color: IOSTheme.iosRed,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: IOSTheme.iosSecondarySystemBackground,
                        width: 2,
                      ),
                    ),
                    child: const Icon(
                      CupertinoIcons.bell_fill,
                      size: 8,
                      color: Colors.white,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(width: IOSTheme.spacing12),

          // Content
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    // Platform icon
                    Container(
                      width: 20,
                      height: 20,
                      decoration: BoxDecoration(
                        color: ChatPlatform.getPlatformColor(conversation.platform).withOpacity(0.2),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Icon(
                        ChatPlatform.getPlatformIcon(conversation.platform),
                        size: 12,
                        color: ChatPlatform.getPlatformColor(conversation.platform),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        conversation.contactName,
                        style: const TextStyle(
                          fontSize: 17,
                          fontWeight: IOSTheme.semibold,
                          color: IOSTheme.iosLabel,
                          letterSpacing: -0.408,
                        ),
                      ),
                    ),
                    // Last texted time (right side)
                    Text(
                      conversation.getTimeSinceLastMessage(),
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: shouldNotify ? IOSTheme.iosRed : IOSTheme.iosSecondaryLabel,
                        letterSpacing: -0.24,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Expanded(
                      child: Row(
                        children: [
                          // Notification text if applicable
                          if (shouldNotify) ...[
                            Icon(
                              CupertinoIcons.bell_fill,
                              size: 12,
                              color: IOSTheme.iosRed,
                            ),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                'Time to reach out!',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                  color: IOSTheme.iosRed,
                                  letterSpacing: -0.24,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ] else
                            Expanded(
                              child: Text(
                                '${conversation.messages.length} messages • ${conversation.platform}',
                                style: const TextStyle(
                                  fontSize: 15,
                                  color: IOSTheme.iosSecondaryLabel,
                                  letterSpacing: -0.24,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                        ],
                      ),
                    ),
                    Icon(
                      CupertinoIcons.chevron_right,
                      size: 16,
                      color: IOSTheme.iosGray3,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
