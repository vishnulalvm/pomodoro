import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../../../data/models/daily_stats.dart';
import '../../../../data/repositories/stats_repository.dart';

part 'stats_state.dart';

class StatsCubit extends Cubit<StatsState> {
  final StatsRepository _statsRepository;

  StatsCubit(this._statsRepository) : super(StatsInitial());

  Future<void> loadStats({int days = 7}) async {
    try {
      emit(StatsLoading());

      final dailyStats = await _statsRepository.getLastNDaysStats(days);
      final totalStats = await _statsRepository.getTotalStats();

      emit(StatsLoaded(
        dailyStats: dailyStats,
        totalPomodoros: totalStats['totalPomodoros'] ?? 0,
        totalFocusTimeMinutes: totalStats['totalFocusTimeMinutes'] ?? 0,
      ));
    } catch (e) {
      emit(StatsError(e.toString()));
    }
  }

  Future<void> refreshStats({int days = 7}) async {
    await loadStats(days: days);
  }
}
