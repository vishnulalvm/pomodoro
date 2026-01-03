class User {
  final String email;
  final String firebaseUid;
  final DateTime createdAt;
  final int totalPomodoros;
  final int totalTasks;

  User({
    required this.email,
    required this.firebaseUid,
    required this.createdAt,
    this.totalPomodoros = 0,
    this.totalTasks = 0,
  });

  // Convert to Map for Firestore
  Map<String, dynamic> toMap() {
    return {
      'email': email,
      'firebaseUid': firebaseUid,
      'createdAt': createdAt.toIso8601String(),
      'totalPomodoros': totalPomodoros,
      'totalTasks': totalTasks,
    };
  }

  // Create from Firestore Map
  factory User.fromMap(Map<String, dynamic> map) {
    return User(
      email: map['email'] as String,
      firebaseUid: map['firebaseUid'] as String,
      createdAt: DateTime.parse(map['createdAt'] as String),
      totalPomodoros: map['totalPomodoros'] as int? ?? 0,
      totalTasks: map['totalTasks'] as int? ?? 0,
    );
  }

  // Copy with for updates
  User copyWith({
    String? email,
    String? firebaseUid,
    DateTime? createdAt,
    int? totalPomodoros,
    int? totalTasks,
  }) {
    return User(
      email: email ?? this.email,
      firebaseUid: firebaseUid ?? this.firebaseUid,
      createdAt: createdAt ?? this.createdAt,
      totalPomodoros: totalPomodoros ?? this.totalPomodoros,
      totalTasks: totalTasks ?? this.totalTasks,
    );
  }
}
