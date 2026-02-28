import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:hearme/core/constants/api_constants.dart';

class ChatService {
  static Future<String> sendMessage(String message,
      {String? sessionId, String language = 'en'}) async {
    final url = Uri.parse('${ApiConstants.chatbotBaseUrl}/chat');
    try {
      final response = await http
          .post(
            url,
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'message': message,
              'session_id': sessionId ?? 'default',
              'language': language,
            }),
          )
          .timeout(const Duration(seconds: 120));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['response'] ?? '';
      }
      throw Exception('Server error: ${response.statusCode}');
    } on TimeoutException {
      throw Exception(
          'The server is waking up. Please try again in a moment.');
    }
  }

  static Stream<String> sendMessageStream(String message,
      {String? sessionId,
      String language = 'en',
      String? medicalContext}) async* {
    final url = Uri.parse('${ApiConstants.chatbotBaseUrl}/chat/stream');
    final request = http.Request('POST', url);
    request.headers['Content-Type'] = 'application/json';

    final body = <String, dynamic>{
      'message': message,
      'session_id': sessionId ?? 'default',
      'language': language,
    };
    if (medicalContext != null) {
      body['medical_context'] = medicalContext;
    }
    request.body = jsonEncode(body);

    final client = http.Client();
    try {
      final streamedResponse = await client.send(request);
      String buffer = '';

      await for (final chunk in streamedResponse.stream.transform(utf8.decoder)) {
        buffer += chunk;
        final lines = buffer.split('\n');
        buffer = lines.removeLast();

        for (final line in lines) {
          if (line.startsWith('data: ')) {
            final data = line.substring(6).trim();
            if (data == '[DONE]') return;
            if (data.isNotEmpty) {
              try {
                final json = jsonDecode(data);
                final token = json['token'] ?? json['content'] ?? '';
                if (token.isNotEmpty) yield token;
              } catch (_) {
                if (data.isNotEmpty) yield data;
              }
            }
          }
        }
      }

      // Process remaining buffer
      if (buffer.isNotEmpty && buffer.startsWith('data: ')) {
        final data = buffer.substring(6).trim();
        if (data != '[DONE]' && data.isNotEmpty) {
          try {
            final json = jsonDecode(data);
            final token = json['token'] ?? json['content'] ?? '';
            if (token.isNotEmpty) yield token;
          } catch (_) {
            yield data;
          }
        }
      }
    } finally {
      client.close();
    }
  }
}
