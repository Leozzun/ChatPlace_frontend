import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:the_place/src/providers/auth_provider.dart';
import 'package:the_place/src/screens/signin_screen.dart';
import 'package:the_place/src/services/auth_service.dart';
import 'package:the_place/src/screens/login_screen.dart';

class SettingScreen extends StatefulWidget {
  const SettingScreen({super.key});

  @override
  State<SettingScreen> createState() => _SettingScreenState();
}

class _SettingScreenState extends State<SettingScreen> {
  final AuthService _authService = AuthService();

  final Color _primaryColor = const Color(0xFF0091EA);
  final Color _subTextColor = const Color(0xFF8E8E93);

  bool _isPushEnabled = true;
  bool _isLocationRecomEnabled = false;
  String _currentStyle = "친구처럼";
  double _currentRadius = 1.5;

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user;
    final nickname = user?.nickname ?? '';

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          '설정',
          style: TextStyle(color: Colors.black, fontSize: 17, fontWeight: FontWeight.w600),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 20),
            _buildProfileSection(nickname),
            const SizedBox(height: 40),
            _buildSectionHeader('AI'),
            _buildMenuTile(
              title: '답변 스타일',
              value: _currentStyle,
              icon: CupertinoIcons.sparkles,
              iconColor: _primaryColor,
              onTap: () async {
                final result = await Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => AnswerStyleScreen(initialStyle: _currentStyle)),
                );
                if (result != null) setState(() => _currentStyle = result);
              },
            ),
            _buildMenuTile(
              title: '검색 반경 설정',
              value: '${_currentRadius.toStringAsFixed(1)}km',
              icon: CupertinoIcons.map,
              iconColor: Colors.black87,
              onTap: () async {
                final result = await Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => RadiusSettingScreen(initialRadius: _currentRadius)),
                );
                if (result != null) setState(() => _currentRadius = result);
              },
            ),
            const SizedBox(height: 32),
            _buildSectionHeader('알림'),
            _buildSwitchTile(
              title: '푸시 알림',
              value: _isPushEnabled,
              onChanged: (v) => setState(() => _isPushEnabled = v),
            ),
            _buildSwitchTile(
              title: '스마트 장소 추천',
              subtitle: '근처에 취향 저격 장소가 있으면 알려드려요',
              value: _isLocationRecomEnabled,
              onChanged: (v) => setState(() => _isLocationRecomEnabled = v),
            ),
            const SizedBox(height: 32),
            _buildSectionHeader('계정 및 지원'),
            _buildMenuTile(title: '문의하기', icon: CupertinoIcons.chat_bubble_text, onTap: () {}),
            _buildMenuTile(title: '버전 정보', value: '1.0.0', isLink: false, onTap: () {}),

            // --- 회원 탈퇴 기능 추가 ---
            const SizedBox(height: 30),
            _buildTextButton(
              '회원 탈퇴',
              Colors.red.shade800,
              fontSize: 18,
              isBold: true,
              isStrong: true,
              onTap: () {
                showDialog(
                  context: context,
                  builder: (ctx) => Dialog(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20), // 둥근 모서리
                    ),
                    elevation: 0, // 그림자 제거하여 깔끔하게 (필요시 추가 가능)
                    backgroundColor: Colors.white,
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
                      child: Column(
                        mainAxisSize: MainAxisSize.min, // 내용만큼만 높이 차지
                        children: [
                          // 1. 아이콘 (선택사항: 경고 느낌을 살짝 주기 위함, 없애도 무방)
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFFEBEE), // 연한 빨강 배경
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(CupertinoIcons.exclamationmark_triangle_fill, color: Colors.red, size: 28),
                          ),
                          const SizedBox(height: 20),

                          // 2. 제목
                          const Text(
                            '정말 떠나시나요?',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.black,
                            ),
                          ),
                          const SizedBox(height: 12),

                          // 3. 본문 내용
                          const Text(
                            '회원 탈퇴 시 모든 데이터가 삭제되며\n복구할 수 없습니다.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 14,
                              color: Color(0xFF8E8E93), // 서브 텍스트 컬러
                              height: 1.5, // 줄간격 확보
                            ),
                          ),
                          const SizedBox(height: 28),

                          // 4. 버튼 영역 (Row로 배치)
                          Row(
                            children: [
                              // 취소 버튼 (회색)
                              Expanded(
                                child: TextButton(
                                  onPressed: () => Navigator.pop(ctx, false),
                                  style: TextButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(vertical: 16),
                                    backgroundColor: const Color(0xFFF2F4F6), // 연한 회색
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                  child: const Text(
                                    '취소',
                                    style: TextStyle(
                                      color: Colors.black87,
                                      fontWeight: FontWeight.w600,
                                      fontSize: 15,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12), // 버튼 사이 간격

                              // 탈퇴 버튼 (빨간색)
                              Expanded(
                                child: TextButton(
                                  onPressed: () => Navigator.pop(ctx, true),
                                  style: TextButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(vertical: 16),
                                    backgroundColor: const Color(0xFFFF3B30), // iOS System Red
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                  child: const Text(
                                    '탈퇴하기',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w600,
                                      fontSize: 15,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ).then((confirm) async {
                  // 다이얼로그가 닫힌 후 결과값 처리 (Logic 유지)
                  if (confirm == true) {
                    try {

                      await _authService.deleteUser();

                      // context 유효성 체크
                      if (!context.mounted) return;
                      await context.read<AuthProvider>().logout(context);

                      if (!context.mounted) return;
                      // 로딩 닫기
                      Navigator.pop(context);

                      Navigator.pushAndRemoveUntil(
                        context,
                        MaterialPageRoute(builder: (_) => LoginScreen()),
                            (route) => false,
                      );

                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('회원 탈퇴가 완료되었습니다.')),
                      );
                    } catch (e) {
                      // 로딩 닫기 (에러 발생 시에도)
                      if (context.mounted && Navigator.canPop(context)) {
                        Navigator.pop(context);
                      }

                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('회원 탈퇴 실패: $e')),
                      );
                    }
                  }
                });
              },
            ),
            const SizedBox(height: 50),
          ],
        ),
      ),
    );
  }

  // --- 프로필: Provider 닉네임 표시 ---
  Widget _buildProfileSection(String nickname) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFF7F8FA),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          const CircleAvatar(
            radius: 28,
            backgroundColor: Colors.white,
            child: Icon(CupertinoIcons.person_fill, color: Color(0xFFE0E0E0), size: 30),
          ),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '$nickname 님',
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              Text('취향 분석 데이터 13건 보유 중', style: TextStyle(fontSize: 13, color: _subTextColor)),
            ],
          ),
          const Spacer(),
          // ✅ 수정 → 로그아웃 버튼으로 변경
          InkWell(
            onTap: () async {
              await context.read<AuthProvider>().logout(context);
              if (!context.mounted) return;
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (_) => const SigninScreen()),
                    (route) => false,
              );
            },
            child: Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: const Text(
                '로그아웃',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Colors.black,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF888888))),
    );
  }

  Widget _buildMenuTile({
    required String title,
    String? value,
    IconData? icon,
    Color iconColor = Colors.black,
    bool isLink = true,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      overlayColor: MaterialStateProperty.all(Colors.transparent),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 14),
        child: Row(
          children: [
            if (icon != null) ...[Icon(icon, size: 22, color: iconColor), const SizedBox(width: 12)],
            Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: Colors.black87)),
            const Spacer(),
            if (value != null) Text(value, style: TextStyle(fontSize: 15, color: _primaryColor, fontWeight: FontWeight.w500)),
            if (isLink) ...[const SizedBox(width: 8), const Icon(CupertinoIcons.chevron_right, size: 16, color: Color(0xFFC7C7CC))],
          ],
        ),
      ),
    );
  }

  Widget _buildSwitchTile({required String title, String? subtitle, required bool value, required Function(bool) onChanged}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
                if (subtitle != null) ...[const SizedBox(height: 4), Text(subtitle, style: TextStyle(fontSize: 12, color: _subTextColor))],
              ],
            ),
          ),
          CupertinoSwitch(value: value, activeColor: _primaryColor, onChanged: onChanged),
        ],
      ),
    );
  }

  // 핵심 수정: 콜백(onTap)만 받아서 구분, 회원탈퇴는 강하게 강조
  Widget _buildTextButton(String title, Color color,
      {double fontSize = 14, bool isBold = false, bool isStrong = false, VoidCallback? onTap}) {
    return InkWell(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 14),
        child: Text(
          title,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: fontSize,
            color: color,
            fontWeight: isStrong
                ? FontWeight.bold
                : (isBold ? FontWeight.w600 : FontWeight.w500),
            letterSpacing: -0.5,
          ),
        ),
      ),
    );
  }
}

class AnswerStyleScreen extends StatefulWidget {
  final String initialStyle;
  const AnswerStyleScreen({super.key, required this.initialStyle});

  @override
  State<AnswerStyleScreen> createState() => _AnswerStyleScreenState();
}
class _AnswerStyleScreenState extends State<AnswerStyleScreen> {
  late String selected;
  final List<String> styles = ["간결하게", "친구처럼", "상세하게", "전문가처럼"];

  @override
  void initState() {
    super.initState();
    selected = widget.initialStyle;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.black),
          onPressed: () => Navigator.pop(context, selected),
        ),
        title: const Text("답변 스타일", style: TextStyle(color: Colors.black, fontSize: 17, fontWeight: FontWeight.w600)),
      ),
      body: Column(
        children: styles.map((style) {
          final isSelected = style == selected;
          return InkWell(
            onTap: () => setState(() => selected = style),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: Color(0xFFF0F0F0)))),
              child: Row(
                children: [
                  Text(style, style: TextStyle(fontSize: 16, fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400, color: isSelected ? const Color(0xFF0091EA) : Colors.black87)),
                  const Spacer(),
                  if (isSelected) const Icon(Icons.check, color: Color(0xFF0091EA)),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class RadiusSettingScreen extends StatefulWidget {
  final double initialRadius;
  const RadiusSettingScreen({super.key, required this.initialRadius});
  @override
  State<RadiusSettingScreen> createState() => _RadiusSettingScreenState();
}
class _RadiusSettingScreenState extends State<RadiusSettingScreen> {
  late double radius;
  @override
  void initState() {
    super.initState();
    radius = widget.initialRadius;
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.black),
          onPressed: () => Navigator.pop(context, radius),
        ),
        title: const Text("검색 반경", style: TextStyle(color: Colors.black, fontSize: 17, fontWeight: FontWeight.w600)),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const SizedBox(height: 40),
            Text("${radius.toStringAsFixed(1)}km", style: const TextStyle(fontSize: 40, fontWeight: FontWeight.bold, color: Color(0xFF0091EA))),
            const Text("이 거리 내의 장소를 추천해 드려요", style: TextStyle(color: Colors.grey)),
            const SizedBox(height: 40),
            Slider(
              value: radius,
              min: 0.5,
              max: 5.0,
              divisions: 9,
              activeColor: const Color(0xFF0091EA),
              inactiveColor: const Color(0xFFE0E0E0),
              onChanged: (val) => setState(() => radius = val),
            ),
          ],
        ),
      ),
    );
  }
}
