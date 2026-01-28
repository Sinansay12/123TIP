/// App Router Configuration using GoRouter
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../features/auth/presentation/screens/login_screen.dart';
import '../../features/auth/presentation/screens/register_screen.dart';
import '../../features/onboarding/presentation/screens/onboarding_screen.dart';
import '../../features/dashboard/presentation/screens/dashboard_screen.dart';
import '../../features/quiz/presentation/screens/quiz_screen.dart';
import '../../features/quiz/presentation/screens/quiz_result_screen.dart';
import '../../features/pdf_viewer/presentation/screens/pdf_viewer_screen.dart';
import '../../features/study_timer/presentation/screens/pomodoro_screen.dart';
import '../../features/study_content/presentation/screens/department_selection_screen.dart';
import '../../features/study_content/presentation/screens/study_content_screen.dart';

/// Route names
class AppRoutes {
  static const String splash = '/';
  static const String onboarding = '/onboarding';
  static const String login = '/login';
  static const String register = '/register';
  static const String dashboard = '/dashboard';
  static const String quiz = '/quiz';
  static const String quizResult = '/quiz/result';
  static const String pdfViewer = '/pdf/:documentId';
  static const String pomodoro = '/pomodoro';
  static const String studyContent = '/study-content';
  static const String departmentContent = '/study-content/:department';
}

/// GoRouter provider
final appRouterProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: AppRoutes.onboarding,
    debugLogDiagnostics: true,
    routes: [
      // Onboarding
      GoRoute(
        path: AppRoutes.onboarding,
        name: 'onboarding',
        builder: (context, state) => const OnboardingScreen(),
      ),
      
      // Auth
      GoRoute(
        path: AppRoutes.login,
        name: 'login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: AppRoutes.register,
        name: 'register',
        builder: (context, state) => const RegisterScreen(),
      ),
      
      // Dashboard
      GoRoute(
        path: AppRoutes.dashboard,
        name: 'dashboard',
        builder: (context, state) => const DashboardScreen(),
      ),
      
      // Quiz
      GoRoute(
        path: AppRoutes.quiz,
        name: 'quiz',
        builder: (context, state) => const QuizScreen(),
      ),
      GoRoute(
        path: AppRoutes.quizResult,
        name: 'quizResult',
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>?;
          return QuizResultScreen(
            score: extra?['score'] ?? 0,
            total: extra?['total'] ?? 0,
          );
        },
      ),
      
      // PDF Viewer with deep link
      GoRoute(
        path: AppRoutes.pdfViewer,
        name: 'pdfViewer',
        builder: (context, state) {
          final documentId = int.tryParse(state.pathParameters['documentId'] ?? '0') ?? 0;
          final pageNumber = int.tryParse(state.uri.queryParameters['page'] ?? '1') ?? 1;
          return PdfViewerScreen(
            documentId: documentId,
            initialPage: pageNumber,
          );
        },
      ),
      
      // Pomodoro Timer
      GoRoute(
        path: AppRoutes.pomodoro,
        name: 'pomodoro',
        builder: (context, state) => const PomodoroScreen(),
      ),
      
      // Study Content
      GoRoute(
        path: AppRoutes.studyContent,
        name: 'studyContent',
        builder: (context, state) => const DepartmentSelectionScreen(),
      ),
      GoRoute(
        path: AppRoutes.departmentContent,
        name: 'departmentContent',
        builder: (context, state) {
          final department = state.pathParameters['department'] ?? '';
          return StudyContentScreen(department: Uri.decodeComponent(department));
        },
      ),
    ],
    
    // Error handling
    errorBuilder: (context, state) => Scaffold(
      body: Center(
        child: Text('Page not found: ${state.uri}'),
      ),
    ),
  );
});
