class Conversation {
  final int id;
  final int userId;
  final String title;
  final String question;
  final String answer;
  final String placesJson;
  final String messagesJson;
  final DateTime createdAt;

  Conversation({
    required this.id,
    required this.userId,
    required this.title,
    required this.question,
    required this.answer,
    required this.placesJson,
    required this.messagesJson,
    required this.createdAt,
  });

  factory Conversation.fromJson(Map<String, dynamic> json) {
    return Conversation(
      id: json['id'],
      userId: json['userId'],
      title: json['title'] ?? '',
      question: json['question'] ?? '',
      answer: json['answer'] ?? '',
      placesJson: json['placesJson'] ?? '[]',
      messagesJson: json['messagesJson'] ?? '[]',
      createdAt: DateTime.parse(json['createdAt']),
    );
  }
}
