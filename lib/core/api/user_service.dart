import 'package:dio/dio.dart';
import '../models/user_model.dart';
import 'api_endpoints.dart';
import 'api_client.dart';

class UserService {
  /// Fetch current logged-in user: GET /users/me
  static Future<UserModel?> getMe() async {
    try {
      final Response res = await api.get('${Api.users}/me');
      // API returns envelope: { success, message, result }
      final data = res.data;
      final result = data is Map ? data['result'] ?? data : data;
      if (result is Map<String, dynamic>) {
        return UserModel.fromJson(result);
      }
      return null;
    } catch (e) {
      return Future.error(e);
    }
  }
}
