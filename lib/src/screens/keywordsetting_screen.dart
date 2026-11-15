import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../services/api_client.dart';

class KeywordSettingScreen extends StatefulWidget {
  const KeywordSettingScreen({super.key});
  @override
  State<KeywordSettingScreen> createState() => _KeywordSettingScreenState();
}

enum KeywordTab { like, dislike }

class _KeywordSettingScreenState extends State<KeywordSettingScreen> {
  // 탭별 키워드 리스트
  final List<String> likedKeywords = [];
  final List<String> dislikedKeywords = [];

  final TextEditingController _controller = TextEditingController();
  bool _loading = false;
  KeywordTab _currentTab = KeywordTab.like;

  @override
  void initState() {
    super.initState();
    _loadFromServer();
  }

  List<String> get _currentList =>
      _currentTab == KeywordTab.like ? likedKeywords : dislikedKeywords;

  Future<void> _loadFromServer() async {
    final userId = (context.read<AuthProvider>().user?.id ?? 0);
    print('🔑 keyword userId=$userId (${userId.runtimeType})');

    setState(() => _loading = true);
    try {
      final api = ApiClient();
      final likeList = await api.loadLikeKeywords(userId);
      final dislikeList = await api.loadDislikeKeywords(userId);

      if (!mounted) return;
      setState(() {
        likedKeywords
          ..clear()
          ..addAll(likeList);
        dislikedKeywords
          ..clear()
          ..addAll(dislikeList);
      });
    } catch (e) {
      // 실패 시 무시
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _saveToServer() async {
    final userId = (context.read<AuthProvider>().user?.id ?? 0);
    print('🔑 keyword userId=$userId (${userId.runtimeType})');

    try {
      final api = ApiClient();
      await api.saveLikeKeywords(userId, likedKeywords);
      await api.saveDislikeKeywords(userId, dislikedKeywords);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('키워드 저장 실패, 잠시 후 다시 시도해주세요.')),
      );
    }
  }

  void _addKeyword() {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    final list = _currentList;
    if (list.contains(text)) return;

    setState(() {
      list.add(text);
    });
    _controller.clear();
    _saveToServer();
  }

  void _removeKeyword(String k) {
    setState(() {
      _currentList.remove(k);
    });
    _saveToServer();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final List<String> showing = _currentList;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.black),
          onPressed: () async {
            await _saveToServer();
            if (!mounted) return;
            Navigator.pop(context);
          },
        ),
        title: const Text(
          "취향 키워드",
          style: TextStyle(color: Colors.black, fontSize: 17, fontWeight: FontWeight.w600),
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("취향 키워드",
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const Text(
              "대화에서 언급된 공간/음식 관련 키워드",
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.normal,
                color: Color(0xFF7C7C7C),
              ),
            ),
            const SizedBox(height: 20),

            // ✅ 좋아해요 / 싫어해요 탭
            Container(
              height: 56,
              decoration: BoxDecoration(
                color: const Color(0xFFF7F8FA),
                borderRadius: BorderRadius.circular(30),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() => _currentTab = KeywordTab.like),
                      child: Container(
                        margin: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: _currentTab == KeywordTab.like
                              ? const Color(0xFFFFFFFF)
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(26),
                        ),
                        child: Center(
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                CupertinoIcons.heart_solid,
                                size: 18,
                                color: _currentTab == KeywordTab.like
                                    ? const Color(0xFFF36461)
                                    : const Color(0xFFB0B0B0),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                '좋아해요',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: _currentTab == KeywordTab.like
                                      ? const Color(0xFFF36461)
                                      : const Color(0xFFB0B0B0),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() => _currentTab = KeywordTab.dislike),
                      child: Container(
                        margin: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: _currentTab == KeywordTab.dislike
                              ? const Color(0xFFFFFFFF)
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(26),
                        ),
                        child: Center(
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                CupertinoIcons.heart_slash_fill,
                                size: 18,
                                color: _currentTab == KeywordTab.dislike
                                    ? const Color(0xFF8E8E93)
                                    : const Color(0xFFB0B0B0),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                '싫어해요',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: _currentTab == KeywordTab.dislike
                                      ? const Color(0xFF8E8E93)
                                      : const Color(0xFFB0B0B0),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: showing.map((k) {
                final bool isLike = _currentTab == KeywordTab.like;
                final Color bgColor =
                isLike ? const Color(0xFFFFEEF0) : const Color(0xFFF0F0F5);
                final Color textColor =
                isLike ? const Color(0xFFF36461) : const Color(0xFF8E8E93);

                return Chip(
                  label: Text(
                    k,
                    style: TextStyle(
                      color: textColor,          // ✅ 좋아요/싫어요에 따라 텍스트 색 변경
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  backgroundColor: bgColor,      // ✅ 탭에 맞는 배경 색
                  deleteIcon: Icon(
                    Icons.close,
                    size: 16,
                    color: textColor,            // x 아이콘 색도 맞추기 (옵션)
                  ),
                  onDeleted: () => _removeKeyword(k),
                  shape: const StadiumBorder(
                    side: BorderSide(
                      color: Colors.transparent,   // ✅ 완전 투명 테두리
                      width: 0,
                    ),
                  ),
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                );
              }).toList(),
            ),

            const SizedBox(height: 20),

            // 입력 박스 + 플러스 버튼
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              height: 50,
              decoration: BoxDecoration(
                color: const Color(0xFFF7F8FA),
                borderRadius: BorderRadius.circular(25),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      decoration: const InputDecoration(
                        hintText: "공간/음식 키워드 입력",
                        border: InputBorder.none,
                      ),
                      onSubmitted: (_) => _addKeyword(),
                    ),
                  ),
                  GestureDetector(
                    onTap: _addKeyword,
                    child: const Icon(
                      Icons.add_circle,
                      color: Color(0xFF0091EA),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
