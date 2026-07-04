import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:progcap_app/core/api/api_client.dart';

final dashboardRepositoryProvider = Provider((ref) {
  return DashboardRepository(ref.watch(apiClientProvider));
});

final rmScorecardProvider = FutureProvider.autoDispose<Map<String, dynamic>>((ref) {
  final repository = ref.watch(dashboardRepositoryProvider);
  return repository.getScorecardSummary();
});

class DashboardRepository {
  final Dio _dio;

  DashboardRepository(this._dio);

  Future<Map<String, dynamic>> getScorecardSummary() async {
    try {
      final response = await _dio.get('/dashboard/summary');
      if (response.data['success']) {
        return response.data['data'];
      } else {
        throw Exception(response.data['message']);
      }
    } catch (e) {
      throw Exception('Failed to load scorecard: $e');
    }
  }
}
