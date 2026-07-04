import 'dart:convert';
import 'dart:io';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:dio/dio.dart';
import 'package:hive/hive.dart';
import 'package:progcap_app/data/models/sync_task.dart';

class SyncQueue {
  final Dio _dio;
  late Box<SyncTask> _syncBox;
  bool _isInitialized = false;
  bool _isSyncing = false;

  SyncQueue(this._dio);

  Future<void> init() async {
    if (_isInitialized) return;
    Hive.registerAdapter(SyncTaskAdapter()); // This requires running build_runner
    _syncBox = await Hive.openBox<SyncTask>('sync_queue');
    _isInitialized = true;

    // Listen for connectivity changes
    Connectivity().onConnectivityChanged.listen((List<ConnectivityResult> results) {
      if (results.contains(ConnectivityResult.mobile) || results.contains(ConnectivityResult.wifi)) {
        processQueue();
      }
    });
  }

  Future<void> enqueueTask(String type, Map<String, dynamic> payload) async {
    if (!_isInitialized) await init();

    final task = SyncTask(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      type: type,
      payload: jsonEncode(payload),
      createdAt: DateTime.now(),
    );

    await _syncBox.put(task.id, task);
    processQueue(); // Try to process immediately
  }

  Future<void> processQueue() async {
    if (!_isInitialized || _isSyncing) return;

    final connectivity = await Connectivity().checkConnectivity();
    if (connectivity.contains(ConnectivityResult.none)) return;

    _isSyncing = true;

    try {
      final pendingTasks = _syncBox.values.where((t) => t.status == 'PENDING').toList();
      if (pendingTasks.isEmpty) return;

      // Sort oldest first
      pendingTasks.sort((a, b) => a.createdAt.compareTo(b.createdAt));

      // Separate file uploads from data syncs
      final docTasks = pendingTasks.where((t) => t.type == 'UPLOAD_DOCUMENT').toList();
      final dataTasks = pendingTasks.where((t) => t.type != 'UPLOAD_DOCUMENT').toList();

      if (dataTasks.isNotEmpty) {
        bool syncSuccess = await _syncBatch(dataTasks);
        for (var task in dataTasks) {
          if (syncSuccess) {
            await task.delete();
          } else {
            task.retryCount++;
            task.status = task.retryCount > 3 ? 'FAILED' : 'PENDING';
            await task.save();
          }
        }
      }

      for (var task in docTasks) {
        bool success = await _executeDocTask(task);
        if (success) {
          await task.delete();
        } else {
          task.retryCount++;
          task.status = task.retryCount > 3 ? 'FAILED' : 'PENDING';
          await task.save();
        }
      }
    } finally {
      _isSyncing = false;
    }
  }

  Future<bool> _syncBatch(List<SyncTask> tasks) async {
    try {
      final queuePayload = tasks.map((t) {
        final data = jsonDecode(t.payload);
        // Map app action types to backend action types
        String actionType = t.type;
        if (t.type == 'CHECK_IN') actionType = 'VISIT_CHECKIN';
        if (t.type == 'CHECK_OUT') actionType = 'VISIT_CHECKOUT';
        if (t.type == 'UPDATE_LEAD') actionType = 'LEAD_STAGE_UPDATE';
        if (t.type == 'SELF_SOURCE_LEAD') actionType = 'SELF_SOURCE_LEAD';
        
        return {
          'id': t.id,
          'actionType': actionType,
          'payload': {
            ...data,
            'timestamp': t.createdAt.toIso8601String() // Critical for LWW Conflict Resolution
          }
        };
      }).toList();

      final response = await _dio.post('/sync/up', data: {
        'deviceId': 'flutter_device_1', // Dummy ID for now
        'queue': queuePayload
      });
      return response.data['success'] == true;
    } catch (e) {
      return false;
    }
  }

  Future<bool> _executeDocTask(SyncTask task) async {
    try {
      final data = jsonDecode(task.payload);
      
      if (task.type == 'UPLOAD_DOCUMENT') {
        final file = File(data['filePath']);
        if (await file.exists()) {
          final fileName = file.path.split('/').last;
          FormData formData = FormData.fromMap({
            'leadId': data['leadId'],
            'dealerId': data['dealerId'],
            'docType': data['docType'],
            'file': await MultipartFile.fromFile(file.path, filename: fileName),
          });
          await _dio.post('/kyc/upload', data: formData);
        }
        return true;
      }
      return true;
    } catch (e) {
      return false;
    }
  }
}
