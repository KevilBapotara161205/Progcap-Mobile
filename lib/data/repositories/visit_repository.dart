import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:progcap_app/core/api/api_client.dart';
import 'package:progcap_app/data/models/visit.dart';

final visitRepositoryProvider = Provider((ref) {
  return VisitRepository(ref.watch(apiClientProvider));
});

class VisitRepository {
  final Dio _dio;

  VisitRepository(this._dio);

  Future<Visit> checkIn({
    required String leadId,
    required String dealerId,
    required double latitude,
    required double longitude,
    String? bypassReason,
  }) async {
    try {
      final response = await _dio.post('/visits/check-in', data: {
        'leadId': leadId,
        'dealerId': dealerId,
        'latitude': latitude,
        'longitude': longitude,
        'bypassReason': bypassReason,
      });
      if (response.data['success']) {
        return Visit.fromJson(response.data['data']);
      } else {
        throw Exception(response.data['message']);
      }
    } catch (e) {
      if (e is DioException && e.response?.data != null) {
        throw Exception(e.response!.data['message'] ?? 'Check-in failed');
      }
      throw Exception('Failed to check in: $e');
    }
  }

  Future<Visit> checkOut({
    required String visitId,
    required String notes,
  }) async {
    try {
      final response = await _dio.post('/visits/$visitId/check-out', data: {
        'notes': notes,
      });
      if (response.data['success']) {
        return Visit.fromJson(response.data['data']);
      } else {
        throw Exception(response.data['message']);
      }
    } catch (e) {
      throw Exception('Failed to check out: $e');
    }
  }
}
