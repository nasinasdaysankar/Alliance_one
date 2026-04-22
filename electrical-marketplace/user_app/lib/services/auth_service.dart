import 'package:dio/dio.dart';
import '../core/network/api_client.dart';
import '../core/constants/api_endpoints.dart';
import '../core/storage/secure_storage.dart';
import '../models/user.dart';

class AuthService {
  final _dio = ApiClient.instance;

  /// Returns the dev OTP if the backend exposes it (NODE_ENV != production),
  /// or Returns a [User] if the backend auto-logs in an existing user.
  Future<dynamic> sendOtp(String phone) async {
    try {
      final res = await _dio.post(
        ApiEndpoints.sendOtp,
        data: {'phone': phone},
      );
      final body = res.data;
      if (body is Map) {
        if (body['isExistingUser'] == true) {
          final token = body['token']?.toString() ?? '';
          final user = User.fromJson(body['user'] as Map<String, dynamic>);
          await SecureStorage.saveToken(token);
          await SecureStorage.saveUserId(user.id);
          await SecureStorage.savePhone(user.phone);
          if (user.name != null) await SecureStorage.saveName(user.name!);
          return user; // Return the user to indicate successful instant login
        }
        if (body.containsKey('otp')) {
          return body['otp']?.toString();
        }
      }
      return null;
    } on DioException catch (e) {
      throw ApiClient.extractErrorMessage(e);
    }
  }

  Future<User> verifyOtp(String phone, String otp) async {
    try {
      final res = await _dio.post(
        ApiEndpoints.verifyOtp,
        data: {'phone': phone, 'otp': otp},
      );
      final data = ApiClient.extractData(res) as Map<String, dynamic>;
      final token = data['token']?.toString() ?? '';
      final user = User.fromJson(data['user'] as Map<String, dynamic>);
      await SecureStorage.saveToken(token);
      await SecureStorage.saveUserId(user.id);
      await SecureStorage.savePhone(user.phone);
      if (user.name != null) await SecureStorage.saveName(user.name!);
      return user;
    } on DioException catch (e) {
      throw ApiClient.extractErrorMessage(e);
    }
  }

  Future<User?> getProfile() async {
    try {
      final res = await _dio.get(ApiEndpoints.profile);
      final data = ApiClient.extractData(res);
      return User.fromJson(data as Map<String, dynamic>);
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) return null;
      throw ApiClient.extractErrorMessage(e);
    }
  }

  Future<User> updateProfile({String? name, String? email}) async {
    try {
      final res = await _dio.put(
        ApiEndpoints.profile,
        data: {
          if (name != null) 'name': name,
          if (email != null) 'email': email,
        },
      );
      final data = ApiClient.extractData(res);
      final user = User.fromJson(data as Map<String, dynamic>);
      if (user.name != null) await SecureStorage.saveName(user.name!);
      return user;
    } on DioException catch (e) {
      throw ApiClient.extractErrorMessage(e);
    }
  }

  Future<void> logout() async {
    await SecureStorage.clearAll();
  }
}
