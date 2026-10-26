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
TAHAP 1: VALIDASI SAMPEL DAUN PADI ASLI
============================================================
Sebelum menganalisis BWD atau penyakit, Anda memeriksa apakah foto ini MEMUAT DAUN TANAMAN PADI ASLI (Oryza sativa) di sawah/lahan pertanian.
Aplikasi PadiNexa ditujukan untuk analisis kesehatan dan Bagan Warna Daun (BWD) tanaman padi.

ATURAN VALIDASI SAMPEL (SANGAT PENTING):
A. SAMPEL YANG WAJIB DINILAI VALID (is_valid_rice_leaf: true):
   1. Foto helai daun padi close-up (1 helai atau beberapa helai daun padi).
   2. Foto tanaman padi, segenggam daun padi, atau satu rumpun padi yang sedang dipegang tangan oleh petani/peneliti (seperti foto petani/peneliti memegang rumpun daun padi di sawah). Tangan yang memegang batang/rumpun di sawah adalah hal lumrah di lapangan, JANGAN PERNAH menolak foto hanya karena ada tangan yang memegang tanaman padi!
   3. Foto rumpun padi di petak sawah dari jarak dekat atau sedang (30 cm hingga 1 meter) di mana helai-helai daun padi terlihat jelas memanjang ke atas beserta warnanya.
   JIKA foto memenuhi salah satu kriteria di atas, MAKA FOTO ADALAH VALID (is_valid_rice_leaf: true) dan LANGSUNG LANJUT KE TAHAP 2!

B. KAPAN FOTO HARUS DITOLAK SEBAGAI TIDAK VALID (is_valid_rice_leaf: false):
   HANYA tolak jika gambar BENAR-BENAR BUKAN daun padi atau lanskap ekstrem berikut:
   1. BENDA BUATAN / KERTAS: Kertas origami hijau, karton, kartu BWD fisik tanpa daun asli, kain/plastik hijau, dinding, meja, layar HP/laptop, makanan, kendaraan.
   2. HEWAN / WAJAH MANUSIA: Foto kucing, anjing, burung, atau selfie wajah manusia TANPA adanya tanaman padi.
   3. TANAMAN LAIN (BUKAN PADI): Tanaman hias (monstera, lidah mertua, aglaonema), sayuran (kangkung, bayam), pohon pisang, gulma daun bulat/lebar.
   4. FOTO LANSKAP SAWAH DARI JARAK SANGAT JAUH SEKALI: HANYA jika foto berupa pemandangan bentang sawah dari kejauhan sangat jauh (jarak belasan/puluhan meter, foto pemandangan lanskap bukit, atau foto udara/drone) di mana helai-helai daun padi individual sama sekali TIDAK TERLIHAT dan hanya berupa hamparan hijau tanpa wujud daun.
      (INGAT: Jika memotret tanaman padi dari jarak dekat/sedang, satu rumpun padi, atau padi dipegang tangan di sawah, ini BUKAN terlalu jauh! Ini adalah SAMPEL VALID!).

JIKA FOTO JELAS MEMENUHI KRITERIA PENOLAKAN (B), KEMBALIKAN JSON:
{
  "is_valid_rice_leaf": false,
  "detected_object": "<sebutkan apa objek yang terdeteksi, misal: 'Kertas Warna Hijau', 'Pemandangan Lanskap Sawah Terlalu Jauh', 'Tanaman Hias'>",
  "error_message": "<pesan informatif dalam bahasa Indonesia yang ramah>"
}

============================================================
TAHAP 2: ANALISIS BWD & KESEHATAN DAUN PADI (JIKA VALID)
============================================================
Lakukan analisis agronomi mendalam pada daun padi yang tampak pada foto:
- Jika foto memuat beberapa helai daun atau satu rumpun daun padi (seperti rumpun padi yang dipegang tangan):
  1. Periksa kesehatan seluruh helai daun padi yang terlihat:
     - Teliti apakah ada helai daun yang mengalami klorosis/menguning, garis oranye/kuning memanjang, atau nekrosis kecokelatan kering dari ujung/tepi daun. Gejala garis memanjang kuning-oranye dari tepi atau ujung helai daun padi adalah ciri khas infeksi Hawar Daun Bakteri (Xanthomonas oryzae pv. oryzae), Blas Daun (Pyricularia oryzae), atau Bercak Coklat.
     - Jika terdeteksi gejala penyakit tersebut, tandai has_disease: true, sebutkan nama spesifik penyakitnya (misal "Hawar Daun Bakteri"), dan jelaskan gejalanya secara detail pada disease_symptoms.
     - Periksa apakah ada bekas gigitan hama serangga/ulat. Jika tidak ada, has_pest: false dan pest_name: "Nihil".
  2. Evaluasi Skala BWD:
     - Tentukan nilai BWD rata-rata (skala 1.0 - 5.0) berdasarkan tingkat kehijauan helai-helai daun padi produktif (daun atas/tengah yang dominan).
     - Berikan interpretasi BWD dan status hara Nitrogen (Urea).

PEDOMAN BWD DAN STATUS NITROGEN (N) SESUAI STANDAR BALITBANGTAN / IRRI:
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

PRINSIP ILMIAH AGRONOMI (HAMA vs PENYAKIT PATOGEN):
1. HAMA TANAMAN (PEST): Kerusakan fisik/mekanis oleh organisme hewan/serangga (contoh: bekas gigitan serangga, ulat penggulung daun, lubang gerek, wereng batang coklat). JANGAN PERNAH mengelompokkan gigitan serangga atau hama sebagai infeksi penyakit!
2. PENYAKIT TANAMAN (DISEASE): Infeksi patogen mikroorganisme (jamur/fungi, bakteri, virus) seperti Hawar Daun Bakteri (Xanthomonas oryzae), Blas Daun (Pyricularia oryzae), Bercak Coklat (Bipolaris oryzae), atau Tungro.
3. DAUN SEHAT: Jika tidak tampak lesi/bercak/hawar/nekrosis patogen, maka tanaman bebas penyakit (has_disease: false, disease_name: "Normal / Sehat").
4. HUBUNGAN BWD & HARA N: Nilai BWD semata-mata mengukur tingkat kehijauan daun dan kecukupan hara Nitrogen (Urea), BUKAN penyakit.

FORMAT OUTPUT JIKA DAUN PADI VALID (HANYA JSON murni tanpa markdown):
{
  "is_valid_rice_leaf": true,
  "bwd_value": <float, estimasi nilai BWD antara 1.0 sampai 5.0>,
  "bwd_status": <string, misal "Sangat rendah", "Rendah", "Cukup", "Tinggi", "Sangat tinggi">,
  "nitrogen_status": <string, misal "Sangat rendah", "Berpotensi kurang", "Cukup", "Tinggi">,
  "has_pest": <boolean, true jika terdeteksi kerusakan/serangan hama serangga atau ulat, false jika nihil/bersih>,
  "pest_name": <string, misal "Bekas Gigitan Serangga", "Ulat Penggulung Daun", atau "Nihil">,
  "pest_symptoms": <string, detail gejala hama serangga atau "Tidak terdeteksi serangan hama">,
  "has_disease": <boolean, true HANYA jika terdeteksi infeksi patogen jamur/bakteri/virus, false jika tidak ada lesi/patogen>,
  "disease_name": <string, nama spesifik penyakit jika ada misal "Hawar Daun Bakteri", atau "Normal / Sehat">,
  "disease_symptoms": <string, detail gejala penyakit patogen atau "Tidak terdeteksi gejala penyakit hawar atau bercak daun">,
  "bwd_interpretation": <string, arti nilai BWD dari kehijauan daun dan kecukupan hara N>,
  "conclusion": <string, ringkasan diagnosis terpadu yang memisahkan status kehijauan N, deteksi hama serangga, dan status penyakit patogen>,
  "recommendation_basis": <string, dasar acuan ilmiah: "Acuan Skala Bagan Warna Daun (BWD) IRRI / Balitbangtan Kementan RI untuk pemupukan N dan pengamatan visual gejala fisik untuk hama/patogen">,
  "recommendation": <string, saran tindakan spesifik yang membedakan: 1. Rekomendasi Pemupukan Urea (kg/ha) berdasarkan BWD dan target panen, 2. Rekomendasi Pengendalian Hama / Sanitasi Penyakit jika ada tanda lapangan>,
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

      GenerateContentResponse? response;
      const int maxRetries = 2;
      for (int attempt = 0; attempt <= maxRetries; attempt++) {
        try {
          response = await _model.generateContent(content);
          break;
        } catch (e) {
          final errStr = e.toString().toLowerCase();
          final isTransient = errStr.contains('503') ||
              errStr.contains('high demand') ||
              errStr.contains('unavailable') ||
              errStr.contains('resource has been exhausted') ||
              errStr.contains('resource_exhausted') ||
              errStr.contains('429');

          if (isTransient && attempt < maxRetries) {
            // Beri jeda exponential backoff sebelum mencoba lagi otomatis
            await Future.delayed(Duration(milliseconds: 1500 * (attempt + 1)));
            continue;
          }

          if (isTransient) {
            throw Exception('SERVER_BUSY: Server AI sedang mengalami antrean trafik tinggi (HTTP 503). Lonjakan permintaan ini bersifat sementara, silakan coba beberapa saat lagi.');
          }
          rethrow;
        }
      }
      
      if (response != null && response.text != null) {
        final jsonString = response.text!.trim().replaceAll('```json', '').replaceAll('```', '');
        final Map<String, dynamic> data = jsonDecode(jsonString);

        // Validasi apakah daun padi atau bukan
        if (data['is_valid_rice_leaf'] == false) {
          final detected = data['detected_object'] ?? 'Bukan Daun Padi';
          final errorMsg = data['error_message'] ?? 'Objek yang dipindai terdeteksi sebagai $detected, bukan daun padi asli. Silakan ambil foto daun padi di sawah.';
          throw Exception(errorMsg);
        }

        // Perlindungan tambahan jika model tetap mendeskripsikan kertas atau hewan
        final conclusion = (data['conclusion'] ?? '').toString().toLowerCase();
        final detected = (data['detected_object'] ?? '').toString().toLowerCase();

        if (detected.contains('kertas') || detected.contains('paper') || detected.contains('karton') ||
            (conclusion.contains('bukan daun') && (conclusion.contains('kertas') || conclusion.contains('origami')))) {
          throw Exception('Objek terdeteksi sebagai kertas/benda buatan berwarna hijau, bukan daun padi alami. Pastikan mengambil foto daun padi asli di sawah.');
        }

        if (detected.contains('kucing') || detected.contains('anjing') || detected.contains('cat') || detected.contains('dog') ||
            (conclusion.contains('bukan daun') && (conclusion.contains('kucing') || conclusion.contains('anjing')))) {
          throw Exception('Objek terdeteksi sebagai hewan peliharaan. Harap arahkan kamera ke daun padi.');
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
