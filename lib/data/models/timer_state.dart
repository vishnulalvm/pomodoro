class TimerState {
  final String userId;
  final int remainingSeconds;
  final String mode; // 'pomodoro', 'rest', 'longRest'
  final String status; // 'running', 'paused', 'idle'
  final DateTime sessionStartTime;
  final int completedPomodoros;
  final String? currentTaskId;
  final DateTime lastUpdated;

  TimerState({
    required this.userId,
    required this.remainingSeconds,
    required this.mode,
    required this.status,
    required this.sessionStartTime,
    required this.completedPomodoros,
    this.currentTaskId,
    required this.lastUpdated,
  });

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'remainingSeconds': remainingSeconds,
      'mode': mode,
      'status': status,
      'sessionStartTime': sessionStartTime.toIso8601String(),
      'completedPomodoros': completedPomodoros,
      'currentTaskId': currentTaskId,
      'lastUpdated': lastUpdated.toIso8601String(),
    };
  }

  factory TimerState.fromMap(Map<String, dynamic> map) {
    return TimerState(
      userId: map['userId'] ?? '',
      remainingSeconds: map['remainingSeconds'] ?? 0,
      mode: map['mode'] ?? 'pomodoro',
      status: map['status'] ?? 'idle',
      sessionStartTime: DateTime.parse(map['sessionStartTime']),
      completedPomodoros: map['completedPomodoros'] ?? 0,
      currentTaskId: map['currentTaskId'],
      lastUpdated: DateTime.parse(map['lastUpdated']),
    );
  }

  TimerState copyWith({
    String? userId,
    int? remainingSeconds,
    String? mode,
    String? status,
    DateTime? sessionStartTime,
    int? completedPomodoros,
    String? currentTaskId,
    DateTime? lastUpdated,
  }) {
    return TimerState(
      userId: userId ?? this.userId,
      remainingSeconds: remainingSeconds ?? this.remainingSeconds,
      mode: mode ?? this.mode,
      status: status ?? this.status,
      sessionStartTime: sessionStartTime ?? this.sessionStartTime,
      completedPomodoros: completedPomodoros ?? this.completedPomodoros,
      currentTaskId: currentTaskId ?? this.currentTaskId,
      lastUpdated: lastUpdated ?? this.lastUpdated,
    );
  }
}
