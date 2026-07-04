import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:hive/hive.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:progcap_app/core/api/api_client.dart';
import 'package:progcap_app/data/models/nba_insight.dart';

final nbaRepositoryProvider = Provider((ref) {
  return NbaRepository(ref.watch(apiClientProvider));
});

final nbaInsightsProvider = FutureProvider.autoDispose<List<NbaInsight>>((ref) async {
  final repository = ref.watch(nbaRepositoryProvider);
  
  double? lat;
  double? lon;
  
  try {
    final permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.whileInUse || permission == LocationPermission.always) {
      final position = await Geolocator.getCurrentPosition(
        timeLimit: const Duration(seconds: 2),
      );
      lat = position.latitude;
      lon = position.longitude;
    }
  } catch (_) {
    // Fail silently, fetch normal ranked feed without geo-proximity
  }

  return repository.getInsights(latitude: lat, longitude: lon);
});

class NbaRepository {
  final Dio _dio;

  NbaRepository(this._dio);

  Future<List<NbaInsight>> getInsights({double? latitude, double? longitude}) async {
    try {
      final Map<String, dynamic> queryParams = {};
      if (latitude != null) queryParams['latitude'] = latitude;
      if (longitude != null) queryParams['longitude'] = longitude;

      final response = await _dio.get('/nba', queryParameters: queryParams);
      if (response.data['success']) {
        final List data = response.data['data'];
        
        // Cache data offline
        try {
          final box = await Hive.openBox('nba_cache');
          await box.put('insights', jsonEncode(data));
        } catch (_) {}
        
        return data.map((json) => NbaInsight.fromJson(json)).toList();
      } else {
        throw Exception(response.data['message']);
      }
    } catch (e) {
      // Fallback to offline cache
      try {
        final box = await Hive.openBox('nba_cache');
        final cachedStr = box.get('insights');
        if (cachedStr != null) {
          final List data = jsonDecode(cachedStr);
          return data.map((json) => NbaInsight.fromJson(json)).toList();
        }
      } catch (_) {}
      
      throw Exception('Failed to load insights: $e');
    }
  }

  Future<void> completeNba(String leadId, String notes) async {
    try {
      final response = await _dio.post('/nba/$leadId/complete', data: {'notes': notes});
      if (!response.data['success']) {
        throw Exception(response.data['message']);
      }
    } catch (e) {
      throw Exception('Failed to complete NBA: $e');
    }
  }

  Future<void> checkInNba(String leadId) async {
    try {
      final response = await _dio.post('/nba/$leadId/checkin');
      if (!response.data['success']) {
        throw Exception(response.data['message']);
      }
    } catch (e) {
      throw Exception('Failed to check-in to NBA: $e');
    }
  }
}
