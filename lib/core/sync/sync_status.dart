enum SyncState {
  idle,
  syncing,
  offline,
  error,
  hasConflicts,
}

class SyncReport {
  final SyncState state;
  final int pendingCount;
  final int conflictCount;
  final DateTime? lastSyncTime;
  final String? lastError;
  final bool isOnline;

  const SyncReport({
    this.state = SyncState.idle,
    this.pendingCount = 0,
    this.conflictCount = 0,
    this.lastSyncTime,
    this.lastError,
    this.isOnline = true,
  });

  SyncReport copyWith({
    SyncState? state,
    int? pendingCount,
    int? conflictCount,
    DateTime? lastSyncTime,
    String? lastError,
    bool? isOnline,
  }) {
    return SyncReport(
      state: state ?? this.state,
      pendingCount: pendingCount ?? this.pendingCount,
      conflictCount: conflictCount ?? this.conflictCount,
      lastSyncTime: lastSyncTime ?? this.lastSyncTime,
      lastError: lastError,
      isOnline: isOnline ?? this.isOnline,
    );
  }
}
