import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../../../data/models/task.dart';
import '../../../../data/repositories/task_repository.dart';

part 'task_state.dart';

class TaskCubit extends Cubit<TaskState> {
  final TaskRepository _taskRepository;
  StreamSubscription<List<Task>>? _taskSubscription;

  TaskCubit(this._taskRepository) : super(TaskInitial()) {
    loadTasks();
  }

  Future<void> loadTasks() async {
    try {
      emit(TaskLoading());
      _taskSubscription?.cancel();
      _taskSubscription = _taskRepository.watchAllTasks().listen(
        (tasks) {
          emit(TaskLoaded(tasks));
        },
        onError: (error) {
          emit(TaskError(error.toString()));
        },
      );
    } catch (e) {
      emit(TaskError(e.toString()));
    }
  }

  Future<void> addTask(String title) async {
    try {
      final task = Task(title: title);
      await _taskRepository.addTask(task);
    } catch (e) {
      emit(TaskError(e.toString()));
    }
  }

  Future<void> toggleTask(int id) async {
    try {
      await _taskRepository.toggleTaskCompletion(id);
    } catch (e) {
      emit(TaskError(e.toString()));
    }
  }

  Future<void> deleteTask(int id) async {
    try {
      await _taskRepository.deleteTask(id);
    } catch (e) {
      emit(TaskError(e.toString()));
    }
  }

  Future<void> incrementTaskPomodoro(int id) async {
    try {
      await _taskRepository.incrementPomodoroCount(id);
    } catch (e) {
      emit(TaskError(e.toString()));
    }
  }

  @override
  Future<void> close() {
    _taskSubscription?.cancel();
    return super.close();
  }
}
