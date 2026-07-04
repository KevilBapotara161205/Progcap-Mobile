import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:progcap_app/core/api/api_client.dart';
import 'package:progcap_app/data/models/dashboard_summary.dart';

final homeRepositoryProvider = Provider((ref) {
  return HomeRepository(ref.watch(apiClientProvider));
});

final dashboardSummaryProvider = FutureProvider.autoDispose<DashboardSummary>((ref) {
  final repository = ref.watch(homeRepositoryProvider);
  return repository.getSummary();
});

class HomeRepository {
  final Dio _dio;

  HomeRepository(this._dio);

  Future<DashboardSummary> getSummary() async {
    try {
      final response = await _dio.get('/dashboard/summary');
      if (response.data['success']) {
        return DashboardSummary.fromJson(response.data['data']);
      } else {
        throw Exception(response.data['message']);
      }
    } catch (e) {
      throw Exception('Failed to load dashboard summary: $e');
    }
  }
}
