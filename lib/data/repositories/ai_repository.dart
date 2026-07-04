import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:progcap_app/core/api/api_client.dart';

final aiRepositoryProvider = Provider((ref) {
  return AiRepository(ref.watch(apiClientProvider));
});

class AiRepository {
  final Dio _dio;

  AiRepository(this._dio);

  Future<Map<String, dynamic>?> getMerchantXray({String? leadId, String? dealerId}) async {
    try {
      final Map<String, dynamic> reqData = {};
      if (leadId != null) reqData['leadId'] = leadId;
      if (dealerId != null) reqData['dealerId'] = dealerId;
      
      final response = await _dio.post('/ai/merchant-xray', data: reqData);
      if (response.data['success']) {
        return response.data['data'];
      }
      return null;
    } catch (_) {
      return null; // Gracefully degrade when offline/error
    }
  }

  /// Feature 2: Daily RM Brief
  Future<Map<String, dynamic>?> getDailyBrief() async {
    try {
      final response = await _dio.get('/ai/daily-brief');
      if (response.data['success']) {
        return response.data['data'];
      }
      return null;
    } catch (_) {
      return null; // Gracefully degrade
    }
  }

  /// Feature 3: Visit Assistant Prep
  Future<Map<String, dynamic>?> getVisitAssistant({String? leadId, String? dealerId}) async {
    try {
      final Map<String, dynamic> reqData = {};
      if (leadId != null) reqData['leadId'] = leadId;
      if (dealerId != null) reqData['dealerId'] = dealerId;
      
      final response = await _dio.post('/ai/visit-assistant', data: reqData);
      if (response.data['success']) {
        return response.data['data'];
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  /// Feature 4: NBA Explanation
  Future<Map<String, dynamic>?> getNbaExplanation(String leadId, double score) async {
    try {
      final response = await _dio.post('/ai/nba-explain', data: {
        'leadId': leadId,
        'score': score,
      });
      if (response.data['success']) {
        return response.data['data'];
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  /// Feature 5: Visit Summary
  Future<Map<String, dynamic>?> getVisitSummary(String visitId) async {
    try {
      final response = await _dio.post('/ai/visit-summary', data: {
        'visitId': visitId,
      });
      if (response.data['success']) {
        return response.data['data'];
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  /// Feature 6: Follow-up Suggestions
  Future<List<String>?> getFollowUpSuggestions(String leadId) async {
    try {
      final response = await _dio.post('/ai/follow-up', data: {
        'leadId': leadId,
      });
      if (response.data['success'] && response.data['data'] != null) {
        final data = response.data['data'];
        if (data['suggestions'] != null) {
          return List<String>.from(data['suggestions']);
        }
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  /// Feature 7: Smart Search
  Future<Map<String, dynamic>?> smartSearch(String query) async {
    try {
      final response = await _dio.post('/ai/smart-search', data: {
        'query': query,
      });
      if (response.data['success']) {
        return response.data['data'];
      }
      return null;
    } catch (_) {
      return null;
    }
  }
}
