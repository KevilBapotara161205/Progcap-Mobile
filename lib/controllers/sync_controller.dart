import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:progcap_app/core/widgets/sync_banner.dart';
import 'package:progcap_app/services/sync_queue.dart';
import 'package:progcap_app/core/api/api_client.dart';

class SyncNotifier extends StateNotifier<SyncState> {
  final SyncQueue _syncQueue;

  SyncNotifier(this._syncQueue) : super(SyncState.synced);

  Future<void> runSync() async {
    state = SyncState.syncing;
    try {
      await _syncQueue.processQueue();
      state = SyncState.synced;
    } catch (e) {
      state = SyncState.error;
    }
  }
}

final syncProvider = StateNotifierProvider<SyncNotifier, SyncState>((ref) {
  return SyncNotifier(SyncQueue(ref.watch(apiClientProvider)));
});
