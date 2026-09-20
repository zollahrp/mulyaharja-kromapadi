import 'lahan_model.dart';

class RiwayatScanModel {
  final int id;
  final int userId;
  final int lahanId;
  final String penyakit;
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
    this.akurasi,
    this.tindakan,
    this.fotoPath,
    required this.createdAt,
    this.lahan,
  });

  factory RiwayatScanModel.fromJson(Map<String, dynamic> json) {
    return RiwayatScanModel(
      id: json['id'],
      userId: json['user_id'],
      lahanId: json['lahan_id'],
      penyakit: json['penyakit'],
      akurasi: json['akurasi'] != null ? double.tryParse(json['akurasi'].toString()) : null,
      tindakan: json['tindakan'],
      fotoPath: json['foto_path'],
      createdAt: json['created_at'] ?? '',
      lahan: json['lahan'] != null ? LahanModel.fromJson(json['lahan']) : null,
    );
  }
}
