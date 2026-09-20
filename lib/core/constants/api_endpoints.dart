import 'package:flutter_dotenv/flutter_dotenv.dart';

class ApiEndpoints {
  static String get baseUrl => dotenv.env['API_BASE_URL'] ?? 'http://localhost:5001';

  // Categories API Endpoint
  static String get categories => '$baseUrl/api/categories';
    static String get technicians => '$baseUrl/api/technicians';

}
