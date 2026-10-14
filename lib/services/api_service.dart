import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ApiService {
  static String get baseUrl {
    // Pada Chrome (Flutter Web), selalu gunakan 127.0.0.1 agar lancar dan bebas CORS
    if (kIsWeb) {
      return 'http://127.0.0.1:8000/api';
    }
    // Pada HP Android (APK / perangkat fisik), gunakan IP Wi-Fi laptop dari .env
    return dotenv.env['API_BASE_URL'] ?? 'http://192.168.108.17:8000/api';
  }

  static Future<Map<String, String>> getHeaders({bool requireAuth = false}) async {
    Map<String, String> headers = {
      'Accept': 'application/json',
    };

    if (requireAuth) {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');
      if (token != null) {
        headers['Authorization'] = 'Bearer $token';
      }
    }
    return headers;
  }
}
