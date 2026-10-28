import 'package:flutter/material.dart';

import '../core/theme/app_theme.dart';
import '../core/utils/formatters.dart';
import '../models/models.dart';
import '../providers/app_state.dart';
import '../widgets/app_ui.dart';

class CommitmentsScreen extends StatelessWidget {
  final AppState state;

  const CommitmentsScreen({
    super.key,
    required this.state,
  });

  Future<void> form(BuildContext context, {Commitment? item}) async {
    final key = GlobalKey<FormState>();
    final title = TextEditingController(text: item?.title ?? '');
    final amount = TextEditingController(
      text: item == null
          ? ''
          : (item.amount % 1 == 0
              ? item.amount.toInt().toString()
              : item.amount.toString()),
    );
    DateTime due = item?.dueDate ?? DateTime.now().add(const Duration(days: 7));
    String status = item?.status ?? 'pending';

    final ok = await AppDialogs.form<bool>(
      context,
      title: item == null ? 'Nuevo compromiso' : 'Editar compromiso',
      child: StatefulBuilder(
        builder: (context, setLocal) => Form(
          key: key,
          child: Column(
            children: [
              AppField(
                controller: title,
                label: 'Nombre',
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Campo obligatorio' : null,
              ),
              AppField(
                controller: amount,
                label: 'Monto',
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                validator: (v) =>
                    (double.tryParse(v ?? '') ?? 0) <= 0 ? 'Monto inválido' : null,
              ),
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Fecha de pago'),
                subtitle: Text(shortDate(due)),
                trailing: const Icon(Icons.calendar_month),
                onTap: () async {
                  final picked = await showDatePicker(
                    context: context,
                    firstDate:
                        DateTime.now().subtract(const Duration(days: 365)),
                    lastDate: DateTime.now().add(const Duration(days: 3650)),
                    initialDate: due,
                  );
                  if (picked != null) setLocal(() => due = picked);
                },
              ),
              DropdownButtonFormField<String>(
                value: status,
                decoration: const InputDecoration(labelText: 'Estado'),
                items: const [
                  DropdownMenuItem(value: 'pending', child: Text('Pendiente')),
                  DropdownMenuItem(value: 'paid', child: Text('Pagado')),
                ],
                onChanged: (v) => setLocal(() => status = v!),
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
                          await state.saveCommitment(
                            Commitment(
                              id: item?.id ?? 'new',
                              title: title.text.trim(),
                              amount: double.parse(amount.text),
                              dueDate: due,
                              status: status,
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
      ),
    );
    if (ok == true && context.mounted) {
      AppAlerts.success(context, 'Compromiso guardado');
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? AppTheme.textDark : AppTheme.text;
    final mutedColor = isDark ? AppTheme.mutedDark : AppTheme.muted;

    return Scaffold(
      backgroundColor: isDark ? AppTheme.backgroundDark : AppTheme.background,
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(Icons.arrow_back_rounded, color: textColor),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'Dinero comprometido',
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
            child: ListenableBuilder(
              listenable: state,
              builder: (context, _) => ListView(
                padding: const EdgeInsets.fromLTRB(18, 16, 18, 30),
                children: [
                  PageHeader(
                    title: 'Compromisos',
                    subtitle: 'Pagos que no deberías tocar del dinero disponible.',
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
                  if (state.commitments.isEmpty)
                    const EmptyState(
                      title: 'Sin compromisos',
                      message: 'No tenés pagos pendientes registrados.',
                    )
                  else
                    ...state.commitments.map(
                      (x) => Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: Card(
                          color: isDark ? AppTheme.surfaceDark : Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                            side: BorderSide(
                              color: isDark ? AppTheme.borderDark : AppTheme.border,
                            ),
                          ),
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundColor: x.status == 'paid'
                                  ? (isDark
                                      ? const Color(0xFF14532D)
                                      : const Color(0xFFE3FBEF))
                                  : (isDark
                                      ? const Color(0xFF1E3A8A)
                                      : const Color(0xFFEDF4FF)),
                              child: Icon(
                                x.status == 'paid' ? Icons.check : Icons.schedule,
                                color: x.status == 'paid'
                                    ? (isDark
                                        ? const Color(0xFF4ADE80)
                                        : AppTheme.success)
                                    : (isDark
                                        ? const Color(0xFF60A5FA)
                                        : AppTheme.primary),
                              ),
                            ),
                            title: Text(
                              x.title,
                              style: TextStyle(
                                fontWeight: FontWeight.w800,
                                color: textColor,
                              ),
                            ),
                            subtitle: Text(
                              'Vence ${shortDate(x.dueDate)} • ${x.status == 'paid' ? 'Pagado' : 'Pendiente'}',
                              style: TextStyle(color: mutedColor),
                            ),
                            trailing: Wrap(
                              crossAxisAlignment: WrapCrossAlignment.center,
                              children: [
                                Text(
                                  money(x.amount),
                                  style: TextStyle(
                                    fontWeight: FontWeight.w900,
                                    color: textColor,
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
                                        title: 'Eliminar compromiso',
                                        message:
                                            '¿Eliminar ${x.title} por ${money(x.amount)}?',
                                      );
                                      if (ok) {
                                        await state.deleteCommitment(x.id);
                                        if (context.mounted) {
                                          AppAlerts.success(
                                              context, 'Compromiso eliminado');
                                        }
                                      }
                                    }
                                  },
                                  itemBuilder: (_) => const [
                                    PopupMenuItem(value: 'edit', child: Text('Editar')),
                                    PopupMenuItem(
                                        value: 'delete', child: Text('Eliminar')),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
