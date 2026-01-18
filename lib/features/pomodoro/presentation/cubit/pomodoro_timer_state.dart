import 'package:equatable/equatable.dart';

enum TimerStatus { initial, running, paused, completed }

enum TimerMode { pomodoro, rest, longRest }

class PomodoroTimerState extends Equatable {
  final int duration;
  final int elapsed;
  final TimerStatus status;
  final TimerMode mode;

  final int completedPomodoros;

  // REST MODE fields
  final bool isRestMode;
  final int? restDuration;
  final int restElapsed;

  final bool isAlarmPlaying;

  const PomodoroTimerState({
    required this.duration,
    this.elapsed = 0,
    this.status = TimerStatus.initial,
    this.mode = TimerMode.pomodoro,
    this.completedPomodoros = 0,
    this.isRestMode = false,
    this.restDuration,
    this.restElapsed = 0,
    this.isAlarmPlaying = false,
  });

  PomodoroTimerState copyWith({
    int? duration,
    int? elapsed,
    TimerStatus? status,
    TimerMode? mode,
    int? completedPomodoros,
    bool? isRestMode,
    int? restDuration,
    int? restElapsed,
    bool? isAlarmPlaying,
  }) {
    return PomodoroTimerState(
      duration: duration ?? this.duration,
      elapsed: elapsed ?? this.elapsed,
      status: status ?? this.status,
      mode: mode ?? this.mode,
      completedPomodoros: completedPomodoros ?? this.completedPomodoros,
      isRestMode: isRestMode ?? this.isRestMode,
      restDuration: restDuration ?? this.restDuration,
      restElapsed: restElapsed ?? this.restElapsed,
      isAlarmPlaying: isAlarmPlaying ?? this.isAlarmPlaying,
    );
  }

  @override
  List<Object?> get props => [
    duration,
    elapsed,
    status,
    mode,
    completedPomodoros,
    isRestMode,
    restDuration,
    restElapsed,
    isAlarmPlaying,
  ];
}
