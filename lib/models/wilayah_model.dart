class WilayahModel {
  final int id;
  final String name;
  final String? latitude;
  final String? longitude;

  WilayahModel({
    required this.id,
    required this.name,
    this.latitude,
    this.longitude,
  });

  factory WilayahModel.fromJson(Map<String, dynamic> json) {
    return WilayahModel(
      id: json['id'],
      name: json['name'],
      latitude: json['latitude']?.toString(),
      longitude: json['longitude']?.toString(),
    );
  }
}
