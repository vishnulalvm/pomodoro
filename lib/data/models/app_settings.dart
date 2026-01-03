import 'package:hive/hive.dart';

part 'app_settings.g.dart';

@HiveType(typeId: 3)
class AppSettings extends HiveObject {
  @HiveField(0)
  int? id;

  @HiveField(1)
  late int pomodoroDurationMinutes;

  @HiveField(2)
  late int restDurationMinutes;

  @HiveField(3)
  late int longRestDurationMinutes;

  @HiveField(4)
  late bool soundEnabled;

  @HiveField(5)
  late int pomodorosUntilLongRest;

  AppSettings({
    this.id = 1,
    this.pomodoroDurationMinutes = 25,
    this.restDurationMinutes = 5,
    this.longRestDurationMinutes = 15,
    this.soundEnabled = true,
    this.pomodorosUntilLongRest = 4,
  });
}
