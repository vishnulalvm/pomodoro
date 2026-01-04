part of 'stats_cubit.dart';

abstract class StatsState extends Equatable {
  const StatsState();

  @override
  List<Object?> get props => [];
}

class StatsInitial extends StatsState {}

class StatsLoading extends StatsState {}

class StatsLoaded extends StatsState {
  final List<DailyStats> dailyStats;
  final int totalPomodoros;
  final int totalFocusTimeMinutes;
  final UserAnalytics? userAnalytics;
  final StreakStats? streakStats;

  const StatsLoaded({
    required this.dailyStats,
    required this.totalPomodoros,
    required this.totalFocusTimeMinutes,
    this.userAnalytics,
    this.streakStats,
  });

  @override
  List<Object?> get props => [
        dailyStats,
        totalPomodoros,
        totalFocusTimeMinutes,
        userAnalytics,
        streakStats,
      ];
}

class StatsError extends StatsState {
  final String message;

  const StatsError(this.message);

  @override
  List<Object> get props => [message];
}
