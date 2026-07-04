import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:hive/hive.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:progcap_app/core/api/api_client.dart';
import 'package:progcap_app/data/models/lead.dart';
import 'package:progcap_app/services/sync_queue.dart';

final syncQueueProvider = Provider((ref) {
  return SyncQueue(ref.watch(apiClientProvider));
});

final leadRepositoryProvider = Provider((ref) {
  return LeadRepository(ref.watch(apiClientProvider), ref.watch(syncQueueProvider));
});

final myLeadsProvider = FutureProvider.autoDispose<List<Lead>>((ref) {
  final repository = ref.watch(leadRepositoryProvider);
  return repository.getMyLeads();
});

final leadDetailProvider = FutureProvider.autoDispose.family<Lead, String>((ref, id) {
  final repository = ref.watch(leadRepositoryProvider);
  return repository.getLeadById(id);
});

class LeadRepository {
  final Dio _dio;
  final SyncQueue _syncQueue;

  LeadRepository(this._dio, this._syncQueue);

  Future<List<Lead>> getMyLeads() async {
    try {
      final response = await _dio.get('/leads/my');
      if (response.data['success']) {
        final List data = response.data['data'];
        
        // Cache data offline
        try {
          final box = await Hive.openBox('leads_cache');
          await box.put('my_leads', jsonEncode(data));
        } catch (_) {} // Ignore cache write errors

        return data.map((json) => Lead.fromJson(json)).toList();
      } else {
        throw Exception(response.data['message']);
      }
    } catch (e) {
      // Fallback to offline cache
      try {
        final box = await Hive.openBox('leads_cache');
        final cachedStr = box.get('my_leads');
        if (cachedStr != null) {
          final List data = jsonDecode(cachedStr);
          return data.map((json) => Lead.fromJson(json)).toList();
        }
      } catch (_) {}
      
      throw Exception('Failed to load leads: $e');
    }
  }

  Future<Lead> getLeadById(String id) async {
    try {
      final response = await _dio.get('/leads/$id');
      if (response.data['success']) {
        return Lead.fromJson(response.data['data']);
      } else {
        throw Exception(response.data['message']);
      }
    } catch (e) {
      throw Exception('Failed to load lead details: $e');
    }
  }

  Future<Lead> selfSourceLead({
    required String anchorId,
    required String businessName,
    required String phone,
    required double expectedValue,
    required String notes,
    required double latitude,
    required double longitude,
  }) async {
    try {
      final response = await _dio.post('/leads/self-source', data: {
        'anchor': anchorId,
        'dealerInfo': {
          'name': businessName,
          'phone': phone,
          'latitude': latitude,
          'longitude': longitude,
        },
        'expectedValue': expectedValue,
        'notes': notes,
      });
      if (response.data['success']) {
        return Lead.fromJson(response.data['data']);
      } else {
        throw Exception(response.data['message']);
      }
    } catch (e) {
      if (e is DioException && e.type != DioExceptionType.connectionError && e.type != DioExceptionType.unknown) {
        throw Exception(e.response?.data['message'] ?? 'Failed to self-source lead');
      }
      
      // Offline fallback
      await _syncQueue.enqueueTask('SELF_SOURCE_LEAD', {
        'anchor': anchorId,
        'merchantName': businessName,
        'phone': phone,
        'expectedValue': expectedValue,
        'notes': notes,
        'location': {
          'lat': latitude,
          'lng': longitude,
        }
      });
      
      return Lead(
        id: 'offline_${DateTime.now().millisecondsSinceEpoch}',
        stage: 'PENDING_REVIEW',
        expectedValue: expectedValue,
        urgencyFlag: false,
        isStuck: false,
        lastActivityAt: DateTime.now(),
      );
    }
  }
}
