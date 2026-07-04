import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:progcap_app/core/api/api_client.dart';
import 'package:progcap_app/data/models/user_profile.dart';

final profileRepositoryProvider = Provider((ref) {
  return ProfileRepository(ref.watch(apiClientProvider));
});

final userProfileProvider = FutureProvider.autoDispose<UserProfile>((ref) {
  final repository = ref.watch(profileRepositoryProvider);
  return repository.getMe();
});

class ProfileRepository {
  final Dio _dio;

  ProfileRepository(this._dio);

  Future<UserProfile> getMe() async {
    try {
      final response = await _dio.get('/auth/me');
      if (response.data['success']) {
        return UserProfile.fromJson(response.data['data']);
      } else {
        throw Exception(response.data['message']);
      }
    } catch (e) {
      throw Exception('Failed to load profile: $e');
    }
  }
}
