import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart'; // 아이콘 및 iOS 스타일 사용

import '../models/signup_request.dart';
import '../services/auth_service.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> with TickerProviderStateMixin {
  final AuthService _authService = AuthService();
  final TextEditingController idController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController passwordConfirmController = TextEditingController();
  final TextEditingController nicknameController = TextEditingController();
  final TextEditingController birthController = TextEditingController();
  final TextEditingController emailCodeController = TextEditingController();

  // --- 애니메이션 컨트롤러 정의 ---
  late final AnimationController _nicknameController;
  late final AnimationController _birthController;
  late final AnimationController _genderController;
  late final AnimationController _restController;
  late final AnimationController _submitController;

  late final Animation<Offset> _nicknameOffset;
  late final Animation<Offset> _birthOffset;
  late final Animation<Offset> _genderOffset;
  late final Animation<Offset> _restOffset;
  late final Animation<Offset> _submitOffset;

  late final Animation<double> _nicknameOpacity;
  late final Animation<double> _birthOpacity;
  late final Animation<double> _genderOpacity;
  late final Animation<double> _restOpacity;
  late final Animation<double> _submitOpacity;

  // --- 상태 변수 ---
  bool mandatoryComplete = false;
  bool nicknameChecked = false;
  bool canUseNickname = false;
  bool birthComplete = false;
  bool genderComplete = false;
  bool emailVerified = false;
  bool termsAgreed = false;
  bool privacyAgreed = false;
  bool showSubmitButton = false;
  String selectedGender = '';
  String? passwordMatchMessage;
  Color? passwordMatchColor;

  @override
  void initState() {
    super.initState();
    idController.addListener(checkMandatoryFields);
    passwordController.addListener(checkMandatoryFields);
    passwordConfirmController.addListener(checkMandatoryFields);
    nicknameController.addListener(onNicknameChanged);
    birthController.addListener(checkBirthComplete);

    // 애니메이션 초기화 (기존 코드와 동일)
    _nicknameController = AnimationController(vsync: this, duration: Duration(milliseconds: 300));
    _birthController = AnimationController(vsync: this, duration: Duration(milliseconds: 300));
    _genderController = AnimationController(vsync: this, duration: Duration(milliseconds: 300));
    _restController = AnimationController(vsync: this, duration: Duration(milliseconds: 300));
    _submitController = AnimationController(vsync: this, duration: Duration(milliseconds: 300));

    _nicknameOffset = Tween<Offset>(begin: Offset(0, -0.2), end: Offset.zero).animate(CurvedAnimation(parent: _nicknameController, curve: Curves.easeOut));
    _nicknameOpacity = Tween<double>(begin: 0, end: 1).animate(_nicknameController);

    _birthOffset = Tween<Offset>(begin: Offset(0, -0.2), end: Offset.zero).animate(CurvedAnimation(parent: _birthController, curve: Curves.easeOut));
    _birthOpacity = Tween<double>(begin: 0, end: 1).animate(_birthController);

    _genderOffset = Tween<Offset>(begin: Offset(0, -0.2), end: Offset.zero).animate(CurvedAnimation(parent: _genderController, curve: Curves.easeOut));
    _genderOpacity = Tween<double>(begin: 0, end: 1).animate(_genderController);

    _restOffset = Tween<Offset>(begin: Offset(0, -0.2), end: Offset.zero).animate(CurvedAnimation(parent: _restController, curve: Curves.easeOut));
    _restOpacity = Tween<double>(begin: 0, end: 1).animate(_restController);

    _submitOffset = Tween<Offset>(begin: Offset(0, -0.2), end: Offset.zero).animate(CurvedAnimation(parent: _submitController, curve: Curves.easeOut));
    _submitOpacity = Tween<double>(begin: 0, end: 1).animate(_submitController);
  }

  @override
  void dispose() {
    idController.dispose();
    passwordController.dispose();
    passwordConfirmController.dispose();
    nicknameController.dispose();
    birthController.dispose();
    _nicknameController.dispose();
    _birthController.dispose();
    _genderController.dispose();
    _restController.dispose();
    _submitController.dispose();
    emailCodeController.dispose();
    super.dispose();
  }

  // --- 기존 로직 함수들 ---
  void checkMandatoryFields() {
    final idFilled = idController.text.isNotEmpty && emailVerified;
    final pwFilled = passwordController.text.isNotEmpty;
    final pwConfirmFilled = passwordConfirmController.text.isNotEmpty;
    final passwordsMatch = passwordController.text == passwordConfirmController.text;

    setState(() {
      if (pwFilled && pwConfirmFilled) {
        if (passwordsMatch) {
          passwordMatchMessage = '비밀번호가 일치합니다';
          passwordMatchColor = Colors.green;
        } else {
          passwordMatchMessage = '비밀번호가 일치하지 않습니다';
          passwordMatchColor = Colors.red;
        }
      } else {
        passwordMatchMessage = null;
        passwordMatchColor = null;
      }
    });

    final shouldShow = idFilled && pwFilled && pwConfirmFilled && passwordsMatch;

    if (shouldShow != mandatoryComplete) {
      setState(() {
        mandatoryComplete = shouldShow;
      });
      if (shouldShow)
        _nicknameController.forward();
      else {
        _nicknameController.reverse();
        _birthController.reverse();
        _genderController.reverse();
        _restController.reverse();
        _submitController.reverse();
        setState(() {
          nicknameChecked = false;
          canUseNickname = false;
          birthComplete = false;
          genderComplete = false;
        });
      }
    }
  }

  void onNicknameChanged() {
    setState(() {
      nicknameChecked = false;
      canUseNickname = false;
      _birthController.reverse();
      birthComplete = false;
      genderComplete = false;
      _genderController.reverse();
      _restController.reverse();
      _submitController.reverse();
    });
  }

  void checkBirthComplete() {
    final filled = birthController.text.length == 8;
    if (filled != birthComplete) {
      setState(() {
        birthComplete = filled;
      });
      if (filled)
        _genderController.forward();
      else {
        _genderController.reverse();
        _restController.reverse();
        _submitController.reverse();
        setState(() {
          genderComplete = false;
        });
      }
    }
  }

  void onGenderSelected(String gender) {
    if (gender != selectedGender) {
      setState(() {
        selectedGender = gender;
        genderComplete = true;
      });
      _restController.forward();
    }
  }

  void onAgreedChanged(String key, bool? value) {
    setState(() {
      if (key == "terms") termsAgreed = value ?? false;
      if (key == "privacy") privacyAgreed = value ?? false;
      bool shouldShow = termsAgreed && privacyAgreed;
      if (shouldShow && !(showSubmitButton)) {
        showSubmitButton = true;
        _submitController.forward();
      } else if (!shouldShow && showSubmitButton) {
        showSubmitButton = false;
        _submitController.reverse();
      }
    });
  }

  // --- [UI Helper] 커스텀 스낵바 (메세지) ---
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

    ScaffoldMessenger.of(context).hideCurrentSnackBar(); // 기존꺼 숨김
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

  // --- [UI Helper] 이메일 인증 다이얼로그 (수정됨) ---
  Future<bool?> _showEmailVerificationDialog() {
    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        elevation: 0,
        backgroundColor: Colors.white,
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                '이메일 인증',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              const Text(
                '이메일로 전송된 인증번호 6자리를\n입력해주세요.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Color(0xFF8E8E93), fontSize: 14, height: 1.5),
              ),
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: const Color(0xFFF7F8FA),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: TextField(
                  controller: emailCodeController,
                  keyboardType: TextInputType.number, // 숫자 키패드
                  maxLength: 6, // 6자리 제한
                  buildCounter: (context, {required currentLength, required isFocused, maxLength}) => null, // 하단 카운터(0/6) 숨김
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 18, letterSpacing: 5, fontWeight: FontWeight.bold), // 자간 넓혀서 번호 잘 보이게
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                    hintText: '000000',
                    hintStyle: TextStyle(color: Color(0xFFC1C1C1), letterSpacing: 5),
                    counterText: "", // 카운터 텍스트 제거 (이중 안전장치)
                  ),
                ),
              ),
              const SizedBox(height: 28),
              Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: () => Navigator.pop(ctx, false),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        backgroundColor: const Color(0xFFF2F4F6),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Text('취소', style: TextStyle(color: Colors.black87, fontWeight: FontWeight.w600)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextButton(
                      onPressed: () => Navigator.pop(ctx, true),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        backgroundColor: Colors.black,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Text('확인', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // --- [UI Helper] 회원가입 성공 다이얼로그 ---
  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        backgroundColor: Colors.white,
        child: Padding(
          padding: const EdgeInsets.all(30),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(CupertinoIcons.checkmark_alt, color: Colors.green, size: 40),
              ),
              const SizedBox(height: 20),
              const Text(
                '회원가입 완료!',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              const Text(
                '성공적으로 가입되었습니다.\n로그인 화면으로 이동합니다.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Color(0xFF8E8E93), height: 1.5),
              ),
              const SizedBox(height: 30),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(ctx); // 다이얼로그 닫기
                    Navigator.pop(context); // 회원가입 화면 닫기 (로그인 화면으로)
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                    elevation: 0,
                  ),
                  child: const Text('로그인하러 가기', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // 이메일 형식 간단 검사용 함수 (클래스 안에 추가)
  bool _isValidEmail(String email) {
    final regex = RegExp(r'^[^@]+@[^@]+\.[^@]+');  // 간단한 이메일 패턴
    return regex.hasMatch(email);
  }

  Widget buildIdField() {
    return Row(
      children: [
        Expanded(
          flex: 3,
          child: TextField(
            controller: idController,
            decoration: const InputDecoration(
              labelText: '아이디 (이메일 주소)',
              labelStyle: TextStyle(color: Color(0xFF939393), fontSize: 20),
              enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Color(0xFFC1C1C1), width: 2)),
              focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.black, width: 2)),
            ),
            style: const TextStyle(fontSize: 20),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          flex: 1,
          child: OutlinedButton(
            // buildIdField 안의 OutlinedButton.onPressed 수정
            onPressed: () async {
              final email = idController.text.trim();

              // 1) 비어있는지 체크
              if (email.isEmpty) {
                _showCustomSnackBar('이메일을 입력해주세요.', isError: true);
                return;
              }

              // 2) 이메일 형식 체크
              if (!_isValidEmail(email)) {
                _showCustomSnackBar('올바른 이메일 형식을 입력해주세요.', isError: true);
                return;
              }

              try {
                // 3) 백엔드에 이메일 중복 확인 API 호출
                final isDuplicate = await _authService.checkEmailDuplicate(email);

                if (isDuplicate) {
                  _showCustomSnackBar('이미 가입된 이메일입니다.', isError: true);
                  return;
                }

                // 4) 여기까지 통과하면 인증 코드 전송
                await _authService.sendEmailVerification(email);
                if (!mounted) return;
                _showCustomSnackBar('인증 코드가 전송되었습니다.', isSuccess: true);

                // 5) 다이얼로그 열고 코드 입력 받기
                emailCodeController.clear();
                final ok = await _showEmailVerificationDialog();

                if (ok == true) {
                  final code = emailCodeController.text.trim();

                  if (code.isEmpty) {
                    _showCustomSnackBar('인증코드를 입력해주세요.', isError: true);
                    return;
                  }
                  if (code.length != 6) {
                    _showCustomSnackBar('인증코드는 6자리 숫자입니다.', isError: true);
                    return;
                  }

                  final result = await _authService.verifySignupCode(email, code);
                  if (!mounted) return;

                  final verified = result['verified'] == true;
                  final message = result['message']?.toString() ?? '';

                  if (verified) {
                    setState(() => emailVerified = true);
                    _showCustomSnackBar('이메일 인증이 완료되었습니다.', isSuccess: true);
                  } else {
                    String errorMessage = '인증코드가 올바르지 않습니다.';
                    if (message.toLowerCase().contains('expire')) {
                      errorMessage = '인증 시간이 만료되었습니다. 다시 시도해주세요.';
                    } else if (message.isNotEmpty) {
                      errorMessage = message.length > 30 ? '인증 정보를 확인해주세요.' : message;
                    }
                    _showCustomSnackBar(errorMessage, isError: true);
                  }
                }
              } catch (e) {
                if (!mounted) return;
                debugPrint("❌ Email Verification Error: $e");
                _showCustomSnackBar(
                  '서버 연결 중 오류가 발생했습니다.\n잠시 후 다시 시도해주세요.',
                  isError: true,
                );
              }
            },
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: Color(0xFF36324D), width: 2),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
            child: const Text(
              '인증하기',
              style: TextStyle(color: Color(0xFF36324D), fontSize: 16, fontWeight: FontWeight.w700, fontFamily: 'Noto Sans', letterSpacing: -0.88),
            ),
          ),
        ),
      ],
    );
  }

  Widget buildNicknameField() {
    return Row(
      children: [
        Expanded(
          flex: 3,
          child: TextField(
            controller: nicknameController,
            decoration: const InputDecoration(
              labelText: '이름 (닉네임)',
              labelStyle: TextStyle(color: Color(0xFF939393), fontSize: 20),
              enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Color(0xFFC1C1C1), width: 2)),
              focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.black, width: 2)),
            ),
            style: const TextStyle(fontSize: 20),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          flex: 1,
          child: OutlinedButton(
            onPressed: () async {
              final nickname = nicknameController.text.trim();
              if (nickname.isEmpty) {
                _showCustomSnackBar('닉네임을 입력해주세요.', isError: true);
                return;
              }

              try {
                final isDuplicate = await _authService.checkNickname(nickname);

                setState(() {
                  nicknameChecked = true;
                  canUseNickname = !isDuplicate;
                  if (canUseNickname) {
                    _birthController.forward();
                  } else {
                    _birthController.reverse();
                    birthComplete = false;
                    genderComplete = false;
                    _genderController.reverse();
                    _restController.reverse();
                    _submitController.reverse();
                  }
                });

                if (isDuplicate) {
                  _showCustomSnackBar('이미 사용중인 닉네임입니다.', isError: true);
                } else {
                  _showCustomSnackBar('사용 가능한 닉네임입니다!', isSuccess: true);
                }
              } catch (e) {
                _showCustomSnackBar('중복확인 오류: $e', isError: true);
              }
            },
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: Color(0xFF000000), width: 2),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
            child: const Text(
              '중복확인',
              style: TextStyle(color: Color(0xFF000000), fontSize: 16, fontWeight: FontWeight.w700, fontFamily: 'Noto Sans', letterSpacing: -0.88),
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 26, vertical: 120),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '회원가입',
                  style: TextStyle(color: Color(0xFF5C5C60), fontSize: 24, fontFamily: 'Noto Sans', fontWeight: FontWeight.w700, letterSpacing: -0.96),
                ),
                const SizedBox(height: 40),
                buildIdField(),
                const SizedBox(height: 30),
                TextField(
                  controller: passwordController,
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: '비밀번호',
                    labelStyle: TextStyle(color: Color(0xFF939393), fontSize: 20),
                    enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Color(0xFFC1C1C1), width: 2)),
                    focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.black, width: 2)),
                  ),
                  style: const TextStyle(fontSize: 20),
                ),
                const SizedBox(height: 30),
                TextField(
                  controller: passwordConfirmController,
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: '비밀번호 확인',
                    labelStyle: TextStyle(color: Color(0xFF939393), fontSize: 20),
                    enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Color(0xFFC1C1C1), width: 2)),
                    focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.black, width: 2)),
                  ),
                  style: const TextStyle(fontSize: 20),
                ),
                if (passwordMatchMessage != null)
                  Padding(
                    padding: const EdgeInsets.only(left: 4, top: 6),
                    child: Text(
                      passwordMatchMessage!,
                      style: TextStyle(color: passwordMatchColor, fontSize: 14, fontWeight: FontWeight.w600),
                    ),
                  ),
                const SizedBox(height: 30),

                // 닉네임 폼
                AnimatedBuilder(
                  animation: _nicknameController,
                  builder: (context, child) => Opacity(
                    opacity: _nicknameOpacity.value,
                    child: FractionalTranslation(translation: _nicknameOffset.value, child: child),
                  ),
                  child: mandatoryComplete
                      ? Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      buildNicknameField(),
                      const SizedBox(height: 30),
                    ],
                  )
                      : const SizedBox.shrink(),
                ),

                // 생년월일 폼
                AnimatedBuilder(
                  animation: _birthController,
                  builder: (context, child) => Opacity(
                    opacity: _birthOpacity.value,
                    child: FractionalTranslation(translation: _birthOffset.value, child: child),
                  ),
                  child: (nicknameChecked && canUseNickname)
                      ? Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      TextField(
                        controller: birthController,
                        decoration: const InputDecoration(
                          labelText: '생년월일 (8자리 입력, 예: 19900101)',
                          labelStyle: TextStyle(color: Color(0xFF939393), fontSize: 20),
                          enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Color(0xFFC1C1C1), width: 2)),
                          focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.black, width: 2)),
                        ),
                        style: const TextStyle(fontSize: 20),
                        keyboardType: TextInputType.number,
                      ),
                      const SizedBox(height: 30),
                    ],
                  )
                      : const SizedBox.shrink(),
                ),

                // 성별 폼
                AnimatedBuilder(
                  animation: _genderController,
                  builder: (context, child) => Opacity(
                    opacity: _genderOpacity.value,
                    child: FractionalTranslation(translation: _genderOffset.value, child: child),
                  ),
                  child: birthComplete
                      ? Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () => onGenderSelected('male'),
                              style: OutlinedButton.styleFrom(
                                side: const BorderSide(color: Color(0xFF000000), width: 2),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                                padding: const EdgeInsets.symmetric(vertical: 14),
                                backgroundColor: selectedGender == 'male' ? const Color(0xFF000000) : null,
                              ),
                              child: Text(
                                '남성',
                                style: TextStyle(
                                  color: selectedGender == 'male' ? Colors.white : const Color(0xFF000000),
                                  fontSize: 20,
                                  fontWeight: FontWeight.w700,
                                  fontFamily: 'Noto Sans',
                                  letterSpacing: -0.88,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 20),
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () => onGenderSelected('female'),
                              style: OutlinedButton.styleFrom(
                                side: const BorderSide(color: Color(0xFF000000), width: 2),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                                padding: const EdgeInsets.symmetric(vertical: 14),
                                backgroundColor: selectedGender == 'female' ? const Color(0xFF000000) : null,
                              ),
                              child: Text(
                                '여성',
                                style: TextStyle(
                                  color: selectedGender == 'female' ? Colors.white : const Color(0xFF000000),
                                  fontSize: 20,
                                  fontWeight: FontWeight.w700,
                                  fontFamily: 'Noto Sans',
                                  letterSpacing: -0.88,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 40),
                    ],
                  )
                      : const SizedBox.shrink(),
                ),

                // 약관 및 완료 버튼
                AnimatedBuilder(
                  animation: _restController,
                  builder: (context, restChild) => Opacity(
                    opacity: _restOpacity.value,
                    child: FractionalTranslation(
                      translation: _restOffset.value,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Checkbox(
                                value: termsAgreed,
                                onChanged: (v) => onAgreedChanged("terms", v),
                                fillColor: MaterialStateProperty.resolveWith<Color>((states) {
                                  if (states.contains(MaterialState.selected)) {
                                    return Colors.black;
                                  }
                                  return Colors.white;
                                }),
                                side: const BorderSide(width: 2, color: Colors.black),
                              ),
                              const Text('이용약관 동의', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, fontFamily: 'Noto Sans', color: Colors.black87)),
                            ],
                          ),
                          Row(
                            children: [
                              Checkbox(
                                value: privacyAgreed,
                                onChanged: (v) => onAgreedChanged("privacy", v),
                                fillColor: MaterialStateProperty.resolveWith<Color>((states) {
                                  if (states.contains(MaterialState.selected)) {
                                    return Colors.black;
                                  }
                                  return Colors.white;
                                }),
                                side: const BorderSide(width: 2, color: Colors.black),
                              ),
                              const Text('개인정보 취급 방침 동의', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, fontFamily: 'Noto Sans', color: Colors.black87)),
                            ],
                          ),
                          const SizedBox(height: 40),

                          // 회원가입 완료 버튼
                          AnimatedBuilder(
                            animation: _submitController,
                            builder: (context, submitChild) => Opacity(
                              opacity: _submitOpacity.value,
                              child: FractionalTranslation(
                                translation: _submitOffset.value,
                                child: showSubmitButton
                                    ? SizedBox(
                                  width: double.infinity,
                                  height: 50,
                                  child: ElevatedButton(
                                    onPressed: () async {
                                      try {
                                        // 로딩 처리 (필요시 추가)
                                        await _authService.signup(
                                          SignupRequest(
                                            email: idController.text,
                                            password: passwordController.text,
                                            nickname: nicknameController.text,
                                            birth: birthController.text,
                                            gender: selectedGender,
                                            agree1: termsAgreed,
                                            agree2: privacyAgreed,
                                          ),
                                        );

                                        // 성공 다이얼로그 호출
                                        if (!mounted) return;
                                        _showSuccessDialog();

                                      } catch (e) {
                                        // 에러 스낵바 호출
                                        _showCustomSnackBar('회원가입 실패: $e', isError: true);
                                      }
                                    },
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color(0xFF000000),
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                                    ),
                                    child: const Text(
                                      '회원가입',
                                      style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700, fontFamily: 'Noto Sans', letterSpacing: -0.88, color: Colors.white),
                                    ),
                                  ),
                                )
                                    : const SizedBox.shrink(),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  child: const SizedBox.shrink(),
                ),
              ],
            ),
          ),

          // 뒤로가기 버튼
          SafeArea(
            child: Align(
              alignment: Alignment.topLeft,
              child: Padding(
                padding: const EdgeInsets.only(left: 4, top: 4),
                child: IconButton(
                  icon: const Icon(Icons.arrow_back_ios_new, color: Colors.black),
                  onPressed: () => Navigator.of(context).pop(),
                  tooltip: '뒤로가기',
                  splashRadius: 22,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}