import 'dart:convert';
import 'package:http/http.dart' as http;

class WeatherData {
  final double temperature;
  final int humidity;
  final String description;

  WeatherData({
    required this.temperature,
    required this.humidity,
    required this.description,
  });
}

class WeatherService {
  Future<WeatherData?> getCurrentWeather(double lat, double lng) async {
    try {
      final url = Uri.parse(
          'https://api.open-meteo.com/v1/forecast?latitude=$lat&longitude=$lng&current=temperature_2m,relative_humidity_2m,weather_code');
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final current = data['current'];
        if (current != null) {
          final temp = (current['temperature_2m'] as num?)?.toDouble() ?? 0.0;
          final hum = (current['relative_humidity_2m'] as num?)?.toInt() ?? 0;
          final code = (current['weather_code'] as num?)?.toInt() ?? 0;
          return WeatherData(
            temperature: temp,
            humidity: hum,
            description: _getWeatherDescription(code),
          );
        }
      }
    } catch (e) {
      print('Error fetching weather: $e');
    }
    return null;
  }

  String _getWeatherDescription(int code) {
    // WMO Weather interpretation codes
    if (code == 0) return 'Cerah';
    if (code == 1 || code == 2 || code == 3) return 'Berawan';
    if (code == 45 || code == 48) return 'Berkabut';
    if (code >= 51 && code <= 67) return 'Hujan Ringan/Gerimis';
    if (code >= 71 && code <= 77) return 'Bersalju';
    if (code >= 80 && code <= 82) return 'Hujan Deras';
    if (code >= 95 && code <= 99) return 'Badai Petir';
    return 'Tidak Diketahui';
  }
}
