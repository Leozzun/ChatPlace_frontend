class LoginResponse {
  final int id;
  final String accessToken;
  final String email;
  final String nickname;
  final DateTime createdAt;

  LoginResponse({
    required this.id,
    required this.accessToken,
    required this.email,
    required this.nickname,
    required this.createdAt,
  });

  factory LoginResponse.fromJson(Map<String, dynamic> json) => LoginResponse(
    id: json['id'] as int,
    accessToken: json['accessToken'],
    email: json['email'],
    nickname: json['nickname'],
    createdAt: DateTime.parse(json['createdAt']),
  );
}
