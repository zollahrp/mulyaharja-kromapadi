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

  Future<Map<String, dynamic>> analyzeLeaf(
    XFile imageFile, {
    String? weather,
    double? temperature,
    int? humidity,
    int? lux,
    int? plantAgeDays,
  }) async {
    try {
      final imageBytes = await imageFile.readAsBytes();
      
      String envData = "";
      if (weather != null || temperature != null || lux != null || plantAgeDays != null) {
        envData = "Data Lingkungan dan Tanaman:\n";
        if (plantAgeDays != null) envData += "- Umur Tanaman: $plantAgeDays Hari Setelah Tanam (HST)\n";
        if (weather != null) envData += "- Cuaca: $weather\n";
        if (temperature != null) envData += "- Suhu: $temperature °C\n";
        if (humidity != null) envData += "- Kelembapan: $humidity %\n";
        if (lux != null) envData += "- Intensitas Cahaya: $lux Lux\n";
      }

      final prompt = '''
Anda adalah ahli pertanian cerdas yang bertugas menganalisis kesehatan daun padi dengan pedoman BWD dan Computer Vision.
$envData

PEDOMAN BWD DAN STATUS NITROGEN (N) SESUAI STANDAR:
2: Unsur N sangat kurang
3: Unsur N kurang
4: Unsur N Ideal
5: Kelebihan Nitrogen

(Catatan: Jika di antara 2 skala, misal 2.5 atau 3.5, berikan estimasi sesuai rentangnya).

ACUAN REKOMENDASI PEMUPUKAN UREA (Contoh Target Hasil 6 Ton/ha):
- Nilai BWD 2 - 3: Takaran urea 100 kg/ha
- Nilai BWD 3 - 4: Takaran urea 75 kg/ha
- Nilai BWD 4 - 5: Takaran urea 0 atau 50 kg/ha
Catatan: Pemupukan N idealnya dilakukan 2 atau 3 kali (dasar dan susulan) sesuai fase (21-28 HST dan 35-40 HST).

KONSEP UTAMA (BWD ≠ Diagnosis Kesehatan Keseluruhan):
BWD mengestimasi kehijauan daun terkait status N, bukan alat diagnosis penyakit. Oleh karena itu, bedakan kondisi berikut:
1. Kondisi 1 (BWD rendah tanpa gejala lain): Tidak ada bercak, lubang, nekrosis -> Dugaan utama: defisiensi N.
2. Kondisi 2 (BWD rendah + gejala penyakit): Ada bercak/lesi -> BWD rendah bukan berarti kurang N, tapi berpotensi infeksi patogen. Perlu pemeriksaan lanjut, JANGAN langsung sarankan pupuk N.
3. Kondisi 3 (BWD normal + gejala hama): BWD 3-4, tapi ada bekas gigitan, lubang, jaringan daun terpotong, atau daun menggulung -> Status N relatif normal, tapi ada indikasi serangan hama.
4. Kondisi 4 (BWD normal + gejala penyakit): BWD 3-4, tapi ada bercak, nekrosis, hawar, atau lesi -> BWD normal, tapi tanaman tidak sehat (indikasi patogen).

PARAMETER GEJALA:
- HAMA (Kerusakan Mekanis/Feeding Damage): lubang pada daun, bagian daun hilang, tepi daun rusak, jaringan daun terpotong, daun menggulung, perubahan bentuk, daun mengering, kerusakan pada pucuk, perubahan warna lokal.
- PENYAKIT/PATOGEN (Pola Visual): bercak daun, nekrosis, klorosis, hawar, lesi, perubahan warna tidak merata, perubahan bentuk jaringan.

TUGAS ANDA:
Analisis gambar daun padi yang diberikan dan kombinasikan BWD sebagai indikator status hara + Computer Vision sebagai indikator kesehatan visual (gejala penyakit/hama) menjadi satu simpulan cerdas pendukung keputusan. Jangan gantikan diagnosis lapangan, melainkan berikan saran yang aman (jika terdeteksi penyakit, sarankan cek lapangan daripada memupuk N).

Saya akan memberikan gambar daun padi. Tolong berikan output HANYA dalam format JSON berikut (tanpa markdown ```json):
{
  "bwd_value": <float, estimasi nilai BWD antara 1.0 sampai 5.0>,
  "bwd_status": <string, misal "Sangat rendah", "Rendah", "Cukup", "Tinggi", "Sangat tinggi">,
  "nitrogen_status": <string, misal "Sangat rendah", "Berpotensi kurang", "Cukup", "Tinggi">,
  "pest_symptoms": <string, sebutkan detail gejalanya atau "Tidak terdeteksi">,
  "disease_symptoms": <string, sebutkan detail gejalanya atau "Tidak terdeteksi">,
  "bwd_interpretation": <string, arti nilai BWD dari kehijauan daun>,
  "conclusion": <string, paragraf simpulan gabungan antara status kehijauan BWD, status N, dan deteksi gejala visual hama/penyakit>,
  "recommendation": <string, saran tindakan, jika ada penyakit, tekankan untuk periksa lapangan lebih lanjut. Jika murni defisiensi N, sarankan dosis pemupukan sesuai fase>,
  "plant_age": <string, umur tanaman atau HST>,
  "variety": <string, varietas jika diketahui atau "Belum diketahui">,
  "microclimate": <string, ringkasan iklim mikro dari data jika ada>,
  "color_index": <float, estimasi indeks warna daun>,
  "image_quality": <string, penilaian kualitas gambar (maks 2 kata, misal "Sangat Baik")>,
  "light_intensity": <string, kondisi cahaya saat foto (maks 2 kata, misal "Optimal")>,
  "confidence": <integer, tingkat keyakinan dalam persentase, misal 85>
}
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
