import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:the_place/main.dart';
import 'dart:math' as math;
import 'package:the_place/src/screens/signin_screen.dart';
import 'package:kakao_flutter_sdk_user/kakao_flutter_sdk_user.dart';
import '../models/login_response.dart';
import '../providers/auth_provider.dart';
import '../providers/bookmark_provider.dart';
import '../services/auth_service.dart';

final AuthService _authService = AuthService();

Future<void> _loginWithKakao(BuildContext context) async {
  try {
    OAuthToken token;

    if (await isKakaoTalkInstalled()) {
      token = await UserApi.instance.loginWithKakaoTalk();
    } else {
      token = await UserApi.instance.loginWithKakaoAccount();
    }

    final kakaoAccessToken = token.accessToken;
    debugPrint('Kakao accessToken = $kakaoAccessToken');

    // ✅ 1) 카카오 토큰을 백엔드로 보내서 우리 서비스 로그인
    final LoginResponse res =
    await _authService.loginWithKakao(kakaoAccessToken);

    final auth = context.read<AuthProvider>();
    await auth.saveUser(res);

    final bookmarkProvider = context.read<BookmarkProvider>();
    await bookmarkProvider.loadBookmarks(res.id);

    if (!context.mounted) return;

    // ✅ 3) 메인 화면으로 이동 (탭 구조)
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const MainScreen()),
    );
  } catch (e) {
    debugPrint('Kakao login failed: $e');
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('카카오 로그인 중 오류가 발생했어요.')),
    );
  }
}

// 진한 파란 사각형 도형 (angle 도 단위)
class BlueBox extends StatelessWidget {
  final double width;
  final double height;
  final double angleDegree;
  final Color color;
  const BlueBox({
    Key? key,
    this.width = 100,
    this.height = 100,
    this.angleDegree = 0,
    this.color = const Color(0xFF2792ED),
  }) : super(key: key);

  double get angleRadian => angleDegree * math.pi / 180;
  @override
  Widget build(BuildContext context) {
    return Transform.rotate(
      angle: angleRadian,
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(color: color),
      ),
    );
  }
}

// 연한 파란 사각형 도형 (angle 도 단위)
class PaleBox extends StatelessWidget {
  final double width;
  final double height;
  final double angleDegree;
  final Color color;
  const PaleBox({
    Key? key,
    this.width = 200,
    this.height = 40,
    this.angleDegree = 0,
    this.color = const Color(0xFFBBE1FE),
  }) : super(key: key);

  double get angleRadian => angleDegree * math.pi / 180;
  @override
  Widget build(BuildContext context) {
    return Transform.rotate(
      angle: angleRadian,
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(color: color),
      ),
    );
  }
}

// 커스텀 레이아웃 Delegate (도형만)
class MyLayoutDelegate extends MultiChildLayoutDelegate {
  @override
  void performLayout(Size size) {
    if (hasChild('blue1')) {
      layoutChild('blue1', BoxConstraints.loose(size));
      positionChild('blue1', Offset(75, 530));
    }
    if (hasChild('blue2')) {
      layoutChild('blue2', BoxConstraints.loose(size));
      positionChild('blue2', Offset(-30, 633));
    }
    if (hasChild('blue3')) {
      layoutChild('blue3', BoxConstraints.loose(size));
      positionChild('blue3', Offset(180, 690));
    }
    if (hasChild('pale1')) {
      layoutChild('pale1', BoxConstraints.loose(size));
      positionChild('pale1', Offset(0, 175));
    }
    if (hasChild('pale2')) {
      layoutChild('pale2', BoxConstraints.loose(size));
      positionChild('pale2', Offset(0, 35));
    }
  }

  @override
  bool shouldRelayout(covariant MultiChildLayoutDelegate oldDelegate) => false;
}

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;

    // 디자인상 요소들이 배치된 최하단 높이를 고려해 최소 높이 설정 (약 950px)
    // 화면이 이것보다 작으면 스크롤이 생기고, 크면 꽉 차게 보임
    const double minDesignHeight = 950.0;

    return Scaffold(
      body: SingleChildScrollView(
        child: Container(
          width: screenSize.width,
          height: screenSize.height,
          color: Colors.white,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              // 도형(OverflowBox로 감쌈)
              CustomMultiChildLayout(
                delegate: MyLayoutDelegate(),
                children: [
                  LayoutId(
                    id: 'blue1',
                    child: BlueBox(width: 120, height: 100, angleDegree: -45),
                  ),
                  LayoutId(
                    id: 'blue2',
                    child: BlueBox(width: 120, height: 100, angleDegree: -45),
                  ),
                  LayoutId(
                    id: 'blue3',
                    child: BlueBox(width: 210, height: 200, angleDegree: -45),
                  ),
                  LayoutId(
                    id: 'pale1',
                    child: OverflowBox(
                      minWidth: 0,
                      minHeight: 0,
                      maxWidth: double.infinity,
                      maxHeight: double.infinity,
                      child: PaleBox(width: 700, height: 70, angleDegree: -45),
                    ),
                  ),
                  LayoutId(
                    id: 'pale2',
                    child: OverflowBox(
                      minWidth: 0,
                      minHeight: 0,
                      maxWidth: double.infinity,
                      maxHeight: double.infinity,
                      child: PaleBox(width: 700, height: 70, angleDegree: -135),
                    ),
                  ),
                ],
              ),

              // 그라데이션 배경
              Positioned(
                left: 0,
                top: 238,
                right: 0, // 가로 꽉 차게
                child: Container(
                  height: 694,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.white.withOpacity(0.1),
                        Colors.white.withOpacity(0.3),
                        const Color(0xFF3EA0F4).withOpacity(0.5),
                      ],
                      stops: const [0.0, 0.2, 1.0],
                    ),
                  ),
                ),
              ),

              // 카카오 버튼 (가로 반응형 수정: left, right 15)
              Positioned(
                left: 15,
                right: 15,
                top: 702,
                child: GestureDetector(
                  onTap: () => _loginWithKakao(context),
                  child: Container(
                    height: 50,
                    decoration: ShapeDecoration(
                      color: const Color(0xFFFEE500),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                    ),
                    alignment: Alignment.center,
                    child: const Text(
                      '카카오로 계속하기',
                      style: TextStyle(
                        color: Colors.black,
                        fontSize: 22,
                        fontFamily: 'Noto Sans',
                        fontWeight: FontWeight.w700,
                        height: 1.18,
                        letterSpacing: -0.88,
                        decoration: TextDecoration.none,
                      ),
                    ),
                  ),
                ),
              ),

              // 이메일 로그인 버튼 (가로 반응형 수정)
              Positioned(
                left: 15,
                right: 15,
                top: 772,
                child: GestureDetector(
                  onTap: () {
                    Navigator.push(context,
                        MaterialPageRoute(builder: (_) => const SigninScreen()));
                  },
                  child: Container(
                    height: 50,
                    decoration: ShapeDecoration(
                      color: Colors.black,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                    ),
                    alignment: Alignment.center,
                    child: const Text(
                      '로그인 또는 회원가입',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontFamily: 'Noto Sans',
                        fontWeight: FontWeight.w700,
                        height: 1.18,
                        letterSpacing: -0.88,
                        decoration: TextDecoration.none,
                      ),
                    ),
                  ),
                ),
              ),

              // 채팅 버블 1
              Positioned(
                left: 23,
                top: 513,
                child: Container(
                  width: 140,
                  height: 40,
                  decoration: ShapeDecoration(
                    gradient: const LinearGradient(
                      begin: Alignment(0.00, 0.50),
                      end: Alignment(1.00, 0.50),
                      colors: [Color(0xFF449DFD), Color(0xFF86BEFB)],
                    ),
                    shape: RoundedRectangleBorder(
                      side: const BorderSide(
                        width: 1,
                        color: Color(0xFF459DFD),
                      ),
                      borderRadius: BorderRadius.circular(25),
                    ),
                    shadows: const [
                      BoxShadow(
                        color: Color(0xFF7EBAFB),
                        blurRadius: 30,
                        offset: Offset(4, 12),
                        spreadRadius: 0,
                      )
                    ],
                  ),
                ),
              ),
              const Positioned(
                left: 39,
                top: 521,
                child: Text(
                  '주변 맛집 알려줘',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontFamily: 'Noto Sans',
                    fontWeight: FontWeight.w600,
                    height: 1.50,
                    decoration: TextDecoration.none,
                  ),
                ),
              ),

              // 채팅 버블 2
              Positioned(
                left: 187,
                top: 385,
                child: Container(
                  width: 198,
                  height: 40,
                  decoration: ShapeDecoration(
                    gradient: const LinearGradient(
                      begin: Alignment(0.00, 0.50),
                      end: Alignment(1.00, 0.50),
                      colors: [Color(0xFF449DFD), Color(0xFF86BEFB)],
                    ),
                    shape: RoundedRectangleBorder(
                      side: const BorderSide(
                        width: 1,
                        color: Color(0xFF459DFD),
                      ),
                      borderRadius: BorderRadius.circular(25),
                    ),
                    shadows: const [
                      BoxShadow(
                        color: Color(0xFF7EBAFB),
                        blurRadius: 30,
                        offset: Offset(4, 12),
                        spreadRadius: 0,
                      )
                    ],
                  ),
                ),
              ),
              const Positioned(
                left: 201,
                top: 393,
                child: SizedBox(
                  width: 169.63,
                  child: Text(
                    '공부하기 좋은 카페 알려줘',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontFamily: 'Noto Sans',
                      fontWeight: FontWeight.w600,
                      height: 1.50,
                      decoration: TextDecoration.none,
                    ),
                  ),
                ),
              ),

              // 채팅 버블 3
              Positioned(
                left: 125,
                top: 249,
                child: Container(
                  width: 130,
                  height: 40,
                  decoration: ShapeDecoration(
                    gradient: const LinearGradient(
                      begin: Alignment(0.00, 0.50),
                      end: Alignment(1.00, 0.50),
                      colors: [Color(0xFF449DFD), Color(0xFF86BEFB)],
                    ),
                    shape: RoundedRectangleBorder(
                      side: const BorderSide(
                        width: 1,
                        color: Color(0xFF459DFD),
                      ),
                      borderRadius: BorderRadius.circular(25),
                    ),
                    shadows: const [
                      BoxShadow(
                        color: Color(0xFF7EBAFB),
                        blurRadius: 30,
                        offset: Offset(4, 12),
                        spreadRadius: 0,
                      )
                    ],
                  ),
                ),
              ),
              const Positioned(
                left: 138,
                top: 257,
                child: Text(
                  '일식집 추천해줘',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontFamily: 'Noto Sans',
                    fontWeight: FontWeight.w600,
                    height: 1.50,
                    decoration: TextDecoration.none,
                  ),
                ),
              ),

              // 타이틀 및 헤더
              const Positioned(
                left: 25,
                top: 134,
                child: Text(
                  'AI 채팅으로 만나는\n나만의 플레이스',
                  style: TextStyle(
                    color: Color(0xFF95959F),
                    fontSize: 18,
                    fontFamily: 'Noto Sans',
                    fontWeight: FontWeight.w700,
                    height: 1.44,
                    letterSpacing: -0.72,
                    decoration: TextDecoration.none,
                  ),
                ),
              ),
              const Positioned(
                left: 25,
                top: 88,
                child: Text(
                  'ChatPlace',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Color(0xFF064A68),
                    fontSize: 34,
                    fontFamily: 'Noto Sans Bengali',
                    fontWeight: FontWeight.w600,
                    height: 1.35,
                    letterSpacing: -1.36,
                    decoration: TextDecoration.none,
                  ),
                ),
              ),

              // 타이틀 옆 점 데코레이션
              Positioned(
                left: 102,
                top: 84,
                child: Container(
                  width: 6,
                  height: 6,
                  decoration: const ShapeDecoration(
                    color: Color(0xFF064A68),
                    shape: OvalBorder(),
                  ),
                ),
              ),
              Positioned(
                left: 34,
                top: 84,
                child: Container(
                  width: 6,
                  height: 6,
                  decoration: const ShapeDecoration(
                    color: Color(0xFF064A68),
                    shape: OvalBorder(),
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