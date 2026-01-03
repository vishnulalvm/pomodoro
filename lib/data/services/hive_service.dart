import 'package:hive_flutter/hive_flutter.dart';
import '../models/pomodoro_session.dart';
import '../models/task.dart';
import '../models/app_settings.dart';
import '../models/daily_stats.dart';

class HiveService {
  static final HiveService _instance = HiveService._internal();
  factory HiveService() => _instance;
  HiveService._internal();

  Box<PomodoroSession>? _pomodoroSessionBox;
  Box<Task>? _taskBox;
  Box<AppSettings>? _settingsBox;
  Box<DailyStats>? _statsBox;

  Future<void> init() async {
    await Hive.initFlutter();

    // Register Adapters
    Hive.registerAdapter(PomodoroSessionAdapter());
    Hive.registerAdapter(PomodoroModeAdapter());
    Hive.registerAdapter(TaskAdapter());
    Hive.registerAdapter(AppSettingsAdapter());
    Hive.registerAdapter(DailyStatsAdapter());

    // Open Boxes
    _pomodoroSessionBox = await Hive.openBox<PomodoroSession>(
      'pomodoro_sessions',
    );
    _taskBox = await Hive.openBox<Task>('tasks');
    _settingsBox = await Hive.openBox<AppSettings>('app_settings');
    _statsBox = await Hive.openBox<DailyStats>('daily_stats');

    // Init Default Settings if Empty
    if (_settingsBox!.isEmpty) {
      await _settingsBox!.put('settings', AppSettings());
    }
  }

  Box<PomodoroSession> get pomodoroSessions {
    if (_pomodoroSessionBox == null) {
      throw Exception('HiveService not initialized');
    }
    return _pomodoroSessionBox!;
  }

  Box<Task> get tasks {
    if (_taskBox == null) {
      throw Exception('HiveService not initialized');
    }
    return _taskBox!;
  }

  Box<AppSettings> get settings {
    if (_settingsBox == null) {
      throw Exception('HiveService not initialized');
    }
    return _settingsBox!;
  }

  Box<DailyStats> get dailyStats {
    if (_statsBox == null) {
      throw Exception('HiveService not initialized');
    }
    return _statsBox!;
  }
}
