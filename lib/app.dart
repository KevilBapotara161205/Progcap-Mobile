import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:progcap_app/core/router/app_router.dart';
import 'package:progcap_app/core/theme/app_theme.dart';
import 'package:progcap_app/services/connectivity_watcher.dart';
import 'package:progcap_app/controllers/sync_controller.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

class ProgcapApp extends ConsumerStatefulWidget {
  const ProgcapApp({super.key});
  @override
  ConsumerState<ProgcapApp> createState() => _ProgcapAppState();
}

class _ProgcapAppState extends ConsumerState<ProgcapApp> {
  @override
  Widget build(BuildContext context) {
    ref.listen(
      connectivityProvider,
      (previous, next) {
        if (next.value != null && next.value != ConnectivityResult.none) {
          ref.read(syncProvider.notifier).runSync();
        }
      },
    );
    final router = ref.watch(routerProvider);
    return MaterialApp.router(
      title: 'Progcap RM App',
      theme: AppTheme.lightTheme,
      routerConfig: router,
      debugShowCheckedModeBanner: false,
    );
  }
}
