import 'package:hive/hive.dart';

part 'pomodoro_session.g.dart';

@HiveType(typeId: 0)
class PomodoroSession extends HiveObject {
  @HiveField(0)
  int? id; // Hive key

  @HiveField(1)
  late DateTime startTime;

  @HiveField(2)
  DateTime? endTime;

  @HiveField(3)
  late int durationMinutes;

  @HiveField(4)
  late PomodoroMode mode;

  @HiveField(5)
  late bool completed;

  @HiveField(6)
  int? taskId;

  PomodoroSession({
    this.id,
    required this.startTime,
    this.endTime,
    required this.durationMinutes,
    required this.mode,
    this.completed = false,
    this.taskId,
  });
}

@HiveType(typeId: 1)
enum PomodoroMode {
  @HiveField(0)
  pomodoro,
  @HiveField(1)
  rest,
  @HiveField(2)
  longRest,
}
