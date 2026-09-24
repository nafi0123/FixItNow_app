import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../../auth/models/user_model.dart';
import '../../auth/providers/auth_provider.dart';
import '../../../core/constants/api_endpoints.dart';
import '../../admin/services/admin_service.dart' show PaginationMeta;

/// 🌟 মডেল: কাস্টমার বুকিং আইটেম
class CustomerBookingItem {
  final String id;
  final String technicianProfileId;
  final String? bookingDate;
  final String? slot;
  final String status; // PENDING, ACCEPTED, DECLINED, COMPLETED
  final String paymentStatus; // PAID, UNPAID
  final double price;
  final String createdAt;
  final String technicianName;
  final String technicianEmail;
  final String? technicianLocation;
  final String? technicianPhone;
  final Map<String, dynamic>? review;

  CustomerBookingItem({
    required this.id,
    required this.technicianProfileId,
    this.bookingDate,
    this.slot,
    required this.status,
    required this.paymentStatus,
    required this.price,
    required this.createdAt,
    required this.technicianName,
    required this.technicianEmail,
    this.technicianLocation,
    this.technicianPhone,
    this.review,
  });

  factory CustomerBookingItem.fromJson(Map<String, dynamic> json) {
    final techProfile = json['technicianProfile'] as Map<String, dynamic>?;
    final techUser = techProfile?['user'] as Map<String, dynamic>?;

    double calculatedPrice = 50.0;
    if (json['price'] != null) {
      calculatedPrice = (json['price'] as num).toDouble();
    } else if (techProfile?['basePrice'] != null) {
      calculatedPrice = (techProfile!['basePrice'] as num).toDouble();
    } else if (techProfile?['hourlyRate'] != null) {
      calculatedPrice = (techProfile!['hourlyRate'] as num).toDouble();
    }

    return CustomerBookingItem(
      id: json['id'] ?? '',
      technicianProfileId: json['technicianProfileId'] ?? techProfile?['id'] ?? '',
      bookingDate: json['bookingDate']?.toString(),
      slot: json['slot']?.toString(),
      status: (json['status'] ?? 'PENDING').toString().toUpperCase(),
      paymentStatus: (json['paymentStatus'] ?? 'UNPAID').toString().toUpperCase(),
      price: calculatedPrice,
      createdAt: json['createdAt']?.toString() ?? '',
      technicianName: techUser?['name'] ?? 'Professional Technician',
      technicianEmail: techUser?['email'] ?? 'tech@fixitnow.com',
      technicianLocation: techProfile?['location']?.toString(),
      technicianPhone: techUser?['phone']?.toString(),
      review: json['review'] is Map<String, dynamic> ? json['review'] : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'technicianProfileId': technicianProfileId,
      'bookingDate': bookingDate,
      'slot': slot,
      'status': status,
      'paymentStatus': paymentStatus,
      'price': price,
      'createdAt': createdAt,
      'technicianProfile': {
        'id': technicianProfileId,
        'location': technicianLocation,
        'basePrice': price,
        'user': {
          'name': technicianName,
          'email': technicianEmail,
          'phone': technicianPhone,
        }
      },
      'review': review,
    };
  }

  CustomerBookingItem copyWith({
    String? status,
    String? paymentStatus,
    Map<String, dynamic>? review,
  }) {
    return CustomerBookingItem(
      id: id,
      technicianProfileId: technicianProfileId,
      bookingDate: bookingDate,
      slot: slot,
      status: status ?? this.status,
      paymentStatus: paymentStatus ?? this.paymentStatus,
      price: price,
      createdAt: createdAt,
      technicianName: technicianName,
      technicianEmail: technicianEmail,
      technicianLocation: technicianLocation,
      technicianPhone: technicianPhone,
      review: review ?? this.review,
    );
  }
}

/// 🌟 মডেল: কাস্টমার ড্যাশবোর্ড ওভারভিউ ডেটা
class CustomerOverviewData {
  final int totalBookings;
  final int activeBookingsCount;
  final int completedBookingsCount;
  final double totalSpent;
  final int unpaidBookingsCount;
  final List<CustomerBookingItem> recentBookings;
  final UserModel? user;

  CustomerOverviewData({
    required this.totalBookings,
    required this.activeBookingsCount,
    required this.completedBookingsCount,
    required this.totalSpent,
    required this.unpaidBookingsCount,
    required this.recentBookings,
    this.user,
  });

  factory CustomerOverviewData.fromBookings(List<CustomerBookingItem> bookings, UserModel? user) {
    int active = 0;
    int completed = 0;
    int unpaid = 0;
    double spent = 0.0;

    for (final b in bookings) {
      if (b.status == 'PENDING' || b.status == 'ACCEPTED') {
        active++;
      } else if (b.status == 'COMPLETED') {
        completed++;
      }

      if (b.paymentStatus == 'PAID') {
        spent += b.price;
      } else {
        unpaid++;
      }
    }

    return CustomerOverviewData(
      totalBookings: bookings.length,
      activeBookingsCount: active,
      completedBookingsCount: completed,
      totalSpent: spent,
      unpaidBookingsCount: unpaid,
      recentBookings: bookings.take(5).toList(),
      user: user,
    );
  }

  factory CustomerOverviewData.fromJson(Map<String, dynamic> json) {
    final list = (json['recentBookings'] as List<dynamic>? ?? [])
        .map((e) => CustomerBookingItem.fromJson(e as Map<String, dynamic>))
        .toList();

    return CustomerOverviewData(
      totalBookings: json['totalBookings'] ?? 0,
      activeBookingsCount: json['activeBookingsCount'] ?? 0,
      completedBookingsCount: json['completedBookingsCount'] ?? 0,
      totalSpent: (json['totalSpent'] as num?)?.toDouble() ?? 0.0,
      unpaidBookingsCount: json['unpaidBookingsCount'] ?? 0,
      recentBookings: list,
      user: json['user'] != null ? UserModel.fromJson(json['user']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'totalBookings': totalBookings,
      'activeBookingsCount': activeBookingsCount,
      'completedBookingsCount': completedBookingsCount,
      'totalSpent': totalSpent,
      'unpaidBookingsCount': unpaidBookingsCount,
      'recentBookings': recentBookings.map((e) => e.toJson()).toList(),
      'user': user?.toJson(),
    };
  }
}

/// 🌟 রেসপন্স হেল্পার
class CustomerActionResponse {
  final bool success;
  final String message;
  final dynamic data;

  CustomerActionResponse({
    required this.success,
    required this.message,
    this.data,
  });
}

/// 🌟 সার্ভিস: কাস্টমার ড্যাশবোর্ড ও বুকিংস ম্যানেজমেন্ট
class CustomerService {
  static String get baseUrl => ApiEndpoints.baseUrl;

  static const String _kOverviewCacheKey = 'customer_overview_cache_v1';
  static const String _kBookingsCacheKey = 'customer_bookings_cache_v1';

  // ইন-মেমোরি ক্যাশ
  static CustomerOverviewData? _memoryOverview;
  static List<CustomerBookingItem>? _memoryBookings;

  // ==========================================
  // ১. ড্যাশবোর্ড ওভারভিউ (GET /api/bookings & /api/auth/me)
  // ==========================================
  static Future<CustomerOverviewData?> getCustomerOverview({bool forceRefresh = false}) async {
    // ১. মেমোরি ক্যাশ চেক
    if (!forceRefresh && _memoryOverview != null) {
      return _memoryOverview;
    }

    // ২. লোকাল ডিস্ক ক্যাশ চেক
    if (!forceRefresh) {
      try {
        final prefs = await SharedPreferences.getInstance();
        final cached = prefs.getString(_kOverviewCacheKey);
        if (cached != null && cached.isNotEmpty) {
          _memoryOverview = CustomerOverviewData.fromJson(jsonDecode(cached));
          return _memoryOverview;
        }
      } catch (e) {
        if (kDebugMode) print("Overview cache read error: $e");
      }
    }

    final token = await AuthService.getToken();
    if (token == null || token.isEmpty) return _memoryOverview;

    try {
      final headers = {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      };

      final results = await Future.wait([
        http.get(Uri.parse('$baseUrl/api/bookings?limit=50&page=1'), headers: headers),
        http.get(Uri.parse('$baseUrl/api/auth/me'), headers: headers),
      ]);

      final bookingsRes = results[0];
      final meRes = results[1];

      List<CustomerBookingItem> bookingsList = [];
      UserModel? currentUser = AuthService.currentUser;

      if (bookingsRes.statusCode == 200) {
        final bData = jsonDecode(bookingsRes.body);
        if (bData['success'] == true && bData['data'] is List) {
          bookingsList = (bData['data'] as List)
              .map((e) => CustomerBookingItem.fromJson(e as Map<String, dynamic>))
              .toList();
        }
      }

      if (meRes.statusCode == 200) {
        final mData = jsonDecode(meRes.body);
        if (mData['success'] == true && mData['data'] != null) {
          currentUser = UserModel.fromJson(mData['data']);
        }
      }

      final overview = CustomerOverviewData.fromBookings(bookingsList, currentUser);
      _memoryOverview = overview;
      _memoryBookings = bookingsList;

      // লোকাল স্টোরেজে সংরক্ষণ
      try {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(_kOverviewCacheKey, jsonEncode(overview.toJson()));
      } catch (_) {}

      return overview;
    } catch (e) {
      if (kDebugMode) print("getCustomerOverview error: $e");
      return _memoryOverview;
    }
  }

  // ==========================================
  // ২. কাস্টমার সব বুকিং লোড (GET /api/bookings)
  // ==========================================
  static Future<(List<CustomerBookingItem>, PaginationMeta)> getCustomerBookings({
    int page = 1,
    int limit = 10,
    String? search,
    String? status,
    bool forceRefresh = false,
  }) async {
    final isDefaultQuery = page == 1 && (search == null || search.isEmpty) && (status == null || status == 'ALL');

    // ক্যাশ চেক
    if (!forceRefresh && isDefaultQuery) {
      if (_memoryBookings != null && _memoryBookings!.isNotEmpty) {
        return (
          _memoryBookings!,
          PaginationMeta(page: 1, limit: limit, total: _memoryBookings!.length, totalPage: 1)
        );
      }

      try {
        final prefs = await SharedPreferences.getInstance();
        final cached = prefs.getString(_kBookingsCacheKey);
        if (cached != null && cached.isNotEmpty) {
          final list = (jsonDecode(cached) as List)
              .map((e) => CustomerBookingItem.fromJson(e as Map<String, dynamic>))
              .toList();
          _memoryBookings = list;
          return (
            list,
            PaginationMeta(page: 1, limit: limit, total: list.length, totalPage: 1)
          );
        }
      } catch (_) {}
    }

    final token = await AuthService.getToken();
    if (token == null || token.isEmpty) {
      return (<CustomerBookingItem>[], PaginationMeta(page: 1, limit: limit, total: 0, totalPage: 1));
    }

    try {
      final queryParams = <String, String>{
        'page': page.toString(),
        'limit': limit.toString(),
      };
      if (search != null && search.trim().isNotEmpty) {
        queryParams['search'] = search.trim();
      }
      if (status != null && status != 'ALL' && status.trim().isNotEmpty) {
        queryParams['status'] = status.trim();
      }

      final uri = Uri.parse('$baseUrl/api/bookings').replace(queryParameters: queryParams);
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
            .map((e) => CustomerBookingItem.fromJson(e as Map<String, dynamic>))
            .toList();

        final metaJson = data['meta'] as Map<String, dynamic>?;
        final meta = metaJson != null
            ? PaginationMeta.fromJson(metaJson)
            : PaginationMeta(page: page, limit: limit, total: list.length, totalPage: 1);

        if (isDefaultQuery) {
          _memoryBookings = list;
          try {
            final prefs = await SharedPreferences.getInstance();
            await prefs.setString(_kBookingsCacheKey, jsonEncode(list.map((e) => e.toJson()).toList()));
          } catch (_) {}
        }

        return (list, meta);
      } else {
        return (<CustomerBookingItem>[], PaginationMeta(page: 1, limit: limit, total: 0, totalPage: 1));
      }
    } catch (e) {
      if (kDebugMode) print("getCustomerBookings network error: $e");
      return (_memoryBookings ?? <CustomerBookingItem>[], PaginationMeta(page: 1, limit: limit, total: 0, totalPage: 1));
    }
  }

  // ==========================================
  // ৩. রিভিউ জমা দেওয়া (POST /api/reviews)
  // ==========================================
  static Future<CustomerActionResponse> createReview({
    required String bookingId,
    required String technicianProfileId,
    required int rating,
    String? comment,
  }) async {
    final token = await AuthService.getToken();
    if (token == null || token.isEmpty) {
      return CustomerActionResponse(success: false, message: 'Unauthorized! Please log in.');
    }

    try {
      final uri = Uri.parse('$baseUrl/api/reviews');
      final response = await http.post(
        uri,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'bookingId': bookingId,
          'technicianProfileId': technicianProfileId,
          'rating': rating,
          'comment': comment?.trim() ?? '',
        }),
      );

      final data = jsonDecode(response.body);

      if ((response.statusCode == 200 || response.statusCode == 201) && data['success'] == true) {
        // মেমোরি ও ক্যাশ ক্লিয়ার যাতে ফ্রেশ বুকিং ফেচ হয়
        _memoryBookings = null;
        _memoryOverview = null;
        return CustomerActionResponse(
          success: true,
          message: data['message']?.toString() ?? 'Review submitted successfully! Thank you.',
          data: data['data'],
        );
      } else {
        return CustomerActionResponse(
          success: false,
          message: data['message']?.toString() ?? 'Failed to submit review',
        );
      }
    } catch (e) {
      return CustomerActionResponse(success: false, message: 'Network error: $e');
    }
  }

  // ==========================================
  // ৪. প্রোফাইল আপডেট (PATCH /api/auth/update-profile)
  // ==========================================
  static Future<CustomerActionResponse> updateProfile({required String name}) async {
    final token = await AuthService.getToken();
    if (token == null || token.isEmpty) {
      return CustomerActionResponse(success: false, message: 'Unauthorized');
    }

    try {
      final uri = Uri.parse('$baseUrl/api/auth/update-profile');
      final response = await http.patch(
        uri,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'name': name.trim(),
        }),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 && data['success'] == true) {
        // লোকাল ইউজার রিফ্রেশ
        await AuthService.getUser(forceRefresh: true);
        _memoryOverview = null;
        return CustomerActionResponse(
          success: true,
          message: data['message']?.toString() ?? 'Profile updated successfully!',
          data: data['data'],
        );
      } else {
        return CustomerActionResponse(
          success: false,
          message: data['message']?.toString() ?? 'Failed to update profile',
        );
      }
    } catch (e) {
      return CustomerActionResponse(success: false, message: 'Network error: $e');
    }
  }

  // ==========================================
  // ৫. পাসওয়ার্ড পরিবর্তন (PATCH /api/auth/change-password)
  // ==========================================
  static Future<CustomerActionResponse> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    final token = await AuthService.getToken();
    if (token == null || token.isEmpty) {
      return CustomerActionResponse(success: false, message: 'Unauthorized');
    }

    try {
      final uri = Uri.parse('$baseUrl/api/auth/change-password');
      final response = await http.patch(
        uri,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'currentPassword': currentPassword,
          'newPassword': newPassword,
        }),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 && data['success'] == true) {
        return CustomerActionResponse(
          success: true,
          message: data['message']?.toString() ?? 'Password changed successfully!',
        );
      } else {
        return CustomerActionResponse(
          success: false,
          message: data['message']?.toString() ?? 'Failed to change password',
        );
      }
    } catch (e) {
      return CustomerActionResponse(success: false, message: 'Network error: $e');
    }
  }

  // ==========================================
  // ৬. নতুন বুকিং তৈরি করা (POST /api/bookings)
  // ==========================================
  static Future<CustomerActionResponse> createBooking({
    required String technicianProfileId,
    required String bookingDate,
    required String slot,
    String? serviceId,
  }) async {
    final token = await AuthService.getToken();
    if (token == null || token.isEmpty) {
      return CustomerActionResponse(
        success: false,
        message: 'Please log in as a customer to book an appointment.',
      );
    }

    try {
      final uri = Uri.parse('$baseUrl/api/bookings');
      final bodyMap = <String, dynamic>{
        'technicianProfileId': technicianProfileId,
        'bookingDate': bookingDate,
        'slot': slot,
      };
      if (serviceId != null && serviceId.isNotEmpty) {
        bodyMap['serviceId'] = serviceId;
      }

      final response = await http.post(
        uri,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode(bodyMap),
      );

      final data = jsonDecode(response.body);

      if ((response.statusCode == 200 || response.statusCode == 201) && data['success'] == true) {
        _memoryBookings = null;
        _memoryOverview = null;
        try {
          final prefs = await SharedPreferences.getInstance();
          await prefs.remove(_kBookingsCacheKey);
          await prefs.remove(_kOverviewCacheKey);
        } catch (_) {}

        return CustomerActionResponse(
          success: true,
          message: data['message']?.toString() ?? 'Appointment booked successfully! Track status in dashboard.',
          data: data['data'],
        );
      } else {
        return CustomerActionResponse(
          success: false,
          message: data['message']?.toString() ?? 'Failed to create booking.',
        );
      }
    } catch (e) {
      if (kDebugMode) print("createBooking error: $e");
      return CustomerActionResponse(success: false, message: 'Network error: $e');
    }
  }

  // ==========================================
  // ৭. নির্দিষ্ট বুকিংয়ের ডিটেইলস (GET /api/bookings/:id)
  // ==========================================
  static Future<CustomerBookingItem?> getBookingDetails(String bookingId) async {
    final token = await AuthService.getToken();
    if (token == null || token.isEmpty) return null;

    try {
      final uri = Uri.parse('$baseUrl/api/bookings/$bookingId');
      final response = await http.get(
        uri,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      final data = jsonDecode(response.body);
      if (response.statusCode == 200 && data['success'] == true && data['data'] != null) {
        return CustomerBookingItem.fromJson(data['data']);
      }
      return null;
    } catch (e) {
      if (kDebugMode) print("getBookingDetails error: $e");
      return null;
    }
  }
}
