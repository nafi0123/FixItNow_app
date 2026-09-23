import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/constants/api_endpoints.dart';
import '../models/user_model.dart';

class AuthService {
  static const String _tokenKey = 'auth_token';
  static const String _userKey = 'auth_user';

  // 🌟 ইন-মেমোরি ক্যাশিং: যাতে প্রতিবার ডিস্ক রিড না করতে হয় এবং ইনস্ট্যান্ট রেন্ডার হয়
  static UserModel? _cachedUser;
  static String? _cachedToken;
  static bool _hasLoaded = false;

  // ১. টোকেন ও ইউজার ডাটা লোকাল মেমরিতে ও ক্যাশে সেভ করা
  static Future<void> saveAuthData({
    required String token,
    required Map<String, dynamic> userData,
  }) async {
    final user = UserModel.fromJson(userData);
    _cachedToken = token;
    _cachedUser = user;
    _hasLoaded = true;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, token);
    await prefs.setString(_userKey, jsonEncode(userData));
  }

  // ২. সেভ করা টোকেন পাওয়া (ক্যাশ ফার্স্ট)
  static Future<String?> getToken() async {
    if (_cachedToken != null) return _cachedToken;
    final prefs = await SharedPreferences.getInstance();
    _cachedToken = prefs.getString(_tokenKey);
    return _cachedToken;
  }

  // ৩. সেভ করা ইউজার মডেল পাওয়া (ক্যাশ ফার্স্ট + ব্যাকগ্রাউন্ডে /api/auth/me থেকে সিঙ্ক)
  static Future<UserModel?> getUser({bool forceRefresh = false}) async {
    final prefs = await SharedPreferences.getInstance();
    _cachedToken = prefs.getString(_tokenKey);

    // ১. লোকাল ক্যাশ থেকে আগে লোড
    if (!forceRefresh && _hasLoaded && _cachedUser != null) {
      return _cachedUser;
    }

    final userJson = prefs.getString(_userKey);
    if (userJson != null) {
      try {
        _cachedUser = UserModel.fromJson(jsonDecode(userJson));
      } catch (_) {}
    }
    _hasLoaded = true;

    // ২. টোকেন থাকলে সার্ভার /api/auth/me থেকে লেটেস্ট টেকনিশিয়ান প্রোফাইল সহ ফ্রেশ ডাটা আনা
    if (_cachedToken != null && _cachedToken!.isNotEmpty) {
      try {
        final uri = Uri.parse('${ApiEndpoints.baseUrl}/api/auth/me');
        final response = await http.get(
          uri,
          headers: {
            'Authorization': 'Bearer $_cachedToken',
            'Content-Type': 'application/json',
          },
        );

        final data = jsonDecode(response.body);
        if (response.statusCode == 200 && data['success'] == true && data['data'] != null) {
          final freshUser = UserModel.fromJson(data['data']);
          _cachedUser = freshUser;
          await prefs.setString(_userKey, jsonEncode(data['data']));
          return freshUser;
        }
      } catch (e) {
        debugPrint('Error fetching fresh user /api/auth/me: $e');
      }
    }

    return _cachedUser;
  }

  // ৪. সিনক্রোনাসলি ক্যাশড ইউজার পাওয়ার অপশন
  static UserModel? get currentUser => _cachedUser;
  static String? get token => _cachedToken;
  static bool get isLoggedIn => _cachedUser != null;

  // ৫. লগআউট (ক্যাশ ও ডিস্ক ডাটা সম্পূর্ণ ক্লিয়ার)
  static Future<void> logout() async {
    _cachedUser = null;
    _cachedToken = null;
    _hasLoaded = true;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
    await prefs.remove(_userKey);
  }
}
