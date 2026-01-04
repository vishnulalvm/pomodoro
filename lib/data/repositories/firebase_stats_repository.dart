import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/daily_stats.dart';
import '../models/streak_stats.dart';
import '../models/user_analytics.dart';

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
}
