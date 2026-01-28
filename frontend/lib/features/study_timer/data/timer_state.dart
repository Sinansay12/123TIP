/// Timer State Models for Pomodoro Feature
library;

import 'package:flutter/foundation.dart';

/// Timer session types
enum SessionType {
  work,
  shortBreak,
  longBreak,
}

/// Extension for SessionType
extension SessionTypeExtension on SessionType {
  String get label {
    switch (this) {
      case SessionType.work:
        return 'Çalışma';
      case SessionType.shortBreak:
        return 'Kısa Mola';
      case SessionType.longBreak:
        return 'Uzun Mola';
    }
  }

  int get durationMinutes {
    switch (this) {
      case SessionType.work:
        return 25;
      case SessionType.shortBreak:
        return 5;
      case SessionType.longBreak:
        return 15;
    }
  }

  Duration get duration => Duration(minutes: durationMinutes);
}

/// Timer status
enum TimerStatus {
  idle,
  running,
  paused,
  completed,
}

/// Pomodoro Timer State
@immutable
class PomodoroState {
  final TimerStatus status;
  final SessionType sessionType;
  final Duration remainingTime;
  final int completedSessions;
  final int totalWorkMinutes;
  
  /// Time synchronization fields
  final DateTime? startTime;         // When timer was started
  final Duration pausedDuration;     // Accumulated paused time
  final DateTime? lastUpdateTime;    // Last time state was updated

  const PomodoroState({
    this.status = TimerStatus.idle,
    this.sessionType = SessionType.work,
    required this.remainingTime,
    this.completedSessions = 0,
    this.totalWorkMinutes = 0,
    this.startTime,
    this.pausedDuration = Duration.zero,
    this.lastUpdateTime,
  });

  factory PomodoroState.initial() {
    return PomodoroState(
      remainingTime: SessionType.work.duration,
    );
  }

  PomodoroState copyWith({
    TimerStatus? status,
    SessionType? sessionType,
    Duration? remainingTime,
    int? completedSessions,
    int? totalWorkMinutes,
    DateTime? startTime,
    Duration? pausedDuration,
    DateTime? lastUpdateTime,
    bool clearStartTime = false,
  }) {
    return PomodoroState(
      status: status ?? this.status,
      sessionType: sessionType ?? this.sessionType,
      remainingTime: remainingTime ?? this.remainingTime,
      completedSessions: completedSessions ?? this.completedSessions,
      totalWorkMinutes: totalWorkMinutes ?? this.totalWorkMinutes,
      startTime: clearStartTime ? null : (startTime ?? this.startTime),
      pausedDuration: pausedDuration ?? this.pausedDuration,
      lastUpdateTime: lastUpdateTime ?? this.lastUpdateTime,
    );
  }

  /// Format remaining time as MM:SS
  String get formattedTime {
    final minutes = remainingTime.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = remainingTime.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  /// Progress percentage (0.0 to 1.0)
  double get progress {
    final total = sessionType.duration.inSeconds;
    final remaining = remainingTime.inSeconds;
    if (total == 0) return 0;
    return (total - remaining) / total;
  }
}

/// Daily Study Statistics
@immutable
class StudyStats {
  final int totalSessions;
  final int totalMinutes;
  final DateTime lastStudyDate;

  const StudyStats({
    this.totalSessions = 0,
    this.totalMinutes = 0,
    required this.lastStudyDate,
  });

  factory StudyStats.empty() {
    return StudyStats(lastStudyDate: DateTime.now());
  }

  StudyStats copyWith({
    int? totalSessions,
    int? totalMinutes,
    DateTime? lastStudyDate,
  }) {
    return StudyStats(
      totalSessions: totalSessions ?? this.totalSessions,
      totalMinutes: totalMinutes ?? this.totalMinutes,
      lastStudyDate: lastStudyDate ?? this.lastStudyDate,
    );
  }

  String get formattedTotalTime {
    final hours = totalMinutes ~/ 60;
    final mins = totalMinutes % 60;
    if (hours > 0) {
      return '${hours}s ${mins}dk';
    }
    return '${mins}dk';
  }
}
