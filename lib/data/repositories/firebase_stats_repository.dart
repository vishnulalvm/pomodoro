import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/daily_stats.dart';
import '../models/streak_stats.dart';
import '../models/user_analytics.dart';
import '../models/timer_state.dart';

class FirebaseStatsRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Get user's analytics
  Future<UserAnalytics?> getUserAnalytics(String userId) async {
    try {
      final doc = await _firestore
          .collection('users')
          .doc(userId)
          .collection('analytics')
          .doc('summary')
          .get();

      if (doc.exists && doc.data() != null) {
        return UserAnalytics.fromMap(doc.data()!);
      }
      return null;
    } catch (e) {
      print('Error getting user analytics: $e');
      rethrow;
    }
  }

  // Save user analytics
  Future<void> saveUserAnalytics(UserAnalytics analytics) async {
    try {
      await _firestore
          .collection('users')
          .doc(analytics.userId)
          .collection('analytics')
          .doc('summary')
          .set(analytics.toMap());
    } catch (e) {
      print('Error saving user analytics: $e');
      rethrow;
    }
  }

  // Get streak stats
  Future<StreakStats?> getStreakStats(String userId) async {
    try {
      final doc = await _firestore
          .collection('users')
          .doc(userId)
          .collection('streak_stats')
          .doc('current')
          .get();

      if (doc.exists && doc.data() != null) {
        return StreakStats.fromMap(doc.data()!);
      }
      return null;
    } catch (e) {
      print('Error getting streak stats: $e');
      rethrow;
    }
  }

  // Save streak stats
  Future<void> saveStreakStats(StreakStats stats) async {
    try {
      await _firestore
          .collection('users')
          .doc(stats.userId)
          .collection('streak_stats')
          .doc('current')
          .set(stats.toMap());
    } catch (e) {
      print('Error saving streak stats: $e');
      rethrow;
    }
  }

  // Get daily stats for a date range
  Future<List<DailyStats>> getDailyStats(
    String userId, {
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    try {
      final snapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('daily_stats')
          .where('date', isGreaterThanOrEqualTo: startDate.toIso8601String())
          .where('date', isLessThanOrEqualTo: endDate.toIso8601String())
          .orderBy('date')
          .get();

      return snapshot.docs
          .map((doc) => DailyStats.fromMap(doc.data()))
          .toList();
    } catch (e) {
      print('Error getting daily stats: $e');
      rethrow;
    }
  }

  // Get last N days stats
  Future<List<DailyStats>> getLastNDaysStats(String userId, int days) async {
    final endDate = DateTime.now();
    final startDate = endDate.subtract(Duration(days: days));

    return getDailyStats(
      userId,
      startDate: startDate,
      endDate: endDate,
    );
  }

  // Save daily stat
  Future<void> saveDailyStat(String userId, DailyStats stat) async {
    try {
      final dateKey = '${stat.date.year}-${stat.date.month.toString().padLeft(2, '0')}-${stat.date.day.toString().padLeft(2, '0')}';

      await _firestore
          .collection('users')
          .doc(userId)
          .collection('daily_stats')
          .doc(dateKey)
          .set(stat.toMap());
    } catch (e) {
      print('Error saving daily stat: $e');
      rethrow;
    }
  }

  // Update analytics after session completion
  Future<void> updateAnalyticsAfterSession({
    required String userId,
    required int pomodoroMinutes,
    required int restMinutes,
  }) async {
    try {
      final analytics = await getUserAnalytics(userId);

      final updatedAnalytics = (analytics ?? UserAnalytics(
        userId: userId,
        lastUpdated: DateTime.now(),
      )).copyWith(
        totalPomodoroTime: (analytics?.totalPomodoroTime ?? 0) + pomodoroMinutes,
        totalRestTime: (analytics?.totalRestTime ?? 0) + restMinutes,
        totalSessions: (analytics?.totalSessions ?? 0) + 1,
        lastUpdated: DateTime.now(),
      );

      await saveUserAnalytics(updatedAnalytics);
    } catch (e) {
      print('Error updating analytics: $e');
      rethrow;
    }
  }

  // ==================== TIMER STATE SYNC METHODS ====================

  /// Save current timer state to Firebase for cross-device sync
  Future<void> saveTimerState(TimerState timerState) async {
    try {
      await _firestore
          .collection('users')
          .doc(timerState.userId)
          .collection('timer_state')
          .doc('current')
          .set(timerState.toMap());
    } catch (e) {
      print('Error saving timer state: $e');
      rethrow;
    }
  }

  /// Get current timer state from Firebase
  Future<TimerState?> getTimerState(String userId) async {
    try {
      final doc = await _firestore
          .collection('users')
          .doc(userId)
          .collection('timer_state')
          .doc('current')
          .get();

      if (doc.exists && doc.data() != null) {
        return TimerState.fromMap(doc.data()!);
      }
      return null;
    } catch (e) {
      print('Error getting timer state: $e');
      return null;
    }
  }

  /// Stream timer state changes for real-time cross-device sync
  Stream<TimerState?> streamTimerState(String userId) {
    return _firestore
        .collection('users')
        .doc(userId)
        .collection('timer_state')
        .doc('current')
        .snapshots()
        .map((snapshot) {
      if (snapshot.exists && snapshot.data() != null) {
        return TimerState.fromMap(snapshot.data()!);
      }
      return null;
    });
  }

  /// Delete timer state (called when session completes or resets)
  Future<void> deleteTimerState(String userId) async {
    try {
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('timer_state')
          .doc('current')
          .delete();
    } catch (e) {
      print('Error deleting timer state: $e');
      rethrow;
    }
  }

  // ==================== PARTIAL SESSION TRACKING ====================

  /// Save partial session data (for incomplete/paused sessions)
  Future<void> savePartialSession({
    required String userId,
    required String sessionId,
    required DateTime startTime,
    required int accumulatedMinutes,
    required String mode,
    String? taskId,
    bool isCompleted = false,
  }) async {
    try {
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('partial_sessions')
          .doc(sessionId)
          .set({
        'startTime': startTime.toIso8601String(),
        'accumulatedMinutes': accumulatedMinutes,
        'mode': mode,
        'taskId': taskId,
        'isCompleted': isCompleted,
        'lastUpdated': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      print('Error saving partial session: $e');
      rethrow;
    }
  }

  /// Mark partial session as completed
  Future<void> completePartialSession(String userId, String sessionId) async {
    try {
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('partial_sessions')
          .doc(sessionId)
          .update({
        'isCompleted': true,
        'completedAt': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      print('Error completing partial session: $e');
      rethrow;
    }
  }

  /// Get all partial sessions for a user (for analytics/history)
  Future<List<Map<String, dynamic>>> getPartialSessions(
      String userId, {DateTime? since}) async {
    try {
      Query query = _firestore
          .collection('users')
          .doc(userId)
          .collection('partial_sessions');

      if (since != null) {
        query = query.where('startTime',
            isGreaterThanOrEqualTo: since.toIso8601String());
      }

      final snapshot = await query.get();
      return snapshot.docs.map((doc) => doc.data() as Map<String, dynamic>).toList();
    } catch (e) {
      print('Error getting partial sessions: $e');
      return [];
    }
  }
}
