import 'wilayah_model.dart';

class UserModel {
  final int id;
  final String name;
  final String email;
  final String role;
  final int? wilayahId;
  final int? kelompokTaniId;
  final String? kelompokTaniName;
  final WilayahModel? wilayah;

  UserModel({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    this.wilayahId,
    this.kelompokTaniId,
    this.kelompokTaniName,
    this.wilayah,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'],
      name: json['name'],
      email: json['email'],
      role: json['role'],
      wilayahId: json['wilayah_id'],
      kelompokTaniId: json['kelompok_tani_id'],
      kelompokTaniName: json['kelompok_tani'] != null ? json['kelompok_tani']['name'] : null,
      wilayah: json['wilayah'] != null ? WilayahModel.fromJson(json['wilayah']) : null,
    );
  }
}
