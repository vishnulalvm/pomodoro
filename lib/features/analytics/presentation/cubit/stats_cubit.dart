import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../../../data/models/daily_stats.dart';
import '../../../../data/models/streak_stats.dart';
import '../../../../data/models/user_analytics.dart';
import '../../../../data/repositories/stats_repository.dart';
import '../../../../data/repositories/firebase_stats_repository.dart';
import '../../../../core/services/local_storage_service.dart';

part 'stats_state.dart';

class StatsCubit extends Cubit<StatsState> {
  final StatsRepository _statsRepository;
  final FirebaseStatsRepository _firebaseStatsRepository;
  final LocalStorageService _localStorageService;

  StatsCubit(
    this._statsRepository,
    this._firebaseStatsRepository,
    this._localStorageService,
  ) : super(StatsInitial());

  Future<void> loadStats({int days = 7}) async {
    try {
      emit(StatsLoading());

      // Get user email
      final userId = await _localStorageService.getEmail();

      if (userId == null) {
        // No user logged in, load from local Hive only
        final dailyStats = await _statsRepository.getLastNDaysStats(days);
        final totalStats = await _statsRepository.getTotalStats();

        emit(StatsLoaded(
          dailyStats: dailyStats,
          totalPomodoros: totalStats['totalPomodoros'] ?? 0,
          totalFocusTimeMinutes: totalStats['totalFocusTimeMinutes'] ?? 0,
        ));
        return;
      }

      // Load from Firebase
      final dailyStats = await _firebaseStatsRepository.getLastNDaysStats(userId, days);
      final analytics = await _firebaseStatsRepository.getUserAnalytics(userId);
      final streakStats = await _firebaseStatsRepository.getStreakStats(userId);

      // Calculate total pomodoros from daily stats
      final totalPomodoros = dailyStats.fold<int>(
        0,
        (sum, stat) => sum + stat.completedPomodoros,
      );

      // Calculate total focus time from daily stats
      final totalFocusTimeMinutes = dailyStats.fold<int>(
        0,
        (sum, stat) => sum + stat.focusTimeMinutes,
      );

      emit(StatsLoaded(
        dailyStats: dailyStats,
        totalPomodoros: totalPomodoros,
        totalFocusTimeMinutes: totalFocusTimeMinutes,
        userAnalytics: analytics,
        streakStats: streakStats,
      ));
    } catch (e) {
      print('Error loading stats: $e');
      // Fallback to local data
      try {
        final dailyStats = await _statsRepository.getLastNDaysStats(days);
        final totalStats = await _statsRepository.getTotalStats();

        emit(StatsLoaded(
          dailyStats: dailyStats,
          totalPomodoros: totalStats['totalPomodoros'] ?? 0,
          totalFocusTimeMinutes: totalStats['totalFocusTimeMinutes'] ?? 0,
        ));
      } catch (localError) {
        emit(StatsError(localError.toString()));
      }
    }
  }

  Future<void> refreshStats({int days = 7}) async {
    await loadStats(days: days);
  }
}
