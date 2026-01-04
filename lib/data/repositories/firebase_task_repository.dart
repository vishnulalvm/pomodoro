import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/task.dart';

class FirebaseTaskRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Get all tasks for a user
  Future<List<Task>> getTasks(String userId) async {
    try {
      final snapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('tasks')
          .orderBy('createdAt', descending: false)  // Ascending order (oldest first)
          .get();

      final tasks = snapshot.docs
          .map((doc) => Task.fromMap(doc.data(), firebaseId: doc.id))
          .toList();

      // Separate active and completed tasks
      final activeTasks = tasks.where((t) => !t.isCompleted).toList();
      final completedTasks = tasks.where((t) => t.isCompleted).toList();

      // Active tasks first, then completed tasks
      return [...activeTasks, ...completedTasks];
    } catch (e) {
      print('Error getting tasks: $e');
      rethrow;
    }
  }

  // Save task to Firebase
  Future<String> saveTask(String userId, Task task) async {
    try {
      final docRef = await _firestore
          .collection('users')
          .doc(userId)
          .collection('tasks')
          .add(task.toMap(userId: userId));

      return docRef.id;
    } catch (e) {
      print('Error saving task: $e');
      rethrow;
    }
  }

  // Update task in Firebase
  Future<void> updateTask(String userId, String taskId, Task task) async {
    try {
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('tasks')
          .doc(taskId)
          .update(task.toMap(userId: userId));
    } catch (e) {
      print('Error updating task: $e');
      rethrow;
    }
  }

  // Toggle task completion
  Future<void> toggleTaskCompletion(String userId, String taskId, bool currentStatus) async {
    try {
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('tasks')
          .doc(taskId)
          .update({
        'isCompleted': !currentStatus,
        'completedAt': !currentStatus ? DateTime.now().toIso8601String() : null,
      });
    } catch (e) {
      print('Error toggling task: $e');
      rethrow;
    }
  }

  // Delete task from Firebase
  Future<void> deleteTask(String userId, String taskId) async {
    try {
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('tasks')
          .doc(taskId)
          .delete();
    } catch (e) {
      print('Error deleting task: $e');
      rethrow;
    }
  }

  // Increment pomodoro count
  Future<void> incrementPomodoroCount(String userId, String taskId) async {
    try {
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('tasks')
          .doc(taskId)
          .update({
        'pomodoroCount': FieldValue.increment(1),
      });
    } catch (e) {
      print('Error incrementing pomodoro: $e');
      rethrow;
    }
  }

  // Watch tasks in real-time
  Stream<List<Task>> watchTasks(String userId) {
    return _firestore
        .collection('users')
        .doc(userId)
        .collection('tasks')
        .orderBy('createdAt', descending: false)  // Ascending order (oldest first)
        .snapshots()
        .map((snapshot) {
          final tasks = snapshot.docs
              .map((doc) => Task.fromMap(doc.data(), firebaseId: doc.id))
              .toList();

          // Separate active and completed tasks
          final activeTasks = tasks.where((t) => !t.isCompleted).toList();
          final completedTasks = tasks.where((t) => t.isCompleted).toList();

          // Active tasks first, then completed tasks
          return [...activeTasks, ...completedTasks];
        });
  }

  // Sync local task to Firebase
  Future<void> syncTask(String userId, Task task, String? firebaseId) async {
    try {
      if (firebaseId != null) {
        // Update existing task
        await updateTask(userId, firebaseId, task);
      } else {
        // Create new task
        await saveTask(userId, task);
      }
    } catch (e) {
      print('Error syncing task: $e');
      rethrow;
    }
  }
}
