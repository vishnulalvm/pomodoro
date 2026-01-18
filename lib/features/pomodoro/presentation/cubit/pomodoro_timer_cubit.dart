import 'dart:async';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/services/notification_service.dart';
import '../../../../core/services/local_storage_service.dart';
import '../../../../data/models/pomodoro_session.dart';
import '../../../../data/models/daily_stats.dart';
import '../../../../data/models/timer_state.dart' as model;
import '../../../../data/repositories/pomodoro_repository.dart';
import '../../../../data/repositories/stats_repository.dart';
import '../../../../data/repositories/firebase_stats_repository.dart';
import 'pomodoro_timer_state.dart';

class PomodoroTimerCubit extends Cubit<PomodoroTimerState> {
  Timer? _timer;
  Timer? _alarmTimer;
  final AudioPlayer _audioPlayer = AudioPlayer();
  final PomodoroRepository _pomodoroRepository;
  final StatsRepository _statsRepository;
  final FirebaseStatsRepository _firebaseStatsRepository;
  final LocalStorageService _localStorageService;

  static const int _pomodoroDuration = 25 * 60;
  static const int _restDuration = 5 * 60;
  static const int _longRestDuration = 15 * 60;

  DateTime? _sessionStartTime;
  int? _currentTaskId;
  String? _currentSessionId; // For tracking partial sessions

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
    this._firebaseStatsRepository,
    this._localStorageService,
  ) : super(const PomodoroTimerState(duration: _pomodoroDuration));

  void setCurrentTask(int? taskId) {
    _currentTaskId = taskId;
  }

  DateTime? _timerStartTime;
  int _elapsedBeforeSuspending = 0;

  void startTimer() {
    if (state.status == TimerStatus.running) return;

    // Stop alarm sound if it's playing
    _stopAlarm();

    _timerStartTime = DateTime.now();

    if (state.isRestMode) {
      _sessionStartTime = DateTime.now(); // Track start of rest session
      _elapsedBeforeSuspending = state.restElapsed;
      if (state.restDuration == null) return; // No duration selected

      emit(state.copyWith(status: TimerStatus.running));

      _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
        final now = DateTime.now();
        final secondsPassed = now.difference(_timerStartTime!).inSeconds;
        final newElapsed = _elapsedBeforeSuspending + secondsPassed;

        if (newElapsed < state.restDuration!) {
          emit(state.copyWith(restElapsed: newElapsed));
        } else {
          _completeTimer();
        }
      });
    } else {
      // Pomodoro timer
      _sessionStartTime = DateTime.now();
      _currentSessionId = '${DateTime.now().millisecondsSinceEpoch}';
      _elapsedBeforeSuspending = state.elapsed;

      final newStatus = TimerStatus.running;
      _modeStatuses[state.mode] = newStatus;
      emit(state.copyWith(status: newStatus));

      // Sync timer state to Firebase when starting
      _syncTimerStateToFirebase();

      _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
        final now = DateTime.now();
        final secondsPassed = now.difference(_timerStartTime!).inSeconds;
        final newElapsed = _elapsedBeforeSuspending + secondsPassed;

        if (newElapsed < state.duration) {
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

      // Update one last time to ensure precision before pausing
      if (_timerStartTime != null) {
        final now = DateTime.now();
        final secondsPassed = now.difference(_timerStartTime!).inSeconds;
        final finalElapsed = _elapsedBeforeSuspending + secondsPassed;

        if (state.isRestMode) {
          emit(state.copyWith(status: newStatus, restElapsed: finalElapsed));
        } else {
          _modeElapsedTimes[state.mode] = finalElapsed;
          emit(state.copyWith(status: newStatus, elapsed: finalElapsed));
        }
      } else {
        emit(state.copyWith(status: newStatus));
      }

      _timerStartTime = null;

      // Sync timer state and save partial session to Firebase when pausing
      _syncTimerStateToFirebase();
      _savePartialSession();
    }
  }

  void stopTimer() {
    _timer?.cancel();
    _timerStartTime = null;
    _elapsedBeforeSuspending = 0;
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

    emit(
      state.copyWith(
        mode: mode,
        duration: newDuration,
        elapsed: savedElapsed,
        status: savedStatus,
      ),
    );

    // If we were running before switching, continue running in the new mode
    if (wasRunning) {
      _sessionStartTime = DateTime.now();

      // Setup for new timer
      _timerStartTime = DateTime.now();
      _elapsedBeforeSuspending = savedElapsed;

      final runningStatus = TimerStatus.running;
      _modeStatuses[mode] = runningStatus;
      emit(state.copyWith(status: runningStatus));

      _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
        final now = DateTime.now();
        final secondsPassed = now.difference(_timerStartTime!).inSeconds;
        final newElapsed = _elapsedBeforeSuspending + secondsPassed;

        if (newElapsed < state.duration) {
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
    _timerStartTime = null;
    _elapsedBeforeSuspending = 0;

    if (state.isRestMode) {
      // Reset rest mode timer
      emit(state.copyWith(status: TimerStatus.initial, restElapsed: 0));
    } else {
      // Reset pomodoro timer
      _modeElapsedTimes[state.mode] = 0;
      _modeStatuses[state.mode] = TimerStatus.initial;
      emit(state.copyWith(status: TimerStatus.initial, elapsed: 0));
    }
    _sessionStartTime = null;
    _currentSessionId = null;

    // Clear Firebase timer state when resetting
    _clearFirebaseTimerState();
  }

  void toggleRestMode() {
    _timer?.cancel();
    _stopAlarm();
    _timerStartTime = null;
    _elapsedBeforeSuspending = 0;
    _sessionStartTime = null; // Prevent leaking session data
    _currentSessionId = null;

    if (state.isRestMode) {
      // Toggle OFF: Return to Pomodoro mode, reset rest timer
      emit(
        state.copyWith(
          isRestMode: false,
          status: _modeStatuses[state.mode] ?? TimerStatus.initial,
          elapsed: _modeElapsedTimes[state.mode] ?? 0,
          restDuration: null,
          restElapsed: 0,
        ),
      );
    } else {
      // Toggle ON: Enter REST MODE
      emit(
        state.copyWith(
          isRestMode: true,
          status: TimerStatus.initial,
          restDuration: null,
          restElapsed: 0,
        ),
      );
    }
  }

  void setRestDuration(int minutes) {
    if (state.isRestMode) {
      emit(
        state.copyWith(
          restDuration: minutes * 60,
          restElapsed: 0,
          status: TimerStatus.initial,
        ),
      );
    }
  }

  Future<void> _completeTimer() async {
    _timer?.cancel();
    _timerStartTime = null;
    _elapsedBeforeSuspending = 0;

    if (state.isRestMode) {
      // REST MODE completion
      await _playSound();
      await NotificationService().showNotification(
        id: 0,
        title: 'Rest time is up!',
        body: 'Your rest period has ended.',
      );

      // Track rest time
      if (_sessionStartTime != null) {
        final restMinutes = (state.restDuration ?? 0) ~/ 60;

        // Update Firebase analytics with rest time
        final userId = await _localStorageService.getEmail();
        if (userId != null) {
          try {
            await _firebaseStatsRepository.updateAnalyticsAfterSession(
              userId: userId,
              pomodoroMinutes: 0, // No pomodoro time
              restMinutes: restMinutes, // Rest time
            );
          } catch (e) {
            print('Error updating Firebase analytics for rest: $e');
          }
        }
      }

      emit(state.copyWith(status: TimerStatus.completed));
      // Stay in rest mode, don't auto-switch
      return;
    }

    // Pomodoro timer completion
    // Save session to database
    if (_sessionStartTime != null) {
      final pomodoroMinutes = state.duration ~/ 60;
      final session = PomodoroSession(
        startTime: _sessionStartTime!,
        endTime: DateTime.now(),
        durationMinutes: pomodoroMinutes,
        mode: _mapTimerModeToPomodoroMode(state.mode),
        completed: true,
        taskId: _currentTaskId,
      );
      await _pomodoroRepository.saveSession(session);

      // Update local daily stats
      await _statsRepository.updateDailyStats(DateTime.now());

      // Sync to Firebase
      final userId = await _localStorageService.getEmail();
      if (userId != null) {
        try {
          // Save daily stats to Firebase
          final today = DateTime.now();

          // Get current daily stats from local Hive
          final localStats = await _statsRepository.getOrCreateDailyStats(
            today,
          );
          final dailyStat = DailyStats(
            date: today,
            completedPomodoros: localStats.completedPomodoros,
            focusTimeMinutes: localStats.focusTimeMinutes,
          );
          await _firebaseStatsRepository.saveDailyStat(userId, dailyStat);

          // Update user analytics
          await _firebaseStatsRepository.updateAnalyticsAfterSession(
            userId: userId,
            pomodoroMinutes: pomodoroMinutes,
            restMinutes: 0, // No rest time in pomodoro mode
          );

          // Mark partial session as completed
          if (_currentSessionId != null) {
            await _firebaseStatsRepository.completePartialSession(
              userId,
              _currentSessionId!,
            );
          }

          // Clear Firebase timer state since session is complete
          await _clearFirebaseTimerState();
        } catch (e) {
          print('Error syncing to Firebase: $e');
        }
      }
    }

    // Reset session ID
    _currentSessionId = null;

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
      emit(state.copyWith(isAlarmPlaying: true)); // Update UI

      // Ensure volume is max
      await _audioPlayer.setVolume(1.0);
      await _audioPlayer.play(AssetSource('sounds/pomo_alrm.mp3'));

      // Stop the alarm after 10 seconds
      _alarmTimer?.cancel();
      _alarmTimer = Timer(const Duration(seconds: 10), () {
        _stopAlarm();
      });
    } catch (e) {
      // Handle audio error (log it or ignore)
      print('Error playing sound: $e');
      // If error, reset state so button doesn't get stuck
      emit(state.copyWith(isAlarmPlaying: false));
    }
  }

  void _stopAlarm() {
    _alarmTimer?.cancel();
    _audioPlayer.stop();
    emit(state.copyWith(isAlarmPlaying: false)); // Update UI
  }

  // ==================== FIREBASE SYNC HELPERS ====================

  /// Sync current timer state to Firebase for cross-device sync
  Future<void> _syncTimerStateToFirebase() async {
    try {
      final userId = await _localStorageService.getEmail();
      if (userId == null) return;

      final timerState = model.TimerState(
        userId: userId,
        remainingSeconds: state.duration - state.elapsed,
        mode: _mapTimerModeToString(state.mode),
        status: _mapTimerStatusToString(state.status),
        sessionStartTime: _sessionStartTime ?? DateTime.now(),
        completedPomodoros: state.completedPomodoros,
        currentTaskId: _currentTaskId?.toString(),
        lastUpdated: DateTime.now(),
      );

      await _firebaseStatsRepository.saveTimerState(timerState);
    } catch (e) {
      print('Error syncing timer state to Firebase: $e');
    }
  }

  /// Save partial session data when pausing
  Future<void> _savePartialSession() async {
    try {
      final userId = await _localStorageService.getEmail();
      if (userId == null || _sessionStartTime == null) return;

      // Generate session ID if not exists
      _currentSessionId ??= '${DateTime.now().millisecondsSinceEpoch}';

      final elapsedMinutes = state.elapsed ~/ 60;

      await _firebaseStatsRepository.savePartialSession(
        userId: userId,
        sessionId: _currentSessionId!,
        startTime: _sessionStartTime!,
        accumulatedMinutes: elapsedMinutes,
        mode: _mapTimerModeToString(state.mode),
        taskId: _currentTaskId?.toString(),
        isCompleted: false,
      );
    } catch (e) {
      print('Error saving partial session: $e');
    }
  }

  /// Clear Firebase timer state (on completion or reset)
  Future<void> _clearFirebaseTimerState() async {
    try {
      final userId = await _localStorageService.getEmail();
      if (userId == null) return;

      await _firebaseStatsRepository.deleteTimerState(userId);
    } catch (e) {
      print('Error clearing Firebase timer state: $e');
    }
  }

  String _mapTimerModeToString(TimerMode mode) {
    switch (mode) {
      case TimerMode.pomodoro:
        return 'pomodoro';
      case TimerMode.rest:
        return 'rest';
      case TimerMode.longRest:
        return 'longRest';
    }
  }

  String _mapTimerStatusToString(TimerStatus status) {
    switch (status) {
      case TimerStatus.initial:
        return 'idle';
      case TimerStatus.running:
        return 'running';
      case TimerStatus.paused:
        return 'paused';
      case TimerStatus.completed:
        return 'completed';
    }
  }

  @override
  Future<void> close() {
    _timer?.cancel();
    _alarmTimer?.cancel();
    _audioPlayer.dispose();
    return super.close();
  }
}
