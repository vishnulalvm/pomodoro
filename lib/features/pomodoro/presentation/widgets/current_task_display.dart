import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../data/models/task.dart';
import '../../../tasks/presentation/cubit/task_cubit.dart';

class CurrentTaskDisplay extends StatefulWidget {
  final VoidCallback onAddTaskPressed;

  const CurrentTaskDisplay({
    super.key,
    required this.onAddTaskPressed,
  });

  @override
  State<CurrentTaskDisplay> createState() => _CurrentTaskDisplayState();
}

class _CurrentTaskDisplayState extends State<CurrentTaskDisplay> {
  bool _isCurrentTaskHovered = false;
  bool _isAddTaskHovered = false;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<TaskCubit, TaskState>(
      builder: (context, state) {
        if (state is TaskLoaded) {
          // Get first active (non-completed) task
          final activeTasks = state.tasks.where((t) => !t.isCompleted).toList();

          if (activeTasks.isEmpty) {
            return _buildNoTasksCard(context);
          }

          return _buildCurrentTaskCard(context, activeTasks.first);
        }

        // Loading or error state
        return _buildNoTasksCard(context);
      },
    );
  }

  Widget _buildCurrentTaskCard(BuildContext context, Task task) {
    final isCompleted = task.isCompleted;

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 300),
      child: MouseRegion(
        key: ValueKey(task.id),
        onEnter: (_) => setState(() => _isCurrentTaskHovered = true),
        onExit: (_) => setState(() => _isCurrentTaskHovered = false),
        child: AnimatedScale(
          scale: _isCurrentTaskHovered ? 1.02 : 1.0,
          duration: const Duration(milliseconds: 200),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            decoration: BoxDecoration(
              color: _isCurrentTaskHovered
                  ? Colors.white.withValues(alpha: 0.15)
                  : Colors.white.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(15),
              border: Border.all(
                color: _isCurrentTaskHovered
                    ? Colors.white.withValues(alpha: 0.3)
                    : Colors.white.withValues(alpha: 0.2),
              ),
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(15),
                onTap: () {
                  if (task.id != null) {
                    context.read<TaskCubit>().toggleTask(task.id!);
                  }
                },
                child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  // Checkbox (same as sidebar)
                  Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isCompleted
                            ? Colors.greenAccent
                            : Colors.white,
                        width: 2,
                      ),
                      color: isCompleted
                          ? Colors.greenAccent
                          : Colors.transparent,
                    ),
                    child: isCompleted
                        ? const Icon(
                            Icons.check,
                            size: 16,
                            color: Colors.black,
                          )
                        : null,
                  ),
                  const SizedBox(width: 15),
                  // Task title
                  Expanded(
                    child: Text(
                      task.title,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        decoration: isCompleted
                            ? TextDecoration.lineThrough
                            : TextDecoration.none,
                        decorationColor: Colors.white,
                        decorationThickness: 2,
                      ),
                    ),
                  ),
                  // Pomodoro count badge
                  if (task.pomodoroCount > 0)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        '${task.pomodoroCount}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
          ),
        ),
      ),
    );
  }

  Widget _buildNoTasksCard(BuildContext context) {
    return MouseRegion(
      key: const ValueKey('no-tasks'),
      onEnter: (_) => setState(() => _isAddTaskHovered = true),
      onExit: (_) => setState(() => _isAddTaskHovered = false),
      child: AnimatedScale(
        scale: _isAddTaskHovered ? 1.05 : 1.0,
        duration: const Duration(milliseconds: 200),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(15),
            onTap: widget.onAddTaskPressed,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
              decoration: BoxDecoration(
                color: _isAddTaskHovered
                    ? Colors.white.withValues(alpha: 0.1)
                    : Colors.white.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(15),
                border: _isAddTaskHovered
                    ? Border.all(
                        color: Colors.white.withValues(alpha: 0.3),
                        width: 1,
                      )
                    : null,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.add_circle_outline,
                    color: _isAddTaskHovered
                        ? Colors.greenAccent
                        : Colors.white.withValues(alpha: 0.7),
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Add Task',
                    style: TextStyle(
                      color: _isAddTaskHovered
                          ? Colors.white
                          : Colors.white.withValues(alpha: 0.7),
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
