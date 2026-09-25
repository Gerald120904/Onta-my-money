import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../core/theme/app_theme.dart';
import '../core/utils/formatters.dart';
import '../models/models.dart';

class ExpenseForm extends StatefulWidget {
  final MoneyTransaction? expense;
  final double availableBalance;

  const ExpenseForm({
    super.key,
    this.expense,
    required this.availableBalance,
  });

  static Future<MoneyTransaction?> show(
    BuildContext context, {
    MoneyTransaction? expense,
    required double availableBalance,
  }) {
    return showDialog<MoneyTransaction>(
      context: context,
      barrierDismissible: false,
      builder: (_) {
        return ExpenseForm(
          expense: expense,
          availableBalance: availableBalance,
        );
      },
    );
  }

  @override
  State<ExpenseForm> createState() => _ExpenseFormState();
}

class _ExpenseFormState extends State<ExpenseForm> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _amountController;
  late final TextEditingController _descriptionController;

  late String _category;
  late DateTime _date;
  late bool _recognized;

  bool _saving = false;

  static const _categories = [
    'Comida',
    'Transporte',
    'Compras',
    'Ocio',
    'Servicios',
    'Salud',
    'Educación',
    'Otros',
  ];

  @override
  void initState() {
    super.initState();

    final expense = widget.expense;

    _amountController = TextEditingController(
      text: expense == null
          ? ''
          : expense.amount.toStringAsFixed(0),
    );

    _descriptionController = TextEditingController(
      text: expense?.description ?? '',
    );

    _category = expense?.category ?? 'Comida';

    if (!_categories.contains(_category)) {
      _category = 'Otros';
    }

    _date = expense?.date ?? DateTime.now();

    _recognized = expense?.recognized ?? true;
  }

  @override
  void dispose() {
    _amountController.dispose();
    _descriptionController.dispose();

    super.dispose();
  }

  double? _parseAmount(String value) {
    final normalized = value
        .replaceAll('₡', '')
        .replaceAll(' ', '')
        .replaceAll(',', '.');

    return double.tryParse(normalized);
  }

  double get _maximumAllowedExpense {
    var available = widget.availableBalance;

    // Si se está editando un gasto, el monto anterior ya está
    // descontado del saldo actual. Se devuelve temporalmente
    // para calcular correctamente el máximo permitido.
    if (widget.expense != null) {
      available += widget.expense!.amount;
    }

    if (available < 0) {
      return 0;
    }

    return available;
  }

  Future<void> _showInsufficientBalanceDialog(
    double attemptedAmount,
  ) async {
    final available = _maximumAllowedExpense;

    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(22),
          ),
          titlePadding: const EdgeInsets.fromLTRB(
            22,
            22,
            22,
            8,
          ),
          contentPadding: const EdgeInsets.fromLTRB(
            22,
            4,
            22,
            8,
          ),
          actionsPadding: const EdgeInsets.fromLTRB(
            22,
            8,
            22,
            20,
          ),
          title: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: const Color(0xFFFFECEC),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.account_balance_wallet_outlined,
                  color: Colors.red.shade700,
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'Saldo insuficiente',
                  style: TextStyle(
                    fontSize: 19,
                    fontWeight: FontWeight.w900,
                    color: AppTheme.text,
                  ),
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Lo sentimos, tu saldo disponible es de '
                '${money(available)}. No podés registrar un gasto '
                'mayor a ese monto.',
                style: const TextStyle(
                  fontSize: 12.5,
                  height: 1.5,
                  color: AppTheme.text,
                ),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFD),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: AppTheme.border,
                  ),
                ),
                child: Column(
                  children: [
                    _AmountDialogRow(
                      label: 'Saldo disponible',
                      value: money(available),
                      valueColor: AppTheme.successDark,
                    ),
                    const SizedBox(height: 10),
                    _AmountDialogRow(
                      label: 'Monto intentado',
                      value: money(attemptedAmount),
                      valueColor: Colors.red.shade700,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'Reducí el monto del gasto para continuar.',
                style: TextStyle(
                  fontSize: 10.5,
                  color: AppTheme.muted,
                ),
              ),
            ],
          ),
          actions: [
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () {
                  Navigator.of(dialogContext).pop();
                },
                child: const Text(
                  'Entendido',
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _selectDate() async {
    final selected = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2020),
      lastDate: DateTime(2035),
      helpText: 'Seleccionar fecha',
      cancelText: 'Cancelar',
      confirmText: 'Seleccionar',
    );

    if (selected == null) return;

    setState(() {
      _date = selected;
    });
  }

  Future<void> _save() async {
    final valid = _formKey.currentState?.validate() ?? false;

    if (!valid) return;

    final amount = _parseAmount(
      _amountController.text,
    );

    if (amount == null) return;

    if (amount > _maximumAllowedExpense) {
      await _showInsufficientBalanceDialog(
        amount,
      );
      return;
    }

    setState(() {
      _saving = true;
    });

    final expense = MoneyTransaction(
      id: widget.expense?.id ?? 'new',
      type: 'expense',
      category: _category,
      amount: amount,
      description: _descriptionController.text.trim(),
      date: _date,
      recognized: _recognized,
    );

    Navigator.of(context).pop(
      expense,
    );
  }

  @override
  Widget build(BuildContext context) {
    final editing = widget.expense != null;

    return Dialog(
      insetPadding: const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 24,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
      ),
      clipBehavior: Clip.antiAlias,
      child: ConstrainedBox(
        constraints: const BoxConstraints(
          maxWidth: 520,
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(22),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: const Color(0xFFEAF3FF),
                        borderRadius:
                            BorderRadius.circular(13),
                      ),
                      child: const Icon(
                        Icons.receipt_long_outlined,
                        color: AppTheme.primary,
                      ),
                    ),

                    const SizedBox(width: 12),

                    Expanded(
                      child: Column(
                        crossAxisAlignment:
                            CrossAxisAlignment.start,
                        children: [
                          Text(
                            editing
                                ? 'Editar gasto'
                                : 'Agregar gasto',
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight:
                                  FontWeight.w900,
                              color: AppTheme.text,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            editing
                                ? 'Actualizá la información del movimiento.'
                                : 'Registrá un nuevo movimiento.',
                            style: const TextStyle(
                              fontSize: 11.5,
                              color: AppTheme.muted,
                            ),
                          ),
                        ],
                      ),
                    ),

                    IconButton(
                      tooltip: 'Cerrar',
                      onPressed: _saving
                          ? null
                          : () {
                              Navigator.pop(context);
                            },
                      icon: const Icon(
                        Icons.close_rounded,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 24),

                const _FieldLabel(
                  text: 'Monto',
                  requiredField: true,
                ),

                const SizedBox(height: 7),

                TextFormField(
                  controller: _amountController,
                  autofocus: !editing,
                  keyboardType:
                      const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(
                      RegExp(r'[0-9.,]'),
                    ),
                  ],
                  decoration: const InputDecoration(
                    hintText: 'Ej. 4500',
                    prefixText: '₡ ',
                    prefixIcon: Icon(
                      Icons.payments_outlined,
                    ),
                  ),
                  validator: (value) {
                    if (value == null ||
                        value.trim().isEmpty) {
                      return 'Ingresá el monto del gasto';
                    }

                    final amount = _parseAmount(value);

                    if (amount == null) {
                      return 'Ingresá un monto válido';
                    }

                    if (amount <= 0) {
                      return 'El monto debe ser mayor a ₡0';
                    }

                    if (amount > 999999999) {
                      return 'El monto ingresado es demasiado alto';
                    }

                    return null;
                  },
                ),

                const SizedBox(height: 10),

                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 13,
                    vertical: 11,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF0FFF6),
                    borderRadius: BorderRadius.circular(13),
                    border: Border.all(
                      color: const Color(0xFFBCEBCD),
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.account_balance_wallet_outlined,
                        size: 19,
                        color: AppTheme.success,
                      ),
                      const SizedBox(width: 9),
                      const Expanded(
                        child: Text(
                          'Máximo disponible para este gasto',
                          style: TextStyle(
                            fontSize: 10.5,
                            color: AppTheme.muted,
                          ),
                        ),
                      ),
                      Text(
                        money(_maximumAllowedExpense),
                        style: const TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w900,
                          color: AppTheme.successDark,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 18),

                const _FieldLabel(
                  text: 'Categoría',
                  requiredField: true,
                ),

                const SizedBox(height: 7),

                DropdownButtonFormField<String>(
                  value: _category,
                  isExpanded: true,
                  decoration: const InputDecoration(
                    prefixIcon: Icon(
                      Icons.category_outlined,
                    ),
                  ),
                  items: _categories.map(
                    (category) {
                      return DropdownMenuItem(
                        value: category,
                        child: Row(
                          children: [
                            Icon(
                              _categoryIcon(category),
                              size: 20,
                              color: AppTheme.primary,
                            ),
                            const SizedBox(width: 10),
                            Text(category),
                          ],
                        ),
                      );
                    },
                  ).toList(),
                  onChanged: _saving
                      ? null
                      : (value) {
                          if (value == null) return;

                          setState(() {
                            _category = value;
                          });
                        },
                ),

                const SizedBox(height: 18),

                const _FieldLabel(
                  text: 'Descripción',
                ),

                const SizedBox(height: 7),

                TextFormField(
                  controller: _descriptionController,
                  maxLines: 3,
                  maxLength: 120,
                  decoration: const InputDecoration(
                    hintText:
                        'Ej. Almuerzo, supermercado, gasolina...',
                    alignLabelWithHint: true,
                    prefixIcon: Padding(
                      padding: EdgeInsets.only(
                        bottom: 55,
                      ),
                      child: Icon(
                        Icons.notes_rounded,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 10),

                const _FieldLabel(
                  text: 'Fecha',
                  requiredField: true,
                ),

                const SizedBox(height: 7),

                InkWell(
                  borderRadius: BorderRadius.circular(14),
                  onTap: _saving
                      ? null
                      : _selectDate,
                  child: InputDecorator(
                    decoration: const InputDecoration(
                      prefixIcon: Icon(
                        Icons.calendar_month_outlined,
                      ),
                      suffixIcon: Icon(
                        Icons.chevron_right_rounded,
                      ),
                    ),
                    child: Text(
                      shortDate(_date),
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 18),

                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 7,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FBFF),
                    borderRadius:
                        BorderRadius.circular(14),
                    border: Border.all(
                      color: AppTheme.border,
                    ),
                  ),
                  child: SwitchListTile.adaptive(
                    contentPadding: EdgeInsets.zero,
                    value: _recognized,
                    activeColor: AppTheme.primary,
                    title: const Text(
                      'Reconozco este movimiento',
                      style: TextStyle(
                        fontSize: 13.5,
                        fontWeight:
                            FontWeight.w800,
                      ),
                    ),
                    subtitle: Text(
                      _recognized
                          ? 'Este gasto fue identificado correctamente.'
                          : 'Se marcará para revisarlo después.',
                      style: const TextStyle(
                        fontSize: 10.5,
                        color: AppTheme.muted,
                      ),
                    ),
                    onChanged: _saving
                        ? null
                        : (value) {
                            setState(() {
                              _recognized = value;
                            });
                          },
                  ),
                ),

                const SizedBox(height: 24),

                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: _saving
                            ? null
                            : () {
                                Navigator.pop(context);
                              },
                        child: const Text(
                          'Cancelar',
                        ),
                      ),
                    ),

                    const SizedBox(width: 12),

                    Expanded(
                      child: FilledButton.icon(
                        onPressed:
                            _saving ? null : _save,
                        icon: const Icon(
                          Icons.save_outlined,
                          size: 19,
                        ),
                        label: Text(
                          editing
                              ? 'Guardar cambios'
                              : 'Agregar gasto',
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  static IconData _categoryIcon(
    String category,
  ) {
    switch (category.toLowerCase()) {
      case 'comida':
        return Icons.restaurant_rounded;

      case 'transporte':
        return Icons.directions_bus_rounded;

      case 'compras':
        return Icons.shopping_bag_outlined;

      case 'ocio':
        return Icons.sports_esports_outlined;

      case 'servicios':
        return Icons.receipt_long_outlined;

      case 'salud':
        return Icons.favorite_outline_rounded;

      case 'educación':
      case 'educacion':
        return Icons.school_outlined;

      default:
        return Icons.more_horiz_rounded;
    }
  }
}

class _AmountDialogRow extends StatelessWidget {
  final String label;
  final String value;
  final Color valueColor;

  const _AmountDialogRow({
    required this.label,
    required this.value,
    required this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 10.5,
              color: AppTheme.muted,
            ),
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w900,
            color: valueColor,
          ),
        ),
      ],
    );
  }
}

class _FieldLabel extends StatelessWidget {
  final String text;
  final bool requiredField;

  const _FieldLabel({
    required this.text,
    this.requiredField = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          text,
          style: const TextStyle(
            fontSize: 12.5,
            fontWeight: FontWeight.w800,
            color: AppTheme.text,
          ),
        ),
        if (requiredField)
          const Text(
            ' *',
            style: TextStyle(
              color: Colors.red,
              fontWeight: FontWeight.w900,
            ),
          ),
      ],
    );
  }
}