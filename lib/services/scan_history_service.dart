import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/riwayat_scan_model.dart';
import 'api_service.dart';

class ScanHistoryService {
  Future<List<RiwayatScanModel>> getHistory() async {
    final url = Uri.parse('${ApiService.baseUrl}/history');
    final headers = await ApiService.getHeaders(requireAuth: true);
    
    final response = await http.get(url, headers: headers);

    if (response.statusCode == 200) {
      final jsonResponse = jsonDecode(response.body);
      final List<dynamic> data = jsonResponse['data'];
      return data.map((json) => RiwayatScanModel.fromJson(json)).toList();
    } else {
      throw Exception('Failed to load history: ${response.body}');
    }
  }

  Future<RiwayatScanModel> submitScan({
    required int lahanId,
    required String penyakit,
    double? akurasi,
    String? tindakan,
    String? fotoPath,
  }) async {
    final url = Uri.parse('${ApiService.baseUrl}/scan');
    final headers = await ApiService.getHeaders(requireAuth: true);

    var request = http.MultipartRequest('POST', url);
    request.headers.addAll(headers);

    request.fields['lahan_id'] = lahanId.toString();
    request.fields['penyakit'] = penyakit;
    
    if (akurasi != null) {
      request.fields['akurasi'] = akurasi.toString();
    }
    if (tindakan != null && tindakan.isNotEmpty) {
      request.fields['tindakan'] = tindakan;
    }

    if (fotoPath != null && fotoPath.isNotEmpty) {
      request.files.add(await http.MultipartFile.fromPath('foto', fotoPath));
    }

    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);

    if (response.statusCode == 200 || response.statusCode == 201) {
      final jsonResponse = jsonDecode(response.body);
      return RiwayatScanModel.fromJson(jsonResponse['data']);
    } else {
      throw Exception('Failed to submit scan: ${response.body}');
    }
  }
}
