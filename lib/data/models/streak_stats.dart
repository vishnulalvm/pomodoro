class StreakStats {
  final String userId;
  final int currentStreak;
  final int longestStreak;
  final DateTime lastActiveDate;
  final int totalActiveDays;
  final DateTime? streakStartDate;

  StreakStats({
    required this.userId,
    this.currentStreak = 0,
    this.longestStreak = 0,
    required this.lastActiveDate,
    this.totalActiveDays = 0,
    this.streakStartDate,
  });

  // Convert to Map for Firestore
  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'currentStreak': currentStreak,
      'longestStreak': longestStreak,
      'lastActiveDate': lastActiveDate.toIso8601String(),
      'totalActiveDays': totalActiveDays,
      'streakStartDate': streakStartDate?.toIso8601String(),
    };
  }

  // Create from Firestore Map
  factory StreakStats.fromMap(Map<String, dynamic> map) {
    return StreakStats(
      userId: map['userId'] as String,
      currentStreak: map['currentStreak'] as int? ?? 0,
      longestStreak: map['longestStreak'] as int? ?? 0,
      lastActiveDate: DateTime.parse(map['lastActiveDate'] as String),
      totalActiveDays: map['totalActiveDays'] as int? ?? 0,
      streakStartDate: map['streakStartDate'] != null
          ? DateTime.parse(map['streakStartDate'] as String)
          : null,
    );
  }

  // Copy with for updates
  StreakStats copyWith({
    String? userId,
    int? currentStreak,
    int? longestStreak,
    DateTime? lastActiveDate,
    int? totalActiveDays,
    DateTime? streakStartDate,
  }) {
    return StreakStats(
      userId: userId ?? this.userId,
      currentStreak: currentStreak ?? this.currentStreak,
      longestStreak: longestStreak ?? this.longestStreak,
      lastActiveDate: lastActiveDate ?? this.lastActiveDate,
      totalActiveDays: totalActiveDays ?? this.totalActiveDays,
      streakStartDate: streakStartDate ?? this.streakStartDate,
    );
  }
}
