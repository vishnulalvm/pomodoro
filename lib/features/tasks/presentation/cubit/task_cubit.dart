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

  // Map to track Hive ID to Firebase ID
  final Map<int, String> _firebaseIdMap = {};

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

      // Load from Firebase
      try {
        _taskSubscription?.cancel();
        _taskSubscription = _firebaseTaskRepository.watchTasks(userId).listen(
          (tasks) {
            emit(TaskLoaded(tasks));
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

      // Save to Hive first
      await _taskRepository.addTask(task);

      // Try to sync to Firebase
      final userId = await _localStorageService.getEmail();
      if (userId != null) {
        try {
          final firebaseId = await _firebaseTaskRepository.saveTask(userId, task);
          if (task.id != null) {
            _firebaseIdMap[task.id!] = firebaseId;
          }
        } catch (e) {
          print('Error syncing task to Firebase: $e');
          // Task is still saved locally, continue
        }
      }
    } catch (e) {
      emit(TaskError(e.toString()));
    }
  }

  Future<void> toggleTask(int id) async {
    try {
      // Toggle in Hive first
      await _taskRepository.toggleTaskCompletion(id);

      // Try to sync to Firebase
      final userId = await _localStorageService.getEmail();
      if (userId != null && _firebaseIdMap.containsKey(id)) {
        try {
          final task = await _taskRepository.getTaskById(id);
          if (task != null) {
            await _firebaseTaskRepository.toggleTaskCompletion(
              userId,
              _firebaseIdMap[id]!,
              !task.isCompleted,
            );
          }
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
      // Delete from Hive first
      await _taskRepository.deleteTask(id);

      // Try to delete from Firebase
      final userId = await _localStorageService.getEmail();
      if (userId != null && _firebaseIdMap.containsKey(id)) {
        try {
          await _firebaseTaskRepository.deleteTask(userId, _firebaseIdMap[id]!);
          _firebaseIdMap.remove(id);
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
      // Increment in Hive first
      await _taskRepository.incrementPomodoroCount(id);

      // Try to sync to Firebase
      final userId = await _localStorageService.getEmail();
      if (userId != null && _firebaseIdMap.containsKey(id)) {
        try {
          await _firebaseTaskRepository.incrementPomodoroCount(
            userId,
            _firebaseIdMap[id]!,
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
