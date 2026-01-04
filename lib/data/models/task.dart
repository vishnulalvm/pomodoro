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

  @HiveField(5)
  String? firebaseId;

  Task({
    this.id,
    required this.title,
    this.isCompleted = false,
    this.pomodoroCount = 0,
    this.firebaseId,
  }) {
    createdAt = DateTime.now();
  }

  // Convert to Map for Firestore
  Map<String, dynamic> toMap({String? userId}) {
    return {
      if (userId != null) 'userId': userId,
      'title': title,
      'isCompleted': isCompleted,
      'createdAt': createdAt.toIso8601String(),
      'pomodoroCount': pomodoroCount,
      'completedAt': isCompleted ? DateTime.now().toIso8601String() : null,
    };
  }

  // Create from Firestore Map
  factory Task.fromMap(Map<String, dynamic> map, {int? localId, String? firebaseId}) {
    return Task(
      id: localId,
      title: map['title'] as String,
      isCompleted: map['isCompleted'] as bool? ?? false,
      pomodoroCount: map['pomodoroCount'] as int? ?? 0,
      firebaseId: firebaseId,
    )..createdAt = DateTime.parse(map['createdAt'] as String);
  }
}
