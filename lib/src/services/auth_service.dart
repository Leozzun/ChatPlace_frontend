import 'package:dio/dio.dart';
import '../models/login_response.dart';
import '../models/signup_request.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AuthService {
  late final Dio dio;

  AuthService({String? token}) {
    dio = Dio(
      BaseOptions(
        baseUrl: 'http://192.0.0.2:3000', // 실제 서버로 교체
        connectTimeout: const Duration(seconds: 20),
        receiveTimeout: const Duration(seconds: 20),
        headers: {'Content-Type': 'application/json'},
      ),
    );

    // 자동 토큰 헤더
    dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        final prefs = await SharedPreferences.getInstance();
        final savedToken = prefs.getString('token');
        if (savedToken != null && savedToken.isNotEmpty) {
          options.headers['Authorization'] = 'Bearer $savedToken';
        }
        handler.next(options);
      },
    ));
  }

  Future<void> sendEmailVerification(String email) async {
    try {
      final res = await dio.post(
        '/auth/send-verification-email',
        data: {'email': email},
      );
      if (res.statusCode != 200) {
        throw Exception('이메일 인증 코드 전송 실패: ${res.statusCode}');
      }
    } on DioException catch (e) {
      if (e.response != null) {
        print('이메일 코드 전송 서버 에러: ${e.response?.statusCode} - ${e.response?.data}');
      } else {
        print('이메일 코드 전송 네트워크 에러: ${e.message}');
      }
      rethrow;
    }
  }

  // 2) 이메일 + 코드 검증
  Future<Map<String, dynamic>> verifySignupCode(String email, String code) async {
    try {
      final res = await dio.post(
        '/auth/send-verify-code',
        data: {
          'email': email,
          'code': code,
        },
      );
      if (res.statusCode == 200) {
        // verified=true 인 성공 케이스
        if (res.data is Map<String, dynamic>) {
          return res.data as Map<String, dynamic>;
        } else if (res.data is Map) {
          return Map<String, dynamic>.from(res.data as Map);
        }
        throw Exception('응답 형식이 올바르지 않습니다.');
      } else if (res.statusCode == 401) {
        // 인증 실패 케이스 (verified=false)
        if (res.data is Map<String, dynamic>) {
          return res.data as Map<String, dynamic>;
        } else if (res.data is Map) {
          return Map<String, dynamic>.from(res.data as Map);
        }
        return {
          'verified': false,
          'message': '인증 실패 (${res.statusCode})',
        };
      } else {
        throw Exception('이메일 코드 검증 실패: ${res.statusCode}');
      }
    } on DioException catch (e) {
      if (e.response != null) {
        print('이메일 코드 검증 서버 에러: ${e.response?.statusCode} - ${e.response?.data}');
      } else {
        print('이메일 코드 검증 네트워크 에러: ${e.message}');
      }
      rethrow;
    }
  }

  Future<void> signup(SignupRequest req) async {
    try {
      final response = await dio.post('/auth/signup', data: req.toJson());

      if (response.statusCode == 201) {
        print('회원가입 성공!');
      } else {
        print('회원가입 실패: ${response.statusCode} - ${response.data}');
        throw Exception('회원가입 실패');
      }
    } on DioException catch (e) {
      if (e.response != null) {
        print('서버 응답 에러: ${e.response?.statusCode} - ${e.response?.data}');
      } else {
        print('네트워크 에러: ${e.message}');
      }
      rethrow;
    }
  }

  Future<bool> checkNickname(String nickname) async {
    try {
      final response = await dio.get(
        '/auth/check-nickname',
        queryParameters: {'nickname': nickname},
      );
      // 서버에서 true(중복O)/false(중복X) 반환
      return response.data == true;
    } catch (e) {
      print('닉네임 중복확인 실패: $e');
      rethrow;
    }
  }

  Future<LoginResponse> login(String email, String password) async {
    try {
      final response = await dio.post('/auth/login', data: {
        'email': email,
        'password': password,
      });
      print(response.data); // 실제 JSON 응답

      if (response.statusCode == 200) {
        return LoginResponse.fromJson(response.data);
      } else {
        throw Exception('로그인 실패: ${response.statusCode}');
      }
    } on DioException catch (e) {
      if (e.response != null) {
        print('서버 응답 에러: ${e.response?.statusCode} - ${e.response?.data}');
      } else {
        print('네트워크 에러: ${e.message}');
      }
      rethrow;
    }
  }

  Future<void> deleteUser() async {
    try {
      final response = await dio.delete('/auth/delete');
      if (response.statusCode == 200) {
        print('회원탈퇴 성공!');
      } else {
        print('회원탈퇴 실패: ${response.statusCode} - ${response.data}');
        throw Exception('회원탈퇴 실패');
      }
    } on DioException catch (e) {
      if (e.response != null) {
        print('서버 응답 에러: ${e.response?.statusCode} - ${e.response?.data}');
      } else {
        print('네트워크 에러: ${e.message}');
      }
      rethrow;
    }
  }

  // 카카오 accessToken으로 백엔드 로그인
  Future<LoginResponse> loginWithKakao(String kakaoAccessToken) async {
    try {
      final response = await dio.post(
        '/auth/login/kakao',
        data: {'accessToken': kakaoAccessToken},
      );
      if (response.statusCode == 200) {
        return LoginResponse.fromJson(response.data);
      } else {
        throw Exception('카카오 로그인 실패: ${response.statusCode}');
      }
    } on DioException catch (e) {
      if (e.response != null) {
        print('카카오 로그인 서버 에러: ${e.response?.statusCode} - ${e.response?.data}');
      } else {
        print('카카오 로그인 네트워크 에러: ${e.message}');
      }
      rethrow;
    }
  }

  // 이메일 중복 확인 (true면 이미 존재, false면 사용 가능)
  Future<bool> checkEmailDuplicate(String email) async {
    try {
      final response = await dio.get(
        '/auth/check-email',
        queryParameters: {'email': email},
      );
      // 서버에서 { "duplicate": true/false } 형태로 응답한다고 가정
      if (response.statusCode == 200) {
        final data = response.data;
        if (data is Map<String, dynamic>) {
          return data['duplicate'] == true;
        } else if (data is Map) {
          return Map<String, dynamic>.from(data)['duplicate'] == true;
        }
        // 혹시 그냥 true/false만 내려주는 구조라면:
        if (data is bool) return data;
      }
      throw Exception('이메일 중복 확인 실패: ${response.statusCode}');
    } on DioException catch (e) {
      if (e.response != null) {
        print('이메일 중복확인 서버 에러: ${e.response?.statusCode} - ${e.response?.data}');
      } else {
        print('이메일 중복확인 네트워크 에러: ${e.message}');
      }
      rethrow;
    }
  }
}
