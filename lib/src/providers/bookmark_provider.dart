import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http; // http 패키지 예시, 프로젝트 상황에 맞게 변경
import '../models/place.dart';

class BookmarkProvider extends ChangeNotifier {
  final String baseUrl = 'http://192.0.0.2:3000'; // 백엔드 API URL 기본주소
  List<Place> _bookmarkedPlaces = [];

  List<Place> get bookmarkedPlaces => List.unmodifiable(_bookmarkedPlaces);

  void reset() {
    _bookmarkedPlaces.clear();
    notifyListeners();
  }

  Future<void> loadBookmarks(int userId) async {
    debugPrint('loadBookmarks called with userId=$userId');
    if (userId==0) {
      debugPrint('userId is empty, skip loading');
      return;
    }
    final url = Uri.parse('$baseUrl/bookmarks?userId=$userId');
    final response = await http.get(url);
    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      _bookmarkedPlaces
        ..clear()
        ..addAll(data.map((json) => Place.fromJson(json)));
      notifyListeners();
    } else {
      throw Exception('북마크 리스트를 불러오는데 실패했습니다.');
    }
  }

  /// 북마크 추가
  Future<void> addBookmark(int userId, Place place) async {
    print('⭐ addBookmark userId=$userId (${userId.runtimeType}), placeId=${place.id}');
    final url = Uri.parse('$baseUrl/bookmarks');
    final body = jsonEncode({
      'userId': userId,
      'placeId': place.id,
      'name': place.name,
      'address': place.address,
      'imageUrl': place.imageUrl,
    });
    final response = await http.post(url,
        headers: {'Content-Type': 'application/json'}, body: body);
    if (response.statusCode == 201) {
      _bookmarkedPlaces.add(place);
      notifyListeners();
    } else if (response.statusCode == 409) {
      // 이미 북마크된 상태일 경우 처리할 로직 (무시해도 됨)
    } else {
      throw Exception('북마크 추가에 실패했습니다.');
    }
  }

  /// 북마크 삭제
  Future<void> removeBookmark(int userId, String placeId) async {
    final url = Uri.parse('$baseUrl/bookmarks/$placeId?userId=$userId');
    final response = await http.delete(url);
    if (response.statusCode == 200) {
      _bookmarkedPlaces.removeWhere((p) => p.id == placeId);
      notifyListeners();
    } else {
      throw Exception('북마크 삭제에 실패했습니다.');
    }
  }

  /// 존재 여부 확인
  bool isBookmarked(String placeId) {
    return _bookmarkedPlaces.any((p) => p.id == placeId);
  }

  /// 토글 (저장 또는 삭제)
  Future<void> toggleBookmark(int userId, Place place) async {
    if (isBookmarked(place.id)) {
      await removeBookmark(userId, place.id);
    } else {
      await addBookmark(userId, place);
    }
  }
}
