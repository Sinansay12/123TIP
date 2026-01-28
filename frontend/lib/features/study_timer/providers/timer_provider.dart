/// Pomodoro Timer Provider with Riverpod
library;

import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../data/timer_state.dart';

/// Pomodoro Timer StateNotifier with Time Synchronization
class PomodoroTimerNotifier extends StateNotifier<PomodoroState> {
  Timer? _timer;
  final Ref ref;

  PomodoroTimerNotifier(this.ref) : super(PomodoroState.initial());

  /// Start or resume timer with time synchronization
  void start() {
    if (state.status == TimerStatus.running) return;

    final now = DateTime.now();
    
    if (state.status == TimerStatus.paused && state.startTime != null) {
      // Resuming from pause - keep existing startTime and pausedDuration
      state = state.copyWith(
        status: TimerStatus.running,
        lastUpdateTime: now,
      );
    } else {
      // Fresh start
      state = state.copyWith(
        status: TimerStatus.running,
        startTime: now,
        pausedDuration: Duration.zero,
        lastUpdateTime: now,
      );
    }
    
    _saveTimerState();
    _startTimer();
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) => _tick());
  }

  /// Pause timer and record paused duration
  void pause() {
    _timer?.cancel();
    
    if (state.startTime != null) {
      final now = DateTime.now();
      // Calculate and store the active time spent so far
      final activeTime = state.sessionType.duration - state.remainingTime;
      
      state = state.copyWith(
        status: TimerStatus.paused,
        pausedDuration: activeTime,
        lastUpdateTime: now,
      );
    } else {
      state = state.copyWith(status: TimerStatus.paused);
    }
    
    _saveTimerState();
  }

  Duration _getActiveTime() {
    if (state.startTime == null) return Duration.zero;
    return state.sessionType.duration - state.remainingTime;
  }

  /// Reset timer to initial state
  void reset() {
    _timer?.cancel();
    state = state.copyWith(
      status: TimerStatus.idle,
      remainingTime: state.sessionType.duration,
      pausedDuration: Duration.zero,
      clearStartTime: true,
    );
    _clearTimerState();
  }

  /// Skip to next session
  void skip() {
    _timer?.cancel();
    _moveToNextSession();
  }

  /// Recalculate remaining time based on actual elapsed time
  /// Called when app returns from background
  void recalculateTime() {
    if (state.status != TimerStatus.running || state.startTime == null) {
      return;
    }

    final now = DateTime.now();
    final totalElapsed = now.difference(state.startTime!);
    final activeTime = totalElapsed - state.pausedDuration;
    final newRemaining = state.sessionType.duration - activeTime;

    if (newRemaining.inSeconds <= 0) {
      // Session completed while in background
      _onSessionComplete();
    } else {
      state = state.copyWith(
        remainingTime: newRemaining,
        lastUpdateTime: now,
      );
    }
  }

  void _tick() {
    if (state.status != TimerStatus.running) return;
    
    // Use real-time calculation instead of just decrementing
    if (state.startTime != null) {
      final now = DateTime.now();
      final totalElapsed = now.difference(state.startTime!);
      final activeTime = totalElapsed - state.pausedDuration;
      final newRemaining = state.sessionType.duration - activeTime;

      if (newRemaining.inSeconds <= 0) {
        _onSessionComplete();
        return;
      }

      state = state.copyWith(
        remainingTime: newRemaining,
        lastUpdateTime: now,
      );
    } else {
      // Fallback to simple decrement
      if (state.remainingTime.inSeconds <= 0) {
        _onSessionComplete();
        return;
      }
      state = state.copyWith(
        remainingTime: state.remainingTime - const Duration(seconds: 1),
      );
    }
  }

  void _onSessionComplete() {
    _timer?.cancel();
    state = state.copyWith(status: TimerStatus.completed);

    // If work session completed, increment stats
    if (state.sessionType == SessionType.work) {
      final newSessions = state.completedSessions + 1;
      final newMinutes = state.totalWorkMinutes + state.sessionType.durationMinutes;
      
      state = state.copyWith(
        completedSessions: newSessions,
        totalWorkMinutes: newMinutes,
      );
      
      // Save stats
      _saveStats();
    }

    _clearTimerState();

    // Auto-move to next session after a short delay
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        _moveToNextSession();
      }
    });
  }

  void _moveToNextSession() {
    SessionType nextSession;
    
    if (state.sessionType == SessionType.work) {
      // After every 4 work sessions, take a long break
      if ((state.completedSessions + 1) % 4 == 0) {
        nextSession = SessionType.longBreak;
      } else {
        nextSession = SessionType.shortBreak;
      }
    } else {
      nextSession = SessionType.work;
    }

    state = state.copyWith(
      status: TimerStatus.idle,
      sessionType: nextSession,
      remainingTime: nextSession.duration,
      pausedDuration: Duration.zero,
      clearStartTime: true,
    );
  }

  /// Save timer state for persistence across app lifecycle
  Future<void> _saveTimerState() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      if (state.startTime != null) {
        await prefs.setString('timer_start_time', state.startTime!.toIso8601String());
      }
      await prefs.setString('timer_session_type', state.sessionType.name);
      await prefs.setInt('timer_paused_duration_ms', state.pausedDuration.inMilliseconds);
      await prefs.setBool('timer_is_running', state.status == TimerStatus.running);
    } catch (e) {
      // Ignore save errors
    }
  }

  /// Clear timer state from persistence
  Future<void> _clearTimerState() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('timer_start_time');
      await prefs.remove('timer_session_type');
      await prefs.remove('timer_paused_duration_ms');
      await prefs.remove('timer_is_running');
    } catch (e) {
      // Ignore errors
    }
  }

  /// Restore timer state from persistence
  Future<void> restoreTimerState() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      final startTimeStr = prefs.getString('timer_start_time');
      final sessionTypeStr = prefs.getString('timer_session_type');
      final pausedDurationMs = prefs.getInt('timer_paused_duration_ms') ?? 0;
      final isRunning = prefs.getBool('timer_is_running') ?? false;
      
      if (startTimeStr != null && isRunning) {
        final startTime = DateTime.parse(startTimeStr);
        final sessionType = SessionType.values.firstWhere(
          (e) => e.name == sessionTypeStr,
          orElse: () => SessionType.work,
        );
        final pausedDuration = Duration(milliseconds: pausedDurationMs);
        
        // Calculate current remaining time
        final now = DateTime.now();
        final totalElapsed = now.difference(startTime);
        final activeTime = totalElapsed - pausedDuration;
        final remaining = sessionType.duration - activeTime;
        
        if (remaining.inSeconds > 0) {
          state = state.copyWith(
            status: TimerStatus.running,
            sessionType: sessionType,
            startTime: startTime,
            pausedDuration: pausedDuration,
            remainingTime: remaining,
            lastUpdateTime: now,
          );
          _startTimer();
        } else {
          // Session would have completed - handle completion
          _clearTimerState();
        }
      }
    } catch (e) {
      // Ignore restore errors
    }
  }

  Future<void> _saveStats() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final today = DateTime.now().toIso8601String().split('T')[0];
      
      await prefs.setInt('pomodoro_sessions_$today', state.completedSessions);
      await prefs.setInt('pomodoro_minutes_$today', state.totalWorkMinutes);
    } catch (e) {
      // Ignore save errors
    }
  }

  Future<void> loadStats() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final today = DateTime.now().toIso8601String().split('T')[0];
      
      final sessions = prefs.getInt('pomodoro_sessions_$today') ?? 0;
      final minutes = prefs.getInt('pomodoro_minutes_$today') ?? 0;
      
      state = state.copyWith(
        completedSessions: sessions,
        totalWorkMinutes: minutes,
      );
    } catch (e) {
      // Ignore load errors
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}

/// Pomodoro Timer Provider
final pomodoroTimerProvider =
    StateNotifierProvider<PomodoroTimerNotifier, PomodoroState>((ref) {
  final notifier = PomodoroTimerNotifier(ref);
  notifier.loadStats();
  return notifier;
});

/// Study Stats Provider (for dashboard display)
final todayStudyStatsProvider = FutureProvider<StudyStats>((ref) async {
  final prefs = await SharedPreferences.getInstance();
  final today = DateTime.now().toIso8601String().split('T')[0];
  
  final sessions = prefs.getInt('pomodoro_sessions_$today') ?? 0;
  final minutes = prefs.getInt('pomodoro_minutes_$today') ?? 0;
  
  return StudyStats(
    totalSessions: sessions,
    totalMinutes: minutes,
    lastStudyDate: DateTime.now(),
  );
});
