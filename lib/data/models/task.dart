import 'package:hive/hive.dart';

part 'task.g.dart';

@HiveType(typeId: 2)
class Task extends HiveObject {
  @HiveField(0)
  int? id;

  @HiveField(1)
  late String title;

  @HiveField(2)
  late bool isCompleted;

  @HiveField(3)
  late DateTime createdAt;

  @HiveField(4)
  late int pomodoroCount;

  Task({
    this.id,
    required this.title,
    this.isCompleted = false,
    this.pomodoroCount = 0,
  }) {
    createdAt = DateTime.now();
  }
}
