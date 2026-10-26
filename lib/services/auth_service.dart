import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_model.dart';
import 'api_service.dart';

class AuthService {
  Future<UserModel?> login(String email, String password) async {
    final url = Uri.parse('${ApiService.baseUrl}/login');
    final headers = await ApiService.getHeaders();
    
    final response = await http.post(
      url,
      headers: headers,
      body: {
        'email': email,
        'password': password,
      },
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final token = data['token'];
      final userJson = data['user'];

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('auth_token', token);
      await prefs.setString('user_data', jsonEncode(userJson));

      return UserModel.fromJson(userJson);
    } else {
      throw Exception('Failed to login: ${response.body}');
    }
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('auth_token');
    await prefs.remove('user_data');
  }

  Future<UserModel?> getCurrentUser() async {
    final prefs = await SharedPreferences.getInstance();
    final userDataString = prefs.getString('user_data');
    if (userDataString != null) {
      return UserModel.fromJson(jsonDecode(userDataString));
    }
    return null;
  }

  Future<UserModel> updateProfile({required String name, required String email}) async {
    final prefs = await SharedPreferences.getInstance();
    UserModel? currentUser = await getCurrentUser();

    final updatedUser = UserModel(
      id: currentUser?.id ?? 1,
      name: name,
      email: email,
      role: currentUser?.role ?? 'petani',
      wilayahId: currentUser?.wilayahId,
      kelompokTaniId: currentUser?.kelompokTaniId,
      kelompokTaniName: currentUser?.kelompokTaniName,
      wilayah: currentUser?.wilayah,
    );

    final Map<String, dynamic> userMap = {
      'id': updatedUser.id,
      'name': updatedUser.name,
      'email': updatedUser.email,
      'role': updatedUser.role,
      'wilayah_id': updatedUser.wilayahId,
      'kelompok_tani_id': updatedUser.kelompokTaniId,
      if (updatedUser.kelompokTaniName != null) 'kelompok_tani': {'name': updatedUser.kelompokTaniName},
      if (updatedUser.wilayah != null) 'wilayah': {
        'id': updatedUser.wilayah!.id,
        'name': updatedUser.wilayah!.name,
      },
    };
    await prefs.setString('user_data', jsonEncode(userMap));

    try {
      final headers = await ApiService.getHeaders(requireAuth: true);
      headers['Content-Type'] = 'application/json';

      final bodyData = {
        'name': name,
        'email': email,
      };

      final url = Uri.parse('${ApiService.baseUrl}/profile');
      http.Response response = await http.post(
        url,
        headers: headers,
        body: jsonEncode(bodyData),
      );

      if (response.statusCode == 404 && !ApiService.baseUrl.contains('127.0.0.1') && !ApiService.baseUrl.contains('localhost')) {
        try {
          final localUrl = Uri.parse('http://127.0.0.1:8000/api/profile');
          final localResp = await http.post(
            localUrl,
            headers: headers,
            body: jsonEncode(bodyData),
          );
          if (localResp.statusCode == 200 || localResp.statusCode == 201) {
            response = localResp;
          }
        } catch (_) {}
      }

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);
        if (data['user'] != null) {
          await prefs.setString('user_data', jsonEncode(data['user']));
          return UserModel.fromJson(data['user']);
        }
      }
    } catch (_) {}

    return updatedUser;
  }

  Future<Map<String, dynamic>> changePassword({
    required String currentPassword,
    required String newPassword,
    required String confirmPassword,
  }) async {
    try {
      final headers = await ApiService.getHeaders(requireAuth: true);
      headers['Content-Type'] = 'application/json';

      final user = await getCurrentUser();
      final bodyData = {
        'current_password': currentPassword,
        'new_password': newPassword,
        'new_password_confirmation': confirmPassword,
        if (user?.email != null) 'email': user!.email,
      };

      final url = Uri.parse('${ApiService.baseUrl}/change-password');
      http.Response response = await http.post(
        url,
        headers: headers,
        body: jsonEncode(bodyData),
      );

      if (response.statusCode == 404 && !ApiService.baseUrl.contains('127.0.0.1') && !ApiService.baseUrl.contains('localhost')) {
        try {
          final localUrl = Uri.parse('http://127.0.0.1:8000/api/change-password');
          final localResp = await http.post(
            localUrl,
            headers: headers,
            body: jsonEncode(bodyData),
          );
          if (localResp.statusCode == 200 || localResp.statusCode == 422 || localResp.statusCode == 401) {
            response = localResp;
          }
        } catch (_) {}
      }

      final data = jsonDecode(response.body);
      if (response.statusCode == 200) {
        return {'success': true, 'message': data['message'] ?? 'Kata sandi berhasil diubah.'};
      } else {
        return {
          'success': false,
          'message': data['message'] ?? 'Gagal mengubah kata sandi. Periksa kembali data Anda.',
        };
      }
    } catch (e) {
      return {'success': false, 'message': 'Terjadi kendala jaringan saat menghubungi server.'};
    }
  }
}
