import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ApiService {
  static const String defaultBaseUrl = 'https://padinexa.wisatamulyaharja.com/api';

  static String get baseUrl {
    final envUrl = dotenv.env['API_BASE_URL'];
    if (envUrl != null && envUrl.trim().isNotEmpty) {
      return envUrl.trim();
    }
    return defaultBaseUrl;
  }

  static String get rootUrl {
    final url = baseUrl;
    if (url.endsWith('/api')) {
      return url.substring(0, url.length - 4);
    }
    return url;
  }

  static String getStorageUrl(String? path) {
    if (path == null || path.isEmpty) return '';
    if (path.startsWith('http://') || path.startsWith('https://')) return path;
    var cleanPath = path.startsWith('/') ? path.substring(1) : path;
    if (cleanPath.startsWith('api/')) {
      cleanPath = cleanPath.substring(4);
    }
    if (cleanPath.startsWith('storage/')) {
      cleanPath = cleanPath.substring(8);
    }
    // Server cPanel melayani file upload via endpoint Laravel /api/storage/
    // yang juga dilengkapi header CORS (Access-Control-Allow-Origin: *)
    return '$rootUrl/api/storage/$cleanPath';
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
