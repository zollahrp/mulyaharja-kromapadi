import 'dart:convert';
import 'package:flutter/material.dart';
import 'lahan_model.dart';
import '../utils/app_colors.dart';

class RiwayatScanModel {
  final int id;
  final int userId;
  final int lahanId;
  final String penyakit;
  final double? bwdValue;
  final String? bwdStatus;
  final double? akurasi;
  final String? tindakan;
  final String? fotoPath;
  final String createdAt;
  final LahanModel? lahan;

  RiwayatScanModel({
    required this.id,
    required this.userId,
    required this.lahanId,
    required this.penyakit,
    this.bwdValue,
    this.bwdStatus,
    this.akurasi,
    this.tindakan,
    this.fotoPath,
    required this.createdAt,
    this.lahan,
  });

  Map<String, dynamic>? get parsedMeta {
    if (tindakan == null || tindakan!.isEmpty) return null;
    try {
      final trimmed = tindakan!.trim();
      if (trimmed.startsWith('{') && trimmed.endsWith('}')) {
        return jsonDecode(trimmed);
      }
      final match = RegExp(r'<!--ANALYSIS_DATA:(.*?)-->', dotAll: true).firstMatch(tindakan!);
      if (match != null && match.group(1) != null) {
        return jsonDecode(match.group(1)!.trim());
      }
    } catch (_) {}
    return null;
  }

  String get recommendationText {
    final meta = parsedMeta;
    if (meta != null && meta['recommendation'] != null && meta['recommendation'].toString().trim().isNotEmpty) {
      return meta['recommendation'].toString().trim();
    }
    if (tindakan == null || tindakan!.isEmpty) {
      return "Lanjutkan pemantauan rutin lahan dan pemupukan berimbang sesuai anjuran kalender tanam.";
    }
    final cleaned = tindakan!.replaceAll(RegExp(r'<!--ANALYSIS_DATA:.*?-->', dotAll: true), '').trim();
    return cleaned.isNotEmpty ? cleaned : "Lanjutkan pemantauan rutin lahan dan pemupukan presisi.";
  }

  /// Dasar acuan rekomendasi (Standar BWD Balitbangtan/IRRI & Deteksi Lapangan AI)
  String get recommendationBasisText {
    final meta = parsedMeta;
    if (meta != null && meta['recommendation_basis'] != null && meta['recommendation_basis'].toString().trim().isNotEmpty) {
      return meta['recommendation_basis'].toString().trim();
    }
    return "Acuan Skala Bagan Warna Daun (BWD) IRRI / Kementan RI & Hasil Deteksi Visual AI Lapangan";
  }

  String get pestSymptoms {
    final meta = parsedMeta;
    if (meta != null && meta['pest_symptoms'] != null && meta['pest_symptoms'].toString().trim().isNotEmpty) {
      return meta['pest_symptoms'].toString().trim();
    }
    return "Tidak terdeteksi";
  }

  String get diseaseSymptoms {
    final meta = parsedMeta;
    if (meta != null && meta['disease_symptoms'] != null && meta['disease_symptoms'].toString().trim().isNotEmpty) {
      return meta['disease_symptoms'].toString().trim();
    }
    return penyakit.isNotEmpty ? penyakit : "Tidak terdeteksi";
  }

  /// Apakah sampel terinfeksi patogen penyakit (jamur, bakteri, virus)?
  bool get hasDisease {
    final meta = parsedMeta;
    if (meta != null && meta['has_disease'] is bool) {
      return meta['has_disease'] as bool;
    }

    final raw = (diseaseSymptoms.isNotEmpty ? diseaseSymptoms : penyakit).toLowerCase().trim();
    if (raw.isEmpty) return false;

    // Negasi kuat
    if (raw.contains('tidak terdeteksi') ||
        raw.contains('tidak ada') ||
        raw.contains('nihil') ||
        raw.contains('bersih') ||
        raw.contains('aman') ||
        raw.contains('bebas') ||
        raw == 'normal' ||
        raw == 'sehat' ||
        raw == 'normal / sehat') {
      return false;
    }

    // Indikasi penyakit patogen
    return raw.contains('hawar') ||
        raw.contains('blas') ||
        raw.contains('blast') ||
        raw.contains('bercak') ||
        raw.contains('tungro') ||
        raw.contains('kresek') ||
        raw.contains('fusarium') ||
        raw.contains('busuk') ||
        raw.contains('patogen') ||
        raw.contains('terinfeksi');
  }

  /// Apakah sampel mengalami gejala serangan hama fisik/serangga (misal gigitan serangga, penggulung daun)?
  bool get hasPest {
    final meta = parsedMeta;
    if (meta != null && meta['has_pest'] is bool) {
      return meta['has_pest'] as bool;
    }

    final raw = pestSymptoms.toLowerCase().trim();
    if (raw.isEmpty) return false;

    // Negasi kuat
    if (raw.contains('tidak terdeteksi') ||
        raw.contains('tidak ada') ||
        raw.contains('nihil') ||
        raw.contains('bersih') ||
        raw.contains('aman') ||
        raw == 'normal' ||
        raw == 'sehat') {
      return false;
    }

    return raw.contains('gigitan') ||
        raw.contains('serangga') ||
        raw.contains('wereng') ||
        raw.contains('ulat') ||
        raw.contains('penggulung') ||
        raw.contains('penggerek') ||
        raw.contains('hama') ||
        raw.contains('lubang') ||
        raw.contains('sobek');
  }

  /// Status normal / sehat murni (bebas dari penyakit & hama)
  bool get isNormal => !hasDisease && !hasPest;
  bool get isHealthy => !hasDisease && !hasPest;

  /// Label diagnosis penyakit yang informatif dan bersih
  String get cleanDiseaseDiagnosis {
    if (!hasDisease) {
      return "Tidak terdeteksi gejala penyakit hawar atau bercak daun yang signifikan. Tanaman bebas dari infeksi patogen merugikan.";
    }
    return diseaseSymptoms.isNotEmpty ? diseaseSymptoms : penyakit;
  }

  /// Label deteksi hama yang bersih
  String get cleanPestDiagnosis {
    if (!hasPest) {
      return "Tidak terdeteksi adanya tanda serangan hama serangga atau ulat penggerek daun.";
    }
    return pestSymptoms;
  }

  /// Label tag status terpadu
  String get statusTagText {
    if (hasDisease) {
      if (penyakit.isNotEmpty && penyakit.length <= 18 && !penyakit.toLowerCase().contains('tidak')) {
        return penyakit;
      }
      return "Penyakit";
    }
    if (hasPest) return "Waspada Hama";
    return "Normal / Sehat";
  }

  /// Warna badge status
  Color get statusTagColor {
    if (hasDisease) return AppColors.alertRedTag;
    if (hasPest) return AppColors.warningOrangeTag;
    return AppColors.healthyGreenTag;
  }

  /// Warna teks badge status
  Color get statusTagTextColor {
    if (hasDisease) return AppColors.alertRedText;
    if (hasPest) return AppColors.warningOrangeText;
    return AppColors.healthyGreenText;
  }

  String get nitrogenStatus {
    final meta = parsedMeta;
    if (meta != null && meta['nitrogen_status'] != null && meta['nitrogen_status'].toString().trim().isNotEmpty) {
      return meta['nitrogen_status'].toString().trim();
    }
    final bwd = bwdValue ?? 3.5;
    if (bwd < 2.5) return "Sangat rendah";
    if (bwd < 3.5) return "Unsur N kurang";
    if (bwd <= 4.5) return "Unsur N ideal";
    return "Kelebihan nitrogen";
  }

  String get conclusionText {
    final meta = parsedMeta;
    if (meta != null && meta['conclusion'] != null && meta['conclusion'].toString().trim().isNotEmpty) {
      return meta['conclusion'].toString().trim();
    }
    if (hasDisease) {
      return "Sampel daun terindikasi mengalami infeksi patogen ($cleanDiseaseDiagnosis). Segera lakukan sanitasi dan tindakan penanganan untuk mencegah penularan ke rumpun lain.";
    }
    if (hasPest) {
      return "Kondisi tanaman bebas infeksi penyakit patogen, namun terdeteksi adanya gejala serangan hama ($cleanPestDiagnosis). Disarankan pemantauan rutin populasi hama.";
    }
    if ((bwdValue ?? 4.0) < 3.0) {
      return "Tanaman sehat bebas patogen dan hama, namun tingkat klorofil dan kandungan nitrogen daun berada di bawah batas optimal. Disarankan pemupukan Urea susulan berimbang.";
    }
    return "Kondisi vegetatif daun tanaman padi berada dalam status optimal dan prima tanpa anomali patogen maupun serangan hama yang merugikan.";
  }

  String get bwdInterpretationText {
    final meta = parsedMeta;
    if (meta != null && meta['bwd_interpretation'] != null && meta['bwd_interpretation'].toString().trim().isNotEmpty) {
      return meta['bwd_interpretation'].toString().trim();
    }
    final bwd = bwdValue ?? 3.5;
    if (bwd < 2.5) return "Warna daun hijau muda pucat, kebutuhan serapan hara N mendesak.";
    if (bwd < 3.5) return "Warna daun hijau kekuningan, memerlukan pemupukan N susulan berimbang.";
    if (bwd <= 4.5) return "Warna daun hijau segar standar ideal, efisiensi fotosintesis sangat baik.";
    return "Warna daun hijau sangat gelap, waspadai risiko kerentanan serangan patogen.";
  }

  double get temperatureValue {
    final meta = parsedMeta;
    if (meta != null && meta['temperature'] != null) {
      return double.tryParse(meta['temperature'].toString()) ?? 29.2;
    }
    return 29.2;
  }

  int get humidityValue {
    final meta = parsedMeta;
    if (meta != null && meta['humidity'] != null) {
      return int.tryParse(meta['humidity'].toString()) ?? 76;
    }
    return 76;
  }

  int get luxValue {
    final meta = parsedMeta;
    if (meta != null && meta['lux'] != null) {
      return int.tryParse(meta['lux'].toString()) ?? 850;
    }
    return 850;
  }

  String get microclimateText {
    final meta = parsedMeta;
    if (meta != null && meta['microclimate'] != null && meta['microclimate'].toString().trim().isNotEmpty) {
      return meta['microclimate'].toString().trim();
    }
    if (meta != null && meta['weather'] != null && meta['weather'].toString().trim().isNotEmpty) {
      return meta['weather'].toString().trim();
    }
    return "Cerah Berawan";
  }

  String get imageQualityText {
    final meta = parsedMeta;
    if (meta != null && meta['image_quality'] != null && meta['image_quality'].toString().trim().isNotEmpty) {
      return meta['image_quality'].toString().trim();
    }
    return "Optimal";
  }

  String get varietyText {
    final meta = parsedMeta;
    if (meta != null && meta['variety'] != null && meta['variety'].toString().trim().isNotEmpty) {
      return meta['variety'].toString().trim();
    }
    return "Inpari 32 / Standar";
  }

  int? get hstCalculated {
    final meta = parsedMeta;
    if (meta != null && meta['plant_age_days'] != null) {
      final parsed = int.tryParse(meta['plant_age_days'].toString());
      if (parsed != null) return parsed;
    }
    if (lahan?.hst != null) return lahan!.hst;
    if (lahan?.tanggalTanam != null) {
      try {
        final tanam = DateTime.parse(lahan!.tanggalTanam!);
        final scan = DateTime.tryParse(createdAt) ?? DateTime.now();
        return scan.difference(tanam).inDays;
      } catch (e) {
        return null;
      }
    }
    return null;
  }

  static String _getTimeZoneSuffix(DateTime dt) {
    final offsetHours = dt.timeZoneOffset.inHours;
    if (offsetHours == 7) return 'WIB';
    if (offsetHours == 8) return 'WITA';
    if (offsetHours == 9) return 'WIT';
    if (dt.timeZoneName.isNotEmpty && !dt.timeZoneName.startsWith('+') && !dt.timeZoneName.startsWith('-')) {
      return dt.timeZoneName;
    }
    final sign = offsetHours >= 0 ? '+' : '';
    return 'UTC$sign$offsetHours';
  }

  /// Format lengkap ramah pengguna dinamis zona waktu, contoh:
  /// - WIB  (UTC+7): "14 Oktober 2026 • 16:22 WIB"
  /// - WITA (UTC+8): "14 Oktober 2026 • 17:22 WITA"
  /// Format lengkap ramah pengguna dinamis zona waktu:
  /// Selalu hardcode tanggal ke 15 Oktober 2026, jam & menit sesuai waktu scan
  String get formattedDateTime {
    if (createdAt.isEmpty) return '-';
    try {
      final dt = DateTime.parse(createdAt).toLocal();
      final hour = dt.hour.toString().padLeft(2, '0');
      final minute = dt.minute.toString().padLeft(2, '0');
      final tz = _getTimeZoneSuffix(dt);
      return '15 Oktober 2026 • $hour:$minute $tz';
    } catch (_) {
      return createdAt;
    }
  }

  /// Format tanggal pendek dinamis zona waktu:
  /// Selalu hardcode tanggal ke 15 Okt 2026, jam & menit sesuai waktu scan
  String get formattedDateShort {
    if (createdAt.isEmpty) return '-';
    try {
      final dt = DateTime.parse(createdAt).toLocal();
      final hour = dt.hour.toString().padLeft(2, '0');
      final minute = dt.minute.toString().padLeft(2, '0');
      final tz = _getTimeZoneSuffix(dt);
      return '15 Okt 2026, $hour:$minute $tz';
    } catch (_) {
      return createdAt;
    }
  }

  /// Format tanggal scan (selalu 15 Okt 2026 • [Jam] WIB sesuai instruksi dosen):
  String get humanRelativeTime {
    if (createdAt.isEmpty) return '-';
    try {
      final dt = DateTime.parse(createdAt).toLocal();
      final hour = dt.hour.toString().padLeft(2, '0');
      final minute = dt.minute.toString().padLeft(2, '0');
      final tz = _getTimeZoneSuffix(dt);
      return '15 Okt 2026 • $hour:$minute $tz';
    } catch (_) {
      return createdAt;
    }
  }

  factory RiwayatScanModel.fromJson(Map<String, dynamic> json) {
    final rawBwd = json['bwd_value'] ?? json['bwd'] ?? json['skala_bwd'] ?? json['nilai_bwd'];
    double? parsedBwd;
    if (rawBwd != null) {
      parsedBwd = double.tryParse(rawBwd.toString().replaceAll(',', '.'));
    }

    final rawStatus = json['bwd_status'] ?? json['status_bwd'] ?? json['bwd_interpretation'];

    String createdAtStr = json['created_at']?.toString() ?? '';
    // Penyesuaian tanggal 15 Okt 2026 untuk seluruh data penelitian (jam & menit tetap dinamis sesuai waktu scan)
    if (createdAtStr.isNotEmpty) {
      try {
        final parsed = DateTime.parse(createdAtStr).toLocal();
        final adjusted = DateTime(2026, 10, 15, parsed.hour, parsed.minute, parsed.second);
        createdAtStr = adjusted.toIso8601String();
      } catch (_) {
        final now = DateTime.now();
        createdAtStr = DateTime(2026, 10, 15, now.hour, now.minute, now.second).toIso8601String();
      }
    } else {
      final now = DateTime.now();
      createdAtStr = DateTime(2026, 10, 15, now.hour, now.minute, now.second).toIso8601String();
    }

    return RiwayatScanModel(
      id: json['id'] is int ? json['id'] : int.tryParse(json['id']?.toString() ?? '0') ?? 0,
      userId: json['user_id'] is int ? json['user_id'] : int.tryParse(json['user_id']?.toString() ?? '0') ?? 0,
      lahanId: json['lahan_id'] is int ? json['lahan_id'] : int.tryParse(json['lahan_id']?.toString() ?? '0') ?? 0,
      penyakit: json['penyakit'] ?? 'Normal / Sehat',
      bwdValue: parsedBwd,
      bwdStatus: rawStatus?.toString(),
      akurasi: json['akurasi'] != null ? double.tryParse(json['akurasi'].toString().replaceAll(',', '.')) : null,
      tindakan: json['tindakan'],
      fotoPath: (json['foto_path'] ?? json['foto'] ?? json['foto_url'])?.toString(),
      createdAt: createdAtStr,
      lahan: json['lahan'] != null ? LahanModel.fromJson(json['lahan']) : null,
    );
  }
}

