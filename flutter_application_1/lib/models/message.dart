enum MessageType {
  text,
  elevenlabs,
  share,
}

class Message {
  final String id;
  final String text;
  final bool isUser;
  final MessageType type;
  final String? audioPath;
  final DateTime timestamp;

  Message({
    required this.id,
    required this.text,
    required this.isUser,
    this.type = MessageType.text,
    this.audioPath,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();
}
