import 'dart:convert';
import 'dart:io';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:camera/camera.dart';

class GeminiService {
  late final GenerativeModel _model;

  GeminiService() {
    final apiKey = dotenv.env['GEMINI_API_KEY'];
    if (apiKey == null || apiKey.isEmpty || apiKey == 'YOUR_GEMINI_API_KEY_HERE') {
      throw Exception('API Key Gemini belum diatur. Silakan atur di file .env');
    }

    _model = GenerativeModel(
      model: 'gemini-3.1-flash-lite',
      apiKey: apiKey,
      generationConfig: GenerationConfig(
        responseMimeType: 'application/json',
      ),
    );
  }

  Future<Map<String, dynamic>> analyzeLeaf(XFile imageFile) async {
    try {
      final imageBytes = await imageFile.readAsBytes();
      
      final prompt = '''
Anda adalah ahli pertanian cerdas yang bertugas menganalisis kesehatan daun padi, khususnya terkait tingkat Nitrogen (BWD), gejala serangan hama, dan penyakit.
Saya akan memberikan gambar daun padi. Tolong analisis gambar tersebut dan berikan output dalam format JSON berikut dengan tipe data yang sesuai:
{
  "bwd_value": <float, antara 1.0 sampai 5.0>,
  "bwd_status": <string, misalnya "Rendah", "Cukup", "Tinggi">,
  "bwd_interpretation": <string, penjelasan singkat arti nilai BWD ini>,
  "nitrogen_status": <string, misalnya "Berpotensi Kurang", "Normal", "Berlebih">,
  "pest_symptoms": <string, misalnya "Tidak terdeteksi" atau sebutkan gejalanya>,
  "disease_symptoms": <string, misalnya "Tidak terdeteksi" atau sebutkan gejalanya>,
  "conclusion": <string, paragraf singkat berisi kesimpulan kondisi daun>,
  "recommendation": <string, saran tindakan yang harus dilakukan>,
  "color_index": <float, contoh: 0.42>,
  "image_quality": <string, contoh: "Baik">,
  "light_intensity": <string, contoh: "Cukup">,
  "confidence": <integer, persentase dari 0-100, contoh: 87>
}
Hanya kembalikan JSON murni tanpa ada formatting markdown tambahan (jangan pakai ```json).
''';

      final content = [
        Content.multi([
          TextPart(prompt),
          DataPart('image/jpeg', imageBytes),
        ])
      ];

      final response = await _model.generateContent(content);
      
      if (response.text != null) {
        final jsonString = response.text!.trim().replaceAll('```json', '').replaceAll('```', '');
        return jsonDecode(jsonString);
      } else {
        throw Exception('Gagal mendapatkan respons teks dari Gemini.');
      }
    } catch (e) {
      throw Exception('Terjadi kesalahan saat analisis: $e');
    }
  }
}
