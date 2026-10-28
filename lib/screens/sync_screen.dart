import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../core/sync/conflict_resolver.dart';
import '../core/theme/app_theme.dart';
import '../data/local/app_database.dart';
import '../providers/app_state.dart';

class SyncScreen extends StatefulWidget {
  final AppState state;

  const SyncScreen({super.key, required this.state});

  @override
  State<SyncScreen> createState() => _SyncScreenState();
}

class _SyncScreenState extends State<SyncScreen> {
  List<LocalChangeHistoryData> _history = [];
  bool _loadingHistory = true;

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    setState(() => _loadingHistory = true);
    final history = await widget.state.getChangeHistory();
    if (mounted) {
      setState(() {
        _history = history;
        _loadingHistory = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final report = widget.state.syncReport;
    final conflicts = widget.state.conflicts;
    final timeFormat = DateFormat('dd/MM/yyyy HH:mm');

    return Scaffold(
      backgroundColor: AppTheme.bg(context),
      appBar: AppBar(
        title: Text(
          'Estado de Sincronización',
          style: TextStyle(
            fontWeight: FontWeight.w900,
            color: AppTheme.textColor(context),
          ),
        ),
        backgroundColor: AppTheme.cardBg(context),
        elevation: 0,
        surfaceTintColor: Colors.transparent,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Tarjeta de Estado
          Card(
            color: AppTheme.cardBg(context),
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(color: AppTheme.borderColor(context)),
            ),
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        report.isOnline
                            ? Icons.cloud_done_rounded
                            : Icons.cloud_off_rounded,
                        color: report.isOnline
                            ? AppTheme.successColor(context)
                            : AppTheme.warningColor(context),
                        size: 28,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              report.isOnline
                                  ? 'Conectado al Servidor'
                                  : 'Modo Sin Conexión (Offline)',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.textColor(context),
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              report.lastSyncTime != null
                                  ? 'Última sinc.: ${timeFormat.format(report.lastSyncTime!)}'
                                  : 'Aún no sincronizado',
                              style: TextStyle(
                                fontSize: 13,
                                color: AppTheme.mutedColor(context),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  Divider(height: 24, color: AppTheme.borderColor(context)),
                  Wrap(
                    alignment: WrapAlignment.spaceBetween,
                    spacing: 12,
                    runSpacing: 8,
                    children: [
                      Text(
                        'Cambios pendientes: ${report.pendingCount}',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: AppTheme.textColor(context),
                        ),
                      ),
                      Text(
                        'Conflictos: ${conflicts.length}',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: conflicts.isNotEmpty
                              ? AppTheme.errorColor(context)
                              : AppTheme.mutedColor(context),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: widget.state.isSyncing
                          ? null
                          : () async {
                              await widget.state.syncNow();
                              await _loadHistory();
                            },
                      icon: widget.state.isSyncing
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2))
                          : const Icon(Icons.sync_rounded),
                      label: Text(widget.state.isSyncing
                          ? 'Sincronizando...'
                          : 'Sincronizar ahora'),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Sección de Conflictos
          if (conflicts.isNotEmpty) ...[
            Text(
              'Conflictos por resolver',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppTheme.errorColor(context),
              ),
            ),
            const SizedBox(height: 8),
            ...conflicts.map((c) => Card(
                  color: AppTheme.tintError(context),
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(
                        color: AppTheme.errorColor(context).withOpacity(0.4)),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Entidad: ${c.entityType.toUpperCase()} (ID: ${c.entityId})',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: AppTheme.textColor(context),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Versión local: ${c.baseVersion} | Versión remota: ${c.serverVersion}',
                          style: TextStyle(
                              color: AppTheme.mutedColor(context),
                              fontSize: 13),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Datos en este dispositivo: ${c.clientPayload}',
                          style: TextStyle(
                              color: AppTheme.textColor(context), fontSize: 13),
                        ),
                        Text(
                          'Datos en el servidor: ${c.serverPayload}',
                          style: TextStyle(
                              color: AppTheme.textColor(context), fontSize: 13),
                        ),
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            ElevatedButton(
                              onPressed: () async {
                                await widget.state.resolveConflict(c.id,
                                    ConflictResolutionStrategy.clientWins);
                                await _loadHistory();
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppTheme.primaryColor(context),
                                foregroundColor: Colors.white,
                              ),
                              child: const Text('Usar este dispositivo'),
                            ),
                            OutlinedButton(
                              onPressed: () async {
                                await widget.state.resolveConflict(c.id,
                                    ConflictResolutionStrategy.serverWins);
                                await _loadHistory();
                              },
                              child: const Text('Usar servidor'),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                )),
            const SizedBox(height: 20),
          ],

          // Historial de Modificaciones (Auditoría)
          Text(
            'Historial de Cambios Locales',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppTheme.textColor(context),
            ),
          ),
          const SizedBox(height: 8),
          if (_loadingHistory)
            const Center(
                child: Padding(
                    padding: EdgeInsets.all(20),
                    child: CircularProgressIndicator()))
          else if (_history.isEmpty)
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(
                'No hay modificaciones registradas aún.',
                style: TextStyle(
                    color: AppTheme.mutedColor(context), fontSize: 13.5),
              ),
            )
          else
            ..._history.map((h) => Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  color: AppTheme.cardBg(context),
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(color: AppTheme.borderColor(context)),
                  ),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: h.action == 'delete'
                          ? AppTheme.tintError(context)
                          : (h.action == 'create'
                              ? AppTheme.tintSuccess(context)
                              : AppTheme.tintPrimary(context)),
                      child: Icon(
                        h.action == 'delete'
                            ? Icons.delete_outline
                            : (h.action == 'create' ? Icons.add : Icons.edit),
                        color: h.action == 'delete'
                            ? AppTheme.errorColor(context)
                            : (h.action == 'create'
                                ? AppTheme.successColor(context)
                                : AppTheme.primaryColor(context)),
                        size: 20,
                      ),
                    ),
                    title: Text(
                      '${h.entityType.toUpperCase()} • ${h.action.toUpperCase()}',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textColor(context),
                      ),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 3),
                        Text(
                          'Fecha: ${timeFormat.format(h.localTimestamp)}',
                          style: TextStyle(
                              fontSize: 12.5,
                              color: AppTheme.mutedColor(context)),
                        ),
                        if (h.previousValuesJson != null)
                          Text(
                            'Antes: ${h.previousValuesJson}',
                            style: TextStyle(
                                fontSize: 12,
                                color: AppTheme.mutedColor(context)),
                          ),
                        Text(
                          'Nuevo: ${h.newValuesJson}',
                          style: TextStyle(
                              fontSize: 12, color: AppTheme.textColor(context)),
                        ),
                      ],
                    ),
                    trailing: Chip(
                      label: Text(
                        h.syncStatus,
                        style: TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w700,
                          color: h.syncStatus == 'synced'
                              ? AppTheme.successColor(context)
                              : AppTheme.warningColor(context),
                        ),
                      ),
                      backgroundColor: h.syncStatus == 'synced'
                          ? AppTheme.tintSuccess(context)
                          : AppTheme.tintWarning(context),
                      side: BorderSide(
                        color: (h.syncStatus == 'synced'
                                ? AppTheme.successColor(context)
                                : AppTheme.warningColor(context))
                            .withOpacity(0.3),
                      ),
                    ),
                  ),
                )),
        ],
      ),
    );
  }
}
