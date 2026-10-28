import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../core/api/api_client.dart';
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

  /// blitz.cloud Free solo se despierta con una visita real del navegador.
  /// Abrir health en una pestana externa mantiene los cambios locales intactos.
  Future<void> _openWakePage(BuildContext context) async {
    final url = Uri.parse('${ApiConfig.baseUrl}/api/health');
    try {
      final opened = await launchUrl(url, mode: LaunchMode.externalApplication);
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(opened
              ? 'Espera a ver healthy en la pestana del servidor, vuelve y pulsa sincronizar.'
              : 'No se pudo abrir el servidor. Abre ${url.toString()} en tu navegador.'),
        ),
      );
    } catch (_) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(
                'Abre ${url.toString()} en tu navegador y luego pulsa sincronizar.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final report = state.syncReport;
    final isDark = AppTheme.isDarkMode(context);

    if (state.hasConflicts) {
      final bg = isDark ? const Color(0xFF3F1218) : const Color(0xFFFEF2F2);
      final border = isDark ? const Color(0xFF7F1D1D) : const Color(0xFFF87171);
      final iconColor =
          isDark ? const Color(0xFFF87171) : const Color(0xFFDC2626);
      final textColor =
          isDark ? const Color(0xFFFCA5A5) : const Color(0xFF991B1B);

      return Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: border),
        ),
        child: Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: iconColor, size: 21),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                '${report.conflictCount} conflicto(s) detectado(s).',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: textColor,
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
                foregroundColor: iconColor,
              ),
              child: const Text('Resolver',
                  style: TextStyle(fontWeight: FontWeight.w800)),
            ),
          ],
        ),
      );
    }

    if (report.state == SyncState.syncing) {
      final bg = isDark ? const Color(0xFF1E3A8A) : const Color(0xFFEFF6FF);
      final border = isDark ? const Color(0xFF2563EB) : const Color(0xFF93C5FD);
      final textColor =
          isDark ? const Color(0xFFDBEAFE) : const Color(0xFF1E40AF);
      final spinnerColor = isDark ? const Color(0xFF60A5FA) : AppTheme.primary;

      return Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: border),
        ),
        child: Row(
          children: [
            SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
                  strokeWidth: 2.2, color: spinnerColor),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Sincronizando cambios con el servidor...',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: textColor,
                ),
              ),
            ),
          ],
        ),
      );
    }

    if (!report.isOnline || report.state == SyncState.offline) {
      final bg = isDark ? const Color(0xFF3E2703) : const Color(0xFFFFFBEB);
      final border = isDark ? const Color(0xFF78350F) : const Color(0xFFFCD34D);
      final iconColor =
          isDark ? const Color(0xFFFBBF24) : const Color(0xFFD97706);
      final textColor =
          isDark ? const Color(0xFFFDE68A) : const Color(0xFF92400E);

      return Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: border),
        ),
        child: Row(
          children: [
            Icon(Icons.cloud_off_rounded, color: iconColor, size: 20),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                report.pendingCount > 0
                    ? 'Modo sin conexión • ${report.pendingCount} cambio(s) pendiente(s)'
                    : 'Modo sin conexión • Datos guardados localmente',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: textColor,
                ),
              ),
            ),
            IconButton(
              icon: Icon(Icons.open_in_new_rounded, size: 19, color: iconColor),
              tooltip: 'Activar servidor de blitz.cloud en el navegador',
              visualDensity: VisualDensity.compact,
              onPressed: () => _openWakePage(context),
            ),
            IconButton(
              icon: Icon(Icons.refresh_rounded, size: 19, color: iconColor),
              tooltip: 'Sincronizar ahora',
              visualDensity: VisualDensity.compact,
              onPressed: () => state.syncNow(),
            ),
          ],
        ),
      );
    }

    if (report.pendingCount > 0) {
      final bg = isDark ? const Color(0xFF0F3A2A) : const Color(0xFFF0FDF4);
      final border = isDark ? const Color(0xFF14532D) : const Color(0xFF86EFAC);
      final iconColor =
          isDark ? const Color(0xFF34D399) : const Color(0xFF16A34A);
      final textColor =
          isDark ? const Color(0xFF86EFAC) : const Color(0xFF166534);

      return Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: border),
        ),
        child: Row(
          children: [
            Icon(Icons.cloud_queue_rounded, color: iconColor, size: 20),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                '${report.pendingCount} cambio(s) pendiente(s) de sincronizar',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: textColor,
                ),
              ),
            ),
            TextButton(
              onPressed: () => state.syncNow(),
              style: TextButton.styleFrom(
                visualDensity: VisualDensity.compact,
                foregroundColor: iconColor,
              ),
              child: const Text('Sincronizar',
                  style: TextStyle(fontWeight: FontWeight.w800)),
            ),
          ],
        ),
      );
    }

    return const SizedBox.shrink();
  }
}
