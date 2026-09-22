import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
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

  // ৩. সেভ করা ইউজার মডেল পাওয়া (ক্যাশ ফার্স্ট)
  static Future<UserModel?> getUser({bool forceRefresh = false}) async {
    if (!forceRefresh && _hasLoaded) {
      return _cachedUser;
    }
    final prefs = await SharedPreferences.getInstance();
    final userJson = prefs.getString(_userKey);
    _cachedToken = prefs.getString(_tokenKey);
    if (userJson != null) {
      try {
        _cachedUser = UserModel.fromJson(jsonDecode(userJson));
      } catch (_) {
        _cachedUser = null;
      }
    } else {
      _cachedUser = null;
    }
    _hasLoaded = true;
    return _cachedUser;
  }

  // ৪. সিনক্রোনাসলি ক্যাশড ইউজার পাওয়ার অপশন
  static UserModel? get currentUser => _cachedUser;
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
