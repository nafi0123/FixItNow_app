import 'package:flutter_dotenv/flutter_dotenv.dart';

class ApiEndpoints {
  static String get baseUrl =>
      dotenv.env['API_BASE_URL'] ?? 'http://localhost:5001';

  // API Endpoints
  static String get categories => '$baseUrl/api/categories';
  static String get services => '$baseUrl/api/services';
  static String get technicians => '$baseUrl/api/technicians';
  // Auth Endpoints
  static String get login => '$baseUrl/api/auth/login';
  static String get register => '$baseUrl/api/auth/register';
  static String get profile => '$baseUrl/api/auth/profile';
}
