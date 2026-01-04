class UserAnalytics {
  final String userId;
  final int totalPomodoroTime; // Total minutes in pomodoro mode
  final int totalRestTime; // Total minutes in rest mode
  final int totalSessions; // Total number of sessions
  final int totalCompletedTasks;
  final int totalActiveTasks;
  final double averageDailyPomodoros;
  final DateTime lastUpdated;

  UserAnalytics({
    required this.userId,
    this.totalPomodoroTime = 0,
    this.totalRestTime = 0,
    this.totalSessions = 0,
    this.totalCompletedTasks = 0,
    this.totalActiveTasks = 0,
    this.averageDailyPomodoros = 0.0,
    required this.lastUpdated,
  });

  // Convert to Map for Firestore
  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'totalPomodoroTime': totalPomodoroTime,
      'totalRestTime': totalRestTime,
      'totalSessions': totalSessions,
      'totalCompletedTasks': totalCompletedTasks,
      'totalActiveTasks': totalActiveTasks,
      'averageDailyPomodoros': averageDailyPomodoros,
      'lastUpdated': lastUpdated.toIso8601String(),
    };
  }

  // Create from Firestore Map
  factory UserAnalytics.fromMap(Map<String, dynamic> map) {
    return UserAnalytics(
      userId: map['userId'] as String,
      totalPomodoroTime: map['totalPomodoroTime'] as int? ?? 0,
      totalRestTime: map['totalRestTime'] as int? ?? 0,
      totalSessions: map['totalSessions'] as int? ?? 0,
      totalCompletedTasks: map['totalCompletedTasks'] as int? ?? 0,
      totalActiveTasks: map['totalActiveTasks'] as int? ?? 0,
      averageDailyPomodoros: (map['averageDailyPomodoros'] as num?)?.toDouble() ?? 0.0,
      lastUpdated: DateTime.parse(map['lastUpdated'] as String),
    );
  }

  // Copy with for updates
  UserAnalytics copyWith({
    String? userId,
    int? totalPomodoroTime,
    int? totalRestTime,
    int? totalSessions,
    int? totalCompletedTasks,
    int? totalActiveTasks,
    double? averageDailyPomodoros,
    DateTime? lastUpdated,
  }) {
    return UserAnalytics(
      userId: userId ?? this.userId,
      totalPomodoroTime: totalPomodoroTime ?? this.totalPomodoroTime,
      totalRestTime: totalRestTime ?? this.totalRestTime,
      totalSessions: totalSessions ?? this.totalSessions,
      totalCompletedTasks: totalCompletedTasks ?? this.totalCompletedTasks,
      totalActiveTasks: totalActiveTasks ?? this.totalActiveTasks,
      averageDailyPomodoros: averageDailyPomodoros ?? this.averageDailyPomodoros,
      lastUpdated: lastUpdated ?? this.lastUpdated,
    );
  }

  // Helper getters
  String get totalPomodoroTimeFormatted {
    final hours = totalPomodoroTime ~/ 60;
    final minutes = totalPomodoroTime % 60;
    return '${hours}h ${minutes}m';
  }

  String get totalRestTimeFormatted {
    final hours = totalRestTime ~/ 60;
    final minutes = totalRestTime % 60;
    return '${hours}h ${minutes}m';
  }
}
