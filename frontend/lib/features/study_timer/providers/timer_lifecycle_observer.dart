/// Timer Lifecycle Observer for handling app background/foreground transitions
library;

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'timer_provider.dart';

/// Observer to handle app lifecycle changes and recalculate timer
/// when app returns from background
class TimerLifecycleObserver extends WidgetsBindingObserver {
  final WidgetRef ref;
  
  TimerLifecycleObserver(this.ref);
  
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    
    switch (state) {
      case AppLifecycleState.resumed:
        // App came to foreground - recalculate timer
        _onResumed();
        break;
      case AppLifecycleState.paused:
      case AppLifecycleState.inactive:
      case AppLifecycleState.detached:
      case AppLifecycleState.hidden:
        // App going to background - state is already persisted
        break;
    }
  }
  
  void _onResumed() {
    // Recalculate timer based on actual elapsed time
    ref.read(pomodoroTimerProvider.notifier).recalculateTime();
  }
}

/// Mixin to add lifecycle observer to a widget
mixin TimerLifecycleMixin<T extends ConsumerStatefulWidget> on ConsumerState<T> {
  TimerLifecycleObserver? _lifecycleObserver;
  
  @override
  void initState() {
    super.initState();
    _lifecycleObserver = TimerLifecycleObserver(ref);
    WidgetsBinding.instance.addObserver(_lifecycleObserver!);
    
    // Also restore timer state when widget initializes
    _restoreTimerState();
  }
  
  Future<void> _restoreTimerState() async {
    await ref.read(pomodoroTimerProvider.notifier).restoreTimerState();
  }
  
  @override
  void dispose() {
    if (_lifecycleObserver != null) {
      WidgetsBinding.instance.removeObserver(_lifecycleObserver!);
    }
    super.dispose();
  }
}
