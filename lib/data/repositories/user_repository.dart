import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user.dart';

class UserRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static const String _collectionName = 'users';

  // Save user to Firestore (email as document ID)
  Future<void> saveUser(User user) async {
    try {
      await _firestore
          .collection(_collectionName)
          .doc(user.email) // Use email as document ID
          .set(user.toMap());
    } catch (e) {
      print('Error saving user: $e');
      rethrow;
    }
  }

  // Get user from Firestore by email
  Future<User?> getUser(String email) async {
    try {
      final doc = await _firestore.collection(_collectionName).doc(email).get();

      if (doc.exists && doc.data() != null) {
        return User.fromMap(doc.data()!);
      }
      return null;
    } catch (e) {
      print('Error getting user: $e');
      rethrow;
    }
  }

  // Update user data
  Future<void> updateUser(User user) async {
    try {
      await _firestore
          .collection(_collectionName)
          .doc(user.email)
          .update(user.toMap());
    } catch (e) {
      print('Error updating user: $e');
      rethrow;
    }
  }

  // Update user stats
  Future<void> updateStats({
    required String email,
    int? totalPomodoros,
    int? totalTasks,
  }) async {
    try {
      final Map<String, dynamic> updates = {};
      if (totalPomodoros != null) updates['totalPomodoros'] = totalPomodoros;
      if (totalTasks != null) updates['totalTasks'] = totalTasks;

      if (updates.isNotEmpty) {
        await _firestore
            .collection(_collectionName)
            .doc(email)
            .update(updates);
      }
    } catch (e) {
      print('Error updating stats: $e');
      rethrow;
    }
  }

  // Delete user
  Future<void> deleteUser(String email) async {
    try {
      await _firestore.collection(_collectionName).doc(email).delete();
    } catch (e) {
      print('Error deleting user: $e');
      rethrow;
    }
  }
}
