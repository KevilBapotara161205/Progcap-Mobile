import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:progcap_app/core/api/api_client.dart';
import 'package:progcap_app/data/models/kyc_document.dart';

import 'package:progcap_app/services/sync_queue.dart';

final kycRepositoryProvider = Provider((ref) {
  return KycRepository(ref.watch(apiClientProvider), SyncQueue(ref.watch(apiClientProvider)));
});

final kycDocumentsProvider = FutureProvider.autoDispose.family<List<KycDocument>, String>((ref, leadId) {
  final repository = ref.watch(kycRepositoryProvider);
  return repository.getDocumentsByLead(leadId);
});

class KycRepository {
  final Dio _dio;
  final SyncQueue _syncQueue;

  KycRepository(this._dio, this._syncQueue);

  Future<List<KycDocument>> getDocumentsByLead(String leadId) async {
    try {
      final response = await _dio.get('/kyc/lead/$leadId');
      if (response.data['success']) {
        final List data = response.data['data'];
        return data.map((json) => KycDocument.fromJson(json)).toList();
      } else {
        throw Exception(response.data['message']);
      }
    } catch (e) {
      throw Exception('Failed to load KYC documents: $e');
    }
  }

  Future<KycDocument> uploadDocument({
    required String leadId,
    required String dealerId,
    required String docType,
    required File file,
  }) async {
    try {
      String fileName = file.path.split('/').last;
      FormData formData = FormData.fromMap({
        'leadId': leadId,
        'dealerId': dealerId,
        'docType': docType,
        'file': await MultipartFile.fromFile(file.path, filename: fileName),
      });

      final response = await _dio.post(
        '/kyc/upload',
        data: formData,
      );

      if (response.data['success']) {
        return KycDocument.fromJson(response.data['data']);
      } else {
        throw Exception(response.data['message']);
      }
    } catch (e) {
      // Offline Mode Fallback
      if (e is DioException && e.type != DioExceptionType.badResponse) {
        // Enqueue for offline sync
        await _syncQueue.enqueueTask('UPLOAD_DOCUMENT', {
          'leadId': leadId,
          'dealerId': dealerId,
          'docType': docType,
          'filePath': file.path,
        });
        
        // Return a dummy successful response so UI can proceed
        return KycDocument(
          id: 'offline_${DateTime.now().millisecondsSinceEpoch}',
          leadId: leadId,
          docType: docType,
          status: 'PENDING_SYNC',
          s3Url: file.path,
        );
      }
      throw Exception('Failed to upload document: $e');
    }
  }

  Future<bool> completeKyc(String leadId) async {
    try {
      final response = await _dio.patch('/leads/$leadId/kyc-complete');
      return response.data['success'];
    } catch (e) {
      throw Exception('Failed to complete KYC: $e');
    }
  }
}
