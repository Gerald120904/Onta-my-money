import 'package:flutter/material.dart';
import '../core/sync/sync_status.dart';
import '../core/theme/app_theme.dart';
import '../providers/app_state.dart';
import '../screens/sync_screen.dart';

class SyncStatusBanner extends StatelessWidget {
  final AppState state;

  const SyncStatusBanner({
    super.key,
    required this.state,
  });

  @override
  Widget build(BuildContext context) {
    final report = state.syncReport;

    if (state.hasConflicts) {
      return Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: const Color(0xFFFEF2F2),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFF87171)),
        ),
        child: Row(
          children: [
            const Icon(Icons.warning_amber_rounded, color: Color(0xFFDC2626), size: 20),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                '${report.conflictCount} conflicto(s) detectado(s).',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF991B1B),
                ),
              ),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => SyncScreen(state: state)),
                );
              },
              style: TextButton.styleFrom(
                visualDensity: VisualDensity.compact,
                foregroundColor: const Color(0xFFDC2626),
              ),
              child: const Text('Resolver'),
            ),
          ],
        ),
      );
    }

    if (report.state == SyncState.syncing) {
      return Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: const Color(0xFFEFF6FF),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFF93C5FD)),
        ),
        child: const Row(
          children: [
            SizedBox(
              width: 14,
              height: 14,
              child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.primary),
            ),
            SizedBox(width: 12),
            Expanded(
              child: Text(
                'Sincronizando cambios con el servidor...',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.primaryDark,
                ),
              ),
            ),
          ],
        ),
      );
    }

    if (!report.isOnline || report.state == SyncState.offline) {
      return Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: const Color(0xFFFFFBEB),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFFCD34D)),
        ),
        child: Row(
          children: [
            const Icon(Icons.cloud_off_rounded, color: Color(0xFFD97706), size: 18),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                report.pendingCount > 0
                    ? 'Modo sin conexión • ${report.pendingCount} cambio(s) pendiente(s)'
                    : 'Modo sin conexión • Datos guardados localmente',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF92400E),
                ),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.refresh_rounded, size: 18, color: Color(0xFFD97706)),
              tooltip: 'Sincronizar ahora',
              visualDensity: VisualDensity.compact,
              onPressed: () => state.syncNow(),
            ),
          ],
        ),
      );
    }

    if (report.pendingCount > 0) {
      return Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: const Color(0xFFF0FDF4),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFF86EFAC)),
        ),
        child: Row(
          children: [
            const Icon(Icons.cloud_queue_rounded, color: Color(0xFF16A34A), size: 18),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                '${report.pendingCount} cambio(s) pendiente(s) de sincronizar',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF166534),
                ),
              ),
            ),
            TextButton(
              onPressed: () => state.syncNow(),
              style: TextButton.styleFrom(
                visualDensity: VisualDensity.compact,
                foregroundColor: const Color(0xFF16A34A),
              ),
              child: const Text('Sincronizar'),
            ),
          ],
        ),
      );
    }

    return const SizedBox.shrink();
  }
}
