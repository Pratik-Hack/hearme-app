import 'package:hearme/core/constants/api_constants.dart';
import 'package:hearme/services/api_service.dart';

class AuthService {
  static Future<Map<String, dynamic>> register(
      Map<String, dynamic> data) async {
    final response = await ApiService.post(ApiConstants.register, body: data);
    return response;
  }

  static Future<Map<String, dynamic>> login(
      String email, String password) async {
    final response = await ApiService.post(
      ApiConstants.login,
      body: {'email': email, 'password': password},
    );
    return response;
  }
}
