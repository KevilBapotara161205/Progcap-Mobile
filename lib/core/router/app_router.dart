import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:progcap_app/modules/auth/screens/splash_screen.dart';
import 'package:progcap_app/modules/auth/screens/onboarding_screen.dart';
import 'package:progcap_app/modules/auth/screens/login_screen.dart';
import 'package:progcap_app/modules/auth/screens/otp_verify_screen.dart';
import 'package:progcap_app/modules/home/shell.dart';
import 'package:progcap_app/modules/home/screens/home_screen.dart';
import 'package:progcap_app/modules/nba/screens/nba_pipeline_screen.dart';
import 'package:progcap_app/modules/profile/screens/profile_screen.dart';
import 'package:progcap_app/modules/leads/screens/history_screen.dart';

import 'package:progcap_app/modules/leads/screens/lead_detail_screen.dart';
import 'package:progcap_app/modules/visits/screens/checkin_screen.dart';
import 'package:progcap_app/modules/visits/screens/checkout_screen.dart';
import 'package:progcap_app/modules/kyc/screens/kyc_screen.dart';
import 'package:progcap_app/modules/kyc/screens/document_capture_screen.dart';
import 'package:progcap_app/modules/xray/screens/xray_screen.dart';
import 'package:progcap_app/modules/self_source/screens/self_source_screen.dart';
import 'package:progcap_app/modules/scorecard/screens/scorecard_screen.dart';
import 'package:progcap_app/modules/training/screens/training_home_screen.dart';
import 'package:progcap_app/modules/notifications/screens/notifications_screen.dart';

final rootNavigatorKey = GlobalKey<NavigatorState>();
final shellNavigatorKey = GlobalKey<NavigatorState>();

final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    navigatorKey: rootNavigatorKey,
    initialLocation: '/',
    routes: [
      GoRoute(path: '/', builder: (context, state) => const SplashScreen()),
      GoRoute(path: '/onboarding', builder: (context, state) => const OnboardingScreen()),
      GoRoute(path: '/login', builder: (context, state) => const LoginScreen()),
      GoRoute(path: '/otp', builder: (context, state) => OtpVerifyScreen(phone: state.extra as String)),
      GoRoute(path: '/self-source', builder: (context, state) => const SelfSourceScreen()),
      GoRoute(path: '/scorecard', builder: (context, state) => const ScorecardScreen()),
      GoRoute(path: '/training', builder: (context, state) => const TrainingHomeScreen()),
      GoRoute(path: '/notifications', builder: (context, state) => const NotificationsScreen()),
      GoRoute(path: '/leads/:id', builder: (context, state) => LeadDetailScreen(leadId: state.pathParameters['id']!)),
      GoRoute(path: '/check-in/:id/:dealerId', builder: (context, state) => CheckInScreen(leadId: state.pathParameters['id']!, dealerId: state.pathParameters['dealerId']!)),
      GoRoute(path: '/check-out/:id', builder: (context, state) => CheckOutScreen(visitId: state.pathParameters['id']!)),
      GoRoute(path: '/kyc/:id/:dealerId', builder: (context, state) => KycScreen(leadId: state.pathParameters['id']!, dealerId: state.pathParameters['dealerId']!)),
      GoRoute(path: '/kyc/:id/:dealerId/capture/:docType', builder: (context, state) => DocumentCaptureScreen(leadId: state.pathParameters['id']!, dealerId: state.pathParameters['dealerId']!, docType: state.pathParameters['docType']!)),
      GoRoute(path: '/xray', builder: (context, state) => const XrayScreen()),
      
      ShellRoute(
        navigatorKey: shellNavigatorKey,
        builder: (context, state, child) => AppShell(child: child),
        routes: [
          GoRoute(path: '/home', builder: (context, state) => const HomeScreen()),
          GoRoute(path: '/pipeline', builder: (context, state) => const NbaPipelineScreen()),
          GoRoute(path: '/history', builder: (context, state) => const HistoryScreen()),
          GoRoute(path: '/profile', builder: (context, state) => const ProfileScreen()),
        ],
      ),
    ]
  );
});
