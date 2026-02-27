import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:hearme/core/constants/api_constants.dart';
import 'package:hearme/services/api_service.dart';

class VitalsService {
  static Future<Map<String, dynamic>> startSession({
    required String patientId,
    String? doctorId,
    String? scenario,
    double? latitude,
    double? longitude,
  }) async {
    final url =
        Uri.parse('${ApiConstants.chatbotBaseUrl}${ApiConstants.vitalsStart}');
    final body = <String, dynamic>{
      'patient_id': patientId,
    };
    if (doctorId != null) body['doctor_id'] = doctorId;
    if (scenario != null) body['scenario'] = scenario;
    if (latitude != null) body['latitude'] = latitude;
    if (longitude != null) body['longitude'] = longitude;

    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(body),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }
    throw Exception('Failed to start vitals session');
  }

  static Future<Map<String, dynamic>> tick(String sessionId) async {
    final url =
        Uri.parse('${ApiConstants.chatbotBaseUrl}${ApiConstants.vitalsTick}');
    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'session_id': sessionId}),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }
    throw Exception('Failed to get vitals tick');
  }

  static Future<void> stopSession(String sessionId) async {
    final url = Uri.parse(
        '${ApiConstants.chatbotBaseUrl}${ApiConstants.vitalsSession}/$sessionId');
    final response = await http.delete(url);

    if (response.statusCode != 200) {
      throw Exception('Failed to stop vitals session');
    }
  }

  static Future<List<dynamic>> getDoctorAlerts(String doctorId) async {
    final url = Uri.parse(
        '${ApiConstants.chatbotBaseUrl}${ApiConstants.vitalsDoctorAlerts}/$doctorId');
    final response = await http.get(url);

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['alerts'] ?? [];
    }
    throw Exception('Failed to fetch doctor alerts');
  }

  static Future<List<dynamic>> getPatientAlerts(String patientId) async {
    final url = Uri.parse(
        '${ApiConstants.chatbotBaseUrl}${ApiConstants.vitalsPatientAlerts}/$patientId');
    final response = await http.get(url);

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['alerts'] ?? [];
    }
    throw Exception('Failed to fetch patient alerts');
  }

  static Future<void> markAlertRead(String alertId) async {
    final url = Uri.parse(
        '${ApiConstants.chatbotBaseUrl}/vitals/alerts/$alertId/read');
    final response = await http.put(url);

    if (response.statusCode != 200) {
      throw Exception('Failed to mark alert as read');
    }
  }

  static Future<void> saveSessionSummary({
    required String token,
    required Map<String, dynamic> summary,
  }) async {
    ApiService.setToken(token);
    await ApiService.post(ApiConstants.vitalsSummary, body: summary);
  }
}
