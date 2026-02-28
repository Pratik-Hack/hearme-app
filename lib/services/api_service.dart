import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:hearme/core/constants/api_constants.dart';

class ApiException implements Exception {
  final String message;
  final int? statusCode;

  ApiException(this.message, {this.statusCode});

  @override
  String toString() => message;
}

class ApiService {
  static String? _token;

  static void setToken(String? token) {
    _token = token;
  }

  static Map<String, String> get _headers {
    final headers = <String, String>{
      'Content-Type': 'application/json',
    };
    if (_token != null) {
      headers['Authorization'] = 'Bearer $_token';
    }
    return headers;
  }

  static Future<Map<String, dynamic>> get(String endpoint,
      {String? baseUrl}) async {
    final url = Uri.parse('${baseUrl ?? ApiConstants.baseUrl}$endpoint');
    final response = await http.get(url, headers: _headers);
    return _handleResponse(response);
  }

  static Future<Map<String, dynamic>> post(String endpoint,
      {Map<String, dynamic>? body, String? baseUrl}) async {
    final url = Uri.parse('${baseUrl ?? ApiConstants.baseUrl}$endpoint');
    final response = await http.post(
      url,
      headers: _headers,
      body: body != null ? jsonEncode(body) : null,
    );
    return _handleResponse(response);
  }

  static Future<Map<String, dynamic>> put(String endpoint,
      {Map<String, dynamic>? body, String? baseUrl}) async {
    final url = Uri.parse('${baseUrl ?? ApiConstants.baseUrl}$endpoint');
    final response = await http.put(
      url,
      headers: _headers,
      body: body != null ? jsonEncode(body) : null,
    );
    return _handleResponse(response);
  }

  static Future<Map<String, dynamic>> delete(String endpoint,
      {String? baseUrl}) async {
    final url = Uri.parse('${baseUrl ?? ApiConstants.baseUrl}$endpoint');
    final response = await http.delete(url, headers: _headers);
    return _handleResponse(response);
  }

  static Map<String, dynamic> _handleResponse(http.Response response) {
    dynamic body;
    try {
      body = jsonDecode(response.body);
    } catch (_) {
      throw ApiException(
        'Server unreachable or returned invalid response',
        statusCode: response.statusCode,
      );
    }
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return body is Map<String, dynamic> ? body : {'data': body};
    }
    throw ApiException(
      body['message'] ?? body['error'] ?? 'Request failed',
      statusCode: response.statusCode,
    );
  }
}
