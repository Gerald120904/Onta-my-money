import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../core/theme/app_theme.dart';
import '../providers/app_state.dart';
import '../services/notifications/notification_preferences.dart';
import '../widgets/prototype_ui.dart';

class SettingsScreen extends StatefulWidget {
  final AppState state;

  const SettingsScreen({
    super.key,
    required this.state,
  });

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  NotificationPreferences _prefs = const NotificationPreferences();
  bool _loadingPrefs = true;
  bool _syncingManual = false;
  bool _clearingCache = false;

  @override
  void initState() {
    super.initState();
    _loadNotificationPreferences();
  }

  Future<void> _loadNotificationPreferences() async {
    final userId = widget.state.currentUserId;
    if (userId != null) {
      final p = await NotificationPreferences.load(userId);
      if (mounted) {
        setState(() {
          _prefs = p;
          _loadingPrefs = false;
        });
      }
    } else {
      if (mounted) setState(() => _loadingPrefs = false);
    }
  }

  Future<void> _updatePref(NotificationPreferences Function(NotificationPreferences) updater) async {
    final userId = widget.state.currentUserId;
    if (userId == null) return;
    final updated = updater(_prefs);
    setState(() => _prefs = updated);
    await NotificationPreferences.save(userId, updated);
    await widget.state.loadNotifications();
  }

  Future<void> _handleManualSync() async {
    setState(() => _syncingManual = true);
    try {
      await widget.state.syncNow();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Sincronización completada con éxito.'),
          backgroundColor: AppTheme.success,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al sincronizar: $e'),
          backgroundColor: Colors.red.shade700,
        ),
      );
    } finally {
      if (mounted) setState(() => _syncingManual = false);
    }
  }

  Future<void> _handleClearCache() async {
    final pending = widget.state.pendingOperationsCount;
    if (pending > 0) {
      showDialog<void>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Operaciones pendientes'),
          content: Text(
            'Tienes $pending cambios pendientes de sincronizar. Por seguridad, sincroniza con el servidor antes de realizar cualquier mantenimiento de caché.',
          ),
          actions: [
            FilledButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Entendido'),
            ),
          ],
        ),
      );
      return;
    }

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Limpiar caché temporal'),
        content: const Text(
          'Esta acción liberará archivos temporales y cachés de búsqueda regenerables.\n\nTus movimientos, compromisos, metas y datos financieros NO serán eliminados ni modificados.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(backgroundColor: Colors.amber.shade900),
            child: const Text('Limpiar caché'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() => _clearingCache = true);
    try {
      await widget.state.clearRegenerableCache();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Caché temporal limpiada con éxito.'),
          backgroundColor: AppTheme.success,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) setState(() => _clearingCache = false);
    }
  }

  String _formatDateTime(DateTime? dt) {
    if (dt == null) return 'No confirmada aún';
    return DateFormat('d MMM yyyy, h:mm a', 'es_CR').format(dt);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? AppTheme.textDark : AppTheme.text;
    final mutedColor = isDark ? AppTheme.mutedDark : AppTheme.muted;
    final cardBg = isDark ? AppTheme.surfaceDark : Colors.white;
    final borderColor = isDark ? AppTheme.borderDark : AppTheme.border;
    final state = widget.state;

    return Scaffold(
      backgroundColor: isDark ? AppTheme.backgroundDark : AppTheme.background,
      appBar: AppBar(
        backgroundColor: isDark ? AppTheme.surfaceDark : AppTheme.background,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_rounded, color: textColor),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'Configuración',
          style: TextStyle(
            fontWeight: FontWeight.w900,
            fontSize: 20,
            color: textColor,
          ),
        ),
      ),
      body: SafeArea(
        child: Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 720),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(18, 12, 18, 36),
              children: [
                // ==========================================
                // SECCIÓN: APARIENCIA
                // ==========================================
                _SectionTitle(title: 'Apariencia y tema', icon: Icons.palette_outlined, textColor: textColor),
                const SizedBox(height: 10),
                PrototypePanel(
                  background: cardBg,
                  borderColor: borderColor,
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Tema visual de la aplicación',
                        style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w800, color: textColor),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Seleccioná tu preferencia visual. El cambio se aplica inmediatamente a todas las pantallas.',
                        style: TextStyle(fontSize: 11.5, color: mutedColor),
                      ),
                      const SizedBox(height: 14),
                      Row(
                        children: [
                          _ThemeChoiceChip(
                            label: 'Sistema',
                            icon: Icons.brightness_auto_rounded,
                            selected: state.themeMode == ThemeMode.system,
                            onTap: () => state.setThemeMode(ThemeMode.system),
                            isDark: isDark,
                          ),
                          const SizedBox(width: 8),
                          _ThemeChoiceChip(
                            label: 'Claro',
                            icon: Icons.light_mode_rounded,
                            selected: state.themeMode == ThemeMode.light,
                            onTap: () => state.setThemeMode(ThemeMode.light),
                            isDark: isDark,
                          ),
                          const SizedBox(width: 8),
                          _ThemeChoiceChip(
                            label: 'Oscuro',
                            icon: Icons.dark_mode_rounded,
                            selected: state.themeMode == ThemeMode.dark,
                            onTap: () => state.setThemeMode(ThemeMode.dark),
                            isDark: isDark,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // ==========================================
                // SECCIÓN: PREFERENCIAS DE RECORDATORIOS
                // ==========================================
                _SectionTitle(title: 'Recordatorios y alertas', icon: Icons.notifications_active_outlined, textColor: textColor),
                const SizedBox(height: 10),
                PrototypePanel(
                  background: cardBg,
                  borderColor: borderColor,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: _loadingPrefs
                      ? const Padding(
                          padding: EdgeInsets.all(20),
                          child: Center(child: CircularProgressIndicator()),
                        )
                      : Material(
                          type: MaterialType.transparency,
                          child: Column(
                            children: [
                              SwitchListTile(
                                contentPadding: EdgeInsets.zero,
                                title: Text('Avisar 7 días antes', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: textColor)),
                                subtitle: Text('Compromisos con vencimiento a una semana', style: TextStyle(fontSize: 11, color: mutedColor)),
                                value: _prefs.reminder7d,
                                onChanged: (v) => _updatePref((p) => p.copyWith(reminder7d: v)),
                              ),
                              Divider(height: 1, color: borderColor),
                              SwitchListTile(
                                contentPadding: EdgeInsets.zero,
                                title: Text('Avisar 3 días antes', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: textColor)),
                                subtitle: Text('Alerta cercana al pago programado', style: TextStyle(fontSize: 11, color: mutedColor)),
                                value: _prefs.reminder3d,
                                onChanged: (v) => _updatePref((p) => p.copyWith(reminder3d: v)),
                              ),
                              Divider(height: 1, color: borderColor),
                              SwitchListTile(
                                contentPadding: EdgeInsets.zero,
                                title: Text('Avisar 1 día antes', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: textColor)),
                                subtitle: Text('Recordatorio de víspera para reservar saldo', style: TextStyle(fontSize: 11, color: mutedColor)),
                                value: _prefs.reminder1d,
                                onChanged: (v) => _updatePref((p) => p.copyWith(reminder1d: v)),
                              ),
                              Divider(height: 1, color: borderColor),
                              SwitchListTile(
                                contentPadding: EdgeInsets.zero,
                                title: Text('Avisar el día del vencimiento', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: textColor)),
                                subtitle: Text('Alerta el día exacto de pago', style: TextStyle(fontSize: 11, color: mutedColor)),
                                value: _prefs.reminderDueDay,
                                onChanged: (v) => _updatePref((p) => p.copyWith(reminderDueDay: v)),
                              ),
                              Divider(height: 1, color: borderColor),
                              SwitchListTile(
                                contentPadding: EdgeInsets.zero,
                                title: Text('Avisar pagos vencidos', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: textColor)),
                                subtitle: Text('Notificación continua si un compromiso sigue pendiente', style: TextStyle(fontSize: 11, color: mutedColor)),
                                value: _prefs.reminderOverdue,
                                onChanged: (v) => _updatePref((p) => p.copyWith(reminderOverdue: v)),
                              ),
                              Divider(height: 1, color: borderColor),
                              SwitchListTile(
                                contentPadding: EdgeInsets.zero,
                                title: Text('Revisión semanal de dinero', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: textColor)),
                                subtitle: Text('Aviso para revisar tus gastos y disponible real cada semana', style: TextStyle(fontSize: 11, color: mutedColor)),
                                value: _prefs.reminderWeeklyReview,
                                onChanged: (v) => _updatePref((p) => p.copyWith(reminderWeeklyReview: v)),
                              ),
                            ],
                          ),
                        ),
                ),
                const SizedBox(height: 24),

                // ==========================================
                // SECCIÓN: SINCRONIZACIÓN Y MODO OFFLINE
                // ==========================================
                _SectionTitle(title: 'Sincronización y datos', icon: Icons.sync_rounded, textColor: textColor),
                const SizedBox(height: 10),
                PrototypePanel(
                  background: cardBg,
                  borderColor: borderColor,
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: state.syncReport.isOnline
                                  ? AppTheme.success.withOpacity(.12)
                                  : Colors.orange.withOpacity(.12),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  state.syncReport.isOnline ? Icons.wifi_rounded : Icons.wifi_off_rounded,
                                  size: 14,
                                  color: state.syncReport.isOnline ? AppTheme.success : Colors.orange.shade800,
                                ),
                                const SizedBox(width: 5),
                                Text(
                                  state.syncReport.isOnline ? 'En línea' : 'Sin conexión (Offline)',
                                  style: TextStyle(
                                    fontSize: 11.5,
                                    fontWeight: FontWeight.w800,
                                    color: state.syncReport.isOnline ? AppTheme.success : Colors.orange.shade800,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const Spacer(),
                          Text(
                            '${state.pendingOperationsCount} pendientes',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                              color: state.pendingOperationsCount > 0 ? Colors.orange.shade800 : mutedColor,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      Row(
                        children: [
                          Icon(Icons.schedule_rounded, size: 16, color: mutedColor),
                          const SizedBox(width: 8),
                          Text('Última sincronización confirmada: ', style: TextStyle(fontSize: 11.5, color: mutedColor)),
                          Expanded(
                            child: Text(
                              _formatDateTime(state.syncReport.lastSyncTime),
                              style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700, color: textColor),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      Divider(height: 1, color: borderColor),
                      const SizedBox(height: 10),
                      Material(
                        type: MaterialType.transparency,
                        child: SwitchListTile(
                          contentPadding: EdgeInsets.zero,
                          title: Text('Sincronización automática', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: textColor)),
                          subtitle: Text(
                            'Si se desactiva, los cambios se guardan localmente hasta que pulses Sincronizar.',
                            style: TextStyle(fontSize: 11, color: mutedColor),
                          ),
                          value: state.autoSyncEnabled,
                          onChanged: (v) => state.setAutoSyncEnabled(v),
                        ),
                      ),
                      const SizedBox(height: 12),
                      FilledButton.icon(
                        onPressed: _syncingManual || state.isSyncing ? null : _handleManualSync,
                        icon: _syncingManual || state.isSyncing
                            ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                            : const Icon(Icons.sync_rounded, size: 18),
                        label: Text(_syncingManual || state.isSyncing ? 'Sincronizando...' : 'Sincronizar ahora'),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // ==========================================
                // SECCIÓN: PREFERENCIAS GENERALES
                // ==========================================
                _SectionTitle(title: 'Preferencias generales', icon: Icons.tune_rounded, textColor: textColor),
                const SizedBox(height: 10),
                PrototypePanel(
                  background: cardBg,
                  borderColor: borderColor,
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Pantalla inicial al abrir la aplicación', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: textColor)),
                      const SizedBox(height: 4),
                      Text('Elegí a qué sección deseas ingresar de forma predeterminada.', style: TextStyle(fontSize: 11, color: mutedColor)),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          _InitialTabChoiceChip(
                            label: 'Inicio',
                            index: 0,
                            selected: state.initialTabIndex == 0,
                            onTap: () => state.setInitialTabIndex(0),
                            isDark: isDark,
                          ),
                          const SizedBox(width: 8),
                          _InitialTabChoiceChip(
                            label: 'Movimientos',
                            index: 1,
                            selected: state.initialTabIndex == 1,
                            onTap: () => state.setInitialTabIndex(1),
                            isDark: isDark,
                          ),
                          const SizedBox(width: 8),
                          _InitialTabChoiceChip(
                            label: 'Revisión',
                            index: 2,
                            selected: state.initialTabIndex == 2,
                            onTap: () => state.setInitialTabIndex(2),
                            isDark: isDark,
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Divider(height: 1, color: borderColor),
                      const SizedBox(height: 14),
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Moneda principal', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: textColor)),
                                const SizedBox(height: 2),
                                Text('Colón costarricense (₡)', style: TextStyle(fontSize: 11.5, color: mutedColor)),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: isDark ? const Color(0xFF1E2D4A) : const Color(0xFFEAF3FF),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              'CRC (₡)',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w900,
                                color: isDark ? AppTheme.primaryDarkTheme : AppTheme.primary,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // ==========================================
                // SECCIÓN: PRIVACIDAD Y MANTENIMIENTO
                // ==========================================
                _SectionTitle(title: 'Almacenamiento y privacidad', icon: Icons.storage_rounded, textColor: textColor),
                const SizedBox(height: 10),
                PrototypePanel(
                  background: cardBg,
                  borderColor: borderColor,
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Resumen de datos locales', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: textColor)),
                      const SizedBox(height: 8),
                      _DataSummaryRow(label: 'Motor local', value: kIsWeb ? 'Drift WebAssembly (OPFS/IndexedDB)' : 'SQLite nativo Drift', textColor: textColor, mutedColor: mutedColor),
                      _DataSummaryRow(label: 'Movimientos guardados', value: '${state.transactions.length}', textColor: textColor, mutedColor: mutedColor),
                      _DataSummaryRow(label: 'Compromisos guardados', value: '${state.commitments.length}', textColor: textColor, mutedColor: mutedColor),
                      _DataSummaryRow(label: 'Metas guardadas', value: '${state.goals.length}', textColor: textColor, mutedColor: mutedColor),
                      _DataSummaryRow(label: 'Revisiones guardadas', value: '${state.reviews.length}', textColor: textColor, mutedColor: mutedColor),
                      const SizedBox(height: 14),
                      Divider(height: 1, color: borderColor),
                      const SizedBox(height: 12),
                      OutlinedButton.icon(
                        onPressed: _clearingCache ? null : _handleClearCache,
                        icon: const Icon(Icons.cleaning_services_rounded, size: 18),
                        label: Text(_clearingCache ? 'Limpiando...' : 'Limpiar caché temporal'),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color textColor;

  const _SectionTitle({
    required this.title,
    required this.icon,
    required this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 18, color: AppTheme.primary),
        const SizedBox(width: 8),
        Text(
          title,
          style: TextStyle(
            fontSize: 14.5,
            fontWeight: FontWeight.w900,
            color: textColor,
          ),
        ),
      ],
    );
  }
}

class _ThemeChoiceChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;
  final bool isDark;

  const _ThemeChoiceChip({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final activeBg = isDark ? const Color(0xFF1E3A8A) : const Color(0xFFEAF3FF);
    final inactiveBg = isDark ? const Color(0xFF14213D) : Colors.white;
    final activeBorder = isDark ? AppTheme.primaryDarkTheme : AppTheme.primary;
    final inactiveBorder = isDark ? AppTheme.borderDark : AppTheme.border;
    final activeText = isDark ? Colors.white : AppTheme.primary;
    final inactiveText = isDark ? AppTheme.textDark : AppTheme.text;

    return Expanded(
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
              color: selected ? activeBg : inactiveBg,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: selected ? activeBorder : inactiveBorder,
                width: selected ? 2.0 : 1.0,
              ),
            ),
            child: Column(
              children: [
                Icon(icon, size: 20, color: selected ? activeText : inactiveText),
                const SizedBox(height: 6),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
                    color: selected ? activeText : inactiveText,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _InitialTabChoiceChip extends StatelessWidget {
  final String label;
  final int index;
  final bool selected;
  final VoidCallback onTap;
  final bool isDark;

  const _InitialTabChoiceChip({
    required this.label,
    required this.index,
    required this.selected,
    required this.onTap,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final activeBg = isDark ? const Color(0xFF1E3A8A) : AppTheme.primary;
    final inactiveBg = isDark ? const Color(0xFF14213D) : Colors.white;
    final activeText = Colors.white;
    final inactiveText = isDark ? AppTheme.textDark : AppTheme.text;
    final borderColor = isDark ? AppTheme.borderDark : AppTheme.border;

    return Expanded(
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(10),
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 10),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: selected ? activeBg : inactiveBg,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: selected ? Colors.transparent : borderColor),
            ),
            child: Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
                color: selected ? activeText : inactiveText,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _DataSummaryRow extends StatelessWidget {
  final String label;
  final String value;
  final Color textColor;
  final Color mutedColor;

  const _DataSummaryRow({
    required this.label,
    required this.value,
    required this.textColor,
    required this.mutedColor,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(fontSize: 12, color: mutedColor)),
          Text(value, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: textColor)),
        ],
      ),
    );
  }
}
