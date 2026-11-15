import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/login_response.dart';
import 'package:provider/provider.dart';

import 'bookmark_provider.dart';

class AuthProvider with ChangeNotifier {
  LoginResponse? _user;

  LoginResponse? get user => _user;

  String? get token => _user?.accessToken;

  bool get isLoggedIn => _user != null;

  Future<void> saveUser(LoginResponse user) async {
    _user = user;
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('id', user.id);
    await prefs.setString('token', user.accessToken);
    await prefs.setString('email', user.email);
    await prefs.setString('nickname', user.nickname);
    await prefs.setString('createdAt', user.createdAt.toIso8601String());
  }

  Future<void> loadUser() async {
    final prefs = await SharedPreferences.getInstance();
    final id = prefs.getInt('id');
    final token = prefs.getString('token');
    final email = prefs.getString('email');
    final nickname = prefs.getString('nickname');
    final createdAtStr = prefs.getString('createdAt');
    if (id != null && token != null && email != null && nickname != null && createdAtStr != null) {
      _user = LoginResponse(id: id, accessToken: token, email: email, nickname: nickname, createdAt: DateTime.parse(createdAtStr));
      notifyListeners();
    }
  }

  Future<void> logout(BuildContext context) async {
    _user = null;
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('id');
    await prefs.remove('token');
    await prefs.remove('email');
    await prefs.remove('nickname');

    context.read<BookmarkProvider>().reset();
  }
}
