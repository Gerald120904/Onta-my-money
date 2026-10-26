import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../core/theme/app_theme.dart';
import '../models/models.dart';
import '../providers/app_state.dart';
import '../services/notifications/app_notification.dart';
import '../services/notifications/notification_preferences.dart';
import '../services/notifications/notification_service.dart';
import 'review_screen.dart' as review;

class NotificationsScreen extends StatefulWidget {
  final AppState state;

  const NotificationsScreen({
    super.key,
    required this.state,
  });

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  int _selectedFilter = 0; // 0: Todas, 1: Pendientes, 2: Leídas
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _refreshNotifications();
  }

  Future<void> _refreshNotifications() async {
    setState(() => _loading = true);
    await widget.state.loadNotifications();
    if (mounted) setState(() => _loading = false);
  }

  String _formatNotificationDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final notifDay = DateTime(date.year, date.month, date.day);
    final diff = today.difference(notifDay).inDays;

    if (diff == 0) {
      return 'Hoy ${DateFormat('h:mm a').format(date)}';
    } else if (diff == 1) {
      return 'Ayer ${DateFormat('h:mm a').format(date)}';
    } else if (diff > 1 && diff < 7) {
      return 'Hace $diff días';
    } else {
      try {
        return DateFormat('d MMM yyyy, h:mm a', 'es_CR').format(date);
      } catch (_) {
        return '${date.day}/${date.month}/${date.year}';
      }
    }
  }

  String _formatDueDate(DateTime dt) {
    try {
      return DateFormat('d MMMM yyyy', 'es_CR').format(dt);
    } catch (_) {
      return '${dt.day}/${dt.month}/${dt.year}';
    }
  }

  IconData _iconForType(String type) {
    switch (type) {
      case 'overdue':
        return Icons.warning_amber_rounded;
      case 'reminder_due':
        return Icons.notification_important_rounded;
      case 'reminder_1d':
      case 'reminder_3d':
      case 'reminder_7d':
        return Icons.event_note_rounded;
      case 'weekly_review':
        return Icons.insights_rounded;
      default:
        return Icons.notifications_active_outlined;
    }
  }

  Color _colorForType(String type, bool isDark) {
    switch (type) {
      case 'overdue':
        return const Color(0xFFE53935);
      case 'reminder_due':
        return const Color(0xFFF57C00);
      case 'reminder_1d':
      case 'reminder_3d':
      case 'reminder_7d':
        return isDark ? const Color(0xFF60A5FA) : AppTheme.primary;
      case 'weekly_review':
        return const Color(0xFF8E24AA);
      default:
        return isDark ? AppTheme.primaryDarkTheme : AppTheme.primary;
    }
  }

  Color _bgForType(String type, bool isDark) {
    if (isDark) {
      switch (type) {
        case 'overdue':
          return const Color(0xFF3B1212);
        case 'reminder_due':
          return const Color(0xFF38230B);
        case 'reminder_1d':
        case 'reminder_3d':
        case 'reminder_7d':
          return const Color(0xFF132342);
        case 'weekly_review':
          return const Color(0xFF2A1538);
        default:
          return const Color(0xFF132342);
      }
    } else {
      switch (type) {
        case 'overdue':
          return const Color(0xFFFFEBEE);
        case 'reminder_due':
          return const Color(0xFFFFF3E0);
        case 'reminder_1d':
        case 'reminder_3d':
        case 'reminder_7d':
          return const Color(0xFFEAF3FF);
        case 'weekly_review':
          return const Color(0xFFF3E5F5);
        default:
          return const Color(0xFFEAF3FF);
      }
    }
  }

  void _handleNotificationTap(AppNotification notif) {
    // Mark as read immediately
    if (!notif.isRead) {
      widget.state.markNotificationAsRead(notif.id);
    }

    if (notif.relatedEntityType == 'review') {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (ctx) => review.ReviewScreen(
            state: widget.state,
            onCompleted: (res) {
              widget.state.saveReviewResult(res);
              Navigator.of(ctx).pop();
            },
            onExit: () => Navigator.of(ctx).pop(),
          ),
        ),
      );
    } else if (notif.relatedEntityType == 'commitment' && notif.relatedEntityId != null) {
      // Find commitment
      final commitment = widget.state.commitments.firstWhere(
        (c) => c.id == notif.relatedEntityId,
        orElse: () => Commitment(
          id: '',
          title: notif.title,
          amount: notif.amount ?? 0,
          dueDate: notif.scheduledDate,
          status: 'pending',
        ),
      );

      showDialog<void>(
        context: context,
        builder: (ctx) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text(commitment.title),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Monto: ${NotificationService.formatAmount(commitment.amount)}',
                style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
              ),
              const SizedBox(height: 8),
              Text(
                'Fecha de vencimiento: ${_formatDueDate(commitment.dueDate)}',
              ),
              const SizedBox(height: 8),
              Text(
                'Estado: ${commitment.status == 'paid' ? 'Pagado' : 'Pendiente'}',
                style: TextStyle(
                  color: commitment.status == 'paid' ? AppTheme.success : Colors.orange.shade800,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                notif.body,
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ],
          ),
          actions: [
            if (commitment.id.isNotEmpty && commitment.status != 'paid')
              FilledButton(
                onPressed: () async {
                  Navigator.of(ctx).pop();
                  final updated = Commitment(
                    id: commitment.id,
                    title: commitment.title,
                    amount: commitment.amount,
                    dueDate: commitment.dueDate,
                    status: 'paid',
                  );
                  await widget.state.saveCommitment(updated);
                  await _refreshNotifications();
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Compromiso marcado como pagado. Se retiraron sus recordatorios.'),
                        backgroundColor: AppTheme.success,
                      ),
                    );
                  }
                },
                child: const Text('Marcar como pagado'),
              ),
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Cerrar'),
            ),
          ],
        ),
      );
    }
  }

  void _openPreferencesDialog() async {
    final userId = widget.state.currentUserId;
    if (userId == null) return;
    var prefs = await NotificationPreferences.load(userId);

    if (!mounted) return;
    await showDialog<void>(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              title: const Text('Preferencias de avisos', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18)),
              content: SizedBox(
                width: double.maxFinite,
                child: ListView(
                  shrinkWrap: true,
                  children: [
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Avisar 7 días antes', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
                      value: prefs.reminder7d,
                      onChanged: (v) async {
                        setModalState(() => prefs = prefs.copyWith(reminder7d: v));
                        await NotificationPreferences.save(userId, prefs);
                      },
                    ),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Avisar 3 días antes', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
                      value: prefs.reminder3d,
                      onChanged: (v) async {
                        setModalState(() => prefs = prefs.copyWith(reminder3d: v));
                        await NotificationPreferences.save(userId, prefs);
                      },
                    ),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Avisar 1 día antes', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
                      value: prefs.reminder1d,
                      onChanged: (v) async {
                        setModalState(() => prefs = prefs.copyWith(reminder1d: v));
                        await NotificationPreferences.save(userId, prefs);
                      },
                    ),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Avisar el día del vencimiento', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
                      value: prefs.reminderDueDay,
                      onChanged: (v) async {
                        setModalState(() => prefs = prefs.copyWith(reminderDueDay: v));
                        await NotificationPreferences.save(userId, prefs);
                      },
                    ),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Avisar pagos vencidos', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
                      value: prefs.reminderOverdue,
                      onChanged: (v) async {
                        setModalState(() => prefs = prefs.copyWith(reminderOverdue: v));
                        await NotificationPreferences.save(userId, prefs);
                      },
                    ),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Recordatorio semanal de revisión', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
                      value: prefs.reminderWeeklyReview,
                      onChanged: (v) async {
                        setModalState(() => prefs = prefs.copyWith(reminderWeeklyReview: v));
                        await NotificationPreferences.save(userId, prefs);
                      },
                    ),
                  ],
                ),
              ),
              actions: [
                FilledButton(
                  onPressed: () {
                    Navigator.of(ctx).pop();
                    _refreshNotifications();
                  },
                  child: const Text('Aplicar cambios'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? AppTheme.textDark : AppTheme.text;
    final mutedColor = isDark ? AppTheme.mutedDark : AppTheme.muted;
    final cardBg = isDark ? AppTheme.surfaceDark : Colors.white;
    final borderColor = isDark ? AppTheme.borderDark : AppTheme.border;

    final allList = widget.state.notifications;
    final filteredList = allList.where((n) {
      if (_selectedFilter == 1) return !n.isRead;
      if (_selectedFilter == 2) return n.isRead;
      return true;
    }).toList();

    final unreadCount = widget.state.unreadNotificationsCount;

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
          'Notificaciones',
          style: TextStyle(
            fontWeight: FontWeight.w900,
            fontSize: 20,
            color: textColor,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.tune_rounded),
            tooltip: 'Configurar avisos',
            onPressed: _openPreferencesDialog,
          ),
          PopupMenuButton<String>(
            icon: Icon(Icons.more_vert_rounded, color: textColor),
            onSelected: (val) async {
              if (val == 'read_all') {
                await widget.state.markAllNotificationsAsRead();
              } else if (val == 'clear_all') {
                final confirm = await showDialog<bool>(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    title: const Text('Limpiar notificaciones'),
                    content: const Text('¿Deseas eliminar todas las notificaciones?'),
                    actions: [
                      TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
                      FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Eliminar')),
                    ],
                  ),
                );
                if (confirm == true) {
                  await widget.state.clearAllNotifications();
                }
              }
            },
            itemBuilder: (ctx) => [
              const PopupMenuItem(
                value: 'read_all',
                child: Row(
                  children: [
                    Icon(Icons.done_all_rounded, size: 18),
                    SizedBox(width: 8),
                    Text('Marcar todas como leídas'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'clear_all',
                child: Row(
                  children: [
                    Icon(Icons.delete_sweep_outlined, size: 18, color: Colors.red),
                    SizedBox(width: 8),
                    Text('Eliminar todas', style: TextStyle(color: Colors.red)),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: SafeArea(
        child: Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 720),
            child: Column(
              children: [
                // ==========================================
                // BARRA DE FILTROS & ESTADO
                // ==========================================
                Padding(
                  padding: const EdgeInsets.fromLTRB(18, 8, 18, 10),
                  child: Row(
                    children: [
                      _FilterTab(
                        label: 'Todas (${allList.length})',
                        selected: _selectedFilter == 0,
                        onTap: () => setState(() => _selectedFilter = 0),
                        isDark: isDark,
                      ),
                      const SizedBox(width: 8),
                      _FilterTab(
                        label: 'Pendientes ($unreadCount)',
                        selected: _selectedFilter == 1,
                        onTap: () => setState(() => _selectedFilter = 1),
                        isDark: isDark,
                        badgeColor: unreadCount > 0 ? Colors.red : null,
                      ),
                      const SizedBox(width: 8),
                      _FilterTab(
                        label: 'Leídas (${allList.length - unreadCount})',
                        selected: _selectedFilter == 2,
                        onTap: () => setState(() => _selectedFilter = 2),
                        isDark: isDark,
                      ),
                    ],
                  ),
                ),

                // ==========================================
                // LISTADO DE NOTIFICACIONES
                // ==========================================
                Expanded(
                  child: _loading
                      ? const Center(child: CircularProgressIndicator())
                      : filteredList.isEmpty
                          ? _EmptyNotificationsView(
                              filterIndex: _selectedFilter,
                              isDark: isDark,
                              textColor: textColor,
                              mutedColor: mutedColor,
                            )
                          : ListView.separated(
                              padding: const EdgeInsets.fromLTRB(18, 6, 18, 24),
                              itemCount: filteredList.length,
                              separatorBuilder: (_, __) => const SizedBox(height: 10),
                              itemBuilder: (context, idx) {
                                final notif = filteredList[idx];
                                final iconData = _iconForType(notif.type);
                                final iconColor = _colorForType(notif.type, isDark);
                                final iconBg = _bgForType(notif.type, isDark);

                                return Dismissible(
                                  key: Key(notif.id),
                                  direction: DismissDirection.endToStart,
                                  background: Container(
                                    alignment: Alignment.centerRight,
                                    padding: const EdgeInsets.only(right: 20),
                                    decoration: BoxDecoration(
                                      color: Colors.red.shade700,
                                      borderRadius: BorderRadius.circular(14),
                                    ),
                                    child: const Icon(Icons.delete_outline_rounded, color: Colors.white),
                                  ),
                                  onDismissed: (_) {
                                    widget.state.dismissNotification(notif.id);
                                  },
                                  child: Material(
                                    color: Colors.transparent,
                                    child: InkWell(
                                      borderRadius: BorderRadius.circular(14),
                                      onTap: () => _handleNotificationTap(notif),
                                      child: Container(
                                        padding: const EdgeInsets.all(14),
                                        decoration: BoxDecoration(
                                          color: cardBg,
                                          borderRadius: BorderRadius.circular(14),
                                          border: Border.all(
                                            color: notif.isRead
                                                ? borderColor
                                                : (isDark ? AppTheme.primaryDarkTheme : AppTheme.primary).withOpacity(.5),
                                            width: notif.isRead ? 1.0 : 1.5,
                                          ),
                                          boxShadow: notif.isRead
                                              ? null
                                              : [
                                                  BoxShadow(
                                                    color: AppTheme.primary.withOpacity(.06),
                                                    blurRadius: 6,
                                                    offset: const Offset(0, 2),
                                                  ),
                                                ],
                                        ),
                                        child: Row(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            // Icono temático
                                            Container(
                                              width: 42,
                                              height: 42,
                                              decoration: BoxDecoration(
                                                color: iconBg,
                                                borderRadius: BorderRadius.circular(12),
                                              ),
                                              child: Icon(iconData, color: iconColor, size: 22),
                                            ),
                                            const SizedBox(width: 12),

                                            // Contenido
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  Row(
                                                    children: [
                                                      Expanded(
                                                        child: Text(
                                                          notif.title,
                                                          style: TextStyle(
                                                            fontSize: 13.5,
                                                            fontWeight: notif.isRead ? FontWeight.w700 : FontWeight.w900,
                                                            color: textColor,
                                                          ),
                                                        ),
                                                      ),
                                                      if (!notif.isRead)
                                                        Container(
                                                          width: 8,
                                                          height: 8,
                                                          margin: const EdgeInsets.only(left: 6),
                                                          decoration: BoxDecoration(
                                                            color: isDark ? AppTheme.primaryDarkTheme : AppTheme.primary,
                                                            shape: BoxShape.circle,
                                                          ),
                                                        ),
                                                    ],
                                                  ),
                                                  const SizedBox(height: 4),
                                                  Text(
                                                    notif.body,
                                                    style: TextStyle(
                                                      fontSize: 12,
                                                      height: 1.35,
                                                      color: notif.isRead ? mutedColor : textColor.withOpacity(.85),
                                                    ),
                                                  ),
                                                  const SizedBox(height: 8),

                                                  // Badge de monto y fecha
                                                  Row(
                                                    children: [
                                                      if (notif.amount != null && notif.amount! > 0) ...[
                                                        Container(
                                                          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                                                          decoration: BoxDecoration(
                                                            color: isDark ? const Color(0xFF1E2D4A) : const Color(0xFFEAF3FF),
                                                            borderRadius: BorderRadius.circular(6),
                                                          ),
                                                          child: Text(
                                                            NotificationService.formatAmount(notif.amount!),
                                                            style: TextStyle(
                                                              fontSize: 11,
                                                              fontWeight: FontWeight.w800,
                                                              color: isDark ? AppTheme.primaryDarkTheme : AppTheme.primary,
                                                            ),
                                                          ),
                                                        ),
                                                        const SizedBox(width: 8),
                                                      ],
                                                      Text(
                                                        _formatNotificationDate(notif.scheduledDate),
                                                        style: TextStyle(fontSize: 10.5, color: mutedColor),
                                                      ),
                                                      const Spacer(),
                                                      if (!notif.isRead)
                                                        InkWell(
                                                          borderRadius: BorderRadius.circular(4),
                                                          onTap: () => widget.state.markNotificationAsRead(notif.id),
                                                          child: Padding(
                                                            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                                                            child: Text(
                                                              'Marcar leída',
                                                              style: TextStyle(
                                                                fontSize: 11,
                                                                fontWeight: FontWeight.w700,
                                                                color: isDark ? AppTheme.primaryDarkTheme : AppTheme.primary,
                                                              ),
                                                            ),
                                                          ),
                                                        ),
                                                    ],
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
                              },
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

class _FilterTab extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  final bool isDark;
  final Color? badgeColor;

  const _FilterTab({
    required this.label,
    required this.selected,
    required this.onTap,
    required this.isDark,
    this.badgeColor,
  });

  @override
  Widget build(BuildContext context) {
    final activeBg = isDark ? const Color(0xFF1E3A8A) : AppTheme.primary;
    final inactiveBg = isDark ? const Color(0xFF14213D) : Colors.white;
    final activeText = Colors.white;
    final inactiveText = isDark ? AppTheme.textDark : AppTheme.text;
    final borderColor = isDark ? AppTheme.borderDark : AppTheme.border;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
          decoration: BoxDecoration(
            color: selected ? activeBg : inactiveBg,
            borderRadius: BorderRadius.circular(20),
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
    );
  }
}

class _EmptyNotificationsView extends StatelessWidget {
  final int filterIndex;
  final bool isDark;
  final Color textColor;
  final Color mutedColor;

  const _EmptyNotificationsView({
    required this.filterIndex,
    required this.isDark,
    required this.textColor,
    required this.mutedColor,
  });

  @override
  Widget build(BuildContext context) {
    String message = 'No tienes notificaciones en este momento.';
    if (filterIndex == 1) {
      message = '¡Estás al día! No tienes notificaciones pendientes.';
    } else if (filterIndex == 2) {
      message = 'No tienes notificaciones en el historial de leídas.';
    }

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E2D4A) : const Color(0xFFEAF3FF),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.notifications_none_rounded,
                size: 38,
                color: isDark ? AppTheme.primaryDarkTheme : AppTheme.primary,
              ),
            ),
            const SizedBox(height: 18),
            Text(
              'Bandeja al día',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w900,
                color: textColor,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                height: 1.4,
                color: mutedColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
