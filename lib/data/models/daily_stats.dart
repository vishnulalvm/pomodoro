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
}
