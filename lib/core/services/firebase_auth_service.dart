import 'package:firebase_auth/firebase_auth.dart' as auth;
import '../../data/models/user.dart' as app_models;
import '../../data/repositories/user_repository.dart';
import 'local_storage_service.dart';

class FirebaseAuthService {
  final auth.FirebaseAuth _firebaseAuth = auth.FirebaseAuth.instance;
  final UserRepository _userRepository;
  final LocalStorageService _localStorageService;

  FirebaseAuthService(this._userRepository, this._localStorageService);

  // Get current Firebase user
  auth.User? getCurrentFirebaseUser() {
    return _firebaseAuth.currentUser;
  }

  // Sign in anonymously
  Future<auth.User?> signInAnonymously() async {
    try {
      final userCredential = await _firebaseAuth.signInAnonymously();
      return userCredential.user;
    } catch (e) {
      print('Error signing in anonymously: $e');
      rethrow;
    }
  }

  // Check if user exists in Firestore
  Future<bool> checkUserExists(String email) async {
    try {
      final user = await _userRepository.getUser(email);
      return user != null;
    } catch (e) {
      print('Error checking user existence: $e');
      return false;
    }
  }

  // Create user account with email
  Future<app_models.User> createUserAccount(String email) async {
    try {
      // Sign in anonymously first
      final firebaseUser = await signInAnonymously();

      if (firebaseUser == null) {
        throw Exception('Failed to create anonymous user');
      }

      // Create user model
      final user = app_models.User(
        email: email,
        firebaseUid: firebaseUser.uid,
        createdAt: DateTime.now(),
        totalPomodoros: 0,
        totalTasks: 0,
      );

      // Save to Firestore
      await _userRepository.saveUser(user);

      // Save to local storage
      await _localStorageService.saveEmail(email);
      await _localStorageService.saveFirebaseUid(firebaseUser.uid);

      return user;
    } catch (e) {
      print('Error creating user account: $e');
      rethrow;
    }
  }

  // Get or create user
  Future<app_models.User> getOrCreateUser(String email) async {
    try {
      // Check if user exists in Firestore
      final existingUser = await _userRepository.getUser(email);

      if (existingUser != null) {
        // User exists, save to local storage
        await _localStorageService.saveEmail(email);
        await _localStorageService.saveFirebaseUid(existingUser.firebaseUid);

        // Sign in with existing UID if not already signed in
        if (getCurrentFirebaseUser() == null) {
          await signInAnonymously();
        }

        return existingUser;
      } else {
        // Create new user
        return await createUserAccount(email);
      }
    } catch (e) {
      print('Error getting or creating user: $e');
      rethrow;
    }
  }

  // Sign out
  Future<void> signOut() async {
    try {
      await _firebaseAuth.signOut();
      await _localStorageService.clearUser();
    } catch (e) {
      print('Error signing out: $e');
      rethrow;
    }
  }
}
