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
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text('Estado de Sincronización'),
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Tarjeta de Estado
          Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        report.isOnline ? Icons.cloud_done_rounded : Icons.cloud_off_rounded,
                        color: report.isOnline ? const Color(0xFF16A34A) : const Color(0xFFD97706),
                        size: 28,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              report.isOnline ? 'Conectado al Servidor' : 'Modo Sin Conexión (Offline)',
                              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                            ),
                            Text(
                              report.lastSyncTime != null
                                  ? 'Última sinc.: ${timeFormat.format(report.lastSyncTime!)}'
                                  : 'Aún no sincronizado',
                              style: const TextStyle(fontSize: 12, color: Colors.grey),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const Divider(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Cambios pendientes: ${report.pendingCount}', style: const TextStyle(fontWeight: FontWeight.w600)),
                      Text('Conflictos: ${conflicts.length}', style: TextStyle(fontWeight: FontWeight.w600, color: conflicts.isNotEmpty ? Colors.red : Colors.grey)),
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
                          ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                          : const Icon(Icons.sync_rounded),
                      label: Text(widget.state.isSyncing ? 'Sincronizando...' : 'Sincronizar ahora'),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Sección de Conflictos
          if (conflicts.isNotEmpty) ...[
            const Text('Conflictos por resolver', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.red)),
            const SizedBox(height: 8),
            ...conflicts.map((c) => Card(
                  color: const Color(0xFFFFF1F2),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Entidad: ${c.entityType.toUpperCase()} (ID: ${c.entityId})', style: const TextStyle(fontWeight: FontWeight.bold)),
                        const SizedBox(height: 6),
                        Text('Versión local: ${c.baseVersion} | Versión remota: ${c.serverVersion}'),
                        const SizedBox(height: 8),
                        Text('Datos en este dispositivo: ${c.clientPayload}'),
                        Text('Datos en el servidor: ${c.serverPayload}'),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            ElevatedButton(
                              onPressed: () async {
                                await widget.state.resolveConflict(c.id, ConflictResolutionStrategy.clientWins);
                                await _loadHistory();
                              },
                              style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primary, foregroundColor: Colors.white),
                              child: const Text('Usar este dispositivo'),
                            ),
                            const SizedBox(width: 8),
                            OutlinedButton(
                              onPressed: () async {
                                await widget.state.resolveConflict(c.id, ConflictResolutionStrategy.serverWins);
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
          const Text('Historial de Cambios Locales', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          if (_loadingHistory)
            const Center(child: Padding(padding: EdgeInsets.all(20), child: CircularProgressIndicator()))
          else if (_history.isEmpty)
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: Text('No hay modificaciones registradas aún.', style: TextStyle(color: Colors.grey)),
            )
          else
            ..._history.map((h) => Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: h.action == 'delete'
                          ? Colors.red.shade100
                          : (h.action == 'create' ? Colors.green.shade100 : Colors.blue.shade100),
                      child: Icon(
                        h.action == 'delete'
                            ? Icons.delete_outline
                            : (h.action == 'create' ? Icons.add : Icons.edit),
                        color: h.action == 'delete'
                            ? Colors.red
                            : (h.action == 'create' ? Colors.green : Colors.blue),
                        size: 20,
                      ),
                    ),
                    title: Text('${h.entityType.toUpperCase()} • ${h.action.toUpperCase()}'),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Fecha: ${timeFormat.format(h.localTimestamp)}'),
                        if (h.previousValuesJson != null)
                          Text('Antes: ${h.previousValuesJson}', style: const TextStyle(fontSize: 11, color: Colors.grey)),
                        Text('Nuevo: ${h.newValuesJson}', style: const TextStyle(fontSize: 11)),
                      ],
                    ),
                    trailing: Chip(
                      label: Text(h.syncStatus, style: const TextStyle(fontSize: 10)),
                      backgroundColor: h.syncStatus == 'synced' ? Colors.green.shade50 : Colors.amber.shade50,
                    ),
                  ),
                )),
        ],
      ),
    );
  }
}
