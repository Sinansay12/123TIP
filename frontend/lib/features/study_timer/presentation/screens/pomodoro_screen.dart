/// Pomodoro Timer Screen
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:math' as math;
import '../../../../core/theme/app_theme.dart';
import '../../../../core/services/notification_service.dart';
import '../../data/timer_state.dart';
import '../../providers/timer_provider.dart';
import '../../providers/timer_lifecycle_observer.dart';

class PomodoroScreen extends ConsumerStatefulWidget {
  const PomodoroScreen({super.key});

  @override
  ConsumerState<PomodoroScreen> createState() => _PomodoroScreenState();
}

class _PomodoroScreenState extends ConsumerState<PomodoroScreen>
    with TickerProviderStateMixin, TimerLifecycleMixin {
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
    
    // Initialize notifications
    notificationService.initialize();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final timerState = ref.watch(pomodoroTimerProvider);
    final notifier = ref.read(pomodoroTimerProvider.notifier);

    // Listen for timer completion to show notification
    ref.listen<PomodoroState>(pomodoroTimerProvider, (previous, next) {
      if (next.status == TimerStatus.completed) {
        if (next.sessionType == SessionType.work) {
          notificationService.showWorkComplete();
        } else {
          notificationService.showBreakComplete();
        }
      }
    });

    return Scaffold(
      appBar: AppBar(
        title: const Text('Pomodoro Timer'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline),
            onPressed: () => _showInfoDialog(context),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            const Spacer(),
            
            // Session Type Indicator
            _SessionTypeChip(sessionType: timerState.sessionType),
            
            const SizedBox(height: 32),
            
            // Timer Circle
            _TimerCircle(
              state: timerState,
              pulseAnimation: _pulseController,
            ),
            
            const SizedBox(height: 48),
            
            // Control Buttons
            _ControlButtons(
              state: timerState,
              onStart: notifier.start,
              onPause: notifier.pause,
              onReset: notifier.reset,
              onSkip: notifier.skip,
            ),
            
            const Spacer(),
            
            // Stats at bottom
            _StatsBar(
              completedSessions: timerState.completedSessions,
              totalMinutes: timerState.totalWorkMinutes,
            ),
            
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  void _showInfoDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Text('🍅 '),
            Text('Pomodoro Tekniği'),
          ],
        ),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('• 25 dakika odaklı çalışma'),
            SizedBox(height: 8),
            Text('• 5 dakika kısa mola'),
            SizedBox(height: 8),
            Text('• Her 4 çalışmadan sonra 15 dk uzun mola'),
            SizedBox(height: 16),
            Text(
              'Bu teknik, dikkat dağınıklığını azaltır ve üretkenliği artırır.',
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Anladım'),
          ),
        ],
      ),
    );
  }
}

// Session Type Chip Widget
class _SessionTypeChip extends StatelessWidget {
  final SessionType sessionType;

  const _SessionTypeChip({required this.sessionType});

  @override
  Widget build(BuildContext context) {
    Color chipColor;
    IconData icon;

    switch (sessionType) {
      case SessionType.work:
        chipColor = AppTheme.primaryColor;
        icon = Icons.work_outline;
        break;
      case SessionType.shortBreak:
        chipColor = AppTheme.accentGreen;
        icon = Icons.coffee_outlined;
        break;
      case SessionType.longBreak:
        chipColor = AppTheme.accentOrange;
        icon = Icons.self_improvement_outlined;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: chipColor.withOpacity(0.2),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: chipColor, size: 20),
          const SizedBox(width: 8),
          Text(
            sessionType.label,
            style: TextStyle(
              color: chipColor,
              fontWeight: FontWeight.w600,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }
}

// Timer Circle Widget
class _TimerCircle extends StatelessWidget {
  final PomodoroState state;
  final AnimationController pulseAnimation;

  const _TimerCircle({
    required this.state,
    required this.pulseAnimation,
  });

  @override
  Widget build(BuildContext context) {
    final isRunning = state.status == TimerStatus.running;
    final size = MediaQuery.of(context).size.width * 0.7;

    Color progressColor;
    switch (state.sessionType) {
      case SessionType.work:
        progressColor = AppTheme.primaryColor;
        break;
      case SessionType.shortBreak:
        progressColor = AppTheme.accentGreen;
        break;
      case SessionType.longBreak:
        progressColor = AppTheme.accentOrange;
        break;
    }

    return AnimatedBuilder(
      animation: pulseAnimation,
      builder: (context, child) {
        final scale = isRunning
            ? 1.0 + (pulseAnimation.value * 0.02)
            : 1.0;

        return Transform.scale(
          scale: scale,
          child: SizedBox(
            width: size,
            height: size,
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Background Circle
                Container(
                  width: size,
                  height: size,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppTheme.darkCard,
                    boxShadow: [
                      BoxShadow(
                        color: progressColor.withOpacity(isRunning ? 0.3 : 0.1),
                        blurRadius: isRunning ? 30 : 10,
                        spreadRadius: isRunning ? 5 : 0,
                      ),
                    ],
                  ),
                ),

                // Progress Arc
                CustomPaint(
                  size: Size(size, size),
                  painter: _ProgressPainter(
                    progress: state.progress,
                    color: progressColor,
                    strokeWidth: 8,
                  ),
                ),

                // Time Text
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      state.formattedTime,
                      style: const TextStyle(
                        fontSize: 64,
                        fontWeight: FontWeight.w300,
                        letterSpacing: 4,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _getStatusText(state.status),
                      style: TextStyle(
                        color: Colors.grey[500],
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  String _getStatusText(TimerStatus status) {
    switch (status) {
      case TimerStatus.idle:
        return 'Başlamak için hazır';
      case TimerStatus.running:
        return 'Devam ediyor...';
      case TimerStatus.paused:
        return 'Duraklatıldı';
      case TimerStatus.completed:
        return 'Tamamlandı! 🎉';
    }
  }
}

// Progress Painter
class _ProgressPainter extends CustomPainter {
  final double progress;
  final Color color;
  final double strokeWidth;

  _ProgressPainter({
    required this.progress,
    required this.color,
    required this.strokeWidth,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - strokeWidth) / 2;

    // Background circle
    final bgPaint = Paint()
      ..color = color.withOpacity(0.1)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;

    canvas.drawCircle(center, radius, bgPaint);

    // Progress arc
    final progressPaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    final sweepAngle = 2 * math.pi * progress;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2, // Start from top
      sweepAngle,
      false,
      progressPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _ProgressPainter oldDelegate) {
    return oldDelegate.progress != progress || oldDelegate.color != color;
  }
}

// Control Buttons
class _ControlButtons extends StatelessWidget {
  final PomodoroState state;
  final VoidCallback onStart;
  final VoidCallback onPause;
  final VoidCallback onReset;
  final VoidCallback onSkip;

  const _ControlButtons({
    required this.state,
    required this.onStart,
    required this.onPause,
    required this.onReset,
    required this.onSkip,
  });

  @override
  Widget build(BuildContext context) {
    final isRunning = state.status == TimerStatus.running;
    final isPaused = state.status == TimerStatus.paused;
    final isIdle = state.status == TimerStatus.idle;

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Reset Button
        if (!isIdle)
          _CircleButton(
            icon: Icons.refresh,
            onPressed: onReset,
            size: 50,
          ),

        const SizedBox(width: 24),

        // Play/Pause Button
        _CircleButton(
          icon: isRunning ? Icons.pause : Icons.play_arrow,
          onPressed: isRunning ? onPause : onStart,
          size: 80,
          isPrimary: true,
        ),

        const SizedBox(width: 24),

        // Skip Button
        _CircleButton(
          icon: Icons.skip_next,
          onPressed: onSkip,
          size: 50,
        ),
      ],
    );
  }
}

class _CircleButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onPressed;
  final double size;
  final bool isPrimary;

  const _CircleButton({
    required this.icon,
    required this.onPressed,
    required this.size,
    this.isPrimary = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: isPrimary ? AppTheme.primaryGradient : null,
          color: isPrimary ? null : AppTheme.darkCard,
          boxShadow: isPrimary
              ? [
                  BoxShadow(
                    color: AppTheme.primaryColor.withOpacity(0.4),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ]
              : null,
        ),
        child: Icon(
          icon,
          color: Colors.white,
          size: size * 0.5,
        ),
      ),
    );
  }
}

// Stats Bar
class _StatsBar extends StatelessWidget {
  final int completedSessions;
  final int totalMinutes;

  const _StatsBar({
    required this.completedSessions,
    required this.totalMinutes,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.darkCard,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _StatItem(
            icon: Icons.check_circle_outline,
            value: '$completedSessions',
            label: 'Tamamlanan',
          ),
          Container(
            width: 1,
            height: 40,
            color: AppTheme.darkBorder,
          ),
          _StatItem(
            icon: Icons.timer_outlined,
            value: '${totalMinutes}dk',
            label: 'Bugün',
          ),
        ],
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;

  const _StatItem({
    required this.icon,
    required this.value,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: AppTheme.primaryColor, size: 24),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            color: Colors.grey[500],
            fontSize: 12,
          ),
        ),
      ],
    );
  }
}
