enum ChatMessageSender { user, bot }

class ChatMessage {
  final String text;
  final ChatMessageSender sender;
  final DateTime timestamp;

  const ChatMessage({
    required this.text,
    required this.sender,
    required this.timestamp,
  });

  bool get isUser => sender == ChatMessageSender.user;

  Map<String, dynamic> toApiJson() {
    return {
      'role': isUser ? 'user' : 'model',
      'content': text,
      'timestamp': timestamp.toUtc().toIso8601String(),
    };
  }
}

class ChatResponse {
  final String reply;
  final String topic;
  final List<String> suggestions;

  const ChatResponse({
    required this.reply,
    required this.topic,
    required this.suggestions,
  });

  factory ChatResponse.fromJson(Map<String, dynamic> json) {
    final rawSuggestions = json['suggestions'] as List<dynamic>? ?? [];

    return ChatResponse(
      reply: json['reply'] as String? ?? '',
      topic: json['topic'] as String? ?? 'general',
      suggestions: rawSuggestions.map((item) => item.toString()).toList(),
    );
  }
}
