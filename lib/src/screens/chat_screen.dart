import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

// 모델 및 프로바이더 임포트
import '../models/message.dart';
import '../models/place.dart';
import '../models/conversation.dart';
import '../providers/auth_provider.dart';
import '../providers/bookmark_provider.dart';
import '../providers/location_provider.dart';
import '../services/api_client.dart';
import 'menu_screen.dart';
import 'placesmap_screen.dart';

class ChatScreen extends StatefulWidget {
  final Conversation? initialConversation;

  const ChatScreen({super.key, this.initialConversation});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen>
    with SingleTickerProviderStateMixin {
  final _controller = TextEditingController();
  final _scroll = ScrollController();
  final _api = ApiClient();

  late final AnimationController _menuController;
  late final Animation<Offset> _menuOffset;

  bool _sessionSaved = false;
  bool _loading = false;

  final List<Message> _chatMessages = [];

  bool _isOverlayVisible = false;
  bool _isMapScreen = false;
  bool _isMenuOpen = false;

  final GlobalKey _menuKey = GlobalKey();

  String? _sessionTitle;

  // 슬라이드 인디케이터 상태
  int _currentImagePage = 0;
  PageController? _currentPageController;

  @override
  void initState() {
    super.initState();

    _menuController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 260),
    );

    // 왼쪽에서 오른쪽으로 들어오는 슬라이드
    _menuOffset = Tween<Offset>(
      begin: const Offset(-1.0, 0.0), // 화면 밖 왼쪽
      end: const Offset(0.0, 0.0),    // 제자리
    ).animate(CurvedAnimation(
      parent: _menuController,
      curve: Curves.easeInOutCubic,
    ));

    // 현재 위치 로딩
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<LocationProvider>().loadCurrentLocation();
    });

    // 초기 대화 세션 복원 (메뉴에서 들어온 경우)
    if (widget.initialConversation != null) {
      _restoreConversation(widget.initialConversation!);
    }
  }

  void _restoreConversation(Conversation c) {
    try {
      final List<dynamic> msgList = jsonDecode(c.messagesJson);
      final messages = msgList
          .map((e) => Message.fromJson(e as Map<String, dynamic>))
          .toList();

      setState(() {
        _chatMessages
          ..clear()
          ..addAll(messages);
        _isOverlayVisible = true;
      });
    } catch (e) {
      print("대화 복원 오류: $e");
    }
  }

  @override
  void dispose() {
    _menuController.dispose();
    _controller.dispose();
    _scroll.dispose();
    _currentPageController?.dispose();
    super.dispose();
  }

  // ✅ 현재 채팅 세션 전체 저장
  Future<void> _saveCurrentSession() async {
    if (_sessionSaved) return;
    final userId = (context.read<AuthProvider>().user?.id ?? 0);
    if (_chatMessages.isEmpty) return;

    final firstUserMessage = _chatMessages.firstWhere(
          (m) => m.isUser && (m.text?.isNotEmpty ?? false),
      orElse: () => Message(
        id: '',
        text: '',
        isUser: true,
        createdAt: DateTime.now(),
      ),
    );
    final question = firstUserMessage.text ?? '';
    if (question.isEmpty) return;

    final lastBotMessage = _chatMessages.lastWhere(
          (m) => !m.isUser && (m.text?.isNotEmpty ?? false),
      orElse: () => Message(
        id: '',
        text: '',
        isUser: false,
        createdAt: DateTime.now(),
      ),
    );
    final answer = lastBotMessage.text ?? '';

    final places = _chatMessages
        .where((m) => m.place != null)
        .map((m) => m.place!)
        .toList();

    final title = _sessionTitle ?? question;

    try {
      await _api.saveConversation(
        userId: userId,
        title: title,
        question: question,
        answer: answer,
        places: places,
        messages: _chatMessages,
      );
      _sessionSaved = true;
      if (_menuKey.currentState != null) {
        final state = _menuKey.currentState as dynamic;
        state.loadConversations();
      }
    } catch (e) {
      print('세션 저장 실패: $e');
    }
  }

  Future<void> _send({bool forceShowOverlay = false}) async {
    final text = _controller.text.trim();
    if (text.isEmpty || _loading) return;

    if (_chatMessages.isEmpty) {
      _sessionSaved = false;
      _sessionTitle = null;
    }

    setState(() => _loading = true);
    _controller.clear();

    if (!_isOverlayVisible || forceShowOverlay) {
      setState(() {
        _isOverlayVisible = true;
      });
    }

    setState(() {
      _chatMessages.add(
        Message(
          id: UniqueKey().toString(),
          text: text,
          isUser: true,
          createdAt: DateTime.now(),
        ),
      );
    });

    try {
      final data = await _api.chat(text);
      final reply = (data['reply'] as String?) ?? '죄송해요. 결과가 없어요.';
      final placesJson = (data['places'] as List? ?? []);
      final places = placesJson
          .map((e) => Place.fromJson(e as Map<String, dynamic>))
          .toList();
      final keywordsTitle = data['keywordsTitle'] as String?;
      _sessionTitle = keywordsTitle ?? _sessionTitle ?? text;

      setState(() {
        _chatMessages.add(
          Message(
            id: UniqueKey().toString(),
            text: reply,
            isUser: false,
            createdAt: DateTime.now(),
          ),
        );

        if (places.isNotEmpty) {
          _chatMessages.add(
            Message(
              id: UniqueKey().toString(),
              text: 'HEADER',
              isUser: false,
              createdAt: DateTime.now(),
            ),
          );
        }

        for (final p in places) {
          _chatMessages.add(
            Message(
              id: UniqueKey().toString(),
              place: p,
              isUser: false,
              createdAt: DateTime.now(),
            ),
          );
        }
        _loading = false;
      });

      await Future.delayed(const Duration(milliseconds: 100));
      if (_scroll.hasClients) {
        _scroll.animateTo(
          _scroll.position.maxScrollExtent + 150,
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOut,
        );
      }
    } catch (e, stackTrace) {
      print('API 호출 중 오류 발생: $e\n$stackTrace');
      setState(() {
        _chatMessages.add(
          Message(
            id: UniqueKey().toString(),
            text: '오류가 발생했습니다. 잠시 후 다시 시도해주세요.',
            isUser: false,
            createdAt: DateTime.now(),
          ),
        );
        _loading = false;
      });
    }
  }

  Widget _buildPlaceImages(Place p) {
    final List<String> allImages = [
      if (p.imageUrl != null && p.imageUrl!.isNotEmpty) p.imageUrl!,
      ...(p.imageUrls ?? []).where((url) => url != p.imageUrl),
    ];

    if (allImages.isEmpty) {
      return Container(
        height: 270,
        color: Colors.grey[300],
        child: const Icon(Icons.broken_image, size: 64, color: Colors.grey),
      );
    }

    final pageController = PageController(viewportFraction: 1);

    // 이전에 쓰던 컨트롤러와 다르다면 교체 (간단한 로직)
    if (_currentPageController != pageController) {
      // _currentPageController?.dispose(); // 매번 dispose하면 rebuild시 문제될 수 있어 생략하거나 상태관리 정교화 필요
      _currentPageController = pageController;
    }

    return SizedBox(
      height: 270,
      child: StatefulBuilder(
        builder: (context, setImageState) => Stack(
          alignment: Alignment.center,
          children: [
            PageView.builder(
              controller: pageController,
              itemCount: allImages.length,
              onPageChanged: (i) {
                setImageState(() {
                  _currentImagePage = i;
                });
              },
              itemBuilder: (context, idx) {
                return ClipRRect(
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(16),
                    topRight: Radius.circular(16),
                  ),
                  child: Image.network(
                    allImages[idx],
                    fit: BoxFit.cover,
                    width: double.infinity,
                    errorBuilder: (ctx, error, stack) => Container(
                      color: Colors.grey[300],
                      child: const Icon(Icons.broken_image,
                          size: 64, color: Colors.grey),
                    ),
                  ),
                );
              },
            ),
            if (allImages.length > 1) ...[
              Positioned(
                left: 12,
                child: GestureDetector(
                  onTap: () {
                    pageController.previousPage(
                        duration: const Duration(milliseconds: 200),
                        curve: Curves.easeInOut);
                  },
                  child: CircleAvatar(
                    backgroundColor: Colors.black.withOpacity(0.45),
                    radius: 18,
                    child: const Icon(Icons.arrow_back_ios_new,
                        color: Colors.white, size: 20),
                  ),
                ),
              ),
              Positioned(
                right: 12,
                child: GestureDetector(
                  onTap: () {
                    pageController.nextPage(
                        duration: const Duration(milliseconds: 200),
                        curve: Curves.easeInOut);
                  },
                  child: CircleAvatar(
                    backgroundColor: Colors.black.withOpacity(0.45),
                    radius: 18,
                    child: const Icon(Icons.arrow_forward_ios,
                        color: Colors.white, size: 20),
                  ),
                ),
              ),
            ]
          ],
        ),
      ),
    );
  }

  Widget _buildChatContent() {
    final bookmarkProvider = context.watch<BookmarkProvider>();
    final userId = (context.read<AuthProvider>().user?.id ?? 0);

    return ClipRRect(
      child: Container(
        color: Colors.white,
        child: ListView.builder(
          controller: _scroll,
          // ✅ 수정: 입력창에 가려지지 않도록 하단 패딩(80) 넉넉히 추가
          padding: const EdgeInsets.fromLTRB(10, 10, 10, 80),
          itemCount: _chatMessages.length,
          itemBuilder: (ctx, i) {
            final m = _chatMessages[i];

            if (!m.isUser && m.place == null && m.text == 'HEADER') {
              final headerKeyword = _sessionTitle ?? '';
              return Padding(
                padding: const EdgeInsets.fromLTRB(4, 12, 4, 4),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (headerKeyword.isNotEmpty) ...[
                      Text(
                        headerKeyword,
                        style: const TextStyle(
                          fontSize: 14,
                          color: Color(0xFF4285F4),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                    ],
                    const Text(
                      '이번 약속에 딱 맞는 장소들로 찾아왔어요!',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: Colors.black,
                      ),
                    ),
                    const SizedBox(height: 6),
                  ],
                ),
              );
            }

            if (m.place != null) {
              final p = m.place!;
              final isBookmarked = bookmarkProvider.isBookmarked(p.id);

              return Card(
                color: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20)),
                margin:
                const EdgeInsets.symmetric(vertical: 12, horizontal: 2),
                elevation: 3,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildPlaceImages(p),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(18, 20, 18, 20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Flexible(
                                          child: Text(
                                            p.name ?? '',
                                            style: const TextStyle(
                                                fontSize: 20,
                                                fontWeight: FontWeight.bold),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                        if (p.categoryName != null)
                                          Padding(
                                            padding: const EdgeInsets.only(left: 12),
                                            child: Text(
                                              p.categoryName!,
                                              style: TextStyle(
                                                  color: Colors.grey[700],
                                                  fontSize: 15),
                                            ),
                                          ),
                                      ],
                                    ),
                                    const SizedBox(height: 9),
                                    if (p.openHours != null)
                                      Text(
                                        p.openHours!,
                                        style: TextStyle(
                                          fontSize: 15,
                                          fontWeight: FontWeight.w600,
                                          color: (p.openHours!.contains('영업 중') ||
                                              p.openHours!.contains('곧 영업 종료'))
                                              ? Colors.green
                                              : Colors.red,
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                              GestureDetector(
                                onTap: () {
                                  if (userId == 0) return;
                                  bookmarkProvider.toggleBookmark(userId, p);
                                },
                                child: Icon(
                                  isBookmarked
                                      ? Icons.bookmark
                                      : Icons.bookmark_border,
                                  color: isBookmarked
                                      ? const Color(0xFF4285F4)
                                      : Colors.grey,
                                  size: 32,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 7),
                          if (p.rating != null && p.rating is num)
                            Row(
                              children: [
                                const Icon(Icons.star,
                                    color: Color(0xFFFDB022), size: 18),
                                const SizedBox(width: 3),
                                Text(p.rating!.toStringAsFixed(1),
                                    style: const TextStyle(
                                        color: Color(0xFFFDB022),
                                        fontWeight: FontWeight.bold)),
                              ],
                            ),
                          if (p.phone != null && p.phone!.isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.only(top: 8),
                              child: Text(
                                p.phone!.replaceAll(RegExp(r'[^0-9\-]'), ''),
                                style: const TextStyle(
                                  fontSize: 14.5,
                                  color: Color(0xFF444444),
                                ),
                              ),
                            ),
                          if (p.address != null && p.address!.isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.only(top: 8),
                              child: Text(
                                p.address!,
                                style: const TextStyle(
                                  fontSize: 14.5,
                                  color: Color(0xFF444444),
                                ),
                              ),
                            ),
                          if (p.searchUrl != null && p.searchUrl!.isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.only(top: 8),
                              child: InkWell(
                                onTap: () async {
                                  final url = p.searchUrl!;
                                  if (await canLaunch(url)) {
                                    await launch(url);
                                  }
                                },
                                child: const Text(
                                  '사이트 바로가기',
                                  style: TextStyle(
                                    fontSize: 14.5,
                                    color: Color(0xFF1565C0),
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            }

            return Align(
              alignment: m.isUser ? Alignment.centerRight : Alignment.centerLeft,
              child: Container(
                margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 1),
                padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 14),
                constraints: BoxConstraints(
                    maxWidth: MediaQuery.of(context).size.width * 0.7),
                decoration: BoxDecoration(
                  color: m.isUser
                      ? const Color(0xFFF4F4F4)
                      : const Color(0xFFFFFFFF),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(
                  m.text ?? '',
                  style: const TextStyle(color: Colors.black, fontSize: 15),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildIntroScreen() {
    final currentAddress = context.watch<LocationProvider>().currentAddress;
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Container(
        color: Colors.white,
        width: double.infinity,
        height: double.infinity, // ✅ 수정: 배경을 꽉 채워 회색 배경 노출 방지
        child: Column(
          children: [
            // ✅ 수정: SafeArea 대신 동적 패딩 사용 (상태바 높이 고려)
            Padding(
              padding: EdgeInsets.only(
                  top: MediaQuery.of(context).padding.top,
                  bottom: 12
              ),
              child: Center(
                child: Column(
                  children: [
                    const Text(
                      '현재 위치',
                      style: TextStyle(
                        fontSize: 12,
                        color: Color(0xFF9C9CA5),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      currentAddress,
                      style: const TextStyle(
                        fontSize: 14,
                        color: Color(0xFF484651),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const Spacer(flex: 2),

            // ✅ 수정: 그라데이션 텍스트 표시를 위해 srcIn 모드 추가
            ShaderMask(
              blendMode: BlendMode.srcIn,
              shaderCallback: (bounds) => const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF00CEC2), Color(0xFF007BFF)],
              ).createShader(
                Rect.fromLTWH(0, 0, bounds.width, bounds.height),
              ),
              child: const Text(
                '어떤 약속인가요?\n딱 맞는 장소를 찾아볼게요',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w700,
                  fontFamily: 'Noto Sans',
                  color: Colors.white, // srcIn 모드에서 마스크 영역이 됨
                ),
              ),
            ),
            const SizedBox(height: 22),
            const Text(
              '어디서, 언제, 누구랑, 어떤 약속인지 알려주시면 좋아요',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: Color(0xFF96979C),
                fontWeight: FontWeight.w700,
              ),
            ),
            const Spacer(flex: 3),
          ],
        ),
      ),
    );
  }

  Widget _buildInputField() {
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Padding(
        padding: EdgeInsets.only(
          // 키보드가 올라올 때 하단 패딩 확보
          bottom: MediaQuery.of(context).viewInsets.bottom + 10,
          left: 16,
          right: 16,
          top: 10,
        ),
        child: Container(
          height: 46,
          decoration: BoxDecoration(
            color: const Color(0xFFF3F3F3),
            borderRadius: BorderRadius.circular(30),
            border: Border.all(width: 1.6, color: const Color(0xFFF3F3F3)),
          ),
          child: Row(
            children: [
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(left: 19, right: 10),
                  child: TextField(
                    controller: _controller,
                    decoration: const InputDecoration(
                      border: InputBorder.none,
                      hintText: '찾고 싶은 곳에 대해 알려주세요',
                      hintStyle: TextStyle(
                          color: Color(0xFF9E9E9E), fontSize: 14),
                    ),
                    onSubmitted: (_) => _send(forceShowOverlay: true),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(right: 2, left: 2),
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    elevation: 0,
                    backgroundColor: const Color(0xFF98989A),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(28)),
                    padding: EdgeInsets.zero,
                    minimumSize: const Size(32, 32),
                  ),
                  onPressed: _loading ? null : () => _send(forceShowOverlay: true),
                  child: const Icon(Icons.arrow_upward,
                      color: Colors.black, size: 22),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTopButtons() {
    if (_isOverlayVisible) {
      final hasPlaces = _chatMessages.any(
            (m) => m.place != null && m.place!.lat != null && m.place!.lng != null,
      );

      return Positioned(
        top: MediaQuery.of(context).padding.top,
        left: 0,
        right: 0,
        child: Container(
          color: Colors.white.withOpacity(0.95),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back_ios_new, size: 18),
                onPressed: () async {
                  await _saveCurrentSession();
                  setState(() {
                    _isOverlayVisible = false;
                    _chatMessages.clear();
                  });
                },
              ),
              const Spacer(),
              if (hasPlaces && !_isMapScreen)
                const Padding(
                  padding: EdgeInsets.only(right: 8),
                  child: SpeechBubble(text: "지도에서 위치를 확인해 보세요"),
                ),
              IconButton(
                icon: Icon(
                  Icons.map_outlined,
                  size: 24,
                  color: _isMapScreen ? Colors.blue : Colors.black,
                ),
                onPressed: () {
                  final places = _chatMessages
                      .where((m) => m.place != null && m.place!.lat != null)
                      .map((m) => m.place!)
                      .toList();
                  if (places.isNotEmpty) {
                    Navigator.push(context, MaterialPageRoute(builder: (_) => PlacesMapScreen(places: places)));
                  }
                },
              ),
            ],
          ),
        ),
      );
    }

    return Positioned(
      top: MediaQuery.of(context).padding.top,
      left: 16,
      child: IconButton(
        icon: const Icon(Icons.menu, size: 28),
        onPressed: () {
          if (_menuKey.currentState != null) {
            ( _menuKey.currentState as dynamic).loadConversations();
          }
          setState(() => _isMenuOpen = true);
          _menuController.forward(from: 0); // 👈 열릴 때 애니메이
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final statusBarTop = MediaQuery.of(context).padding.top;
    const menuWidth = 315.0;

    return Scaffold(
      backgroundColor: Colors.white,
      // ✅ 수정: 키보드가 올라와도 배경/레이아웃이 찌그러지지 않도록 false 설정
      resizeToAvoidBottomInset: false,
      body: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => FocusScope.of(context).unfocus(),
        child: Stack(
          children: [
            if (!_isOverlayVisible) _buildIntroScreen(),

            AnimatedPositioned(
              duration: const Duration(milliseconds: 180),
              curve: Curves.easeOut,
              left: 0,
              right: 0,
              top: _isOverlayVisible ? statusBarTop + 40 : screenHeight,
              bottom: 0,
              child: _buildChatContent(),
            ),

            if (_loading)
              Positioned.fill(
                child: Container(
                  color: Colors.white.withOpacity(0.8),
                  child: Center(
                    child: Lottie.network(
                      "https://lottie.host/91c40b97-5b24-4e20-add4-80ac0e9ae68c/apFwQmJv9c.json",
                      width: 400,
                      height: 400,
                    ),
                  ),
                ),
              ),

            if (_isMenuOpen)
              Positioned(
                left: 0,
                right: 0,
                top: statusBarTop,
                bottom: 0,
                child: GestureDetector(
                  onTap: () {
                    _menuController.reverse();        // 👈 먼저 닫는 애니메이션
                    Future.delayed(const Duration(milliseconds: 100), () {
                      if (mounted) {
                        setState(() => _isMenuOpen = false);
                      }
                    });
                  },
                  child: Container(color: Colors.black.withOpacity(0.7)),
                ),
              ),

            // 메뉴 탭 (SlideTransition)
            if (_isMenuOpen)
              Positioned(
                top: 0,
                bottom: 0,
                left: 0,
                width: menuWidth,
                child: SafeArea(
                  child: SlideTransition(
                    position: _menuOffset,  // 👈 여기서 슬라이드
                    child: Material(
                      elevation: 8,
                      child: MenuScreen(
                        key: _menuKey,
                        onConversationSelected: (conv) async {
                          // 메뉴 닫기 애니메이션
                          _menuController.reverse();
                          await Future.delayed(const Duration(milliseconds: 100));
                          if (mounted) {
                            setState(() => _isMenuOpen = false);
                          }
                          if (_isOverlayVisible) {
                            setState(() => _isOverlayVisible = false);
                          }
                          _restoreConversation(conv);
                        },
                      ),
                    ),
                  ),
                ),
              ),

            // 입력창 (가장 하단에 고정)
            Align(
              alignment: Alignment.bottomCenter,
              child: Container(
                color: Colors.white,
                child: _buildInputField(),
              ),
            ),

            // 상단 버튼들
            if (!_isMenuOpen) _buildTopButtons(),
          ],
        ),
      ),
    );
  }
}

class SpeechBubble extends StatelessWidget {
  final String text;

  const SpeechBubble({super.key, required this.text});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _BubblePainter(),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        child: Text(
          text,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 13,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }
}

class _BubblePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = const Color(0xFF007AFF);
    final rrect = RRect.fromRectAndRadius(
      Rect.fromLTWH(0, 0, size.width, size.height),
      const Radius.circular(12),
    );
    canvas.drawRRect(rrect, paint);

    // 말풍선 꼬리 그리기
    final path = Path();
    path.moveTo(size.width - 4, size.height / 2 - 4);
    path.lineTo(size.width + 6, size.height / 2);
    path.lineTo(size.width - 4, size.height / 2 + 4);
    path.close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}