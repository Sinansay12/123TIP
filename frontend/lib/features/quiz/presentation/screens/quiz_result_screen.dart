/// Quiz Result Screen
library;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/router/app_router.dart';

class QuizResultScreen extends StatelessWidget {
  final int score;
  final int total;

  const QuizResultScreen({
    super.key,
    required this.score,
    required this.total,
  });

  @override
  Widget build(BuildContext context) {
    final percentage = total > 0 ? (score / total * 100).round() : 0;
    final isExcellent = percentage >= 80;
    final isGood = percentage >= 60;

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Animated result icon
              TweenAnimationBuilder<double>(
                tween: Tween(begin: 0, end: 1),
                duration: const Duration(milliseconds: 800),
                curve: Curves.elasticOut,
                builder: (context, value, child) {
                  return Transform.scale(
                    scale: value,
                    child: child,
                  );
                },
                child: Container(
                  width: 140,
                  height: 140,
                  decoration: BoxDecoration(
                    gradient: isExcellent
                        ? const LinearGradient(
                            colors: [Color(0xFF00C853), Color(0xFF00E676)],
                          )
                        : isGood
                            ? const LinearGradient(
                                colors: [Color(0xFFFFAB00), Color(0xFFFFD600)],
                              )
                            : const LinearGradient(
                                colors: [Color(0xFFFF5252), Color(0xFFFF8A80)],
                              ),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: (isExcellent
                                ? const Color(0xFF00C853)
                                : isGood
                                    ? const Color(0xFFFFAB00)
                                    : const Color(0xFFFF5252))
                            .withOpacity(0.4),
                        blurRadius: 30,
                        spreadRadius: 5,
                      ),
                    ],
                  ),
                  child: Icon(
                    isExcellent
                        ? Icons.emoji_events
                        : isGood
                            ? Icons.thumb_up
                            : Icons.school,
                    size: 70,
                    color: Colors.white,
                  ),
                ),
              ),

              const SizedBox(height: 40),

              // Result text
              Text(
                isExcellent
                    ? 'Mükemmel! 🎉'
                    : isGood
                        ? 'İyi İş! 👍'
                        : 'Devam Et! 💪',
                style: Theme.of(context).textTheme.displayMedium,
              ),

              const SizedBox(height: 16),

              // Score display
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                decoration: BoxDecoration(
                  color: AppTheme.darkCard,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppTheme.darkBorder),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '$score',
                      style: const TextStyle(
                        fontSize: 48,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.primaryColor,
                      ),
                    ),
                    Text(
                      ' / $total',
                      style: const TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.w300,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 12),

              Text(
                '%$percentage Başarı',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: AppTheme.textMuted,
                    ),
              ),

              const SizedBox(height: 48),

              // Progress bar
              Container(
                height: 12,
                decoration: BoxDecoration(
                  color: AppTheme.darkCard,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: LinearProgressIndicator(
                    value: percentage / 100,
                    backgroundColor: Colors.transparent,
                    valueColor: AlwaysStoppedAnimation(
                      isExcellent
                          ? AppTheme.accentGreen
                          : isGood
                              ? AppTheme.accentOrange
                              : AppTheme.errorColor,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 60),

              // Action buttons
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => context.go(AppRoutes.dashboard),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 18),
                  ),
                  child: const Text('Ana Sayfaya Dön'),
                ),
              ),

              const SizedBox(height: 16),

              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () => context.go(AppRoutes.quiz),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 18),
                  ),
                  child: const Text('Tekrar Çöz'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
