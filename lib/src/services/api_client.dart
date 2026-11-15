import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:http/http.dart' as http;

import '../models/conversation.dart';
import '../models/message.dart';
import '../models/place.dart';

const String _baseUrl = 'http://192.0.0.2:3000';

class ApiClient {
  final Dio _dio;

  ApiClient()
      : _dio = Dio(
    BaseOptions(
      baseUrl: _baseUrl,
      connectTimeout: const Duration(seconds: 120),
      receiveTimeout: const Duration(seconds: 120),
    ),
  );

  // Chat 추천 API
  Future<Map<String, dynamic>> chat(String message) async {
    final res = await _dio.post('/chat/recommend', data: {'message': message});
    if (res.data is String) {
      return jsonDecode(res.data);
    } else if (res.data is Map<String, dynamic>) {
      return res.data as Map<String, dynamic>;
    } else {
      throw Exception('Unexpected response type: ${res.data.runtimeType}');
    }
  }

  // 위치 기반 주변 장소 조회
  Future<Map<String, dynamic>> fetchPlacesByLocation(
      double latitude,
      double longitude, {
        String type = '',
        String keyword = '',
        String? pageToken,
      }) async {
    final res = await _dio.post(
      '/places/nearby',
      data: {
        'latitude': latitude,
        'longitude': longitude,
        'type': type,
        'keyword': keyword,
        'pageToken': pageToken ?? '',
      },
      options: Options(headers: {'Content-Type': 'application/json'}),
    );

    if (res.statusCode == 200) {
      if (res.data is String) {
        return jsonDecode(res.data) as Map<String, dynamic>;
      } else if (res.data is Map<String, dynamic>) {
        return res.data as Map<String, dynamic>;
      } else {
        throw Exception('Unexpected response type: ${res.data.runtimeType}');
      }
    } else {
      throw Exception('Failed to fetch nearby places');
    }
  }

  Future<Conversation> saveConversation({
    required int userId,
    required String title,
    required String question,
    required String answer,
    required List<Place> places,
    required List<Message> messages,
  }) async {
    final url = Uri.parse('$_baseUrl/conversations');

    final placesJson = jsonEncode(
      places.map((p) => p.toJson()).toList(),
    );

    final messagesJson = jsonEncode(
      messages.map((m) => m.toJson()).toList(),
    );

    final body = jsonEncode({
      'userId': userId,
      'title': title,
      'question': question,
      'answer': answer,
      'placesJson': placesJson,
      'messagesJson': messagesJson,
    });

    final res = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: body,
    );

    if (res.statusCode == 200) {
      final data = jsonDecode(res.body);
      return Conversation.fromJson(data);
    } else {
      throw Exception('대화 저장 실패');
    }
  }

// 2) 유저별 대화 목록
  Future<List<Conversation>> loadConversations(int userId) async {
    final url = Uri.parse('$_baseUrl/conversations?userId=$userId');
    final res = await http.get(url);

    if (res.statusCode == 200) {
      final List<dynamic> data = jsonDecode(res.body);
      return data.map((e) => Conversation.fromJson(e)).toList();
    } else {
      throw Exception('대화 목록 조회 실패');
    }
  }

// 3) 특정 대화 상세
  Future<Conversation> loadConversationDetail({
    required int userId,
    required int conversationId,
  }) async {
    final url = Uri.parse('$_baseUrl/conversations/$conversationId?userId=$userId');
    final res = await http.get(url);

    if (res.statusCode == 200) {
      final data = jsonDecode(res.body);
      return Conversation.fromJson(data);
    } else {
      throw Exception('대화 상세 조회 실패');
    }
  }

  Future<int> loadTotalPlacesCount(int userId) async {
    final url = Uri.parse('$_baseUrl/conversations/places/count?userId=$userId');
    final res = await http.get(url);
    if (res.statusCode == 200) {
      return int.tryParse(res.body) ?? 0;
    }
    throw Exception('총 추천 장소 수 로드 실패');
  }

  Future<List<String>> loadLikeKeywords(int userId) async {
    final res = await _dio.get(
      '/api/preferences/keywords/like',
      queryParameters: {'userId': userId},
    );
    if (res.statusCode == 200) {
      final data = res.data as List;
      return data.map((e) => e.toString()).toList();
    }
    throw Exception('좋아해요 키워드 로드 실패');
  }

  Future<List<String>> loadDislikeKeywords(int userId) async {
    final res = await _dio.get(
      '/api/preferences/keywords/dislike',
      queryParameters: {'userId': userId},
    );
    if (res.statusCode == 200) {
      final data = res.data as List;
      return data.map((e) => e.toString()).toList();
    }
    throw Exception('싫어해요 키워드 로드 실패');
  }

  Future<void> saveLikeKeywords(int userId, List<String> keywords) async {
    await _dio.post(
      '/api/preferences/keywords/like',
      queryParameters: {'userId': userId},
      data: keywords,
      options: Options(headers: {'Content-Type': 'application/json'}),
    );
  }

  Future<void> saveDislikeKeywords(int userId, List<String> keywords) async {
    await _dio.post(
      '/api/preferences/keywords/dislike',
      queryParameters: {'userId': userId},
      data: keywords,
      options: Options(headers: {'Content-Type': 'application/json'}),
    );
  }
}
