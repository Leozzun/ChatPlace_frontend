class SignupRequest {
  final String email;
  final String password;
  final String nickname;
  final String birth;
  final String gender;
  final bool agree1;
  final bool agree2;

  SignupRequest({
    required this.email,
    required this.password,
    required this.nickname,
    required this.birth,
    required this.gender,
    required this.agree1,
    required this.agree2,
  });

  Map<String, dynamic> toJson() => {
    'email': email,
    'password': password,
    'nickname': nickname,
    'birth': birth,
    'gender': gender,
    'agree1': agree1,
    'agree2': agree2,
  };
}
