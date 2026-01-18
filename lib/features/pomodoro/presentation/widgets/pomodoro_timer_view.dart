import 'dart:ui';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../cubit/pomodoro_timer_cubit.dart';
import '../cubit/pomodoro_timer_state.dart';
import 'current_task_display.dart';

class PomodoroTimerView extends StatefulWidget {
  final VoidCallback? onOpenSidebar;

  const PomodoroTimerView({super.key, this.onOpenSidebar});

  @override
  State<PomodoroTimerView> createState() => _PomodoroTimerViewState();
}

class _PomodoroTimerViewState extends State<PomodoroTimerView> {
  bool _isStartButtonHovered = false;
  bool _isBreakButtonHovered = false;
  bool _isResetButtonHovered = false;
  final Map<int, bool> _durationBubbleHovered = {};

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
        final isHovered = _durationBubbleHovered[duration] ?? false;
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: MouseRegion(
            onEnter: (_) =>
                setState(() => _durationBubbleHovered[duration] = true),
            onExit: (_) =>
                setState(() => _durationBubbleHovered[duration] = false),
            child: GestureDetector(
              onTap: () {
                context.read<PomodoroTimerCubit>().setRestDuration(duration);
              },
              child: AnimatedScale(
                scale: isHovered ? 1.1 : 1.0,
                duration: const Duration(milliseconds: 200),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 70,
                  height: 70,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isSelected
                        ? Colors.white.withValues(alpha: 0.3)
                        : isHovered
                        ? Colors.white.withValues(alpha: 0.25)
                        : Colors.white.withValues(alpha: 0.15),
                    border: Border.all(
                      color: isSelected
                          ? Colors.white.withValues(alpha: 0.7)
                          : isHovered
                          ? Colors.white.withValues(alpha: 0.5)
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
            ),
          ),
        );
      }).toList(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<PomodoroTimerCubit, PomodoroTimerState>(
      listener: (context, state) {
        final remaining = state.isRestMode
            ? (state.restDuration ?? 0) - state.restElapsed
            : state.duration - state.elapsed;

        // Update browser title
        final timeString = _formatTime(remaining);
        final modeString = state.isRestMode ? 'Rest' : 'Focus';
        SystemChrome.setApplicationSwitcherDescription(
          ApplicationSwitcherDescription(
            label: '$timeString - $modeString | Pomodoro',
            primaryColor: Theme.of(context).primaryColor.value,
          ),
        );
      },
      builder: (context, state) {
        final remaining = state.isRestMode
            ? (state.restDuration ?? 0) - state.restElapsed
            : state.duration - state.elapsed;

        final duration = state.isRestMode
            ? (state.restDuration ?? 1)
            : state.duration;

        // Avoid division by zero
        final progress = duration > 0 ? remaining / duration : 0.0;

        return LayoutBuilder(
          builder: (context, constraints) {
            final isMobile = constraints.maxWidth < 600;
            // Use 90% of width on mobile, max 500 on desktop
            final containerWidth = isMobile
                ? constraints.maxWidth * 0.9
                : 500.0;
            final ringSize =
                containerWidth * 0.6; // Ring size relative to container
            final strokeWidth = isMobile ? 10.0 : 15.0;
            final fontSize = ringSize * 0.25; // Font size proportional to ring

            return Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Combined Timer and Task Container
                ClipRRect(
                  borderRadius: BorderRadius.circular(40),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
                    child: Container(
                      width: containerWidth,
                      padding: EdgeInsets.symmetric(
                        horizontal: isMobile ? 20 : 40,
                        vertical: isMobile ? 30 : 40,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.05),
                        borderRadius: BorderRadius.circular(40),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.1),
                          width: 1.0,
                        ),
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            Colors.white.withValues(alpha: 0.1),
                            Colors.white.withValues(alpha: 0.05),
                          ],
                        ),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Timer Display with Custom Gradient Painter
                          Stack(
                            alignment: Alignment.center,
                            children: [
                              // Outer Glow
                              Container(
                                width: ringSize + 20,
                                height: ringSize + 20,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.white.withValues(
                                        alpha: 0.15,
                                      ),
                                      blurRadius: 60,
                                      spreadRadius: 5,
                                    ),
                                  ],
                                ),
                              ),
                              SizedBox(
                                width: ringSize,
                                height: ringSize,
                                child: CustomPaint(
                                  painter: TimerProgressPainter(
                                    progress: progress,
                                    strokeWidth: strokeWidth,
                                  ),
                                ),
                              ),
                              Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    _formatTime(remaining),
                                    style: TextStyle(
                                      fontSize: fontSize,
                                      fontWeight: FontWeight.w900,
                                      color: Colors.white,
                                      height: 1.0,
                                      fontFeatures: const [
                                        FontFeature.tabularFigures(),
                                      ],
                                      shadows: [
                                        Shadow(
                                          color: Colors.black.withValues(
                                            alpha: 0.2,
                                          ),
                                          offset: const Offset(0, 4),
                                          blurRadius: 10,
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(height: 10),
                                  Text(
                                    state.isRestMode ? 'REST' : 'FOCUS',
                                    style: TextStyle(
                                      fontSize:
                                          fontSize * 0.2, // proportional text
                                      letterSpacing: 4.0,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.white.withValues(
                                        alpha: 0.7,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          // Reset button - only show when timer is running or paused
                          SizedBox(
                            height: 48,
                            child:
                                (state.status == TimerStatus.running ||
                                    state.status == TimerStatus.paused)
                                ? MouseRegion(
                                    onEnter: (_) => setState(
                                      () => _isResetButtonHovered = true,
                                    ),
                                    onExit: (_) => setState(
                                      () => _isResetButtonHovered = false,
                                    ),
                                    child: GestureDetector(
                                      onTap: () {
                                        context
                                            .read<PomodoroTimerCubit>()
                                            .resetTimer();
                                      },
                                      child: Padding(
                                        padding: const EdgeInsets.only(top: 20),
                                        child: AnimatedScale(
                                          scale: _isResetButtonHovered
                                              ? 1.2
                                              : 1.0,
                                          duration: const Duration(
                                            milliseconds: 200,
                                          ),
                                          child: AnimatedRotation(
                                            turns: _isResetButtonHovered
                                                ? 0.5
                                                : 0.0,
                                            duration: const Duration(
                                              milliseconds: 200,
                                            ),
                                            child: Icon(
                                              Icons.refresh_rounded,
                                              color: _isResetButtonHovered
                                                  ? Colors.white
                                                  : Colors.white.withValues(
                                                      alpha: 0.7,
                                                    ),
                                              size: 28,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  )
                                : null,
                          ),
                          const SizedBox(height: 30),
                          // Current Task Display (inside the same container)
                          CurrentTaskDisplay(
                            onAddTaskPressed: () {
                              if (widget.onOpenSidebar != null) {
                                widget.onOpenSidebar!();
                              }
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                // Duration selection bubbles
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
                    if (state.isAlarmPlaying)
                      // STOP ALARM BUTTON
                      MouseRegion(
                        onEnter: (_) =>
                            setState(() => _isStartButtonHovered = true),
                        onExit: (_) =>
                            setState(() => _isStartButtonHovered = false),
                        child: GestureDetector(
                          onTap: () {
                            // Since _stopAlarm is private, we can call startTimer() which calls _stopAlarm internally
                            // OR expose a public method. Calling startTimer is safe as it checks status.
                            // Better yet, just call startTimer which calls _stopAlarm() immediately.
                            // Actually, let's just trigger start which stops alarm.
                            context.read<PomodoroTimerCubit>().startTimer();
                          },
                          child: AnimatedScale(
                            scale: _isStartButtonHovered ? 1.05 : 1.0,
                            duration: const Duration(milliseconds: 200),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 40,
                                vertical: 15,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.redAccent.withValues(alpha: 0.8),
                                borderRadius: BorderRadius.circular(30),
                                border: Border.all(
                                  color: Colors.red.withValues(alpha: 0.5),
                                  width: 1.5,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.redAccent.withValues(
                                      alpha: 0.4,
                                    ),
                                    blurRadius: 20,
                                    spreadRadius: 2,
                                  ),
                                ],
                              ),
                              child: Row(
                                children: [
                                  const Icon(
                                    Icons.notifications_off_outlined,
                                    color: Colors.white,
                                  ),
                                  const SizedBox(width: 10),
                                  const Text(
                                    'STOP ALARM',
                                    style: TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                      letterSpacing: 1.5,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      )
                    else
                      // NORMAL START/PAUSE BUTTON
                      MouseRegion(
                        onEnter: (_) =>
                            setState(() => _isStartButtonHovered = true),
                        onExit: (_) =>
                            setState(() => _isStartButtonHovered = false),
                        child: GestureDetector(
                          onTap: () {
                            if (state.status == TimerStatus.running) {
                              context.read<PomodoroTimerCubit>().pauseTimer();
                            } else {
                              context.read<PomodoroTimerCubit>().startTimer();
                            }
                          },
                          child: AnimatedScale(
                            scale: _isStartButtonHovered ? 1.05 : 1.0,
                            duration: const Duration(milliseconds: 200),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 50,
                                vertical: 15,
                              ),
                              decoration: BoxDecoration(
                                color: _isStartButtonHovered
                                    ? Colors.white.withValues(alpha: 0.3)
                                    : Colors.white.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(30),
                                border: Border.all(
                                  color: _isStartButtonHovered
                                      ? Colors.white.withValues(alpha: 0.7)
                                      : Colors.white.withValues(alpha: 0.5),
                                  width: 1.5,
                                ),
                              ),
                              child: Text(
                                state.status == TimerStatus.running
                                    ? 'PAUSE'
                                    : 'START',
                                style: const TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                  letterSpacing: 2.0,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    const SizedBox(width: 20),
                    MouseRegion(
                      onEnter: (_) =>
                          setState(() => _isBreakButtonHovered = true),
                      onExit: (_) =>
                          setState(() => _isBreakButtonHovered = false),
                      child: GestureDetector(
                        onTap: () {
                          context.read<PomodoroTimerCubit>().toggleRestMode();
                        },
                        child: AnimatedScale(
                          scale: _isBreakButtonHovered ? 1.05 : 1.0,
                          duration: const Duration(milliseconds: 200),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 50,
                              vertical: 15,
                            ),
                            decoration: BoxDecoration(
                              color: state.isRestMode
                                  ? Colors.white
                                  : _isBreakButtonHovered
                                  ? Colors.white.withValues(alpha: 0.3)
                                  : Colors.white.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(30),
                              border: Border.all(
                                color: state.isRestMode
                                    ? Colors.white
                                    : _isBreakButtonHovered
                                    ? Colors.white.withValues(alpha: 0.7)
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
                      ),
                    ),
                  ],
                ),
              ],
            );
          },
        );
      },
    );
  }
}

class TimerProgressPainter extends CustomPainter {
  final double progress;
  final double strokeWidth;

  TimerProgressPainter({required this.progress, required this.strokeWidth});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.min(size.width, size.height) / 2;

    // Background track (Very subtle white)
    final trackPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.08)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;

    canvas.drawCircle(center, radius - strokeWidth / 2, trackPaint);

    // Progress Arc
    final rect = Rect.fromCircle(
      center: center,
      radius: radius - strokeWidth / 2,
    );
    final startAngle = -math.pi / 2;
    final sweepAngle = 2 * math.pi * progress;

    // "Simple" Design: Solid White
    // No gradients, just a clean, high-contrast arc.
    final paint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = strokeWidth;

    // Optional: Add a subtle shadow/glow to the arc itself for depth,
    // but keep it solid white as requested.
    paint.maskFilter = const MaskFilter.blur(BlurStyle.solid, 2);

    canvas.drawArc(rect, startAngle, sweepAngle, false, paint);

    // Simple design implies no extra decorations like sparkles.
    // Removed the "Sparkle" dot logic entirely.
  }

  @override
  bool shouldRepaint(covariant TimerProgressPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.strokeWidth != strokeWidth;
  }
}
