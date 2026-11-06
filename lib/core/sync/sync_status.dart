enum SyncState {
  idle,
  syncing,
  partial,
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

  bool get completedSuccessfully =>
      state == SyncState.idle && pendingCount == 0 && conflictCount == 0;

  String get manualMessage {
    switch (state) {
      case SyncState.idle:
        return completedSuccessfully
            ? 'Sincronización completada con éxito.'
            : 'Quedan $pendingCount cambio(s) pendientes. Intenta sincronizar de nuevo.';
      case SyncState.partial:
        return 'Sincronización parcial: quedan $pendingCount cambio(s) pendientes. Intenta de nuevo.';
      case SyncState.offline:
        return 'Sin conexión con el servidor. Tus cambios siguen guardados y pendientes.';
      case SyncState.hasConflicts:
        return 'Hay $conflictCount conflicto(s) por resolver. Revisa la pantalla de sincronización.';
      case SyncState.error:
        return 'No se pudo completar la sincronización: ${lastError ?? 'error del servidor'}. Intenta de nuevo.';
      case SyncState.syncing:
        return 'La sincronización sigue en curso.';
    }
  }

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
