import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:progcap_app/controllers/sync_controller.dart';

final connectivityProvider = StreamProvider<ConnectivityResult>((ref) {
  return Connectivity().onConnectivityChanged.map((event) {
    return event.isNotEmpty ? event.first : ConnectivityResult.none;
  });
});

void startConnectivityWatcher(ProviderContainer container) {
  container.listen<AsyncValue<ConnectivityResult>>(
    connectivityProvider,
    (previous, next) {
      if (next.value != null && next.value != ConnectivityResult.none) {
        container.read(syncProvider.notifier).runSync();
      }
    },
  );
}