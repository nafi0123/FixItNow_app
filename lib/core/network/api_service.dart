import 'dart:convert';
import 'package:http/http.dart' as http;
import '../constants/api_endpoints.dart';
import '../../features/categories/models/category_model.dart';
import '../../features/technicians/models/technician_model.dart';

class ApiService {
  // ১. সব ক্যাটাগরি আনার কমন মেথড
  static Future<List<CategoryModel>> getCategories() async {
    final response = await http.get(Uri.parse(ApiEndpoints.categories));
    if (response.statusCode == 200) {
      final decoded = jsonDecode(response.body);
      if (decoded['success'] == true && decoded['data'] is List) {
        return (decoded['data'] as List)
            .map((json) => CategoryModel.fromJson(json))
            .toList();
      }
    }
    throw Exception("Failed to load categories");
  }

  // ২. সব টেকনিশিয়ান আনার কমন মেথড
  static Future<List<TechnicianModel>> getTechnicians() async {
    final response = await http.get(Uri.parse(ApiEndpoints.technicians));
    if (response.statusCode == 200) {
      final decoded = jsonDecode(response.body);
      if (decoded['success'] == true && decoded['data'] is List) {
        return (decoded['data'] as List)
            .map((json) => TechnicianModel.fromJson(json))
            .toList();
      }
    }
    throw Exception("Failed to load technicians");
  }
}
