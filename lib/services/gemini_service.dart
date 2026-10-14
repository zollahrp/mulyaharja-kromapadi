import 'dart:convert';
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
Anda adalah sistem AI agrikultur presisi tinggi untuk aplikasi PadiNexa, spesialis dalam verifikasi sampel dan analisis kesehatan daun padi (Oryza sativa) berbasis Bagan Warna Daun (BWD) serta Computer Vision.
$envData

============================================================
TAHAP 1: VALIDASI SAMPEL DAUN PADI ASLI (SANGAT KETAT)
============================================================
Sebelum menganalisis BWD atau penyakit, Anda WAJIB memeriksa apakah foto ini BENAR-BENAR merupakan DAUN TANAMAN PADI ASLI di lahan pertanian/sawah.
Aplikasi PadiNexa HANYA ditujukan untuk daun padi.

Periksa apakah foto termasuk salah satu kategori BUKAN DAUN PADI berikut:
1. HEWAN / MANUSIA: Hewan apa pun (kucing, anjing, ayam, burung, sapi, serangga close-up tanpa daun padi, dll.), manusia, wajah, jari/tangan, atau bagian tubuh.
2. KERTAS / BENDA BUATAN (TERMASUK KERTAS WARNA HIJAU): Kertas biasa/origami warna hijau, karton, buku, kartu BWD fisik yang difoto tanpa daun asli, kain/baju hijau, plastik hijau, karpet, lantai, dinding, meja, layar monitor/gadget. Kertas hijau BUKAN daun padi, jangan pernah menilai kertas hijau sebagai daun sehat atau mengukur BWD-nya!
3. TANAMAN BUKAN PADI: Tanaman hias (monstera, sansevieria, aglaonema, lidah mertua), sayuran (kangkung, bayam, sawi), gulma berdaun lebar, pohon pisang, dedaunan pohon lain yang bukan tanaman padi.
4. GAMBAR TIDAK RELEVAN / BURAM EKSTREM: Objek acak, makanan, kendaraan, foto gelap gulita total, atau foto terlalu buram/overexposed sehingga tidak ada struktur daun padi yang dapat diidentifikasi.

JIKA FOTO BUKAN DAUN PADI ASLI (HEWAN, KERTAS HIJAU, BENDA MATI, TANAMAN LAIN):
Kembalikan HANYA JSON dengan format berikut:
{
  "is_valid_rice_leaf": false,
  "detected_object": "<sebutkan apa objek yang terdeteksi, misal: 'Kertas Warna Hijau', 'Kucing / Hewan', 'Wajah / Manusia', 'Tanaman Hias'>",
  "error_message": "<pesan informatif dalam bahasa Indonesia yang ramah, contoh: 'Objek terdeteksi sebagai kertas/benda berwarna hijau, bukan daun padi alami. Pastikan mengambil foto daun padi asli di sawah.' atau 'Objek terdeteksi sebagai hewan (kucing), bukan daun tanaman padi. Silakan arahkan kamera ke daun padi.'>"
}

============================================================
TAHAP 2: ANALISIS BWD & KESEHATAN DAUN PADI (JIKA VALID)
============================================================
HANYA jika gambar terbukti merupakan DAUN PADI ASLI, lakukan analisis mendalam:

PEDOMAN BWD DAN STATUS NITROGEN (N) SESUAI STANDAR:
2: Unsur N sangat kurang
3: Unsur N kurang
4: Unsur N Ideal
5: Kelebihan Nitrogen
(Gunakan angka desimal bila berada di antara skala, misal 2.5, 3.2, 3.8).

ACUAN REKOMENDASI PEMUPUKAN UREA BERDASARKAN TINGKAT HASIL (GKG):
- Target 5 t/ha: Nilai BWD 2-3 (75 kg/ha), Antara 3-4 (50 kg/ha), 4-5 (0 kg/ha)
- Target 6 t/ha: Nilai BWD 2-3 (100 kg/ha), Antara 3-4 (75 kg/ha), 4-5 (0 atau 50 kg/ha)
- Target 7 t/ha: Nilai BWD 2-3 (125 kg/ha), Antara 3-4 (100 kg/ha), 4-5 (50 kg/ha)
- Target 8 t/ha: Nilai BWD 2-3 (150 kg/ha), Antara 3-4 (125 kg/ha), 4-5 (50 kg/ha)

KONSEP BWD vs GEJALA PENYAKIT:
1. BWD rendah tanpa gejala lesi/bercak -> Murni defisiensi Nitrogen.
2. BWD rendah + ada lesi/bercak -> Berpotensi infeksi patogen/penyakit, jangan asal tambah pupuk N.
3. BWD normal + ada lubang/bekas gigitan -> Indikasi serangan hama mekanis.
4. BWD normal + ada bercak/nekrosis/hawar -> Tanaman terinfeksi penyakit patogen.

FORMAT OUTPUT JIKA DAUN PADI VALID (HANYA JSON murni tanpa markdown):
{
  "is_valid_rice_leaf": true,
  "bwd_value": <float, estimasi nilai BWD antara 1.0 sampai 5.0>,
  "bwd_status": <string, misal "Sangat rendah", "Rendah", "Cukup", "Tinggi", "Sangat tinggi">,
  "nitrogen_status": <string, misal "Sangat rendah", "Berpotensi kurang", "Cukup", "Tinggi">,
  "pest_symptoms": <string, detail gejala hama atau "Tidak terdeteksi">,
  "disease_symptoms": <string, detail gejala penyakit atau "Tidak terdeteksi">,
  "bwd_interpretation": <string, arti nilai BWD dari kehijauan daun dan kecukupan hara N>,
  "conclusion": <string, paragraf simpulan gabungan status kehijauan BWD, status N, dan deteksi gejala visual hama/penyakit>,
  "recommendation": <string, saran tindakan spesifik: dosis pemupukan jika defisiensi N, atau penanganan jika ada penyakit/hama>,
  "plant_age": <string, umur tanaman atau HST>,
  "variety": <string, varietas jika diketahui atau "Padi Standar">,
  "microclimate": <string, ringkasan kondisi lingkungan>,
  "color_index": <float, estimasi indeks kehijauan 0.0 - 1.0>,
  "image_quality": <string, misal "Sangat Baik", "Baik", "Cukup">,
  "light_intensity": <string, misal "Optimal", "Kurang">,
  "confidence": <integer, persentase keyakinan 50 - 99>
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
        final Map<String, dynamic> data = jsonDecode(jsonString);

        // Validasi apakah daun padi atau bukan
        if (data['is_valid_rice_leaf'] == false) {
          final detected = data['detected_object'] ?? 'Bukan Daun Padi';
          final errorMsg = data['error_message'] ?? 'Objek yang dipindai terdeteksi sebagai $detected, bukan daun padi asli. Silakan ambil foto daun padi di sawah.';
          throw Exception(errorMsg);
        }

        // Perlindungan tambahan jika model tetap menandai true namun mendeskripsikan kertas/hewan
        final conclusion = (data['conclusion'] ?? '').toString().toLowerCase();
        final pest = (data['pest_symptoms'] ?? '').toString().toLowerCase();
        final disease = (data['disease_symptoms'] ?? '').toString().toLowerCase();
        final detected = (data['detected_object'] ?? '').toString().toLowerCase();
        final fullText = '$conclusion $pest $disease $detected';

        if (fullText.contains('kertas') || fullText.contains('paper') || fullText.contains('karton')) {
          throw Exception('Objek terdeteksi sebagai kertas/benda berwarna hijau, bukan daun padi alami. Pastikan mengambil foto daun padi asli di sawah.');
        }

        if (fullText.contains('kucing') || fullText.contains('anjing') || fullText.contains('hewan') || fullText.contains('animal') || fullText.contains('burung')) {
          throw Exception('Objek terdeteksi sebagai hewan/makhluk hidup non-tanaman. Harap arahkan kamera ke daun padi.');
        }

        return data;
      } else {
        throw Exception('Gagal mendapatkan respons teks dari sistem cerdas Gemini.');
      }
    } catch (e) {
      if (e is Exception) {
        rethrow;
      }
      throw Exception('Terjadi kesalahan saat analisis: $e');
    }
  }
}
