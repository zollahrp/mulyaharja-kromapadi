class LahanModel {
  final int id;
  final int kelompokTaniId;
  final String name;
  final int? luas;
  final bool isAktif;
  final String? tanggalTanam;
  final int? hst;

  LahanModel({
    required this.id,
    required this.kelompokTaniId,
    required this.name,
    this.luas,
    required this.isAktif,
    this.tanggalTanam,
    this.hst,
  });

  factory LahanModel.fromJson(Map<String, dynamic> json) {
    int? parseToInt(dynamic value) {
      if (value == null) return null;
      if (value is int) return value;
      if (value is num) return value.toInt();
      if (value is String) return double.tryParse(value)?.toInt();
      return null;
    }

    return LahanModel(
      id: parseToInt(json['id']) ?? 0,
      kelompokTaniId: parseToInt(json['kelompok_tani_id']) ?? 0,
      name: json['name']?.toString() ?? 'Tanpa Nama',
      luas: parseToInt(json['luas']),
      isAktif: json['is_aktif'] == true || json['is_aktif'] == 1 || json['is_aktif'] == '1',
      tanggalTanam: json['tanggal_tanam']?.toString(),
      hst: parseToInt(json['hst']),
    );
  }
}
