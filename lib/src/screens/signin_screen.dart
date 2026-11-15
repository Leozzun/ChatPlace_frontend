import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // 키보드 관련
import 'package:kakao_flutter_sdk_user/kakao_flutter_sdk_user.dart';
import 'package:provider/provider.dart';
import 'package:the_place/main.dart';
import 'package:the_place/src/screens/signup_screen.dart';
import '../models/login_response.dart';
import '../providers/auth_provider.dart';
import '../providers/bookmark_provider.dart';
import '../services/auth_service.dart';
import 'login_screen.dart';

class SigninScreen extends StatelessWidget {
  const SigninScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        scaffoldBackgroundColor: Colors.white,
        fontFamily: 'Noto Sans',
      ),
      home: const SignInPage(),
    );
  }
}

class SignInPage extends StatefulWidget {
  const SignInPage({super.key});

  @override
  State<SignInPage> createState() => _SignInPageState();
}

class _SignInPageState extends State<SignInPage> {
  final AuthService _authService = AuthService();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  // 로딩 상태 관리 (중복 터치 방지)
  bool _isLoading = false;

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  // --- [UI Helper] 커스텀 스낵바 ---
  void _showCustomSnackBar(String message, {bool isError = false, bool isSuccess = false}) {
    Color bgColor = Colors.black87;
    IconData icon = Icons.info_outline;

    if (isError) {
      bgColor = const Color(0xFFFF5252); // Soft Red
      icon = Icons.error_outline;
    } else if (isSuccess) {
      bgColor = const Color(0xFF4CAF50); // Soft Green
      icon = Icons.check_circle_outline;
    }

    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(icon, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
              ),
            ),
          ],
        ),
        backgroundColor: bgColor,
        behavior: SnackBarBehavior.floating, // 둥둥 떠있게
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(20),
        elevation: 4,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  // --- [Logic] 일반 이메일 로그인 ---
  Future<void> _handleEmailLogin() async {
    // 1. 입력값 검증
    if (emailController.text.trim().isEmpty) {
      _showCustomSnackBar('아이디(이메일)를 입력해주세요.', isError: true);
      return;
    }
    if (passwordController.text.trim().isEmpty) {
      _showCustomSnackBar('비밀번호를 입력해주세요.', isError: true);
      return;
    }

    setState(() => _isLoading = true); // 로딩 시작

    try {
      final loginRes = await _authService.login(
        emailController.text.trim(),
        passwordController.text.trim(),
      );

      // Provider 업데이트
      if (!mounted) return;
      await context.read<AuthProvider>().saveUser(loginRes);

      if (!mounted) return;
      await context.read<BookmarkProvider>().loadBookmarks(loginRes.id);

      if (!mounted) return;

      // 성공 메시지 (선택사항 - 바로 넘어가는게 깔끔하면 제거 가능)
      // _showCustomSnackBar('로그인 성공! 환영합니다.', isSuccess: true);

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const MainScreen()),
      );
    } catch (e) {
      debugPrint('Email Login Error: $e');
      // 에러 메시지 정제
      String errorMsg = '로그인에 실패했습니다. 아이디와 비밀번호를 확인해주세요.';
      if (e.toString().contains('User not found') || e.toString().contains('Password')) {
        errorMsg = '계정 정보가 일치하지 않습니다.';
      }
      _showCustomSnackBar(errorMsg, isError: true);
    } finally {
      if (mounted) setState(() => _isLoading = false); // 로딩 종료
    }
  }

  // --- [Logic] 카카오 로그인 ---
  Future<void> _handleKakaoLogin() async {
    setState(() => _isLoading = true);
    try {
      OAuthToken token;
      if (await isKakaoTalkInstalled()) {
        try {
          token = await UserApi.instance.loginWithKakaoTalk();
        } catch (error) {
          debugPrint('카카오톡으로 로그인 실패 $error');
          // 사용자가 취소했을 경우 등 예외 처리
          if (error is PlatformException && error.code == 'CANCELED') {
            return;
          }
          // 카톡 로그인 실패 시 카카오 계정 로그인 시도
          token = await UserApi.instance.loginWithKakaoAccount();
        }
      } else {
        token = await UserApi.instance.loginWithKakaoAccount();
      }

      // 백엔드 연동
      final LoginResponse res = await _authService.loginWithKakao(token.accessToken);

      if (!mounted) return;
      await context.read<AuthProvider>().saveUser(res);

      if (!mounted) return;
      await context.read<BookmarkProvider>().loadBookmarks(res.id);

      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const MainScreen()),
      );
    } catch (e) {
      debugPrint('Kakao Login Failed: $e');
      _showCustomSnackBar('카카오 로그인 중 오류가 발생했어요.', isError: true);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      // 키보드가 올라왔을 때 화면이 밀려올라가도 오버플로우 나지 않도록 스크롤 뷰 적용
      body: SingleChildScrollView(
        child: SizedBox(
          width: MediaQuery.of(context).size.width,
          height: MediaQuery.of(context).size.height, // 전체 화면 높이 사용
          child: Stack(
            children: [
              Column(
                children: [
                  const SizedBox(height: 120),
                  const Align(
                    alignment: Alignment.centerLeft,
                    child: Padding(
                      padding: EdgeInsets.only(left: 26),
                      child: Text(
                        '로그인',
                        style: TextStyle(
                          color: Color(0xFF5C5C60),
                          fontSize: 24,
                          fontWeight: FontWeight.w700,
                          letterSpacing: -0.96,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 57),

                  // 이메일 입력
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 26),
                    child: TextField(
                      controller: emailController,
                      style: const TextStyle(color: Colors.black, fontSize: 20),
                      decoration: const InputDecoration(
                        hintText: "아이디 (이메일 주소)",
                        hintStyle: TextStyle(color: Color(0xFF939393), fontSize: 20),
                        enabledBorder: UnderlineInputBorder(
                          borderSide: BorderSide(color: Color(0xFFC1C1C1), width: 2),
                        ),
                        focusedBorder: UnderlineInputBorder(
                          borderSide: BorderSide(color: Color(0xFF000000), width: 2),
                        ),
                        filled: true,
                        fillColor: Colors.white,
                        contentPadding: EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                  const SizedBox(height: 30),

                  // 비밀번호 입력
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 26),
                    child: TextField(
                      controller: passwordController,
                      obscureText: true,
                      style: const TextStyle(color: Colors.black, fontSize: 20),
                      decoration: const InputDecoration(
                        hintText: "비밀번호",
                        hintStyle: TextStyle(color: Color(0xFF939393), fontSize: 20),
                        enabledBorder: UnderlineInputBorder(
                          borderSide: BorderSide(color: Color(0xFFC1C1C1), width: 2),
                        ),
                        focusedBorder: UnderlineInputBorder(
                          borderSide: BorderSide(color: Color(0xFF000000), width: 2),
                        ),
                        filled: true,
                        fillColor: Colors.white,
                        contentPadding: EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                  const SizedBox(height: 50),

                  // 로그인 버튼
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 15),
                    child: SizedBox(
                      width: double.infinity, // 화면 꽉 차게 (패딩 제외)
                      height: 50,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _handleEmailLogin, // 로딩 중 클릭 방지
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF000000),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                          elevation: 0,
                        ),
                        child: _isLoading
                            ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                        )
                            : const Text(
                          '로그인',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.w700,
                            letterSpacing: -0.88,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 30),

                  // 회원가입 버튼
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 15),
                    child: SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: OutlinedButton(
                        onPressed: () {
                          Navigator.push(context, MaterialPageRoute(builder: (_) => const SignupScreen()));
                        },
                        style: OutlinedButton.styleFrom(
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                          side: const BorderSide(width: 2, color: Color(0xFF000000)),
                        ),
                        child: const Text(
                          '회원가입',
                          style: TextStyle(
                            color: Color(0xFF000000),
                            fontSize: 22,
                            fontWeight: FontWeight.w700,
                            letterSpacing: -0.88,
                          ),
                        ),
                      ),
                    ),
                  ),

                  // Spacer로 화면 비율에 맞게 밀어주기 (고정 높이 대신 사용 권장)
                  const Spacer(),

                  // 구분선
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 20),
                    child: Row(
                      children: [
                        Expanded(child: Divider(thickness: 1, color: Colors.grey)),
                        Padding(
                          padding: EdgeInsets.symmetric(horizontal: 16),
                          child: Text(
                            '또는',
                            style: TextStyle(
                              color: Colors.black,
                              fontSize: 20,
                              fontWeight: FontWeight.w400,
                              letterSpacing: -0.80,
                            ),
                          ),
                        ),
                        Expanded(child: Divider(thickness: 1, color: Colors.grey)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 41),

                  // 카카오 로그인 버튼
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 15),
                    child: SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _handleKakaoLogin,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFFEE500),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                          elevation: 0,
                        ),
                        child: _isLoading
                            ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(color: Colors.black, strokeWidth: 2),
                        )
                            : const Text(
                          '카카오로 계속하기',
                          style: TextStyle(
                            color: Colors.black,
                            fontSize: 22,
                            fontWeight: FontWeight.w700,
                            letterSpacing: -0.88,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 50), // 하단 여백 추가
                ],
              ),

              // 뒤로가기 버튼
              SafeArea(
                child: Align(
                  alignment: Alignment.topLeft,
                  child: Padding(
                    padding: const EdgeInsets.only(left: 4, top: 4),
                    child: IconButton(
                      icon: const Icon(Icons.arrow_back_ios_new, color: Colors.black),
                      onPressed: () {
                        // 기존 화면 전환 효과 유지
                        Navigator.of(context).push(
                          PageRouteBuilder(
                            pageBuilder: (context, animation, secondaryAnimation) => LoginScreen(),
                            transitionsBuilder: (context, animation, secondaryAnimation, child) {
                              const begin = Offset(-1.0, 0.0);
                              const end = Offset.zero;
                              const curve = Curves.ease;
                              final tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
                              return SlideTransition(position: animation.drive(tween), child: child);
                            },
                          ),
                        );
                      },
                      tooltip: '뒤로가기',
                      splashRadius: 22,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}