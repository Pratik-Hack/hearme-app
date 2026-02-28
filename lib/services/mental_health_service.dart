import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:hearme/core/constants/api_constants.dart';
import 'package:hearme/services/api_service.dart';

class MentalHealthService {
  /// Upload audio to the chatbot server for analysis
  static Future<Map<String, dynamic>> uploadAudio({
    required String filePath,
    required String patientId,
    required String patientName,
    String? doctorId,
    String language = 'en',
  }) async {
    final url =
        Uri.parse('${ApiConstants.chatbotBaseUrl}${ApiConstants.mentalHealthAnalyze}');
    final request = http.MultipartRequest('POST', url);

    request.files.add(await http.MultipartFile.fromPath('audio', filePath));
    request.fields['patient_id'] = patientId;
    request.fields['patient_name'] = patientName;
    request.fields['language'] = language;
    if (doctorId != null) request.fields['doctor_id'] = doctorId;

    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }
    throw Exception('Failed to analyze audio: ${response.body}');
  }

  /// Fetch doctor notifications from Node.js backend (persisted in MongoDB)
  static Future<List<dynamic>> getNotifications(String doctorId) async {
    final data = await ApiService.get(ApiConstants.mentalHealthNotifications);
    return data['notifications'] ?? [];
  }

  /// Fetch notifications for a specific patient (doctor view)
  static Future<List<dynamic>> getPatientNotifications(String patientId) async {
    final data = await ApiService.get(
        '${ApiConstants.mentalHealthNotifications}/patient/$patientId');
    return data['notifications'] ?? [];
  }

  /// Mark a notification as read
  static Future<void> markAsRead(String notificationId) async {
    await ApiService.put(
        '${ApiConstants.mentalHealthNotifications}/$notificationId/read');
  }

  /// Redeem a reward (uses chatbot server)
  static Future<Map<String, dynamic>> redeemReward({
    required String rewardType,
    String language = 'en',
  }) async {
    final url =
        Uri.parse('${ApiConstants.chatbotBaseUrl}${ApiConstants.rewardsRedeem}');
    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'reward_type': rewardType,
        'language': language,
      }),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }
    throw Exception('Failed to redeem reward');
  }
}
