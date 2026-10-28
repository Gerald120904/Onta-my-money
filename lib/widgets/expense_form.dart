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
      text: expense == null ? '' : expense.amount.toStringAsFixed(0),
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
        .replaceAll('.', '')
        .replaceAll(',', '.')
        .trim();

    return double.tryParse(normalized);
  }

  double get _maximumAllowedExpense {
    final currentExpense = widget.expense?.amount ?? 0;
    return widget.availableBalance + currentExpense;
  }

  bool _validateBalance(double amount) {
    return amount <= _maximumAllowedExpense;
  }

  void _showInsufficientBalanceDialog(double attemptedAmount) {
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        final available = _maximumAllowedExpense;
        final isDark = AppTheme.isDarkMode(dialogContext);
        final cardBg = AppTheme.cardBg(dialogContext);
        final textColor = AppTheme.textColor(dialogContext);
        final mutedColor = AppTheme.mutedColor(dialogContext);
        final borderColor = AppTheme.borderColor(dialogContext);
        final errorColor = AppTheme.errorColor(dialogContext);
        final successColor = AppTheme.successColor(dialogContext);

        return AlertDialog(
          backgroundColor: cardBg,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: BorderSide(color: borderColor, width: 1.15),
          ),
          insetPadding:
              const EdgeInsets.symmetric(horizontal: 22, vertical: 24),
          titlePadding: const EdgeInsets.fromLTRB(22, 22, 22, 8),
          contentPadding: const EdgeInsets.fromLTRB(22, 4, 22, 8),
          actionsPadding: const EdgeInsets.fromLTRB(22, 8, 22, 20),
          title: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: AppTheme.tintError(dialogContext),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.account_balance_wallet_outlined,
                  color: errorColor,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Saldo insuficiente',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    color: textColor,
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
                style: TextStyle(
                  fontSize: 14,
                  height: 1.45,
                  color: textColor,
                ),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: isDark
                      ? AppTheme.backgroundDark
                      : const Color(0xFFF8FAFD),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: borderColor),
                ),
                child: Column(
                  children: [
                    _AmountDialogRow(
                      label: 'Saldo disponible',
                      value: money(available),
                      valueColor: successColor,
                    ),
                    const SizedBox(height: 10),
                    _AmountDialogRow(
                      label: 'Monto intentado',
                      value: money(attemptedAmount),
                      valueColor: errorColor,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Reducí el monto del gasto para continuar.',
                style: TextStyle(
                  fontSize: 12.5,
                  color: mutedColor,
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
                child: const Text('Entendido'),
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();

    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(now.year - 5),
      lastDate: DateTime(now.year + 5),
      locale: const Locale('es', 'CR'),
    );

    if (picked == null) return;

    setState(() {
      _date = picked;
    });
  }

  void _submit() {
    FocusScope.of(context).unfocus();

    final valid = _formKey.currentState?.validate() ?? false;
    if (!valid) return;

    final parsedAmount = _parseAmount(_amountController.text);

    if (parsedAmount == null || parsedAmount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Ingresá un monto válido mayor a 0.'),
        ),
      );
      return;
    }

    if (!_validateBalance(parsedAmount)) {
      _showInsufficientBalanceDialog(parsedAmount);
      return;
    }

    final id =
        widget.expense?.id ?? 'exp_${DateTime.now().microsecondsSinceEpoch}';

    final created = MoneyTransaction(
      id: id,
      type: 'expense',
      category: _category,
      amount: parsedAmount,
      description: _descriptionController.text.trim(),
      date: _date,
      recognized: _recognized,
    );

    Navigator.of(context).pop(created);
  }

  @override
  Widget build(BuildContext context) {
    final editing = widget.expense != null;
    final isDark = AppTheme.isDarkMode(context);
    final cardBg = AppTheme.cardBg(context);
    final textColor = AppTheme.textColor(context);
    final mutedColor = AppTheme.mutedColor(context);
    final borderColor = AppTheme.borderColor(context);
    final primaryColor = AppTheme.primaryColor(context);

    return Dialog(
      backgroundColor: cardBg,
      insetPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 24),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(22),
        side: BorderSide(color: borderColor, width: 1.15),
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(22),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: AppTheme.tintPrimary(context),
                        borderRadius: BorderRadius.circular(13),
                      ),
                      child: Icon(
                        Icons.receipt_long_outlined,
                        color: primaryColor,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            editing ? 'Editar gasto' : 'Agregar gasto',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w900,
                              color: textColor,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            editing
                                ? 'Actualizá la información del movimiento.'
                                : 'Registrá un nuevo movimiento.',
                            style: TextStyle(
                              fontSize: 13,
                              color: mutedColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      tooltip: 'Cerrar',
                      onPressed: _saving ? null : () => Navigator.pop(context),
                      icon: Icon(Icons.close_rounded, color: textColor),
                    ),
                  ],
                ),
                const SizedBox(height: 22),
                const _FieldLabel(text: 'Monto', requiredField: true),
                const SizedBox(height: 7),
                TextFormField(
                  controller: _amountController,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(
                        RegExp(r'^\d+[\.,]?\d{0,2}')),
                  ],
                  style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: textColor),
                  decoration: const InputDecoration(
                    prefixText: '₡ ',
                    hintText: '0',
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Ingresá el monto del gasto.';
                    }
                    final parsed = _parseAmount(value);
                    if (parsed == null || parsed <= 0) {
                      return 'El monto debe ser mayor a 0.';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 8),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
                  decoration: BoxDecoration(
                    color: AppTheme.tintSuccess(context),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: isDark
                          ? const Color(0xFF166534)
                          : const Color(0xFF9DEBC2),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.account_balance_wallet_outlined,
                        size: 19,
                        color: AppTheme.successColor(context),
                      ),
                      const SizedBox(width: 9),
                      Expanded(
                        child: Text(
                          'Máximo disponible para este gasto',
                          style: TextStyle(
                            fontSize: 12,
                            color: mutedColor,
                          ),
                        ),
                      ),
                      Text(
                        money(_maximumAllowedExpense),
                        style: TextStyle(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w900,
                          color: AppTheme.successColor(context),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 18),
                const _FieldLabel(text: 'Categoría', requiredField: true),
                const SizedBox(height: 7),
                DropdownButtonFormField<String>(
                  value: _category,
                  isExpanded: true,
                  dropdownColor: cardBg,
                  decoration: const InputDecoration(
                    prefixIcon: Icon(Icons.category_outlined),
                  ),
                  items: _categories.map((category) {
                    return DropdownMenuItem(
                      value: category,
                      child: Row(
                        children: [
                          Icon(
                            _categoryIcon(category),
                            size: 20,
                            color: primaryColor,
                          ),
                          const SizedBox(width: 10),
                          Text(category,
                              style: TextStyle(color: textColor, fontSize: 14)),
                        ],
                      ),
                    );
                  }).toList(),
                  onChanged: (value) {
                    if (value == null) return;
                    setState(() => _category = value);
                  },
                ),
                const SizedBox(height: 18),
                const _FieldLabel(text: 'Fecha', requiredField: true),
                const SizedBox(height: 7),
                InkWell(
                  borderRadius: BorderRadius.circular(14),
                  onTap: _pickDate,
                  child: InputDecorator(
                    decoration: const InputDecoration(
                      prefixIcon: Icon(Icons.calendar_today_outlined),
                      suffixIcon: Icon(Icons.arrow_drop_down_rounded),
                    ),
                    child: Text(
                      '${_date.day.toString().padLeft(2, '0')}/'
                      '${_date.month.toString().padLeft(2, '0')}/'
                      '${_date.year}',
                      style: TextStyle(color: textColor, fontSize: 14),
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                const _FieldLabel(text: 'Descripción opcional'),
                const SizedBox(height: 7),
                TextFormField(
                  controller: _descriptionController,
                  maxLines: 2,
                  style: TextStyle(color: textColor, fontSize: 14),
                  decoration: const InputDecoration(
                    hintText: 'Ej. Almuerzo con amigos',
                  ),
                ),
                const SizedBox(height: 14),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: borderColor),
                  ),
                  child: Row(
                    children: [
                      Checkbox(
                        value: _recognized,
                        activeColor: primaryColor,
                        onChanged: (val) {
                          setState(() => _recognized = val ?? true);
                        },
                      ),
                      Expanded(
                        child: Text(
                          'Reconozco este movimiento',
                          style: TextStyle(
                            fontSize: 13.5,
                            fontWeight: FontWeight.w700,
                            color: textColor,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 22),
                FilledButton(
                  onPressed: _saving ? null : _submit,
                  child: Text(editing ? 'Guardar cambios' : 'Registrar gasto'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  IconData _categoryIcon(String category) {
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
        return Icons.medical_services_outlined;
      case 'educación':
        return Icons.school_outlined;
      default:
        return Icons.payments_outlined;
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
    final mutedColor = AppTheme.mutedColor(context);

    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              fontSize: 13,
              color: mutedColor,
            ),
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 14,
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
    final textColor = AppTheme.textColor(context);

    return Row(
      children: [
        Text(
          text,
          style: TextStyle(
            fontSize: 13.5,
            fontWeight: FontWeight.w800,
            color: textColor,
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
