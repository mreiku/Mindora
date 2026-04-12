import 'dart:async';

import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';

import 'backend/auth_service.dart';
import 'backend/firebase_options.dart';
import 'state/theme_provider.dart';
import 'frontend/app_theme.dart';
import 'frontend/splash_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends ConsumerStatefulWidget {
  const MyApp({super.key});

  @override
  ConsumerState<MyApp> createState() => _MyAppState();
}

class _MyAppState extends ConsumerState<MyApp> with WidgetsBindingObserver {
  final AuthService _authService = AuthService();
  Timer? _presenceHeartbeat;
  Timer? _presenceOfflineDelay;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _authService.syncCurrentUserPresence(true);
    _startPresenceHeartbeat();
  }

  @override
  void dispose() {
    _presenceHeartbeat?.cancel();
    _presenceOfflineDelay?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    _authService.syncCurrentUserPresence(false);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _presenceOfflineDelay?.cancel();
      _authService.syncCurrentUserPresence(true);
      _startPresenceHeartbeat();
      return;
    }

    if (state == AppLifecycleState.inactive ||
        state == AppLifecycleState.paused ||
        state == AppLifecycleState.detached ||
        state == AppLifecycleState.hidden) {
      _presenceHeartbeat?.cancel();
      _scheduleOfflinePresenceUpdate();
    }
  }

  void _startPresenceHeartbeat() {
    _presenceHeartbeat?.cancel();
    _presenceHeartbeat = Timer.periodic(const Duration(seconds: 10), (_) {
      _authService.syncCurrentUserPresence(true);
    });
  }

  void _scheduleOfflinePresenceUpdate() {
    _presenceOfflineDelay?.cancel();
    _presenceOfflineDelay = Timer(const Duration(seconds: 20), () {
      _authService.syncCurrentUserPresence(false);
    });
  }

  @override
  Widget build(BuildContext context) {
    final appThemeState = ref.watch(appThemeStateNotifier);

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode:
          appThemeState.isDarkModeEnabled ? ThemeMode.dark : ThemeMode.light,
      home: const SplashScreen(),
    );
  }
}
