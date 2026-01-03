enum SyncStatus {
  pending,   // Waiting to be synced to Firebase
  synced,    // Successfully synced to Firebase
  error,     // Error occurred during sync
  conflict,  // Conflict detected (different versions)
}
