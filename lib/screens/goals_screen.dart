import 'package:flutter/material.dart';

import '../core/theme/app_theme.dart';
import '../core/utils/formatters.dart';
import '../models/models.dart';
import '../providers/app_state.dart';
import '../widgets/app_ui.dart';

class GoalsScreen extends StatelessWidget {
  final AppState state;

  const GoalsScreen({
    super.key,
    required this.state,
  });

  Future<void> form(BuildContext context, {SavingsGoal? item}) async {
    final key = GlobalKey<FormState>();
    final title = TextEditingController(text: item?.title ?? '');
    final target = TextEditingController(
      text: item == null
          ? ''
          : (item.targetAmount % 1 == 0
              ? item.targetAmount.toInt().toString()
              : item.targetAmount.toString()),
    );
    final saved = TextEditingController(
      text: item == null
          ? ''
          : (item.savedAmount % 1 == 0
              ? item.savedAmount.toInt().toString()
              : item.savedAmount.toString()),
    );

    final ok = await AppDialogs.form<bool>(
      context,
      title: item == null ? 'Nueva meta' : 'Editar meta',
      child: Form(
        key: key,
        child: Column(
          children: [
            AppField(
              controller: title,
              label: 'Nombre de la meta',
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Campo obligatorio' : null,
            ),
            AppField(
              controller: target,
              label: 'Monto objetivo',
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              validator: (v) =>
                  (double.tryParse(v ?? '') ?? 0) <= 0 ? 'Monto inválido' : null,
            ),
            AppField(
              controller: saved,
              label: 'Ahorro reservado',
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              validator: (v) =>
                  (double.tryParse(v ?? '') ?? -1) < 0 ? 'Monto inválido' : null,
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context, false),
                    child: const Text('Cancelar'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: FilledButton(
                    onPressed: () async {
                      if (!key.currentState!.validate()) return;
                      try {
                        await state.saveGoal(
                          SavingsGoal(
                            id: item?.id ?? 'new',
                            title: title.text.trim(),
                            targetAmount: double.parse(target.text),
                            savedAmount: double.parse(saved.text),
                            accountId:
                                item?.accountId ?? state.activeAccount?.id,
                          ),
                          create: item == null,
                        );
                        if (context.mounted) Navigator.pop(context, true);
                      } catch (e) {
                        if (context.mounted) {
                          AppAlerts.error(context, e.toString());
                        }
                      }
                    },
                    child: const Text('Guardar'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
    if (ok == true && context.mounted) {
      AppAlerts.success(context, 'Meta guardada');
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? AppTheme.textDark : AppTheme.text;
    final mutedColor = isDark ? AppTheme.mutedDark : AppTheme.muted;

    final content = ListenableBuilder(
      listenable: state,
      builder: (context, _) => ListView(
        padding: const EdgeInsets.fromLTRB(18, 16, 18, 30),
        children: [
          PageHeader(
            title: 'Ahorro',
            subtitle: 'Separá dinero para tus metas antes de gastarlo.',
            action: FilledButton.icon(
              style: FilledButton.styleFrom(
                minimumSize: const Size(0, 44),
              ),
              onPressed: () => form(context),
              icon: const Icon(Icons.add),
              label: const Text('Agregar'),
            ),
          ),
          const SizedBox(height: 20),
          if (state.goals.isEmpty)
            const EmptyState(
              title: 'Sin metas',
              message: 'Creá una meta de ahorro para reservar dinero.',
            )
          else
            LayoutBuilder(
              builder: (context, c) {
                final cols = c.maxWidth >= 800 ? 2 : 1;
                final width = (c.maxWidth - (cols - 1) * 12) / cols;
                return Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: state.goals.map((x) {
                    final p = x.targetAmount == 0
                        ? 0.0
                        : (x.savedAmount / x.targetAmount).clamp(0.0, 1.0);
                    return SizedBox(
                      width: width,
                      child: Card(
                        color: isDark ? AppTheme.surfaceDark : Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                          side: BorderSide(
                            color:
                                isDark ? AppTheme.borderDark : AppTheme.border,
                          ),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(18),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      x.title,
                                      style: TextStyle(
                                        fontSize: 17,
                                        fontWeight: FontWeight.w800,
                                        color: textColor,
                                      ),
                                    ),
                                  ),
                                  PopupMenuButton<String>(
                                    iconColor: mutedColor,
                                    onSelected: (v) async {
                                      if (v == 'edit') {
                                        form(context, item: x);
                                      } else {
                                        final ok = await AppDialogs.confirm(
                                          context,
                                          title: 'Eliminar meta',
                                          message:
                                              '¿Eliminar la meta ${x.title}?',
                                        );
                                        if (ok) {
                                          await state.deleteGoal(x.id);
                                          if (context.mounted) {
                                            AppAlerts.success(
                                                context, 'Meta eliminada');
                                          }
                                        }
                                      }
                                    },
                                    itemBuilder: (_) => const [
                                      PopupMenuItem(
                                          value: 'edit', child: Text('Editar')),
                                      PopupMenuItem(
                                          value: 'delete',
                                          child: Text('Eliminar')),
                                    ],
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '${money(x.savedAmount)} de ${money(x.targetAmount)}',
                                style: TextStyle(color: mutedColor),
                              ),
                              const SizedBox(height: 14),
                              LinearProgressIndicator(
                                value: p,
                                minHeight: 10,
                                borderRadius: BorderRadius.circular(99),
                                backgroundColor: isDark
                                    ? const Color(0xFF1E293B)
                                    : const Color(0xFFE2E8F0),
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  isDark
                                      ? const Color(0xFF60A5FA)
                                      : AppTheme.primary,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                '${(p * 100).round()}% completado',
                                style: TextStyle(
                                  fontWeight: FontWeight.w700,
                                  color: textColor,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                );
              },
            ),
        ],
      ),
    );

    return Scaffold(
      backgroundColor: isDark ? AppTheme.backgroundDark : AppTheme.background,
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(Icons.arrow_back_rounded, color: textColor),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'Ahorro',
          style: TextStyle(
            fontWeight: FontWeight.w900,
            color: textColor,
          ),
        ),
        backgroundColor: isDark ? AppTheme.surfaceDark : AppTheme.background,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
      ),
      body: SafeArea(
        child: Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 760),
            child: content,
          ),
        ),
      ),
    );
  }
}
