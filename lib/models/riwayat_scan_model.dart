import 'lahan_model.dart';

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

  int? get hstCalculated {
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
  /// - WIT  (UTC+9): "14 Oktober 2026 • 18:22 WIT"
  String get formattedDateTime {
    if (createdAt.isEmpty) return '-';
    try {
      final dt = DateTime.parse(createdAt).toLocal();
      const monthNames = [
        'Januari', 'Februari', 'Maret', 'April', 'Mei', 'Juni',
        'Juli', 'Agustus', 'September', 'Oktober', 'November', 'Desember'
      ];
      final day = dt.day;
      final month = monthNames[dt.month - 1];
      final year = dt.year;
      final hour = dt.hour.toString().padLeft(2, '0');
      final minute = dt.minute.toString().padLeft(2, '0');
      final tz = _getTimeZoneSuffix(dt);
      return '$day $month $year • $hour:$minute $tz';
    } catch (_) {
      return createdAt;
    }
  }

  /// Format tanggal pendek dinamis zona waktu, contoh: "14 Okt 2026, 16:22 WIB"
  String get formattedDateShort {
    if (createdAt.isEmpty) return '-';
    try {
      final dt = DateTime.parse(createdAt).toLocal();
      const monthNames = [
        'Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun',
        'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des'
      ];
      final day = dt.day;
      final month = monthNames[dt.month - 1];
      final year = dt.year;
      final hour = dt.hour.toString().padLeft(2, '0');
      final minute = dt.minute.toString().padLeft(2, '0');
      final tz = _getTimeZoneSuffix(dt);
      return '$day $month $year, $hour:$minute $tz';
    } catch (_) {
      return createdAt;
    }
  }

  /// Format relatif pintar dinamis zona waktu:
  /// "Hari ini • 16:22 WIB" / "Hari ini • 18:22 WIT", "Kemarin • ...", dst.
  String get humanRelativeTime {
    if (createdAt.isEmpty) return '-';
    try {
      final dt = DateTime.parse(createdAt).toLocal();
      final now = DateTime.now();
      final hour = dt.hour.toString().padLeft(2, '0');
      final minute = dt.minute.toString().padLeft(2, '0');
      final tz = _getTimeZoneSuffix(dt);

      if (now.year == dt.year && now.month == dt.month && now.day == dt.day) {
        return 'Hari ini • $hour:$minute $tz';
      }

      final yesterday = now.subtract(const Duration(days: 1));
      if (yesterday.year == dt.year && yesterday.month == dt.month && yesterday.day == dt.day) {
        return 'Kemarin • $hour:$minute $tz';
      }

      const monthNames = [
        'Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun',
        'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des'
      ];
      final day = dt.day;
      final month = monthNames[dt.month - 1];
      final year = dt.year;
      return '$day $month $year • $hour:$minute $tz';
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

    return RiwayatScanModel(
      id: json['id'] is int ? json['id'] : int.tryParse(json['id']?.toString() ?? '0') ?? 0,
      userId: json['user_id'] is int ? json['user_id'] : int.tryParse(json['user_id']?.toString() ?? '0') ?? 0,
      lahanId: json['lahan_id'] is int ? json['lahan_id'] : int.tryParse(json['lahan_id']?.toString() ?? '0') ?? 0,
      penyakit: json['penyakit'] ?? 'Normal / Sehat',
      bwdValue: parsedBwd,
      bwdStatus: rawStatus?.toString(),
      akurasi: json['akurasi'] != null ? double.tryParse(json['akurasi'].toString().replaceAll(',', '.')) : null,
      tindakan: json['tindakan'],
      fotoPath: json['foto_path'],
      createdAt: json['created_at'] ?? '',
      lahan: json['lahan'] != null ? LahanModel.fromJson(json['lahan']) : null,
    );
  }
}

