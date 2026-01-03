import 'dart:async';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/services/notification_service.dart';
import '../../../../data/models/pomodoro_session.dart';
import '../../../../data/repositories/pomodoro_repository.dart';
import '../../../../data/repositories/stats_repository.dart';
import 'pomodoro_timer_state.dart';

class PomodoroTimerCubit extends Cubit<PomodoroTimerState> {
  Timer? _timer;
  Timer? _alarmTimer;
  final AudioPlayer _audioPlayer = AudioPlayer();
  final PomodoroRepository _pomodoroRepository;
  final StatsRepository _statsRepository;

  static const int _pomodoroDuration = 25 * 60;
  static const int _restDuration = 5 * 60;
  static const int _longRestDuration = 15 * 60;

  DateTime? _sessionStartTime;
  int? _currentTaskId;

  // Store elapsed time for each mode separately
  final Map<TimerMode, int> _modeElapsedTimes = {
    TimerMode.pomodoro: 0,
    TimerMode.rest: 0,
    TimerMode.longRest: 0,
  };

  // Store status for each mode separately
  final Map<TimerMode, TimerStatus> _modeStatuses = {
    TimerMode.pomodoro: TimerStatus.initial,
    TimerMode.rest: TimerStatus.initial,
    TimerMode.longRest: TimerStatus.initial,
  };

  PomodoroTimerCubit(
    this._pomodoroRepository,
    this._statsRepository,
  ) : super(const PomodoroTimerState(duration: _pomodoroDuration));

  void setCurrentTask(int? taskId) {
    _currentTaskId = taskId;
  }

  void startTimer() {
    if (state.status == TimerStatus.running) return;

    // Stop alarm sound if it's playing
    _stopAlarm();

    if (state.isRestMode) {
      // REST MODE timer
      if (state.restDuration == null) return; // No duration selected

      emit(state.copyWith(status: TimerStatus.running));

      _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
        if (state.restElapsed < state.restDuration!) {
          final newElapsed = state.restElapsed + 1;
          emit(state.copyWith(restElapsed: newElapsed));
        } else {
          _completeTimer();
        }
      });
    } else {
      // Pomodoro timer
      _sessionStartTime = DateTime.now();
      final newStatus = TimerStatus.running;
      _modeStatuses[state.mode] = newStatus;
      emit(state.copyWith(status: newStatus));

      _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
        if (state.elapsed < state.duration) {
          final newElapsed = state.elapsed + 1;
          _modeElapsedTimes[state.mode] = newElapsed;
          emit(state.copyWith(elapsed: newElapsed));
        } else {
          _completeTimer();
        }
      });
    }
  }

  void pauseTimer() {
    if (state.status == TimerStatus.running) {
      _timer?.cancel();
      final newStatus = TimerStatus.paused;
      _modeStatuses[state.mode] = newStatus;
      emit(state.copyWith(status: newStatus));
    }
  }

  void stopTimer() {
    _timer?.cancel();
    emit(state.copyWith(status: TimerStatus.initial, elapsed: 0));
  }

  void setMode(TimerMode mode) {
    // Save current mode's state before switching
    final wasRunning = state.status == TimerStatus.running;

    // Cancel current timer when switching modes
    _timer?.cancel();

    int newDuration;
    switch (mode) {
      case TimerMode.pomodoro:
        newDuration = _pomodoroDuration;
        break;
      case TimerMode.rest:
        newDuration = _restDuration;
        break;
      case TimerMode.longRest:
        newDuration = _longRestDuration;
        break;
    }

    // Restore the saved elapsed time and status for the new mode
    final savedElapsed = _modeElapsedTimes[mode] ?? 0;
    final savedStatus = _modeStatuses[mode] ?? TimerStatus.initial;

    emit(state.copyWith(
      mode: mode,
      duration: newDuration,
      elapsed: savedElapsed,
      status: savedStatus,
    ));

    // If we were running before switching, continue running in the new mode
    if (wasRunning) {
      _sessionStartTime = DateTime.now();
      final runningStatus = TimerStatus.running;
      _modeStatuses[mode] = runningStatus;
      emit(state.copyWith(status: runningStatus));

      _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
        if (state.elapsed < state.duration) {
          final newElapsed = state.elapsed + 1;
          _modeElapsedTimes[state.mode] = newElapsed;
          emit(state.copyWith(elapsed: newElapsed));
        } else {
          _completeTimer();
        }
      });
    }
  }

  void resetTimer() {
    _timer?.cancel();
    if (state.isRestMode) {
      // Reset rest mode timer
      emit(state.copyWith(
        status: TimerStatus.initial,
        restElapsed: 0,
      ));
    } else {
      // Reset pomodoro timer
      _modeElapsedTimes[state.mode] = 0;
      _modeStatuses[state.mode] = TimerStatus.initial;
      emit(state.copyWith(
        status: TimerStatus.initial,
        elapsed: 0,
      ));
    }
    _sessionStartTime = null;
  }

  void toggleRestMode() {
    _timer?.cancel();
    _stopAlarm();

    if (state.isRestMode) {
      // Toggle OFF: Return to Pomodoro mode, reset rest timer
      emit(state.copyWith(
        isRestMode: false,
        status: _modeStatuses[state.mode] ?? TimerStatus.initial,
        elapsed: _modeElapsedTimes[state.mode] ?? 0,
        restDuration: null,
        restElapsed: 0,
      ));
    } else {
      // Toggle ON: Enter REST MODE
      emit(state.copyWith(
        isRestMode: true,
        status: TimerStatus.initial,
        restDuration: null,
        restElapsed: 0,
      ));
    }
  }

  void setRestDuration(int minutes) {
    if (state.isRestMode) {
      emit(state.copyWith(
        restDuration: minutes * 60,
        restElapsed: 0,
        status: TimerStatus.initial,
      ));
    }
  }

  Future<void> _completeTimer() async {
    _timer?.cancel();

    if (state.isRestMode) {
      // REST MODE completion
      await _playSound();
      await NotificationService().showNotification(
        id: 0,
        title: 'Rest time is up!',
        body: 'Your rest period has ended.',
      );

      emit(state.copyWith(status: TimerStatus.completed));
      // Stay in rest mode, don't auto-switch
      return;
    }

    // Pomodoro timer completion
    // Save session to database
    if (_sessionStartTime != null) {
      final session = PomodoroSession(
        startTime: _sessionStartTime!,
        endTime: DateTime.now(),
        durationMinutes: state.duration ~/ 60,
        mode: _mapTimerModeToPomodoroMode(state.mode),
        completed: true,
        taskId: _currentTaskId,
      );
      await _pomodoroRepository.saveSession(session);

      // Update daily stats
      await _statsRepository.updateDailyStats(DateTime.now());
    }

    // Auto-switch Logic
    int newCompletedPomodoros = state.completedPomodoros;
    TimerMode nextMode = state.mode;
    int nextDuration = state.duration;

    if (state.mode == TimerMode.pomodoro) {
      newCompletedPomodoros++;

      if (newCompletedPomodoros % 4 == 0) {
        nextMode = TimerMode.longRest;
        nextDuration = _longRestDuration;
      } else {
        nextMode = TimerMode.rest;
        nextDuration = _restDuration;
      }
    } else {
      // If Break finished, go back to Work
      nextMode = TimerMode.pomodoro;
      nextDuration = _pomodoroDuration;
    }

    // Play sound (10 seconds) and show notification
    await _playSound();
    await NotificationService().showNotification(
      id: 0,
      title: 'Time is up!',
      body: _getNotificationBody(nextMode),
    );

    // Emit completed status first (optional, to trigger UI effects)
    emit(state.copyWith(status: TimerStatus.completed));

    // Reset the next mode's elapsed time and status
    _modeElapsedTimes[nextMode] = 0;
    _modeStatuses[nextMode] = TimerStatus.initial;

    // Switch to next mode immediately (initial status, ready to start)
    emit(
      state.copyWith(
        status: TimerStatus.initial,
        mode: nextMode,
        duration: nextDuration,
        elapsed: 0,
        completedPomodoros: newCompletedPomodoros,
      ),
    );

    // Reset session start time
    _sessionStartTime = null;
  }

  PomodoroMode _mapTimerModeToPomodoroMode(TimerMode mode) {
    switch (mode) {
      case TimerMode.pomodoro:
        return PomodoroMode.pomodoro;
      case TimerMode.rest:
        return PomodoroMode.rest;
      case TimerMode.longRest:
        return PomodoroMode.longRest;
    }
  }

  String _getNotificationBody(TimerMode nextMode) {
    switch (nextMode) {
      case TimerMode.pomodoro:
        return "Break is over! Time to focus.";
      case TimerMode.rest:
        return "Great job! Take a short break.";
      case TimerMode.longRest:
        return "Awesome work! Take a long break.";
    }
  }

  Future<void> _playSound() async {
    try {
      await _audioPlayer.play(AssetSource('sounds/pomo_alrm.mp3'));

      // Stop the alarm after 10 seconds
      _alarmTimer?.cancel();
      _alarmTimer = Timer(const Duration(seconds: 10), () {
        _stopAlarm();
      });
    } catch (e) {
      // Handle audio error (log it or ignore)
      // print('Error playing sound: $e');
    }
  }

  void _stopAlarm() {
    _alarmTimer?.cancel();
    _audioPlayer.stop();
  }

  @override
  Future<void> close() {
    _timer?.cancel();
    _alarmTimer?.cancel();
    _audioPlayer.dispose();
    return super.close();
  }
}
