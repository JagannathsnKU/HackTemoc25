import 'package:flutter_bloc/flutter_bloc.dart';
import '../models/message.dart';

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

// States
class ChatState {
  final List<Message> messages;
  final bool isThinking;

  ChatState({
    this.messages = const [],
    this.isThinking = false,
  });

  ChatState copyWith({
    List<Message>? messages,
    bool? isThinking,
  }) {
    return ChatState(
      messages: messages ?? this.messages,
      isThinking: isThinking ?? this.isThinking,
    );
  }
}

// BLoC
class ChatBloc extends Bloc<ChatEvent, ChatState> {
  ChatBloc() : super(ChatState()) {
    on<SendMessage>(_onSendMessage);
    on<ReceiveMessage>(_onReceiveMessage);
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

    // Simulate thinking delay
    await Future.delayed(const Duration(seconds: 2));

    // Get mock response
    final response = _getAtlasMockResponse(event.text);

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

  Message _getAtlasMockResponse(String prompt) {
    final lowerPrompt = prompt.toLowerCase();

    // ElevenLabs trigger
    if (lowerPrompt.contains('elevenlabs') || lowerPrompt.contains('voice')) {
      return Message(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        text: 'Here\'s a sample of your cloned voice!',
        isUser: false,
        type: MessageType.elevenlabs,
        audioPath: 'assets/audio/elevenlabs_mock.mp3',
      );
    }

    // Share trigger
    if (lowerPrompt.contains('share') || lowerPrompt.contains('draft')) {
      return Message(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        text: 'Hey [Friend], this text was drafted by my AI! Want to hang out this weekend?',
        isUser: false,
        type: MessageType.share,
      );
    }

    // John trigger
    if (lowerPrompt.contains('john')) {
      return Message(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        text: 'Okay, I\'ve run a check on John. It looks like you last chatted on Instagram 7 days ago. Want to plan something?',
        isUser: false,
        audioPath: 'assets/audio/riva_reply_1.mp3',
      );
    }

    // Sarah trigger
    if (lowerPrompt.contains('sarah')) {
      return Message(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        text: 'I found Sarah in your contacts! You haven\'t talked in 2 weeks. Should I draft a message?',
        isUser: false,
        audioPath: 'assets/audio/riva_reply_1.mp3',
      );
    }

    // Default response
    return Message(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      text: 'I\'m still learning! Ask me about \'John\', \'Sarah\', \'elevenlabs\', or \'share\'.',
      isUser: false,
      audioPath: 'assets/audio/riva_reply_1.mp3',
    );
  }
}
