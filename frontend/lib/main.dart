/// Medical Study App - Main Entry Point
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';
import 'core/network/api_client.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(
    const ProviderScope(
      child: MedicalStudyApp(),
    ),
  );
}

class MedicalStudyApp extends ConsumerStatefulWidget {
  const MedicalStudyApp({super.key});

  @override
  ConsumerState<MedicalStudyApp> createState() => _MedicalStudyAppState();
}

class _MedicalStudyAppState extends ConsumerState<MedicalStudyApp> {
  @override
  void initState() {
    super.initState();
    // Initialize auth on app start
    Future.microtask(() {
      ref.read(authProvider.notifier).initialize();
    });
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final router = ref.watch(appRouterProvider);
    
    // Show splash while loading auth
    if (!authState.isInitialized) {
      return MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: AppTheme.darkTheme,
        home: const Scaffold(
          body: Center(
            child: CircularProgressIndicator(),
          ),
        ),
      );
    }
    
    return MaterialApp.router(
      title: '123TIP',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.dark,
      routerConfig: router,
    );
  }
}
