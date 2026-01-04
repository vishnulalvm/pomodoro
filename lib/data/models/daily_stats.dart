import 'package:hive/hive.dart';

part 'daily_stats.g.dart';

@HiveType(typeId: 4)
class DailyStats extends HiveObject {
  @HiveField(0)
  int? id;

  @HiveField(1)
  late DateTime date;

  @HiveField(2)
  late int completedPomodoros;

  @HiveField(3)
  late int focusTimeMinutes;

  DailyStats({
    this.id,
    required this.date,
    this.completedPomodoros = 0,
    this.focusTimeMinutes = 0,
  });

  // Convert to Map for Firestore
  Map<String, dynamic> toMap() {
    return {
      'date': date.toIso8601String(),
      'completedPomodoros': completedPomodoros,
      'focusTimeMinutes': focusTimeMinutes,
    };
  }

  // Create from Firestore Map
  factory DailyStats.fromMap(Map<String, dynamic> map) {
    return DailyStats(
      date: DateTime.parse(map['date'] as String),
      completedPomodoros: map['completedPomodoros'] as int? ?? 0,
      focusTimeMinutes: map['focusTimeMinutes'] as int? ?? 0,
    );
  }
}
