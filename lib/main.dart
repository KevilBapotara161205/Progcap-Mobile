import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:progcap_app/app.dart';
import 'package:progcap_app/data/sources/hive_service.dart';
import 'package:progcap_app/services/fcm_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Disable landscape mode (force portrait only)
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  await Hive.initFlutter();
  await HiveService.init();
  
  await Hive.openBox('leads');
  await Hive.openBox('dealers');
  await Hive.openBox('deals');
  await Hive.openBox('sync_queue');
  
  // Initialize FCM (non-blocking)
  FcmService.init();
  
  runApp(const ProviderScope(child: ProgcapApp()));
}
