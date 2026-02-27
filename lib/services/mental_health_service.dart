import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:hearme/core/constants/api_constants.dart';

class MentalHealthService {
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

  static Future<List<dynamic>> getNotifications(String doctorId) async {
    final url = Uri.parse(
        '${ApiConstants.chatbotBaseUrl}${ApiConstants.mentalHealthNotifications}/$doctorId');
    final response = await http.get(url);

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['notifications'] ?? [];
    }
    throw Exception('Failed to fetch notifications');
  }

  static Future<void> markAsRead(String notificationId) async {
    final url = Uri.parse(
        '${ApiConstants.chatbotBaseUrl}${ApiConstants.mentalHealthNotifications}/$notificationId/read');
    final response = await http.put(url);

    if (response.statusCode != 200) {
      throw Exception('Failed to mark as read');
    }
  }

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
