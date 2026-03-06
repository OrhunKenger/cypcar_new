import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/router/router.dart';
import 'core/services/fcm_service.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/theme_provider.dart';
import 'firebase_options.dart';

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
  } catch (_) {}
  runApp(const ProviderScope(child: _FcmInitializer(child: CypCarApp())));
}

class _FcmInitializer extends ConsumerStatefulWidget {
  final Widget child;
  const _FcmInitializer({required this.child});

  @override
  ConsumerState<_FcmInitializer> createState() => _FcmInitializerState();
}

class _FcmInitializerState extends ConsumerState<_FcmInitializer> {
  @override
  void initState() {
    super.initState();
    ref.read(fcmServiceProvider).init();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}

class CypCarApp extends ConsumerWidget {
  const CypCarApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);
    final themeMode = ref.watch(themeModeProvider);
    return MaterialApp.router(
      title: 'CypCar',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: themeMode,
      routerConfig: router,
    );
  }
}
