import '../../auth/models/user_model.dart';
import 'package:flutter/foundation.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../auth/providers/auth_provider.dart';
import '../../../core/constants/api_endpoints.dart';
import '../../admin/services/admin_service.dart' show PaginationMeta;

/// 🌟 মডেল: টেকনিশিয়ান বুকিং আইটেম
class TechnicianBookingItem {
  final String id;
  final String? serviceId;
  final String status; // PENDING, ACCEPTED, DECLINED, COMPLETED
  final String? paymentStatus;
  final String? bookingDate;
  final String? serviceDate;
  final String? slot;
  final double price;
  final String customerName;
  final String customerEmail;
  final String createdAt;

  TechnicianBookingItem({
    required this.id,
    this.serviceId,
    required this.status,
    this.paymentStatus,
    this.bookingDate,
    this.serviceDate,
    this.slot,
    required this.price,
    required this.customerName,
    required this.customerEmail,
    required this.createdAt,
  });

  factory TechnicianBookingItem.fromJson(Map<String, dynamic> json) {
    final customer = json['customer'] as Map<String, dynamic>?;
    final techProfile = json['technicianProfile'] as Map<String, dynamic>?;

    double p = 50.0;
    if (json['price'] != null) {
      p = (json['price'] as num).toDouble();
    } else if (techProfile?['basePrice'] != null) {
      p = (techProfile!['basePrice'] as num).toDouble();
    }

    return TechnicianBookingItem(
      id: json['id'] ?? '',
      serviceId: json['serviceId'],
      status: (json['status'] ?? 'PENDING').toString().toUpperCase(),
      paymentStatus: (json['paymentStatus'] ?? 'UNPAID').toString().toUpperCase(),
      bookingDate: json['bookingDate']?.toString(),
      serviceDate: json['serviceDate']?.toString(),
      slot: json['slot']?.toString(),
      price: p,
      customerName: customer?['name'] ?? 'FixItNow Customer',
      customerEmail: customer?['email'] ?? 'customer@fixitnow.com',
      createdAt: json['createdAt']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'serviceId': serviceId,
      'status': status,
      'paymentStatus': paymentStatus,
      'bookingDate': bookingDate,
      'serviceDate': serviceDate,
      'slot': slot,
      'price': price,
      'customerName': customerName,
      'customerEmail': customerEmail,
      'createdAt': createdAt,
    };
  }

  TechnicianBookingItem copyWith({
    String? id,
    String? serviceId,
    String? status,
    String? paymentStatus,
    String? bookingDate,
    String? serviceDate,
    String? slot,
    double? price,
    String? customerName,
    String? customerEmail,
    String? createdAt,
  }) {
    return TechnicianBookingItem(
      id: id ?? this.id,
      serviceId: serviceId ?? this.serviceId,
      status: status ?? this.status,
      paymentStatus: paymentStatus ?? this.paymentStatus,
      bookingDate: bookingDate ?? this.bookingDate,
      serviceDate: serviceDate ?? this.serviceDate,
      slot: slot ?? this.slot,
      price: price ?? this.price,
      customerName: customerName ?? this.customerName,
      customerEmail: customerEmail ?? this.customerEmail,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}

/// 🌟 মডেল: টেকনিশিয়ান সার্ভিস আইটেম
class TechnicianServiceItem {
  final String id;
  final String name;
  final String? description;
  final double price;
  final String duration;
  final String categoryId;
  final String categoryName;
  final String? createdAt;

  TechnicianServiceItem({
    required this.id,
    required this.name,
    this.description,
    required this.price,
    required this.duration,
    required this.categoryId,
    required this.categoryName,
    this.createdAt,
  });

  factory TechnicianServiceItem.fromJson(Map<String, dynamic> json) {
    final cat = json['category'] as Map<String, dynamic>?;
    return TechnicianServiceItem(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      description: json['description'],
      price: (json['price'] as num?)?.toDouble() ?? 50.0,
      duration: json['duration'] ?? '1-2 Hours',
      categoryId: json['categoryId'] ?? cat?['id'] ?? '',
      categoryName: cat?['name'] ?? 'Service',
      createdAt: json['createdAt']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'price': price,
      'duration': duration,
      'categoryId': categoryId,
      'category': {'id': categoryId, 'name': categoryName},
      'createdAt': createdAt,
    };
  }
}

/// 🌟 বুকিংস রেসপন্স
class TechnicianBookingsResponse {
  final bool success;
  final List<TechnicianBookingItem> bookings;
  final PaginationMeta meta;
  final String message;

  TechnicianBookingsResponse({
    required this.success,
    required this.bookings,
    required this.meta,
    required this.message,
  });
}

/// 🌟 সার্ভিসেস রেসপন্স
class TechnicianServicesResponse {
  final bool success;
  final List<TechnicianServiceItem> services;
  final PaginationMeta meta;
  final String message;

  TechnicianServicesResponse({
    required this.success,
    required this.services,
    required this.meta,
    required this.message,
  });
}

/// 🌟 জেনারেল অ্যাকশন রেসপন্স
class TechnicianActionResponse {
  final bool success;
  final String message;
  final dynamic data;

  TechnicianActionResponse({
    required this.success,
    required this.message,
    this.data,
  });
}


/// 🌟 মডেল: ক্যাটাগরি আইটেম
class CategoryItem {
  final String id;
  final String name;
  final String slug;
  final String? description;

  CategoryItem({
    required this.id,
    required this.name,
    required this.slug,
    this.description,
  });

  factory CategoryItem.fromJson(Map<String, dynamic> json) {
    return CategoryItem(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      slug: json['slug'] ?? '',
      description: json['description'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'slug': slug,
      'description': description,
    };
  }
}

/// 🌟 সার্ভিস ক্লাস: টেকনিশিয়ান এপিআই কন্ট্রোলার
class TechnicianService {
  // 0. টেকনিশিয়ান প্রোফাইল ফেচ (GET /api/auth/me)
  static Future<UserModel?> getProfile() async {
    return await AuthService.getUser(forceRefresh: true);
  }

  static String get baseUrl => ApiEndpoints.baseUrl;

  // 0. সব ক্যাটাগরি লোড (GET /api/categories - Public & Technician)
  static Future<List<CategoryItem>> getCategories() async {
    try {
      final uri = Uri.parse('$baseUrl/api/categories');
      final response = await http.get(uri);
      final data = jsonDecode(response.body);

      if (data['success'] == true && data['data'] is List) {
        return (data['data'] as List)
            .map((item) => CategoryItem.fromJson(item))
            .toList();
      }
    } catch (e) {
      debugPrint('Error fetching public categories in technician service: $e');
    }
    return [];
  }


  // 1. টেকনিশিয়ান বুকিংস লোড (GET /api/technician/bookings)
  static Future<TechnicianBookingsResponse> getTechnicianBookings({
    int page = 1,
    int limit = 10,
    String? status,
    String search = '',
  }) async {
    final token = await AuthService.getToken();
    if (token == null || token.isEmpty) {
      return TechnicianBookingsResponse(
        success: false,
        bookings: [],
        meta: PaginationMeta(page: 1, limit: limit, total: 0, totalPage: 1),
        message: 'Unauthorized! Please log in.',
      );
    }

    try {
      final queryParams = <String, String>{
        'page': page.toString(),
        'limit': limit.toString(),
      };
      if (search.isNotEmpty) queryParams['search'] = search.trim();
      if (status != null && status.isNotEmpty && status != 'ALL') {
        queryParams['status'] = status.trim();
      }

      final uri = Uri.parse('$baseUrl/api/technician/bookings').replace(queryParameters: queryParams);
      final response = await http.get(
        uri,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 && data['success'] == true) {
        final List list = data['data'] ?? [];
        final bookings = list.map((item) => TechnicianBookingItem.fromJson(item)).toList();
        final meta = PaginationMeta.fromJson(data['meta']);

        return TechnicianBookingsResponse(
          success: true,
          bookings: bookings,
          meta: meta,
          message: data['message']?.toString() ?? 'Bookings loaded successfully',
        );
      } else {
        return TechnicianBookingsResponse(
          success: false,
          bookings: [],
          meta: PaginationMeta(page: 1, limit: limit, total: 0, totalPage: 1),
          message: data['message']?.toString() ?? 'Failed to load bookings',
        );
      }
    } catch (e) {
      return TechnicianBookingsResponse(
        success: false,
        bookings: [],
        meta: PaginationMeta(page: 1, limit: limit, total: 0, totalPage: 1),
        message: 'Network error: $e',
      );
    }
  }

  // 2. বুকিং স্ট্যাটাস আপডেট (PATCH /api/technician/bookings/:id)
  static Future<TechnicianActionResponse> updateBookingStatus({
    required String bookingId,
    required String status,
  }) async {
    final token = await AuthService.getToken();
    if (token == null || token.isEmpty) return TechnicianActionResponse(success: false, message: 'Unauthorized');

    try {
      final uri = Uri.parse('$baseUrl/api/technician/bookings/$bookingId');
      final response = await http.patch(
        uri,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({'status': status}),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 && data['success'] == true) {
        return TechnicianActionResponse(
          success: true,
          message: data['message']?.toString() ?? 'Status updated successfully!',
          data: data['data'],
        );
      } else {
        return TechnicianActionResponse(
          success: false,
          message: data['message']?.toString() ?? 'Failed to update status',
        );
      }
    } catch (e) {
      return TechnicianActionResponse(success: false, message: 'Network error: $e');
    }
  }

  // 3. সব সার্ভিস লোড (GET /api/technician/services বা /api/services)
  static Future<TechnicianServicesResponse> getAllServices({
    int page = 1,
    int limit = 10,
    String search = '',
  }) async {
    final token = await AuthService.getToken();
    if (token == null || token.isEmpty) {
      return TechnicianServicesResponse(
        success: false,
        services: [],
        meta: PaginationMeta(page: 1, limit: limit, total: 0, totalPage: 1),
        message: 'Unauthorized! Please log in.',
      );
    }

    try {
      final queryParams = <String, String>{
        'page': page.toString(),
        'limit': limit.toString(),
      };
      if (search.isNotEmpty) queryParams['search'] = search.trim();

      final uri = Uri.parse('$baseUrl/api/services').replace(queryParameters: queryParams);
      final response = await http.get(
        uri,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 && data['success'] == true) {
        final List list = data['data'] ?? [];
        final services = list.map((item) => TechnicianServiceItem.fromJson(item)).toList();
        final meta = PaginationMeta.fromJson(data['meta']);

        return TechnicianServicesResponse(
          success: true,
          services: services,
          meta: meta,
          message: data['message']?.toString() ?? 'Services loaded successfully',
        );
      } else {
        return TechnicianServicesResponse(
          success: false,
          services: [],
          meta: PaginationMeta(page: 1, limit: limit, total: 0, totalPage: 1),
          message: data['message']?.toString() ?? 'Failed to load services',
        );
      }
    } catch (e) {
      return TechnicianServicesResponse(
        success: false,
        services: [],
        meta: PaginationMeta(page: 1, limit: limit, total: 0, totalPage: 1),
        message: 'Network error: $e',
      );
    }
  }

  // 4. নতুন সার্ভিস তৈরি (POST /api/technician/services)
  static Future<TechnicianActionResponse> createService({
    required String name,
    required String description,
    required double price,
    required String duration,
    required String categoryId,
  }) async {
    final token = await AuthService.getToken();
    if (token == null || token.isEmpty) return TechnicianActionResponse(success: false, message: 'Unauthorized');

    try {
      final uri = Uri.parse('$baseUrl/api/technician/services');
      final response = await http.post(
        uri,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'name': name.trim(),
          'description': description.trim(),
          'price': price,
          'duration': duration.trim(),
          'categoryId': categoryId,
        }),
      );

      final data = jsonDecode(response.body);

      if ((response.statusCode == 200 || response.statusCode == 201) && data['success'] == true) {
        return TechnicianActionResponse(
          success: true,
          message: data['message']?.toString() ?? 'Service created successfully!',
          data: data['data'],
        );
      } else {
        return TechnicianActionResponse(
          success: false,
          message: data['message']?.toString() ?? 'Failed to create service',
        );
      }
    } catch (e) {
      return TechnicianActionResponse(success: false, message: 'Network error: $e');
    }
  }

  // 5. সার্ভিস আপডেট (PUT /api/technician/services/:id)
  static Future<TechnicianActionResponse> updateService({
    required String id,
    required String name,
    required String description,
    required double price,
    required String duration,
    required String categoryId,
  }) async {
    final token = await AuthService.getToken();
    if (token == null || token.isEmpty) return TechnicianActionResponse(success: false, message: 'Unauthorized');

    try {
      final uri = Uri.parse('$baseUrl/api/technician/services/$id');
      final response = await http.put(
        uri,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'name': name.trim(),
          'description': description.trim(),
          'price': price,
          'duration': duration.trim(),
          'categoryId': categoryId,
        }),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 && data['success'] == true) {
        return TechnicianActionResponse(
          success: true,
          message: data['message']?.toString() ?? 'Service updated successfully!',
          data: data['data'],
        );
      } else {
        return TechnicianActionResponse(
          success: false,
          message: data['message']?.toString() ?? 'Failed to update service',
        );
      }
    } catch (e) {
      return TechnicianActionResponse(success: false, message: 'Network error: $e');
    }
  }

  // 6. সার্ভিস ডিলিট (DELETE /api/technician/services/:id)
  static Future<TechnicianActionResponse> deleteService(String id) async {
    final token = await AuthService.getToken();
    if (token == null || token.isEmpty) return TechnicianActionResponse(success: false, message: 'Unauthorized');

    try {
      final uri = Uri.parse('$baseUrl/api/technician/services/$id');
      final response = await http.delete(
        uri,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 && data['success'] == true) {
        return TechnicianActionResponse(
          success: true,
          message: data['message']?.toString() ?? 'Service deleted successfully!',
        );
      } else {
        return TechnicianActionResponse(
          success: false,
          message: data['message']?.toString() ?? 'Failed to delete service',
        );
      }
    } catch (e) {
      return TechnicianActionResponse(success: false, message: 'Network error: $e');
    }
  }

  // 7. টেকনিশিয়ান প্রোফাইল আপডেট (PUT /api/technician/profile)
  static Future<TechnicianActionResponse> updateProfile({
    required String bio,
    required String location,
    required double hourlyRate,
    required List<String> skills,
  }) async {
    final token = await AuthService.getToken();
    if (token == null || token.isEmpty) return TechnicianActionResponse(success: false, message: 'Unauthorized');

    try {
      final uri = Uri.parse('$baseUrl/api/technician/profile');
      final response = await http.put(
        uri,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'bio': bio.trim(),
          'location': location.trim(),
          'hourlyRate': hourlyRate,
          'skills': skills,
        }),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 && data['success'] == true) {
        return TechnicianActionResponse(
          success: true,
          message: data['message']?.toString() ?? 'Profile details updated successfully!',
          data: data['data'],
        );
      } else {
        return TechnicianActionResponse(
          success: false,
          message: data['message']?.toString() ?? 'Failed to update profile details',
        );
      }
    } catch (e) {
      return TechnicianActionResponse(success: false, message: 'Network error: $e');
    }
  }

  // 8. টেকনিশিয়ান শিডিউল ও অ্যাভেইলেবিলিটি আপডেট (PUT /api/technician/availability)
  static Future<TechnicianActionResponse> updateAvailability({
    required bool isAvailable,
    List<String>? workingDays,
    String? workingHours,
  }) async {
    final token = await AuthService.getToken();
    if (token == null || token.isEmpty) return TechnicianActionResponse(success: false, message: 'Unauthorized');

    try {
      final uri = Uri.parse('$baseUrl/api/technician/availability');
      final response = await http.put(
        uri,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'availability': {
            'isAvailable': isAvailable,
            'workingDays': ?workingDays,
            'workingHours': ?workingHours?.trim(),
          },
        }),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 && data['success'] == true) {
        return TechnicianActionResponse(
          success: true,
          message: data['message']?.toString() ?? 'Availability updated successfully!',
          data: data['data'],
        );
      } else {
        return TechnicianActionResponse(
          success: false,
          message: data['message']?.toString() ?? 'Failed to update availability',
        );
      }
    } catch (e) {
      return TechnicianActionResponse(success: false, message: 'Network error: $e');
    }
  }

  // 9. পাসওয়ার্ড পরিবর্তন (PATCH /api/auth/change-password)
  static Future<TechnicianActionResponse> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    final token = await AuthService.getToken();
    if (token == null || token.isEmpty) return TechnicianActionResponse(success: false, message: 'Unauthorized');

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
        return TechnicianActionResponse(
          success: true,
          message: data['message']?.toString() ?? 'Password changed successfully!',
        );
      } else {
        return TechnicianActionResponse(
          success: false,
          message: data['message']?.toString() ?? 'Failed to change password',
        );
      }
    } catch (e) {
      return TechnicianActionResponse(success: false, message: 'Network error: $e');
    }
  }
}
