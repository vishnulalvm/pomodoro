import 'package:shared_preferences/shared_preferences.dart';

class LocalStorageService {
  static const String _emailKey = 'user_email';
  static const String _firebaseUidKey = 'firebase_uid';

  // Save user email locally
  Future<void> saveEmail(String email) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_emailKey, email);
  }

  // Get stored email
  Future<String?> getEmail() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_emailKey);
  }

  // Save Firebase UID
  Future<void> saveFirebaseUid(String uid) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_firebaseUidKey, uid);
  }

  // Get Firebase UID
  Future<String?> getFirebaseUid() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_firebaseUidKey);
  }

  // Check if user exists locally
  Future<bool> hasUser() async {
    final email = await getEmail();
    return email != null && email.isNotEmpty;
  }

  // Clear all user data
  Future<void> clearUser() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_emailKey);
    await prefs.remove(_firebaseUidKey);
  }
}
