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
    return LahanModel(
      id: json['id'],
      kelompokTaniId: json['kelompok_tani_id'],
      name: json['name'],
      luas: json['luas'],
      isAktif: json['is_aktif'] ?? false,
      tanggalTanam: json['tanggal_tanam'],
      hst: json['hst'],
    );
  }
}
