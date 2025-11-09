import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:share_plus/share_plus.dart';
import 'dart:async';
import '../blocs/chat_bloc_api.dart';
import '../blocs/auth_bloc.dart';
import '../services/audio_service.dart';
import '../services/api_service.dart';
import '../widgets/message_bubble.dart';
import '../widgets/suggestion_card.dart';
import '../models/suggestion.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final AudioService _audioService = AudioService();
  final ApiService _apiService = ApiService();
  Suggestion? _currentSuggestion;
  Timer? _suggestionTimer;

  @override
  void initState() {
    super.initState();
    _startSuggestionChecking();
  }

  @override
  void dispose() {
    _textController.dispose();
    _scrollController.dispose();
    _suggestionTimer?.cancel();
    super.dispose();
  }

  void _startSuggestionChecking() {
    // Check for suggestions every 30 seconds
    _suggestionTimer = Timer.periodic(const Duration(seconds: 30), (timer) async {
      final suggestionData = await _apiService.getSuggestions();
      if (suggestionData != null && mounted) {
        setState(() {
          _currentSuggestion = Suggestion.fromJson(suggestionData);
        });
      }
    });
    
    // Also check immediately on start
    Future.delayed(const Duration(seconds: 5), () async {
      final suggestionData = await _apiService.getSuggestions();
      if (suggestionData != null && mounted) {
        setState(() {
          _currentSuggestion = Suggestion.fromJson(suggestionData);
        });
      }
    });
  }

  void _handleSendMessage(String text) {
    if (text.trim().isEmpty) return;

    context.read<ChatBloc>().add(SendMessage(text));
    _textController.clear();

    // Auto-scroll to bottom
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _handlePlayAudio(String? audioPath) {
    if (audioPath != null) {
      _audioService.playAudio(audioPath);
    }
  }

  void _handleShare(String text) {
    Share.share(text);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        elevation: 2,
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
        title: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.psychology_rounded,
                size: 20,
                color: Colors.deepPurple,
              ),
            ),
            const SizedBox(width: 12),
            const Text(
              'Reachly',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 22,
              ),
            ),
          ],
        ),
        actions: [
          // Toggle API/Mock mode
          BlocBuilder<ChatBloc, ChatState>(
            builder: (context, state) {
              return IconButton(
                icon: Icon(
                  state.useRealApi ? Icons.cloud : Icons.cloud_off,
                ),
                onPressed: () {
                  context.read<ChatBloc>().add(ToggleApiMode());
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        state.useRealApi 
                            ? 'Switched to Mock Mode' 
                            : 'Switched to API Mode',
                      ),
                      duration: const Duration(seconds: 2),
                    ),
                  );
                },
                tooltip: state.useRealApi ? 'Using API Mode' : 'Using Mock Mode',
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () {
              context.read<AuthBloc>().add(Logout());
            },
            tooltip: 'Logout',
          ),
        ],
      ),
      body: BlocConsumer<ChatBloc, ChatState>(
        listener: (context, state) {
          // Auto-play audio for AI responses
          if (state.messages.isNotEmpty) {
            final lastMessage = state.messages.last;
            if (!lastMessage.isUser && lastMessage.audioPath != null) {
              _handlePlayAudio(lastMessage.audioPath);
            }
          }

          // Auto-scroll after new messages
          Future.delayed(const Duration(milliseconds: 300), () {
            if (_scrollController.hasClients) {
              _scrollController.animateTo(
                _scrollController.position.maxScrollExtent,
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeOut,
              );
            }
          });
        },
        builder: (context, state) {
          return Column(
            children: [
              // Suggestion Card (if available)
              if (_currentSuggestion != null)
                SuggestionCard(
                  suggestion: _currentSuggestion!,
                  onTap: () {
                    // Send the suggestion text as a message
                    _handleSendMessage(_currentSuggestion!.text);
                    setState(() {
                      _currentSuggestion = null;
                    });
                  },
                  onDismiss: () {
                    setState(() {
                      _currentSuggestion = null;
                    });
                  },
                ),
              
              // Messages List
              Expanded(
                child: state.messages.isEmpty
                    ? _buildEmptyState()
                    : ListView.builder(
                        controller: _scrollController,
                        padding: const EdgeInsets.all(16),
                        itemCount: state.messages.length + (state.isThinking ? 1 : 0),
                        itemBuilder: (context, index) {
                          if (index == state.messages.length) {
                            // Show thinking indicator
                            return _buildThinkingIndicator();
                          }

                          final message = state.messages[index];
                          return MessageBubble(
                            message: message,
                            onPlayAudio: () => _handlePlayAudio(message.audioPath),
                            onShare: () => _handleShare(message.text),
                          );
                        },
                      ),
              ),

              // Input Area
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 4,
                      offset: const Offset(0, -2),
                    ),
                  ],
                ),
                padding: const EdgeInsets.all(12),
                child: SafeArea(
                  child: Row(
                    children: [
                      Expanded(
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(24),
                          ),
                          child: TextField(
                            controller: _textController,
                            decoration: const InputDecoration(
                              hintText: 'Ask Reachly anything...',
                              border: InputBorder.none,
                              contentPadding: EdgeInsets.symmetric(
                                horizontal: 20,
                                vertical: 12,
                              ),
                            ),
                            onSubmitted: _handleSendMessage,
                            textCapitalization: TextCapitalization.sentences,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      FloatingActionButton(
                        onPressed: () => _handleSendMessage(_textController.text),
                        backgroundColor: Colors.deepPurple,
                        child: const Icon(Icons.send, color: Colors.white),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: Colors.deepPurple.shade50,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.psychology_rounded,
                size: 50,
                color: Colors.deepPurple.shade300,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Welcome to Reachly!',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.grey.shade800,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Your personal AI assistant is ready to help.',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey.shade600,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              alignment: WrapAlignment.center,
              children: [
                _buildSuggestionChip('Tell me about John'),
                _buildSuggestionChip('Check on Sarah'),
                _buildSuggestionChip('Show me elevenlabs'),
                _buildSuggestionChip('Share a message'),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSuggestionChip(String text) {
    return ActionChip(
      label: Text(text),
      onPressed: () => _handleSendMessage(text),
      backgroundColor: Colors.deepPurple.shade50,
      labelStyle: TextStyle(color: Colors.deepPurple.shade700),
    );
  }

  Widget _buildThinkingIndicator() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.grey.shade200,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      Colors.deepPurple.shade300,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  'Reachly is thinking...',
                  style: TextStyle(
                    color: Colors.grey.shade700,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
