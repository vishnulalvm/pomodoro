import '../models/daily_stats.dart';
import '../models/pomodoro_session.dart';
import '../services/hive_service.dart';

class StatsRepository {
  final HiveService _hiveService;

  StatsRepository(this._hiveService);

  Future<DailyStats> getOrCreateDailyStats(DateTime date) async {
    final box = _hiveService.dailyStats;
    final normalizedDate = DateTime(date.year, date.month, date.day);

    try {
      final stats = box.values.firstWhere(
        (s) => isSameDay(s.date, normalizedDate),
      );
      return stats;
    } catch (e) {
      final newStats = DailyStats(date: normalizedDate);
      await box.add(newStats);
      return newStats;
    }
  }

  bool isSameDay(DateTime d1, DateTime d2) {
    return d1.year == d2.year && d1.month == d2.month && d1.day == d2.day;
  }

  Future<void> updateDailyStats(DateTime date) async {
    final sessionBox = _hiveService.pomodoroSessions;
    final normalizedDate = DateTime(date.year, date.month, date.day);
    final startOfDay = normalizedDate;
    final endOfDay = DateTime(date.year, date.month, date.day, 23, 59, 59);

    final sessions = sessionBox.values
        .where(
          (s) =>
              s.startTime.isAfter(startOfDay) &&
              s.startTime.isBefore(endOfDay) &&
              s.completed,
        )
        .toList();

    final completedPomodoros = sessions
        .where((s) => s.mode == PomodoroMode.pomodoro)
        .length;

    final focusTimeMinutes = sessions
        .where((s) => s.mode == PomodoroMode.pomodoro)
        .fold<int>(0, (sum, session) => sum + session.durationMinutes);

    final stats = await getOrCreateDailyStats(date);
    stats.completedPomodoros = completedPomodoros;
    stats.focusTimeMinutes = focusTimeMinutes;
    await stats.save();
  }

  Future<List<DailyStats>> getStatsForDateRange(
    DateTime start,
    DateTime end,
  ) async {
    final box = _hiveService.dailyStats;
    final normalizedStart = DateTime(start.year, start.month, start.day);
    final normalizedEnd = DateTime(end.year, end.month, end.day, 23, 59, 59);

    final stats = box.values
        .where(
          (s) =>
              (s.date.isAfter(normalizedStart) ||
                  isSameDay(s.date, normalizedStart)) &&
              (s.date.isBefore(normalizedEnd) ||
                  isSameDay(s.date, normalizedEnd)),
        )
        .toList();

    stats.sort((a, b) => a.date.compareTo(b.date));
    return stats;
  }

  Future<List<DailyStats>> getLastNDaysStats(int days) async {
    final end = DateTime.now();
    final start = end.subtract(Duration(days: days - 1));
    return await getStatsForDateRange(start, end);
  }

  Future<Map<String, int>> getTotalStats() async {
    final box = _hiveService.dailyStats;
    final allStats = box.values.toList();

    final totalPomodoros = allStats.fold<int>(
      0,
      (sum, stat) => sum + stat.completedPomodoros,
    );

    final totalFocusTime = allStats.fold<int>(
      0,
      (sum, stat) => sum + stat.focusTimeMinutes,
    );

    return {
      'totalPomodoros': totalPomodoros,
      'totalFocusTimeMinutes': totalFocusTime,
    };
  }

  Future<void> deleteAllStats() async {
    final box = _hiveService.dailyStats;
    await box.clear();
  }
}
