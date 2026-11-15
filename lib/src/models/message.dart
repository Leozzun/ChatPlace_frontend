import 'place.dart';

class Message {
  final String id;
  final String? text;
  final Place? place;
  final bool isUser;
  final DateTime createdAt;

  Message({
    required this.id,
    this.text,
    this.place,
    required this.isUser,
    required this.createdAt,
  });

  factory Message.fromJson(Map<String, dynamic> json) => Message(
    id: json['id'],
    text: json['text'],
    place: json['place'] != null
        ? Place.fromJson(json['place'])
        : null,
    isUser: json['isUser'] as bool,
    createdAt: DateTime.parse(json['createdAt']),
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'text': text,
    'place': place?.toJson(),
    'isUser': isUser,
    'createdAt': createdAt.toIso8601String(),
  };
}
