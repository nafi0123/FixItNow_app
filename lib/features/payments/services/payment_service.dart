import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../../auth/providers/auth_provider.dart';
import '../../../core/constants/api_endpoints.dart';
import '../models/payment_model.dart';

class PaymentSessionResult {
  final bool success;
  final String message;
  final String? paymentUrl;

  PaymentSessionResult({
    required this.success,
    required this.message,
    this.paymentUrl,
  });
}

class PaymentService {
  static String get baseUrl => ApiEndpoints.baseUrl;

  // ইন-মেমোরি ক্যাশ (রোলের ওপর ভিত্তি করে)
  static final Map<String, List<PaymentItem>> _memoryCache = {};

  // ==========================================
  // ১. পেমেন্ট সেশন শুরু করা (POST /api/payments/create)
  // ==========================================
  static Future<PaymentSessionResult> initiatePayment({
    required String bookingId,
    String? redirectUrl,
  }) async {
    final token = await AuthService.getToken();
    if (token == null || token.isEmpty) {
      return PaymentSessionResult(
        success: false,
        message: 'Unauthorized! Please log in as a customer.',
      );
    }

    try {
      final uri = Uri.parse(ApiEndpoints.createPaymentSession);
      final payload = <String, dynamic>{
        'bookingId': bookingId,
      };
      if (redirectUrl != null && redirectUrl.isNotEmpty) {
        payload['redirectUrl'] = redirectUrl;
      }

      final response = await http.post(
        uri,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode(payload),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 && data['success'] == true) {
        final paymentUrl = data['data']?['paymentUrl']?.toString();
        if (paymentUrl != null && paymentUrl.isNotEmpty) {
          return PaymentSessionResult(
            success: true,
            message: data['message']?.toString() ?? 'Payment session initiated!',
            paymentUrl: paymentUrl,
          );
        } else {
          return PaymentSessionResult(
            success: false,
            message: 'No payment URL received from gateway.',
          );
        }
      } else {
        return PaymentSessionResult(
          success: false,
          message: data['message']?.toString() ?? 'Failed to initiate payment session.',
        );
      }
    } catch (e) {
      if (kDebugMode) print("initiatePayment error: $e");
      return PaymentSessionResult(
        success: false,
        message: 'Network error: $e',
      );
    }
  }

  // ==========================================
  // ২. পেমেন্ট হিস্ট্রি লোড (GET /api/payments)
  // ==========================================
  static Future<List<PaymentItem>> getAllPayments({
    String userRole = 'CUSTOMER',
    bool forceRefresh = false,
  }) async {
    final cacheKey = 'payments_cache_${userRole.toUpperCase()}';

    // ১. মেমোরি ক্যাশ চেক
    if (!forceRefresh && _memoryCache.containsKey(cacheKey) && _memoryCache[cacheKey]!.isNotEmpty) {
      return _memoryCache[cacheKey]!;
    }

    // ২. লোকাল ডিস্ক ক্যাশ চেক
    if (!forceRefresh) {
      try {
        final prefs = await SharedPreferences.getInstance();
        final cached = prefs.getString(cacheKey);
        if (cached != null && cached.isNotEmpty) {
          final list = (jsonDecode(cached) as List)
              .map((e) => PaymentItem.fromJson(e as Map<String, dynamic>))
              .toList();
          _memoryCache[cacheKey] = list;
          return list;
        }
      } catch (_) {}
    }

    final token = await AuthService.getToken();
    if (token == null || token.isEmpty) {
      return _memoryCache[cacheKey] ?? [];
    }

    try {
      final uri = Uri.parse(ApiEndpoints.payments);
      final response = await http.get(
        uri,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 && data['success'] == true) {
        final list = (data['data'] as List? ?? [])
            .map((e) => PaymentItem.fromJson(e as Map<String, dynamic>))
            .toList();

        _memoryCache[cacheKey] = list;

        // লোকাল স্টোরেজে সংরক্ষণ
        try {
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString(cacheKey, jsonEncode(list.map((e) => e.toJson()).toList()));
        } catch (_) {}

        return list;
      } else {
        return _memoryCache[cacheKey] ?? [];
      }
    } catch (e) {
      if (kDebugMode) print("getAllPayments error: $e");
      return _memoryCache[cacheKey] ?? [];
    }
  }

  // ==========================================
  // ৩. নির্দিষ্ট পেমেন্ট ডিটেইলস (GET /api/payments/:id)
  // ==========================================
  static Future<PaymentItem?> getPaymentById(String transactionId) async {
    final token = await AuthService.getToken();
    if (token == null || token.isEmpty) return null;

    try {
      final uri = Uri.parse('${ApiEndpoints.payments}/$transactionId');
      final response = await http.get(
        uri,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 && data['success'] == true && data['data'] != null) {
        return PaymentItem.fromJson(data['data']);
      }
      return null;
    } catch (e) {
      if (kDebugMode) print("getPaymentById error: $e");
      return null;
    }
  }
}
