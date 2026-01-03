import '../models/task.dart';
import '../services/hive_service.dart';

class TaskRepository {
  final HiveService _hiveService;

  TaskRepository(this._hiveService);

  Future<void> addTask(Task task) async {
    final box = _hiveService.tasks;
    final int id = await box.add(task);
    task.id = id;
    await task.save();
  }

  Future<void> updateTask(Task task) async {
    await task.save();
  }

  Future<void> deleteTask(int id) async {
    final box = _hiveService.tasks;
    await box.delete(id);
  }

  Future<List<Task>> getAllTasks() async {
    final box = _hiveService.tasks;
    final tasks = box.values.toList();
    tasks.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return tasks;
  }

  Future<List<Task>> getActiveTasks() async {
    final box = _hiveService.tasks;
    final tasks = box.values.where((t) => !t.isCompleted).toList();
    tasks.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return tasks;
  }

  Future<List<Task>> getCompletedTasks() async {
    final box = _hiveService.tasks;
    final tasks = box.values.where((t) => t.isCompleted).toList();
    tasks.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return tasks;
  }

  Future<Task?> getTaskById(int id) async {
    final box = _hiveService.tasks;
    return box.get(id);
  }

  Future<void> toggleTaskCompletion(int id) async {
    final box = _hiveService.tasks;
    final task = box.get(id);
    if (task != null) {
      task.isCompleted = !task.isCompleted;
      await task.save();
    }
  }

  Future<void> incrementPomodoroCount(int id) async {
    final box = _hiveService.tasks;
    final task = box.get(id);
    if (task != null) {
      task.pomodoroCount++;
      await task.save();
    }
  }

  Stream<List<Task>> watchAllTasks() async* {
    final box = _hiveService.tasks;
    // Initial emission
    List<Task> getSortedTasks() {
      final tasks = box.values.toList();
      tasks.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return tasks;
    }

    yield getSortedTasks();

    // Watch for changes
    await for (final _ in box.watch()) {
      yield getSortedTasks();
    }
  }

  Stream<List<Task>> watchActiveTasks() async* {
    final box = _hiveService.tasks;

    List<Task> getActiveSorted() {
      final tasks = box.values.where((t) => !t.isCompleted).toList();
      tasks.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return tasks;
    }

    yield getActiveSorted();

    await for (final _ in box.watch()) {
      yield getActiveSorted();
    }
  }
}
