import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ApiService {
  static String get baseUrl {
    String url = dotenv.env['API_BASE_URL'] ?? 'http://10.0.2.2:8000/api';
    if (kIsWeb) {
      url = url.replaceAll('10.0.2.2', '127.0.0.1');
    }
    return url;
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
