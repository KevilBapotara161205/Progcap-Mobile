import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:progcap_app/core/api/api_client.dart';
import 'package:progcap_app/data/models/training_module.dart';

final trainingRepositoryProvider = Provider((ref) {
  return TrainingRepository(ref.watch(apiClientProvider));
});

final trainingModulesProvider = FutureProvider.autoDispose<List<TrainingModule>>((ref) async {
  final repository = ref.watch(trainingRepositoryProvider);
  // Using a dummy user ID since authState only tracks authentication status
  final userId = 'current_user_id';
  return repository.getModules(userId);
});

class TrainingRepository {
  final Dio _dio;

  TrainingRepository(this._dio);

  Future<List<TrainingModule>> getModules(String userId) async {
    try {
      final response = await _dio.get('/training');
      if (response.data['success']) {
        final List data = response.data['data'];
        return data.map((json) => TrainingModule.fromJson(json, userId)).toList();
      } else {
        throw Exception(response.data['message']);
      }
    } catch (e) {
      throw Exception('Failed to load training modules: $e');
    }
  }

  Future<void> completeModule(String id) async {
    try {
      final response = await _dio.post('/training/$id/complete');
      if (!response.data['success']) {
        throw Exception(response.data['message']);
      }
    } catch (e) {
      throw Exception('Failed to complete module: $e');
    }
  }
}
