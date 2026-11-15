import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:the_place/src/providers/auth_provider.dart';
import 'package:the_place/src/screens/setting_screen.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models/place.dart'; // Place 모델이 필요하므로 추가 (경로 확인 필요)
import '../providers/bookmark_provider.dart';
import '../providers/recommend_provider.dart';
import '../services/api_client.dart';
import 'bookmark_screen.dart';
import 'keywordsetting_screen.dart';

enum KeywordTab { like, dislike }

class MyScreen extends StatefulWidget {
  const MyScreen({super.key});

  @override
  MyScreenState createState() => MyScreenState();
}

class MyScreenState extends State<MyScreen> {
  int _visitedPlacesCount = 0;
  final List<String> likedKeywords = [];
  final List<String> dislikedKeywords = [];
  KeywordTab _currentTab = KeywordTab.like;

  List<String> get _currentKeywordList =>
      _currentTab == KeywordTab.like ? likedKeywords : dislikedKeywords;

  @override
  void initState() {
    super.initState();
    refreshAll();
  }

  Future<void> refreshAll() async {
    await _loadVisitedPlacesCount();
    await _loadPreferenceKeywords();
  }

  Future<void> _loadVisitedPlacesCount() async {
    final user = context.read<AuthProvider>().user;
    final userId = user?.id;
    if (userId == null) return;
    try {
      final api = ApiClient();
      final count = await api.loadTotalPlacesCount(userId);
      if (!mounted) return;
      setState(() => _visitedPlacesCount = count);
    } catch (e) {
      if (!mounted) return;
      setState(() => _visitedPlacesCount = 0);
    }
  }

  Future<void> _loadPreferenceKeywords() async {
    final user = context.read<AuthProvider>().user;
    final userId = user?.id;
    if (userId == null) return;
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
    } catch (e) {}
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user;
    final nickname = user?.nickname ?? '사용자';
    int daysAgo = 0;
    if (user?.createdAt != null) {
      daysAgo = DateTime.now().difference(user!.createdAt).inDays + 1;
    }

    final bookmarkCount = context.watch<BookmarkProvider>().bookmarkedPlaces.length;
    final bookmarkText = '${bookmarkCount}곳';
    final bookmarkProvider = context.watch<BookmarkProvider>();
    final userId = context.read<AuthProvider>().user?.id ?? 0;
    final todayPlace = context.watch<RecommendProvider>().todayPlace;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        // 세로 스크롤 가능하도록 설정
        child: Column(
          children: [
            // 1. 상단 프로필 및 통계 영역 (흰색 배경)
            _buildTopSection(context, nickname, daysAgo, bookmarkText),

            // 2. 하단 컨텐츠 영역 (회색 배경)
            Container(
              width: double.infinity,
              constraints: const BoxConstraints(minHeight: 600), // 최소 높이 확보
              decoration: const BoxDecoration(
                color: Color(0xFFF3F3F4),
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(30),
                  topRight: Radius.circular(30),
                ),
              ),
              padding: const EdgeInsets.fromLTRB(25, 40, 25, 80),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 취향 분석 섹션
                  _buildSectionTitle(
                    title: '사용자 님의 취향 분석',
                    subtitle: 'AI와 나눈 대화로 분석해봤어요',
                  ),
                  const SizedBox(height: 16),
                  _buildKeywordCard(context),

                  const SizedBox(height: 50),

                  // 추천 플레이스 섹션
                  _buildSectionTitle(
                    title: '오늘의 추천 플레이스',
                    subtitle: '사용자 님의 취향과 가장 잘 맞을 장소를 골라봤어요',
                  ),
                  const SizedBox(height: 16),
                  _buildRecommendCard(context, todayPlace, bookmarkProvider, userId),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 상단 프로필 및 통계 위젯
  Widget _buildTopSection(
      BuildContext context, String nickname, int daysAgo, String bookmarkText) {
    return Container(
      color: Colors.white,
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 10, // 상태바 여백
        bottom: 40,
        left: 20,
        right: 20,
      ),
      child: Column(
        children: [
          // 설정 버튼 (우측 상단)
          Align(
            alignment: Alignment.centerRight,
            child: IconButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const SettingScreen()),
                );
              },
              icon: const Icon(Icons.settings_outlined,
                  color: Colors.black, size: 30),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
          ),
          const SizedBox(height: 10),

          // 닉네임
          Text(
            nickname,
            style: const TextStyle(
              color: Colors.black,
              fontSize: 22,
              fontFamily: 'Noto Sans',
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 16),

          // 가입 일수 뱃지
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFFF3F3F4),
              borderRadius: BorderRadius.circular(17.5),
            ),
            child: Text(
              '우리가 만난 지 $daysAgo일 째',
              style: const TextStyle(
                color: Colors.black,
                fontSize: 16,
                fontFamily: 'Noto Sans',
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(height: 40),

          // 통계 (방문 수 / 저장 수)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildStatItem(
                label: '찾아온 플레이스',
                count: '${_visitedPlacesCount}곳',
                onTap: null,
              ),
              // 구분선 (선택사항, 필요 없으면 제거)
              Container(width: 1, height: 40, color: Colors.grey[300]),
              _buildStatItem(
                label: '저장한 플레이스',
                count: bookmarkText,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const BookmarkScreen()),
                  );
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(
      {required String label, required String count, VoidCallback? onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Text(
            label,
            style: const TextStyle(
              color: Colors.black,
              fontSize: 16, // 화면 작을 때를 대비해 약간 줄임
              fontFamily: 'Noto Sans',
              fontWeight: FontWeight.w400,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            count,
            style: const TextStyle(
              color: Colors.black,
              fontSize: 24,
              fontFamily: 'Noto Sans',
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  // 섹션 타이틀 빌더
  Widget _buildSectionTitle({required String title, required String subtitle}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            color: Color(0xFF1E2938),
            fontSize: 22,
            fontFamily: 'Noto Sans',
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          subtitle,
          style: const TextStyle(
            color: Color(0xFF75757D),
            fontSize: 15,
            fontFamily: 'Noto Sans',
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  // 키워드 카드
  Widget _buildKeywordCard(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 카드 헤더 (타이틀 + 화살표)
          GestureDetector(
            onTap: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const KeywordSettingScreen()),
              );
              await _loadPreferenceKeywords();
            },
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: const [
                Text(
                  '취향 키워드',
                  style: TextStyle(
                    color: Colors.black,
                    fontSize: 20,
                    fontFamily: 'Noto Sans',
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Icon(CupertinoIcons.chevron_forward,
                    size: 20, color: Colors.black),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // 탭 (좋아해요 / 싫어해요)
          Container(
            height: 56,
            decoration: BoxDecoration(
              color: const Color(0xFFF7F8FA),
              borderRadius: BorderRadius.circular(30),
            ),
            padding: const EdgeInsets.all(4),
            child: Row(
              children: [
                _buildTabButton(KeywordTab.like, '좋아해요', CupertinoIcons.heart_fill),
                _buildTabButton(
                    KeywordTab.dislike, '싫어해요', CupertinoIcons.heart_slash_fill),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // 칩 리스트
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _currentKeywordList.map((k) {
              final bool isLike = _currentTab == KeywordTab.like;
              final Color bgColor =
              isLike ? const Color(0xFFFFF3F4) : const Color(0xFFF5F5F7);
              final Color textColor =
              isLike ? const Color(0xFFF36461) : const Color(0xFF8E8E93);

              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: bgColor,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  k,
                  style: TextStyle(
                    color: textColor,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildTabButton(KeywordTab tab, String text, IconData icon) {
    final bool isSelected = _currentTab == tab;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _currentTab = tab),
        child: Container(
          decoration: BoxDecoration(
            color: isSelected ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(26),
            boxShadow: isSelected
                ? [
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 4,
                offset: const Offset(0, 2),
              )
            ]
                : [],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 16,
                color: isSelected
                    ? (tab == KeywordTab.like
                    ? const Color(0xFFF36461)
                    : const Color(0xFF8E8E93))
                    : const Color(0xFFB0B0B0),
              ),
              const SizedBox(width: 6, height: 60,),
              Text(
                text,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: isSelected
                      ? (tab == KeywordTab.like
                      ? const Color(0xFFF36461)
                      : const Color(0xFF8E8E93))
                      : const Color(0xFFB0B0B0),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // 추천 플레이스 카드
  Widget _buildRecommendCard(BuildContext context, Place? todayPlace,
      BookmarkProvider bookmarkProvider, int userId) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 이미지 영역
          Container(
            width: double.infinity,
            height: 150,
            decoration: BoxDecoration(
              color: const Color(0xFFD9D9D9),
              borderRadius: BorderRadius.circular(10),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: (todayPlace != null &&
                  todayPlace.imageUrl != null &&
                  todayPlace.imageUrl!.isNotEmpty)
                  ? Image.network(
                todayPlace.imageUrl!,
                fit: BoxFit.cover,
                errorBuilder: (ctx, _, __) => const Center(
                    child: Icon(Icons.broken_image, color: Colors.grey)),
              )
                  : const Center(
                  child: Icon(Icons.photo, color: Colors.white, size: 40)),
            ),
          ),
          const SizedBox(height: 16),

          // 정보 + 북마크 아이콘 Row
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      todayPlace?.name ?? '추천 장소 준비 중...',
                      style: const TextStyle(
                        color: Color(0xFF1E2938),
                        fontSize: 18,
                        fontFamily: 'Noto Sans',
                        fontWeight: FontWeight.w700,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      todayPlace?.address ?? '주소를 불러오는 중입니다.',
                      style: const TextStyle(
                        color: Color(0xFF95959F),
                        fontSize: 14,
                        fontFamily: 'Noto Sans',
                        fontWeight: FontWeight.w400,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    if (todayPlace?.searchUrl != null &&
                        todayPlace!.searchUrl!.isNotEmpty)
                      GestureDetector(
                        onTap: () async {
                          final uri = Uri.parse(todayPlace.searchUrl!);
                          if (await canLaunchUrl(uri)) {
                            await launchUrl(uri,
                                mode: LaunchMode.externalApplication);
                          }
                        },
                        child: const Text(
                          '사이트 바로가기',
                          style: TextStyle(
                            fontSize: 12,
                            color: Color(0xFF1565C0),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              // 북마크 아이콘
              GestureDetector(
                onTap: () {
                  if (todayPlace == null) return;
                  bookmarkProvider.toggleBookmark(userId, todayPlace);
                },
                child: Icon(
                  todayPlace != null &&
                      bookmarkProvider.isBookmarked(todayPlace.id)
                      ? Icons.bookmark
                      : Icons.bookmark_border,
                  color: todayPlace != null &&
                      bookmarkProvider.isBookmarked(todayPlace.id)
                      ? const Color(0xFF4285F4)
                      : Colors.grey,
                  size: 28,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}