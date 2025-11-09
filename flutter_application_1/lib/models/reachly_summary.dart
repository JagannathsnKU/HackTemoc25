class ReachlySummary {
  final String summary;
  final List<String> topics;
  final String suggestedReply;
  final String? audioUrl;

  ReachlySummary({
    required this.summary,
    required this.topics,
    required this.suggestedReply,
    this.audioUrl,
  });

  factory ReachlySummary.fromJson(Map<String, dynamic> json) {
    return ReachlySummary(
      summary: json['summary_text'] ?? json['summary'] ?? '',
      topics: List<String>.from(json['topics'] ?? []),
      suggestedReply: json['suggested_reply'] ?? '',
      audioUrl: json['summary_audio_url'],
    );
  }
}
