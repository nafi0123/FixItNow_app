import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../auth/providers/auth_provider.dart';
import '../../../core/constants/api_endpoints.dart';

/// 🌟 মডেল: এডমিন ইউজার আইটেম
class AdminUserItem {
  final String id;
  final String name;
  final String email;
  final String role; // "CUSTOMER", "TECHNICIAN", "ADMIN"
  final bool isBanned;
  final String? createdAt;

  AdminUserItem({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    required this.isBanned,
    this.createdAt,
  });

  factory AdminUserItem.fromJson(Map<String, dynamic> json) {
    return AdminUserItem(
      id: json['id'] ?? '',
      name: json['name'] ?? 'User',
      email: json['email'] ?? '',
      role: (json['role'] ?? 'CUSTOMER').toString().toUpperCase(),
      isBanned: json['isBanned'] == true,
      createdAt: json['createdAt']?.toString(),
    );
  }

  AdminUserItem copyWith({bool? isBanned}) {
    return AdminUserItem(
      id: id,
      name: name,
      email: email,
      role: role,
      isBanned: isBanned ?? this.isBanned,
      createdAt: createdAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'role': role,
      'isBanned': isBanned,
      'createdAt': createdAt,
    };
  }
}

/// 🌟 মডেল: এডমিন ক্যাটাগরি আইটেম
class AdminCategoryItem {
  final String id;
  final String name;
  final String slug;
  final String? description;
  final String? createdAt;

  AdminCategoryItem({
    required this.id,
    required this.name,
    required this.slug,
    this.description,
    this.createdAt,
  });

  factory AdminCategoryItem.fromJson(Map<String, dynamic> json) {
    return AdminCategoryItem(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      slug: json['slug'] ?? '',
      description: json['description'],
      createdAt: json['createdAt']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'slug': slug,
      'description': description,
      'createdAt': createdAt,
    };
  }
}

/// 🌟 পেজিনেশন মেটাডাটা
class PaginationMeta {
  final int page;
  final int limit;
  final int total;
  final int totalPage;

  PaginationMeta({
    required this.page,
    required this.limit,
    required this.total,
    required this.totalPage,
  });

  factory PaginationMeta.fromJson(Map<String, dynamic>? json) {
    if (json == null) {
      return PaginationMeta(page: 1, limit: 10, total: 0, totalPage: 1);
    }
    return PaginationMeta(
      page: json['page'] ?? 1,
      limit: json['limit'] ?? 10,
      total: json['total'] ?? 0,
      totalPage: json['totalPage'] ?? 1,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'page': page,
      'limit': limit,
      'total': total,
      'totalPage': totalPage,
    };
  }
}

/// 🌟 স্ট্যান্ডার্ড রেসপন্স ক্লাস
class AdminUsersResponse {
  final bool success;
  final List<AdminUserItem> users;
  final PaginationMeta meta;
  final String? message;

  AdminUsersResponse({
    required this.success,
    required this.users,
    required this.meta,
    this.message,
  });
}

class AdminCategoriesResponse {
  final bool success;
  final List<AdminCategoryItem> categories;
  final PaginationMeta meta;
  final String? message;

  AdminCategoriesResponse({
    required this.success,
    required this.categories,
    required this.meta,
    this.message,
  });
}

class AdminActionResponse {
  final bool success;
  final String message;

  AdminActionResponse({
    required this.success,
    required this.message,
  });
}

/// 🌟 এডমিন API সার্ভিস
class AdminService {
  static String get baseUrl => ApiEndpoints.baseUrl;

  // 1. সব ইউজার ফেচ করা (GET /api/admin/users)
  static Future<AdminUsersResponse> getAllUsers({
    int page = 1,
    int limit = 10,
    String search = '',
    String role = '',
  }) async {
    final token = await AuthService.getToken();
    if (token == null || token.isEmpty) {
      return AdminUsersResponse(
        success: false,
        users: [],
        meta: PaginationMeta(page: 1, limit: 10, total: 0, totalPage: 1),
        message: 'Unauthorized! Please login again.',
      );
    }

    try {
      final queryParams = <String, String>{
        'page': page.toString(),
        'limit': limit.toString(),
      };
      if (search.isNotEmpty) queryParams['search'] = search;
      if (role.isNotEmpty && role != 'ALL') queryParams['role'] = role;

      final uri = Uri.parse('$baseUrl/api/admin/users').replace(queryParameters: queryParams);
      final response = await http.get(
        uri,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 && data['data'] != null) {
        final list = (data['data'] as List)
            .map((item) => AdminUserItem.fromJson(item))
            .toList();
        final meta = PaginationMeta.fromJson(data['meta']);
        return AdminUsersResponse(success: true, users: list, meta: meta);
      } else {
        return AdminUsersResponse(
          success: false,
          users: [],
          meta: PaginationMeta(page: 1, limit: 10, total: 0, totalPage: 1),
          message: data['message']?.toString() ?? 'Failed to load users',
        );
      }
    } catch (e) {
      return AdminUsersResponse(
        success: false,
        users: [],
        meta: PaginationMeta(page: 1, limit: 10, total: 0, totalPage: 1),
        message: 'Network error: $e',
      );
    }
  }

  // 2. ইউজার Ban / Unban করা (PATCH /api/admin/users/:id)
  static Future<AdminActionResponse> updateUserStatus({
    required String userId,
    required bool isBanned,
  }) async {
    final token = await AuthService.getToken();
    if (token == null || token.isEmpty) {
      return AdminActionResponse(success: false, message: 'Unauthorized');
    }

    try {
      final uri = Uri.parse('$baseUrl/api/admin/users/$userId');
      final response = await http.patch(
        uri,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({'isBanned': isBanned}),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 && data['success'] == true) {
        return AdminActionResponse(
          success: true,
          message: isBanned ? 'User banned successfully' : 'User unbanned successfully',
        );
      } else {
        return AdminActionResponse(
          success: false,
          message: data['message']?.toString() ?? 'Failed to update user status',
        );
      }
    } catch (e) {
      return AdminActionResponse(success: false, message: 'Network error: $e');
    }
  }

  // 3. সব ক্যাটাগরি লোড করা (GET /api/admin/categories)
  static Future<AdminCategoriesResponse> getAllCategories({
    int page = 1,
    int limit = 10,
    String search = '',
  }) async {
    final token = await AuthService.getToken();
    if (token == null || token.isEmpty) {
      return AdminCategoriesResponse(
        success: false,
        categories: [],
        meta: PaginationMeta(page: 1, limit: 10, total: 0, totalPage: 1),
        message: 'Unauthorized!',
      );
    }

    try {
      final queryParams = <String, String>{
        'page': page.toString(),
        'limit': limit.toString(),
      };
      if (search.isNotEmpty) queryParams['search'] = search;

      final uri = Uri.parse('$baseUrl/api/admin/categories').replace(queryParameters: queryParams);
      final response = await http.get(
        uri,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 && data['data'] != null) {
        final list = (data['data'] as List)
            .map((item) => AdminCategoryItem.fromJson(item))
            .toList();
        final meta = PaginationMeta.fromJson(data['meta']);
        return AdminCategoriesResponse(success: true, categories: list, meta: meta);
      } else {
        return AdminCategoriesResponse(
          success: false,
          categories: [],
          meta: PaginationMeta(page: 1, limit: 10, total: 0, totalPage: 1),
          message: data['message']?.toString() ?? 'Failed to load categories',
        );
      }
    } catch (e) {
      return AdminCategoriesResponse(
        success: false,
        categories: [],
        meta: PaginationMeta(page: 1, limit: 10, total: 0, totalPage: 1),
        message: 'Network error: $e',
      );
    }
  }

  // 4. নতুন ক্যাটাগরি তৈরি (POST /api/admin/categories)
  static Future<AdminActionResponse> createCategory({
    required String name,
    String? description,
  }) async {
    final token = await AuthService.getToken();
    if (token == null || token.isEmpty) return AdminActionResponse(success: false, message: 'Unauthorized');

    try {
      final uri = Uri.parse('$baseUrl/api/admin/categories');
      final response = await http.post(
        uri,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'name': name.trim(),
          if (description != null && description.isNotEmpty) 'description': description.trim(),
        }),
      );

      final data = jsonDecode(response.body);

      if ((response.statusCode == 200 || response.statusCode == 201) && data['success'] == true) {
        return AdminActionResponse(success: true, message: data['message']?.toString() ?? 'Category created successfully!');
      } else {
        return AdminActionResponse(success: false, message: data['message']?.toString() ?? 'Failed to create category');
      }
    } catch (e) {
      return AdminActionResponse(success: false, message: 'Network error: $e');
    }
  }

  // 5. ক্যাটাগরি আপডেট (PUT /api/admin/categories/:id)
  static Future<AdminActionResponse> updateCategory({
    required String id,
    required String name,
    String? description,
  }) async {
    final token = await AuthService.getToken();
    if (token == null || token.isEmpty) return AdminActionResponse(success: false, message: 'Unauthorized');

    try {
      final uri = Uri.parse('$baseUrl/api/admin/categories/$id');
      final response = await http.put(
        uri,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'name': name.trim(),
          'description': description?.trim() ?? '',
        }),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 && data['success'] == true) {
        return AdminActionResponse(success: true, message: data['message']?.toString() ?? 'Category updated successfully!');
      } else {
        return AdminActionResponse(success: false, message: data['message']?.toString() ?? 'Failed to update category');
      }
    } catch (e) {
      return AdminActionResponse(success: false, message: 'Network error: $e');
    }
  }

  // 6. ক্যাটাগরি ডিলিট (DELETE /api/admin/categories/:id)
  static Future<AdminActionResponse> deleteCategory(String id) async {
    final token = await AuthService.getToken();
    if (token == null || token.isEmpty) return AdminActionResponse(success: false, message: 'Unauthorized');

    try {
      final uri = Uri.parse('$baseUrl/api/admin/categories/$id');
      final response = await http.delete(
        uri,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 && data['success'] == true) {
        return AdminActionResponse(success: true, message: data['message']?.toString() ?? 'Category deleted successfully!');
      } else {
        return AdminActionResponse(success: false, message: data['message']?.toString() ?? 'Failed to delete category');
      }
    } catch (e) {
      return AdminActionResponse(success: false, message: 'Network error: $e');
    }
  }

  // 7. এডমিন প্রোফাইল নাম আপডেট (PATCH /api/auth/update-profile)
  static Future<AdminActionResponse> updateAdminProfile({required String name}) async {
    final token = await AuthService.getToken();
    if (token == null || token.isEmpty) return AdminActionResponse(success: false, message: 'Unauthorized');

    try {
      final uri = Uri.parse('$baseUrl/api/auth/update-profile');
      final response = await http.patch(
        uri,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({'name': name.trim()}),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 && data['success'] == true) {
        return AdminActionResponse(success: true, message: data['message']?.toString() ?? 'Profile updated successfully!');
      } else {
        return AdminActionResponse(success: false, message: data['message']?.toString() ?? 'Failed to update profile');
      }
    } catch (e) {
      return AdminActionResponse(success: false, message: 'Network error: $e');
    }
  }

  // 8. পাসওয়ার্ড পরিবর্তন (PATCH /api/auth/change-password)
  static Future<AdminActionResponse> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    final token = await AuthService.getToken();
    if (token == null || token.isEmpty) return AdminActionResponse(success: false, message: 'Unauthorized');

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
        return AdminActionResponse(success: true, message: data['message']?.toString() ?? 'Password changed successfully!');
      } else {
        return AdminActionResponse(success: false, message: data['message']?.toString() ?? 'Failed to change password');
      }
    } catch (e) {
      return AdminActionResponse(success: false, message: 'Network error: $e');
    }
  }
}
