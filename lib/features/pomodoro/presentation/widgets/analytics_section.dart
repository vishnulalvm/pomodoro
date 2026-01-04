import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../analytics/presentation/cubit/stats_cubit.dart';

class AnalyticsSection extends StatefulWidget {
  const AnalyticsSection({super.key});

  @override
  State<AnalyticsSection> createState() => _AnalyticsSectionState();
}

class _AnalyticsSectionState extends State<AnalyticsSection> {
  @override
  void initState() {
    super.initState();
    context.read<StatsCubit>().loadStats(days: 7);
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
          constraints: const BoxConstraints(
            maxWidth: 800,
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Performance',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.w900,
                  color: Colors.white.withValues(alpha: 0.9),
                ),
              ),
              const SizedBox(height: 20),

              Expanded(
                child: BlocBuilder<StatsCubit, StatsState>(
                  builder: (context, state) {
                    if (state is StatsLoading) {
                      return const Center(
                        child: CircularProgressIndicator(
                          color: Colors.white,
                        ),
                      );
                    }

                    if (state is StatsError) {
                      return Center(
                        child: Text(
                          'Error: ${state.message}',
                          style: const TextStyle(color: Colors.red),
                        ),
                      );
                    }

                    if (state is StatsLoaded) {
                      final totalPomodoros = state.totalPomodoros;
                      final totalFocusHours = (state.totalFocusTimeMinutes / 60).toStringAsFixed(1);
                      final avgDaily = state.dailyStats.isNotEmpty
                          ? (state.totalFocusTimeMinutes / state.dailyStats.length / 60).toStringAsFixed(1)
                          : '0.0';

                      // Get Firebase analytics data
                      final analytics = state.userAnalytics;
                      final streak = state.streakStats;
                      final currentStreak = streak?.currentStreak ?? 0;
                      final longestStreak = streak?.longestStreak ?? 0;
                      final totalPomodoroTime = analytics?.totalPomodoroTimeFormatted ?? '0h 0m';
                      final totalRestTime = analytics?.totalRestTimeFormatted ?? '0h 0m';

                      // Prepare chart data
                      final last7Days = state.dailyStats.length > 7
                          ? state.dailyStats.sublist(state.dailyStats.length - 7)
                          : state.dailyStats;

                      return Row(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // LEFT: Stat Cards
                          Expanded(
                            flex: 4,
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                if (currentStreak > 0)
                                  _buildStatCard(
                                    context,
                                    '🔥 Current Streak',
                                    '$currentStreak days',
                                    Colors.deepOrange,
                                  ),
                                if (currentStreak > 0) const SizedBox(height: 16),
                                _buildStatCard(
                                  context,
                                  'Total Pomodoros',
                                  '$totalPomodoros',
                                  Colors.amber,
                                ),
                                const SizedBox(height: 16),
                                _buildStatCard(
                                  context,
                                  'Total Focus Time',
                                  analytics != null ? totalPomodoroTime : '${totalFocusHours}h',
                                  Colors.cyan,
                                ),
                                const SizedBox(height: 16),
                                if (analytics != null)
                                  _buildStatCard(
                                    context,
                                    'Total Rest Time',
                                    totalRestTime,
                                    Colors.greenAccent,
                                  ),
                                if (analytics == null)
                                  _buildStatCard(
                                    context,
                                    'Avg Daily',
                                    '${avgDaily}h',
                                    Colors.greenAccent,
                                  ),
                                if (longestStreak > 0) const SizedBox(height: 16),
                                if (longestStreak > 0)
                                  _buildStatCard(
                                    context,
                                    '⭐ Best Streak',
                                    '$longestStreak days',
                                    Colors.purpleAccent,
                                  ),
                              ],
                            ),
                          ),

                          const SizedBox(width: 24),

                          // RIGHT: Charts
                          Expanded(
                            flex: 6,
                            child: Column(
                              children: [
                                // Top Chart: Pie (Distribution)
                                Expanded(
                                  flex: 4,
                                  child: _buildChartContainer(
                                    context,
                                    "This Week",
                                    totalPomodoros > 0
                                        ? PieChart(
                                            PieChartData(
                                              sectionsSpace: 2,
                                              centerSpaceRadius: 20,
                                              sections: [
                                                PieChartSectionData(
                                                  color: Colors.amber,
                                                  value: totalPomodoros.toDouble(),
                                                  radius: 25,
                                                  showTitle: false,
                                                ),
                                                PieChartSectionData(
                                                  color: Colors.cyan.withValues(alpha: 0.3),
                                                  value: (7 * 8) - totalPomodoros.toDouble(),
                                                  radius: 25,
                                                  showTitle: false,
                                                ),
                                              ],
                                            ),
                                          )
                                        : Center(
                                            child: Text(
                                              'No data yet',
                                              style: TextStyle(
                                                color: Colors.white.withValues(alpha: 0.5),
                                              ),
                                            ),
                                          ),
                                  ),
                                ),
                                const SizedBox(height: 16),

                                // Bottom Chart: Bar (Last 7 Days)
                                Expanded(
                                  flex: 5,
                                  child: _buildChartContainer(
                                    context,
                                    "Last 7 Days",
                                    last7Days.isNotEmpty
                                        ? BarChart(
                                            BarChartData(
                                              gridData: const FlGridData(show: false),
                                              borderData: FlBorderData(show: false),
                                              titlesData: const FlTitlesData(
                                                topTitles: AxisTitles(
                                                  sideTitles: SideTitles(showTitles: false),
                                                ),
                                                rightTitles: AxisTitles(
                                                  sideTitles: SideTitles(showTitles: false),
                                                ),
                                                leftTitles: AxisTitles(
                                                  sideTitles: SideTitles(showTitles: false),
                                                ),
                                                bottomTitles: AxisTitles(
                                                  sideTitles: SideTitles(showTitles: false),
                                                ),
                                              ),
                                              barGroups: last7Days
                                                  .asMap()
                                                  .entries
                                                  .map(
                                                    (entry) => _barGroup(
                                                      entry.key,
                                                      entry.value.completedPomodoros.toDouble(),
                                                      Colors.amber,
                                                    ),
                                                  )
                                                  .toList(),
                                            ),
                                          )
                                        : Center(
                                            child: Text(
                                              'No data yet',
                                              style: TextStyle(
                                                color: Colors.white.withValues(alpha: 0.5),
                                              ),
                                            ),
                                          ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      );
                    }

                    return const SizedBox();
                  },
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  BarChartGroupData _barGroup(int x, double y, Color color) {
    return BarChartGroupData(
      x: x,
      barRods: [
        BarChartRodData(
          toY: y == 0 ? 0.5 : y,
          color: color,
          width: 12,
          borderRadius: BorderRadius.circular(2),
        ),
      ],
    );
  }

  Widget _buildChartContainer(
    BuildContext context,
    String title,
    Widget chart,
  ) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
      ),
      child: Column(
        children: [
          Text(
            title,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.8),
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Expanded(child: chart),
        ],
      ),
    );
  }

  Widget _buildStatCard(
    BuildContext context,
    String title,
    String value,
    Color accentColor,
  ) {
    return Expanded(
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              title,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.6),
                fontSize: 12,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: accentColor,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}
