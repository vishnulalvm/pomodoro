import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../cubit/pomodoro_timer_cubit.dart';
import '../cubit/pomodoro_timer_state.dart';
import 'current_task_display.dart';

class PomodoroTimerView extends StatelessWidget {
  final VoidCallback? onOpenSidebar;

  const PomodoroTimerView({super.key, this.onOpenSidebar});

  String _formatTime(int totalSeconds) {
    final minutes = totalSeconds ~/ 60;
    final seconds = totalSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  Widget _buildDurationBubbles(BuildContext context, PomodoroTimerState state) {
    final durations = [5, 10, 15, 20];

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: durations.map((duration) {
        final isSelected = state.restDuration == duration * 60;
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: GestureDetector(
            onTap: () {
              context.read<PomodoroTimerCubit>().setRestDuration(duration);
            },
            child: Container(
              width: 70,
              height: 70,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isSelected
                    ? Colors.white.withValues(alpha: 0.3)
                    : Colors.white.withValues(alpha: 0.15),
                border: Border.all(
                  color: isSelected
                      ? Colors.white.withValues(alpha: 0.7)
                      : Colors.white.withValues(alpha: 0.3),
                  width: 2,
                ),
              ),
              child: Center(
                child: Text(
                  '$duration',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: isSelected
                        ? Colors.white
                        : Colors.white.withValues(alpha: 0.7),
                  ),
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<PomodoroTimerCubit, PomodoroTimerState>(
      builder: (context, state) {
        final remaining = state.isRestMode
            ? (state.restDuration ?? 0) - state.restElapsed
            : state.duration - state.elapsed;

        return Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Combined Timer and Task Container
            Container(
              width: 500,
              padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 40),
              decoration: BoxDecoration(
                color: Colors.white.withValues(
                  alpha: 0.1,
                ), // Glassmorphism container
                borderRadius: BorderRadius.circular(30),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.2),
                  width: 1.5,
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Timer Display
                  Text(
                    _formatTime(remaining),
                    style: const TextStyle(
                      fontSize: 120, // Huge font size
                      fontWeight: FontWeight.w900, // Extra Bold
                      color: Colors.white, // All text in white
                      height: 1.0,
                    ),
                  ),
                  // Reset button - only show when timer is running or paused
                  SizedBox(
                    height: 48,
                    child: (state.status == TimerStatus.running ||
                            state.status == TimerStatus.paused)
                        ? GestureDetector(
                            onTap: () {
                              context.read<PomodoroTimerCubit>().resetTimer();
                            },
                            child: Padding(
                              padding: const EdgeInsets.only(top: 20),
                              child: Icon(
                                Icons.refresh_rounded,
                                color: Colors.white.withValues(alpha: 0.7),
                                size: 28,
                              ),
                            ),
                          )
                        : null,
                  ),
                  const SizedBox(height: 30),
                  // Current Task Display (inside the same container)
                  CurrentTaskDisplay(
                    onAddTaskPressed: () {
                      if (onOpenSidebar != null) {
                        onOpenSidebar!();
                      }
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            // Duration selection bubbles (only show in REST MODE when timer not started)
            if (state.isRestMode &&
                state.status != TimerStatus.running &&
                state.status != TimerStatus.paused)
              _buildDurationBubbles(context, state),
            if (state.isRestMode &&
                state.status != TimerStatus.running &&
                state.status != TimerStatus.paused)
              const SizedBox(height: 30),
            // Buttons Row
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                GestureDetector(
                  onTap: () {
                    if (state.status == TimerStatus.running) {
                      context.read<PomodoroTimerCubit>().pauseTimer();
                    } else {
                      context.read<PomodoroTimerCubit>().startTimer();
                    }
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 50,
                      vertical: 15,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(30),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.5),
                        width: 1.5,
                      ),
                    ),
                    child: Text(
                      state.status == TimerStatus.running ? 'PAUSE' : 'START',
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        letterSpacing: 2.0,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 20),
                GestureDetector(
                  onTap: () {
                    context.read<PomodoroTimerCubit>().toggleRestMode();
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 50,
                      vertical: 15,
                    ),
                    decoration: BoxDecoration(
                      color: state.isRestMode
                          ? Colors.white
                          : Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(30),
                      border: Border.all(
                        color: state.isRestMode
                            ? Colors.white
                            : Colors.white.withValues(alpha: 0.5),
                        width: 1.5,
                      ),
                    ),
                    child: Text(
                      'BREAK',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: state.isRestMode
                            ? Colors.black
                            : Colors.white,
                        letterSpacing: 2.0,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );
  }
}
