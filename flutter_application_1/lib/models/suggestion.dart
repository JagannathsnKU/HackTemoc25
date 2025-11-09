class Suggestion {
  final String id;
  final String title;
  final String text;
  final DateTime timestamp;

  Suggestion({
    required this.id,
    required this.title,
    required this.text,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();

  factory Suggestion.fromJson(Map<String, dynamic> json) {
    return Suggestion(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: json['title'] ?? 'Suggestion',
      text: json['text'] ?? '',
    );
  }
}
