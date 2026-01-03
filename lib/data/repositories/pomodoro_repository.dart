import '../models/pomodoro_session.dart';
import '../services/hive_service.dart';

class PomodoroRepository {
  final HiveService _hiveService;

  PomodoroRepository(this._hiveService);

  Future<void> saveSession(PomodoroSession session) async {
    final box = _hiveService.pomodoroSessions;
    if (session.id == null) {
      final int id = await box.add(session);
      session.id = id;
      await session.save(); // Update with ID
    } else {
      await box.put(session.id, session);
    }
  }

  Future<List<PomodoroSession>> getAllSessions() async {
    final box = _hiveService.pomodoroSessions;
    return box.values.toList();
  }

  Future<List<PomodoroSession>> getSessionsByDateRange(
    DateTime start,
    DateTime end,
  ) async {
    final box = _hiveService.pomodoroSessions;
    return box.values.where((session) {
      return session.startTime.isAfter(start) &&
          session.startTime.isBefore(end);
    }).toList();
  }

  Future<List<PomodoroSession>> getCompletedSessions() async {
    final box = _hiveService.pomodoroSessions;
    return box.values.where((session) => session.completed).toList();
  }

  Future<List<PomodoroSession>> getSessionsForTask(int taskId) async {
    final box = _hiveService.pomodoroSessions;
    return box.values.where((session) => session.taskId == taskId).toList();
  }

  Future<int> getCompletedPomodorosCount() async {
    final box = _hiveService.pomodoroSessions;
    return box.values
        .where((s) => s.completed && s.mode == PomodoroMode.pomodoro)
        .length;
  }

  Future<void> deleteSession(int id) async {
    final box = _hiveService.pomodoroSessions;
    await box.delete(id);
  }

  Future<void> deleteAllSessions() async {
    final box = _hiveService.pomodoroSessions;
    await box.clear();
  }
}
