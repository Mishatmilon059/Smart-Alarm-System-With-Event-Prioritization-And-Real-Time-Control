import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/sensor_data.dart';

class BlynkService {
  static const String _token = '2ffoYbFrhgy0tLaotK3rnJGgqIfvfhl5';
  static const String _baseUrl = 'https://blynk.cloud/external/api';

  /// Read all sensor data from Blynk Cloud
  Future<SensorData> fetchSensorData() async {
    try {
      final url = Uri.parse('$_baseUrl/getAll?token=$_token');
      final response = await http.get(url).timeout(
        const Duration(seconds: 5),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        return SensorData.fromJson(data);
      } else {
        throw Exception('HTTP ${response.statusCode}');
      }
    } catch (e) {
      rethrow;
    }
  }

  /// Send reset command to ESP via V3 pin (1 = reset ON)
  Future<bool> sendReset() async {
    try {
      final url = Uri.parse('$_baseUrl/update?token=$_token&v3=1');
      final response = await http.get(url).timeout(
        const Duration(seconds: 5),
      );
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }
}
