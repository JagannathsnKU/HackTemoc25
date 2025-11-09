import 'package:flutter_bloc/flutter_bloc.dart';
import '../models/message.dart';
import '../services/api_service.dart';

// Events
abstract class ChatEvent {}

class SendMessage extends ChatEvent {
  final String text;
  SendMessage(this.text);
}

class ReceiveMessage extends ChatEvent {
  final Message message;
  ReceiveMessage(this.message);
}

class ToggleApiMode extends ChatEvent {}

// States
class ChatState {
  final List<Message> messages;
  final bool isThinking;
  final bool useRealApi;
  final bool apiConnected;

  ChatState({
    this.messages = const [],
    this.isThinking = false,
    this.useRealApi = true,
    this.apiConnected = false,
  });

  ChatState copyWith({
    List<Message>? messages,
    bool? isThinking,
    bool? useRealApi,
    bool? apiConnected,
  }) {
    return ChatState(
      messages: messages ?? this.messages,
      isThinking: isThinking ?? this.isThinking,
      useRealApi: useRealApi ?? this.useRealApi,
      apiConnected: apiConnected ?? this.apiConnected,
    );
  }
}

// BLoC
class ChatBloc extends Bloc<ChatEvent, ChatState> {
  final ApiService _apiService = ApiService();

  ChatBloc() : super(ChatState()) {
    on<SendMessage>(_onSendMessage);
    on<ReceiveMessage>(_onReceiveMessage);
    on<ToggleApiMode>(_onToggleApiMode);
    _checkApiConnection();
  }

  Future<void> _checkApiConnection() async {
    final isConnected = await _apiService.checkConnection();
    add(ReceiveMessage(Message(
      id: 'system-${DateTime.now().millisecondsSinceEpoch}',
      text: isConnected 
          ? '✅ Connected to Atlas Gateway'
          : '⚠️ Gateway offline, using mock responses',
      isUser: false,
    )));
  }

  void _onSendMessage(SendMessage event, Emitter<ChatState> emit) async {
    // Add user message
    final userMessage = Message(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      text: event.text,
      isUser: true,
    );

    emit(state.copyWith(
      messages: [...state.messages, userMessage],
      isThinking: true,
    ));

    Message response;

    // Try to use real API
    if (state.useRealApi) {
      try {
        // Call the real /ask_atlas endpoint
        final replyText = await _apiService.askAtlas(event.text);
        
        response = Message(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          text: replyText,
          isUser: false,
          type: _detectMessageType(replyText),
        );
      } catch (e) {
        // Fallback to mock response if API fails
        print('API failed, using mock: $e');
        await Future.delayed(const Duration(seconds: 1));
        response = _getAtlasMockResponse(event.text);
      }
    } else {
      // Use mock responses
      await Future.delayed(const Duration(seconds: 2));
      response = _getAtlasMockResponse(event.text);
    }

    emit(state.copyWith(
      messages: [...state.messages, response],
      isThinking: false,
    ));
  }

  void _onReceiveMessage(ReceiveMessage event, Emitter<ChatState> emit) {
    emit(state.copyWith(
      messages: [...state.messages, event.message],
    ));
  }

  void _onToggleApiMode(ToggleApiMode event, Emitter<ChatState> emit) {
    emit(state.copyWith(useRealApi: !state.useRealApi));
  }

  MessageType _detectMessageType(String text) {
    final lowerText = text.toLowerCase();
    
    // Check if the response contains keywords for special types
    if (lowerText.contains('voice') || lowerText.contains('elevenlabs')) {
      return MessageType.elevenlabs;
    } else if (lowerText.contains('share') || lowerText.contains('draft')) {
      return MessageType.share;
    }
    return MessageType.text;
  }

  Message _getAtlasMockResponse(String prompt) {
    final lowerPrompt = prompt.toLowerCase();

    // ElevenLabs trigger
    if (lowerPrompt.contains('elevenlabs') || lowerPrompt.contains('voice')) {
      return Message(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        text: '🎙️ Here\'s a sample of your cloned voice!',
        isUser: false,
        type: MessageType.elevenlabs,
        audioPath: 'assets/audio/elevenlabs_mock.mp3',
      );
    }

    // Share trigger
    if (lowerPrompt.contains('share') || lowerPrompt.contains('draft')) {
      return Message(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        text: '📤 Hey [Friend], this text was drafted by my AI! Want to hang out this weekend?',
        isUser: false,
        type: MessageType.share,
      );
    }

    // John trigger
    if (lowerPrompt.contains('john')) {
      return Message(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        text: '👤 Okay, I\'ve run a check on John. It looks like you last chatted on Instagram 7 days ago. Want to plan something?',
        isUser: false,
        audioPath: 'assets/audio/riva_reply_1.mp3',
      );
    }

    // Sarah trigger
    if (lowerPrompt.contains('sarah')) {
      return Message(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        text: '👤 I found Sarah in your contacts! You haven\'t talked in 2 weeks. Should I draft a message?',
        isUser: false,
        audioPath: 'assets/audio/riva_reply_1.mp3',
      );
    }

    // Default response
    return Message(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      text: state.useRealApi 
          ? '🤖 I\'m connected to your backend at hacktemoc25.onrender.com. Try asking me anything!'
          : '💡 I\'m in offline mode. Ask me about \'John\', \'Sarah\', \'elevenlabs\', or \'share\'.',
      isUser: false,
      audioPath: 'assets/audio/riva_reply_1.mp3',
    );
  }
}
