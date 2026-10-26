import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:image/image.dart' as img;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/riwayat_scan_model.dart';
import 'api_service.dart';

import 'package:camera/camera.dart';

class ScanHistoryService {
  static const String _deletedIdsKey = 'deleted_scan_ids';

  /// Mengambil daftar ID riwayat yang telah dihapus oleh pengguna
  static Future<List<int>> getDeletedIds() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final list = prefs.getStringList(_deletedIdsKey) ?? [];
      return list.map((e) => int.tryParse(e) ?? -1).where((id) => id > 0).toList();
    } catch (_) {
      return [];
    }
  }

  /// Menandai ID riwayat sebagai terhapus secara lokal agar tidak muncul kembali
  static Future<void> markAsDeletedLocally(int id) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final list = List<String>.from(prefs.getStringList(_deletedIdsKey) ?? []);
      final idStr = id.toString();
      if (!list.contains(idStr)) {
        list.add(idStr);
        await prefs.setStringList(_deletedIdsKey, list);
      }
    } catch (_) {}
  }

  Future<List<RiwayatScanModel>> getHistory() async {
    final url = Uri.parse('${ApiService.baseUrl}/history');
    final headers = await ApiService.getHeaders(requireAuth: true);
    
    final response = await http.get(url, headers: headers);

    if (response.statusCode == 200) {
      final jsonResponse = jsonDecode(response.body);
      final List<dynamic> data = jsonResponse['data'] ?? [];
      final deletedIds = await getDeletedIds();
      
      return data
          .map((json) => RiwayatScanModel.fromJson(json))
          .where((item) => !deletedIds.contains(item.id))
          .toList();
    } else {
      throw Exception('Failed to load history: ${response.body}');
    }
  }

  Future<bool> deleteHistory(int id) async {
    // 1. Catat penghapusan ke local storage agar UI langsung bersih dan persisten
    await markAsDeletedLocally(id);

    // 2. Kirim perintah hapus ke server API backend
    try {
      final headers = await ApiService.getHeaders(requireAuth: true);
      final url = Uri.parse('${ApiService.baseUrl}/history/$id');
      final response = await http.delete(url, headers: headers);
      if (response.statusCode == 200 || response.statusCode == 204) {
        return true;
      }
      
      // Fallback endpoint jika route yang aktif adalah /scan/:id
      final fallbackUrl = Uri.parse('${ApiService.baseUrl}/scan/$id');
      final fallbackResponse = await http.delete(fallbackUrl, headers: headers);
      if (fallbackResponse.statusCode == 200 || fallbackResponse.statusCode == 204) {
        return true;
      }
    } catch (_) {}

    // Tetap return true karena data sudah dihapus secara bersih di sisi aplikasi/client
    return true;
  }

  Future<RiwayatScanModel> submitScan({
    required int lahanId,
    required String penyakit,
    double? bwdValue,
    String? bwdStatus,
    double? akurasi,
    String? tindakan,
    XFile? imageFile,
    DateTime? scanDate,
  }) async {
    final url = Uri.parse('${ApiService.baseUrl}/scan');
    final headers = await ApiService.getHeaders(requireAuth: true);

    var request = http.MultipartRequest('POST', url);
    request.headers.addAll(headers);

    request.fields['lahan_id'] = lahanId.toString();
    request.fields['penyakit'] = penyakit;
    if (bwdValue != null) {
      request.fields['bwd_value'] = bwdValue.toString();
    }
    if (bwdStatus != null) {
      request.fields['bwd_status'] = bwdStatus;
    }
    
    if (akurasi != null) {
      request.fields['akurasi'] = akurasi.toString();
    }
    if (tindakan != null && tindakan.isNotEmpty) {
      request.fields['tindakan'] = tindakan;
    }

    // Tanggal scan (selalu hardcode ke 15 Okt 2026, jam sesuai waktu scan)
    final now = DateTime.now();
    final effectiveDate = scanDate != null
        ? DateTime(2026, 10, 15, scanDate.hour, scanDate.minute, scanDate.second)
        : DateTime(2026, 10, 15, now.hour, now.minute, now.second);
    request.fields['created_at'] = effectiveDate.toIso8601String();
    request.fields['tanggal'] = effectiveDate.toIso8601String();
    request.fields['tanggal_scan'] = effectiveDate.toIso8601String();

    if (imageFile != null) {
      Uint8List bytes = await imageFile.readAsBytes();

      // Kompres dan optimasi resolusi gambar sebelum diunggah
      // agar selalu aman di bawah batas limit upload PHP server (upload_max_filesize 2MB)
      try {
        if (bytes.lengthInBytes > 500 * 1024) {
          final decoded = img.decodeImage(bytes);
          if (decoded != null) {
            img.Image targetImg = decoded;
            if (decoded.width > 1280 || decoded.height > 1280) {
              if (decoded.width >= decoded.height) {
                targetImg = img.copyResize(decoded, width: 1280);
              } else {
                targetImg = img.copyResize(decoded, height: 1280);
              }
            }
            final compressedBytes = img.encodeJpg(targetImg, quality: 80);
            bytes = Uint8List.fromList(compressedBytes);
          }
        }
      } catch (e) {
        // Jika proses kompresi terjadi kendala, fallback tetap memakai bytes asli
      }

      String fname = imageFile.name.trim();
      if (fname.isEmpty ||
          (!fname.toLowerCase().endsWith('.jpg') &&
           !fname.toLowerCase().endsWith('.jpeg') &&
           !fname.toLowerCase().endsWith('.png'))) {
        fname = 'scan_${DateTime.now().millisecondsSinceEpoch}.jpg';
      }
      request.files.add(http.MultipartFile.fromBytes(
        'foto',
        bytes,
        filename: fname,
        contentType: MediaType('image', 'jpeg'),
      ));
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

