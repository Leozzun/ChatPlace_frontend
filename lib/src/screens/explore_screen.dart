import 'package:flutter/material.dart';
import '../models/place.dart';
import '../providers/auth_provider.dart';
import '../services/api_client.dart';
import 'package:provider/provider.dart';
import '../providers/location_provider.dart';
import 'package:provider/provider.dart';
import '../providers/bookmark_provider.dart';
import '../providers/recommend_provider.dart';


class ExploreScreen extends StatefulWidget {
  const ExploreScreen({Key? key}) : super(key: key);

  @override
  _ExploreScreenState createState() => _ExploreScreenState();
}

class _ExploreScreenState extends State<ExploreScreen> {
  final List<Map<String, String>> categories = [
    {'label': '전체', 'type': 'cafe'},
    {'label': '카페', 'type': 'cafe'},
    {'label': '식당', 'type': 'restaurant'},
    {'label': '쇼핑', 'type': 'clothing_store'},
    {'label': '관광', 'type': 'tourist_attraction'},
    {'label': '숙박', 'type': 'lodging'},
    {'label': '주점', 'type': 'bar'},
    {'label': '운동', 'type': 'gym'}
  ];

  int selectedCategory = 0;
  String searchQuery = '';
  final TextEditingController searchController = TextEditingController();

  List<Place> places = [];
  String? nextPageToken;
  bool isLoading = false;
  final ApiClient _apiClient = ApiClient();
  final ScrollController _scrollController = ScrollController();

  final Set<String> _bookmarkedPlaces = {}; // 북마크 저장용
  bool _hasInitialLoaded = false;          // ✅ 초기 로딩 여부 플래그

  Place? _todayRandomPlace;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // ✅ Provider의 위치 값이 준비된 순간 한 번만 초기 로딩
    final locationProvider = context.watch<LocationProvider>();
    if (!_hasInitialLoaded &&
        locationProvider.latitude != null &&
        locationProvider.longitude != null) {
      _hasInitialLoaded = true;
      _fetchNearbyPlaces(initial: true);
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    searchController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 100) {
      if (!isLoading && nextPageToken != null) {
        _fetchNextPage();
      }
    }
  }

  Future<void> _fetchNearbyPlaces({bool initial = false}) async {
    final locationProvider = context.read<LocationProvider>();
    final latitude = locationProvider.latitude;
    final longitude = locationProvider.longitude;
    if (latitude == null || longitude == null) return;

    setState(() {
      isLoading = true;
      if (initial) places = [];
    });

    final category = categories[selectedCategory]['type'] ?? '';
    final result = await _apiClient.fetchPlacesByLocation(
      latitude,
      longitude,
      type: category,
      keyword: searchQuery,
      pageToken: initial ? null : nextPageToken,
    );

    final List<Place> newPlaces = (result['places'] as List)
        .map((json) => Place.fromJson(json))
        .where((p) => p.imageUrl != null && p.imageUrl!.isNotEmpty)
        .toList();

    setState(() {
      if (initial) {
        places = newPlaces;
      } else {
        places.addAll(newPlaces);
      }
      nextPageToken = result['nextPageToken'];
      isLoading = false;

      // ✅ 키워드가 없을 때만 랜덤 추천 후보 설정 (위치 기반)
      final auth = context.read<AuthProvider>();
      final user = auth.user;
      final hasKeywords = false; // 나중에 실제 키워드 여부로 교체 (예: likedKeywords.isNotEmpty)

      if (!hasKeywords && places.isNotEmpty) {
        final shuffled = List<Place>.from(places)..shuffle();
        final randomPlace = shuffled.first;
        context.read<RecommendProvider>().setTodayPlace(randomPlace);
      }
    });
  }

  Future<void> _fetchNextPage() async {
    if (nextPageToken == null) return;

    final locationProvider = context.read<LocationProvider>();
    final latitude = locationProvider.latitude;
    final longitude = locationProvider.longitude;
    if (latitude == null || longitude == null) return;

    setState(() {
      isLoading = true;
    });

    await Future.delayed(const Duration(seconds: 2));

    final result = await _apiClient.fetchPlacesByLocation(
      latitude,
      longitude,
      type: searchQuery,
      keyword: searchQuery,
      pageToken: nextPageToken,
    );

    final List<Place> newPlaces = (result['places'] as List)
        .map((json) => Place.fromJson(json))
        .where((p) => p.imageUrl != null && p.imageUrl!.isNotEmpty)
        .toList();

    final existingIds = places.map((p) => p.id).toSet();
    setState(() {
      places.addAll(newPlaces.where((p) => !existingIds.contains(p.id)));
      nextPageToken = result['nextPageToken'];
      isLoading = false;
    });
  }

  void _toggleBookmark(String placeId) {
    setState(() {
      if (_bookmarkedPlaces.contains(placeId)) {
        _bookmarkedPlaces.remove(placeId);
      } else {
        _bookmarkedPlaces.add(placeId);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final locationProvider = context.watch<LocationProvider>();
    final bookmarkProvider = context.watch<BookmarkProvider>();
    final currentAddress = locationProvider.currentAddress;

    return Scaffold(
      backgroundColor: const Color(0xFFFFFFFF),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 검색창
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: searchController,
                      onSubmitted: (text) {
                        setState(() {
                          searchQuery = text;
                        });
                        _fetchNearbyPlaces(initial: true);
                      },
                      decoration: InputDecoration(
                        hintText: '지역이나 장소명을 검색하세요',
                        prefixIcon:
                        const Icon(Icons.search, color: Colors.grey),
                        contentPadding: const EdgeInsets.symmetric(
                            vertical: 10, horizontal: 16),
                        filled: true,
                        fillColor: const Color(0xFFF5F5F5),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // 현재 위치 표시
            Padding(
              padding:
              const EdgeInsets.only(right: 20, left: 16, bottom: 10),
              child: Row(
                children: [
                  const Icon(Icons.location_on_outlined,
                      size: 16, color: Color(0xFF4285F4)),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      currentAddress,
                      style: const TextStyle(
                          fontSize: 14, color: Color(0xFF7A7A7A)),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),

            // 카테고리 탭
            SizedBox(
              height: 42,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: categories.length,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                itemBuilder: (context, idx) {
                  final selected = selectedCategory == idx;
                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        selectedCategory = idx;
                        places.clear();
                        nextPageToken = null;
                      });
                      _fetchNearbyPlaces(initial: true);
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 18, vertical: 10),
                      margin: const EdgeInsets.only(right: 10),
                      decoration: BoxDecoration(
                        color: selected
                            ? const Color(0xFF4285F4)
                            : Colors.grey[200],
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Center(
                        child: Text(
                          categories[idx]['label']!,
                          style: TextStyle(
                            color: selected
                                ? Colors.white
                                : Colors.grey[700],
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),

            const SizedBox(height: 8),

            // 장소 카드 그리드
            Expanded(
              child: places.isEmpty && isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : GridView.builder(
                controller: _scrollController,
                padding: const EdgeInsets.symmetric(
                    horizontal: 0, vertical: 6),
                gridDelegate:
                const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  mainAxisSpacing: 4,
                  crossAxisSpacing: 4,
                  childAspectRatio: 0.8,
                ),
                itemCount: places.length,
                itemBuilder: (_, index) {
                  final p = places[index];
                  if (p.imageUrl == null || p.imageUrl!.isEmpty) {
                    return const SizedBox.shrink();
                  }
                  final isBookmarked = bookmarkProvider.isBookmarked(p.id);
                  final userId = (context.read<AuthProvider>().user?.id ?? 0);
                  return Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(14),
                      color: Colors.white,
                      boxShadow: [
                        BoxShadow(
                          color:
                          Colors.black.withOpacity(0.1),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius:
                      BorderRadius.circular(0),
                      child: Stack(
                        children: [
                          Image.network(
                            p.imageUrl!,
                            fit: BoxFit.cover,
                            width: double.infinity,
                            height: double.infinity,
                          ),
                          Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.bottomCenter,
                                end: Alignment.center,
                                colors: [
                                  Colors.black
                                      .withOpacity(0.6),
                                  Colors.transparent,
                                ],
                              ),
                            ),
                          ),
                          Positioned(
                            top: 12,
                            right: 8,
                            child: GestureDetector(
                              onTap: () => bookmarkProvider.toggleBookmark(userId, p),
                              child: CircleAvatar(
                                radius: 16,
                                backgroundColor:
                                Colors.transparent,
                                child: Icon(
                                  isBookmarked ? Icons.bookmark : Icons.bookmark_outline,
                                  color: Color(0xFFFFFFFF),
                                  size: 30,
                                ),
                              ),
                            ),
                          ),
                          Positioned(
                            left: 10,
                            bottom: 14,
                            right: 10,
                            child: Column(
                              crossAxisAlignment:
                              CrossAxisAlignment.start,
                              children: [
                                Text(
                                  p.name,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight:
                                    FontWeight.bold,
                                    fontSize: 14,
                                    shadows: [
                                      Shadow(
                                        blurRadius: 4,
                                        color: Colors.black45,
                                        offset:
                                        Offset(0, 1),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  p.address,
                                  maxLines: 2,
                                  overflow:
                                  TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                    shadows: [
                                      Shadow(
                                        blurRadius: 3,
                                        color: Colors.black38,
                                        offset:
                                        Offset(0, 1),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),

            if (isLoading)
              const Padding(
                padding: EdgeInsets.all(16.0),
                child: Center(
                    child: CircularProgressIndicator()),
              ),
          ],
        ),
      ),
    );
  }
}
