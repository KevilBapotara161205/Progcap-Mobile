import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:progcap_app/core/api/api_client.dart';

final authRepositoryProvider = Provider((ref) {
  return AuthRepository(ref.watch(apiClientProvider), const FlutterSecureStorage());
});

class AuthRepository {
  final Dio _dio;
  final FlutterSecureStorage _storage;

  AuthRepository(this._dio, this._storage);

  Future<void> sendOtp(String phone) async {
    try {
      final response = await _dio.post('/auth/send-otp', data: {'phone': phone});
      if (!(response.data['success'] ?? false)) {
        throw response.data['message'] ?? 'Failed to send OTP';
      }
    } on DioException catch (e) {
      throw e.response?.data['message'] ?? e.message ?? 'Unknown error';
    }
  }

  Future<void> verifyOtp(String phone, String otp) async {
    try {
      final response = await _dio.post('/auth/verify-otp', data: {'phone': phone, 'otp': otp});
      if (response.data['success'] == true) {
        final data = response.data['data'];
        final accessToken = data['accessToken'];
        if (accessToken != null) {
          await _storage.write(key: 'auth_token', value: accessToken);
        } else {
          throw 'No access token received';
        }
      } else {
        throw response.data['message'] ?? 'Failed to verify OTP';
      }
    } on DioException catch (e) {
      throw e.response?.data['message'] ?? e.message ?? 'Unknown error';
    }
  }

  Future<void> logout() async {
    await _storage.deleteAll();
  }
}
