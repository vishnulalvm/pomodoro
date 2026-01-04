import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../analytics/presentation/cubit/stats_cubit.dart';
import '../../../tasks/presentation/cubit/task_cubit.dart';

class AnalyticsSection extends StatefulWidget {
  const AnalyticsSection({super.key});

  @override
  State<AnalyticsSection> createState() => _AnalyticsSectionState();
}

class _AnalyticsSectionState extends State<AnalyticsSection> {
  final Map<String, bool> _statCardHovered = {};

  @override
  void initState() {
    super.initState();
    context.read<StatsCubit>().loadStats(days: 7);
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 30),
            // Stats Grid
            BlocBuilder<StatsCubit, StatsState>(
              builder: (context, statsState) {
                if (statsState is StatsLoading) {
                  return const Center(
                    child: CircularProgressIndicator(color: Colors.white),
                  );
                }

                if (statsState is StatsError) {
                  return Center(
                    child: Text(
                      'Error: ${statsState.message}',
                      style: const TextStyle(color: Colors.red),
                    ),
                  );
                }

                if (statsState is! StatsLoaded) {
                  return const SizedBox();
                }

                final analytics = statsState.userAnalytics;
                final totalPomodoros = statsState.totalPomodoros;
                final totalFocusMinutes = statsState.totalFocusTimeMinutes;
                final totalRestMinutes = analytics?.totalRestTime ?? 0;

                // Calculate averages
                final avgDaily = statsState.dailyStats.isNotEmpty
                    ? (totalFocusMinutes / statsState.dailyStats.length / 60)
                        .toStringAsFixed(1)
                    : '0.0';

                return Column(
                  children: [
                    // Top Row - Main Stats (3 cards)
                    Row(
                      children: [
                        Expanded(
                          child: _buildStatCard(
                            icon: '🍅',
                            title: 'Total Pomodoros',
                            value: '$totalPomodoros',
                            subtitle: 'sessions',
                            color: Colors.amber,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: _buildStatCard(
                            icon: '⏱️',
                            title: 'Focus Time',
                            value: _formatMinutes(totalFocusMinutes),
                            subtitle: 'total',
                            color: Colors.cyan,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: _buildStatCard(
                            icon: '☕',
                            title: 'Break Time',
                            value: _formatMinutes(totalRestMinutes),
                            subtitle: 'total',
                            color: Colors.greenAccent,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Second Row - Secondary Stats (3 cards)
                    BlocBuilder<TaskCubit, TaskState>(
                      builder: (context, taskState) {
                        int completedTasks = 0;
                        String mostProductive = '—';

                        if (taskState is TaskLoaded) {
                          completedTasks = taskState.tasks
                              .where((t) => t.isCompleted)
                              .length;

                          // Find task with most pomodoros
                          final tasksWithPomodoros =
                              taskState.tasks.where((t) => t.pomodoroCount > 0);
                          if (tasksWithPomodoros.isNotEmpty) {
                            final topTask = tasksWithPomodoros.reduce((a, b) =>
                                a.pomodoroCount > b.pomodoroCount ? a : b);
                            mostProductive = topTask.title.length > 12
                                ? '${topTask.title.substring(0, 12)}...'
                                : topTask.title;
                          }
                        }

                        return Row(
                          children: [
                            Expanded(
                              child: _buildStatCard(
                                icon: '✅',
                                title: 'Tasks Done',
                                value: '$completedTasks',
                                subtitle: 'completed',
                                color: Colors.purple,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: _buildStatCard(
                                icon: '📊',
                                title: 'Avg Daily',
                                value: '${avgDaily}h',
                                subtitle: 'per day',
                                color: Colors.orange,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: _buildStatCard(
                                icon: '🏆',
                                title: 'Top Task',
                                value: mostProductive,
                                subtitle: 'most focus',
                                color: Colors.pink,
                                isTextValue: true,
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                    const SizedBox(height: 24),

                    // Chart - Last 7 Days
                    _buildChartCard(
                      title: 'Last 7 Days',
                      child: statsState.dailyStats.isNotEmpty
                          ? _buildBarChart(statsState.dailyStats)
                          : Center(
                              child: Text(
                                'No data yet',
                                style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.5),
                                ),
                              ),
                            ),
                    ),
                    const SizedBox(height: 24),

                    // Top Tasks List
                    BlocBuilder<TaskCubit, TaskState>(
                      builder: (context, taskState) {
                        if (taskState is! TaskLoaded) {
                          return const SizedBox();
                        }

                        final tasksWithPomodoros = taskState.tasks
                            .where((t) => t.pomodoroCount > 0)
                            .toList()
                          ..sort((a, b) =>
                              b.pomodoroCount.compareTo(a.pomodoroCount));

                        if (tasksWithPomodoros.isEmpty) {
                          return const SizedBox();
                        }

                        final topTasks = tasksWithPomodoros.take(5).toList();

                        return _buildTopTasksCard(topTasks);
                      },
                    ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard({
    required String icon,
    required String title,
    required String value,
    required String subtitle,
    required Color color,
    bool isTextValue = false,
  }) {
    final cardKey = '$icon-$title';
    final isHovered = _statCardHovered[cardKey] ?? false;

    return MouseRegion(
      onEnter: (_) => setState(() => _statCardHovered[cardKey] = true),
      onExit: (_) => setState(() => _statCardHovered[cardKey] = false),
      child: AnimatedScale(
        scale: isHovered ? 1.02 : 1.0,
        duration: const Duration(milliseconds: 200),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: isHovered
                ? Colors.white.withValues(alpha: 0.15)
                : Colors.white.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isHovered
                  ? Colors.white.withValues(alpha: 0.3)
                  : Colors.white.withValues(alpha: 0.2),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(icon, style: const TextStyle(fontSize: 24)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      title,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.white.withValues(alpha: 0.6),
                        fontWeight: FontWeight.w500,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                value,
                style: TextStyle(
                  fontSize: isTextValue ? 20 : 32,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.white.withValues(alpha: 0.5),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildChartCard({required String title, required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.white.withValues(alpha: 0.9),
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(height: 200, child: child),
        ],
      ),
    );
  }

  Widget _buildBarChart(List dailyStats) {
    final last7Days = dailyStats.length > 7
        ? dailyStats.sublist(dailyStats.length - 7)
        : dailyStats;

    return BarChart(
      BarChartData(
        gridData: const FlGridData(show: false),
        borderData: FlBorderData(show: false),
        titlesData: FlTitlesData(
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          leftTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                if (value.toInt() >= last7Days.length) return const SizedBox();
                final date = last7Days[value.toInt()].date;
                final weekday = ['', 'M', 'T', 'W', 'T', 'F', 'S', 'S'];
                return Text(
                  weekday[date.weekday],
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.6),
                    fontSize: 12,
                  ),
                );
              },
            ),
          ),
        ),
        barGroups: last7Days
            .asMap()
            .entries
            .map((entry) => BarChartGroupData(
                  x: entry.key,
                  barRods: [
                    BarChartRodData(
                      toY: entry.value.completedPomodoros == 0
                          ? 0.5
                          : entry.value.completedPomodoros.toDouble(),
                      color: Colors.amber,
                      width: 16,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ],
                ))
            .toList(),
      ),
    );
  }

  Widget _buildTopTasksCard(List tasks) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text('📝', style: TextStyle(fontSize: 20)),
              const SizedBox(width: 8),
              Text(
                'Top Tasks',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white.withValues(alpha: 0.9),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...tasks.map((task) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        task.title,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Row(
                      children: [
                        ...List.generate(
                          task.pomodoroCount > 5 ? 5 : task.pomodoroCount,
                          (index) => const Padding(
                            padding: EdgeInsets.only(left: 2),
                            child: Text('🍅', style: TextStyle(fontSize: 12)),
                          ),
                        ),
                        if (task.pomodoroCount > 5)
                          Text(
                            ' +${task.pomodoroCount - 5}',
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.7),
                              fontSize: 12,
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '${task.pomodoroCount}',
                      style: TextStyle(
                        color: Colors.amber,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              )),
        ],
      ),
    );
  }

  String _formatMinutes(int minutes) {
    final hours = minutes ~/ 60;
    final mins = minutes % 60;
    if (hours == 0) return '${mins}m';
    if (mins == 0) return '${hours}h';
    return '${hours}h ${mins}m';
  }
}
