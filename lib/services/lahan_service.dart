import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/lahan_model.dart';
import 'api_service.dart';

class LahanService {
  Future<List<LahanModel>> getLahan() async {
    final url = Uri.parse('${ApiService.baseUrl}/lahan');
    final headers = await ApiService.getHeaders(requireAuth: true);
    
    final response = await http.get(url, headers: headers);

    if (response.statusCode == 200) {
      final jsonResponse = jsonDecode(response.body);
      final List<dynamic> data = jsonResponse['data'];
      return data.map((json) => LahanModel.fromJson(json)).toList();
    } else {
      throw Exception('Failed to load lahan: ${response.body}');
    }
  }
}
