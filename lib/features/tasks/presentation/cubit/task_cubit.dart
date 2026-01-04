import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../../../data/models/task.dart';
import '../../../../data/repositories/task_repository.dart';
import '../../../../data/repositories/firebase_task_repository.dart';
import '../../../../core/services/local_storage_service.dart';

part 'task_state.dart';

class TaskCubit extends Cubit<TaskState> {
  final TaskRepository _taskRepository;
  final FirebaseTaskRepository _firebaseTaskRepository;
  final LocalStorageService _localStorageService;
  StreamSubscription<List<Task>>? _taskSubscription;

  TaskCubit(
    this._taskRepository,
    this._firebaseTaskRepository,
    this._localStorageService,
  ) : super(TaskInitial()) {
    loadTasks();
  }

  Future<void> loadTasks() async {
    try {
      emit(TaskLoading());

      // Get user ID
      final userId = await _localStorageService.getEmail();

      if (userId == null) {
        // No user, load from Hive only
        _taskSubscription?.cancel();
        _taskSubscription = _taskRepository.watchAllTasks().listen(
          (tasks) {
            emit(TaskLoaded(tasks));
          },
          onError: (error) {
            emit(TaskError(error.toString()));
          },
        );
        return;
      }

      // User logged in - load from Firebase
      try {
        // First, sync any existing local tasks to Firebase
        final localTasks = await _taskRepository.getAllTasks();
        for (final localTask in localTasks) {
          // Only sync if task doesn't have a Firebase ID yet
          if (localTask.firebaseId == null) {
            try {
              final firebaseId = await _firebaseTaskRepository.saveTask(userId, localTask);
              localTask.firebaseId = firebaseId;
              await _taskRepository.updateTask(localTask);
            } catch (e) {
              print('Error syncing local task to Firebase: $e');
            }
          }
        }

        _taskSubscription?.cancel();
        _taskSubscription = _firebaseTaskRepository.watchTasks(userId).listen(
          (firebaseTasks) async {
            // Save Firebase tasks to local Hive for offline access
            // Clear local tasks first to avoid duplicates
            final currentLocalTasks = await _taskRepository.getAllTasks();
            for (final localTask in currentLocalTasks) {
              if (localTask.id != null) {
                await _taskRepository.deleteTask(localTask.id!);
              }
            }

            // Save Firebase tasks to Hive
            for (final task in firebaseTasks) {
              await _taskRepository.addTask(task);
            }

            emit(TaskLoaded(firebaseTasks));
          },
          onError: (error) {
            print('Firebase watch error: $error');
            // Fallback to Hive
            _loadFromHive();
          },
        );
      } catch (e) {
        print('Error loading from Firebase: $e');
        // Fallback to Hive
        _loadFromHive();
      }
    } catch (e) {
      emit(TaskError(e.toString()));
    }
  }

  void _loadFromHive() {
    _taskSubscription?.cancel();
    _taskSubscription = _taskRepository.watchAllTasks().listen(
      (tasks) {
        emit(TaskLoaded(tasks));
      },
      onError: (error) {
        emit(TaskError(error.toString()));
      },
    );
  }

  Future<void> addTask(String title) async {
    try {
      final task = Task(title: title);

      // Try to sync to Firebase first
      final userId = await _localStorageService.getEmail();
      if (userId != null) {
        try {
          final firebaseId = await _firebaseTaskRepository.saveTask(userId, task);
          task.firebaseId = firebaseId;
          // Save to Hive with Firebase ID
          await _taskRepository.addTask(task);
        } catch (e) {
          print('Error syncing task to Firebase: $e');
          // Save locally anyway
          await _taskRepository.addTask(task);
        }
      } else {
        // No user, save locally only
        await _taskRepository.addTask(task);
      }
    } catch (e) {
      emit(TaskError(e.toString()));
    }
  }

  Future<void> toggleTask(int id) async {
    try {
      // Get the task first to find its Firebase ID and current status
      final task = await _taskRepository.getTaskById(id);
      if (task == null) return;

      // Store the current status BEFORE toggling
      final currentStatus = task.isCompleted;
      final firebaseId = task.firebaseId;

      // Toggle in Hive first
      await _taskRepository.toggleTaskCompletion(id);

      // Try to sync to Firebase with the ORIGINAL status (before toggle)
      final userId = await _localStorageService.getEmail();
      if (userId != null && firebaseId != null) {
        try {
          await _firebaseTaskRepository.toggleTaskCompletion(
            userId,
            firebaseId,
            currentStatus,  // Use the original status before toggle
          );
        } catch (e) {
          print('Error syncing toggle to Firebase: $e');
        }
      }
    } catch (e) {
      emit(TaskError(e.toString()));
    }
  }

  Future<void> deleteTask(int id) async {
    try {
      // Get the task first to find its Firebase ID
      final task = await _taskRepository.getTaskById(id);
      if (task == null) return;

      // Delete from Hive first
      await _taskRepository.deleteTask(id);

      // Try to delete from Firebase
      final userId = await _localStorageService.getEmail();
      if (userId != null && task.firebaseId != null) {
        try {
          await _firebaseTaskRepository.deleteTask(userId, task.firebaseId!);
        } catch (e) {
          print('Error deleting from Firebase: $e');
        }
      }
    } catch (e) {
      emit(TaskError(e.toString()));
    }
  }

  Future<void> incrementTaskPomodoro(int id) async {
    try {
      // Get the task first to find its Firebase ID
      final task = await _taskRepository.getTaskById(id);
      if (task == null) return;

      // Increment in Hive first
      await _taskRepository.incrementPomodoroCount(id);

      // Try to sync to Firebase
      final userId = await _localStorageService.getEmail();
      if (userId != null && task.firebaseId != null) {
        try {
          await _firebaseTaskRepository.incrementPomodoroCount(
            userId,
            task.firebaseId!,
          );
        } catch (e) {
          print('Error syncing pomodoro count to Firebase: $e');
        }
      }
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
