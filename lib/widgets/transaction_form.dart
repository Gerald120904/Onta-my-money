import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../core/theme/app_theme.dart';
import '../core/utils/formatters.dart';
import '../models/models.dart';

class TransactionForm extends StatefulWidget {
  final String type;
  final MoneyTransaction? transaction;
  final double availableBalance;
  final String currency;

  const TransactionForm({
    super.key,
    required this.type,
    this.transaction,
    required this.availableBalance,
    this.currency = 'CRC',
  });

  static Future<MoneyTransaction?> show(
    BuildContext context, {
    required String type,
    MoneyTransaction? transaction,
    required double availableBalance,
    String currency = 'CRC',
  }) {
    return showDialog<MoneyTransaction>(
      context: context,
      barrierDismissible: true,
      builder: (dialogContext) {
        return CallbackShortcuts(
          bindings: <ShortcutActivator, VoidCallback>{
            const SingleActivator(
              LogicalKeyboardKey.escape,
            ): () {
              Navigator.of(dialogContext).maybePop();
            },
          },
          child: TransactionForm(
            type: type,
            transaction: transaction,
            availableBalance: availableBalance,
            currency: currency,
          ),
        );
      },
    );
  }

  @override
  State<TransactionForm> createState() => _TransactionFormState();
}

class _TransactionFormState extends State<TransactionForm> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _amountController;
  late final TextEditingController _descriptionController;

  late String _category;
  late DateTime _date;

  bool _recognized = true;

  bool get isIncome => widget.type == 'income';

  List<String> get categories {
    if (isIncome) {
      return [
        'Salario',
        'Beca',
        'Ayuda familiar',
        'Trabajo extra',
        'Venta',
        'Transferencia',
        'Otros',
      ];
    }

    return [
      'Comida',
      'Transporte',
      'Compras',
      'Ocio',
      'Servicios',
      'Salud',
      'Educación',
      'Otros',
    ];
  }

  @override
  void initState() {
    super.initState();

    final transaction = widget.transaction;

    _amountController = TextEditingController(
      text: transaction == null
          ? ''
          : (widget.currency == 'CRC'
              ? transaction.amount.toStringAsFixed(0)
              : transaction.amount.toStringAsFixed(2)),
    );

    _descriptionController = TextEditingController(
      text: transaction?.description ?? '',
    );

    _category = transaction?.category ?? (isIncome ? 'Salario' : 'Comida');

    if (!categories.contains(_category)) {
      _category = 'Otros';
    }

    _date = transaction?.date ?? DateTime.now();
    _recognized = transaction?.recognized ?? true;
  }

  @override
  void dispose() {
    _amountController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  double? _parseAmount(String value) {
    final symbol = CurrencyFormatter.symbolFor(widget.currency);
    final normalized = value
        .replaceAll('₡', '')
        .replaceAll(r'$', '')
        .replaceAll('€', '')
        .replaceAll(symbol, '')
        .replaceAll(widget.currency, '')
        .replaceAll(' ', '')
        .replaceAll(',', '.');

    return double.tryParse(normalized);
  }

  double? get _enteredAmount {
    return _parseAmount(_amountController.text);
  }

  bool get _expenseExceedsBalance {
    if (isIncome) return false;

    final amount = _enteredAmount;
    if (amount == null || amount <= 0) {
      return false;
    }

    return amount > _maximumAllowedExpense;
  }

  double get _amountOverBalance {
    if (!_expenseExceedsBalance) {
      return 0;
    }

    return (_enteredAmount ?? 0) - _maximumAllowedExpense;
  }

  double get _maximumAllowedExpense {
    var available = widget.availableBalance;

    // Si se edita un gasto existente, ese monto ya fue descontado
    // del saldo actual. Se devuelve para calcular el máximo real.
    if (!isIncome &&
        widget.transaction != null &&
        widget.transaction!.type.toLowerCase() == 'expense') {
      available += widget.transaction!.amount;
    }

    if (available < 0) {
      return 0;
    }

    return available;
  }

  String _format(double amount) {
    return CurrencyFormatter.format(amount, currency: widget.currency);
  }

  Future<void> _showInsufficientBalanceDialog(
    double attemptedAmount,
  ) async {
    final available = _maximumAllowedExpense;
    final isDark = AppTheme.isDarkMode(context);
    final textColor = AppTheme.textColor(context);
    final mutedColor = AppTheme.mutedColor(context);
    final surfaceColor = AppTheme.cardBg(context);
    final cardColor = AppTheme.tintPrimary(context);
    final borderColor = AppTheme.borderColor(context);
    final iconBg = AppTheme.tintError(context);

    await showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (dialogContext) {
        return CallbackShortcuts(
          bindings: <ShortcutActivator, VoidCallback>{
            const SingleActivator(
              LogicalKeyboardKey.escape,
            ): () {
              Navigator.of(dialogContext).maybePop();
            },
          },
          child: AlertDialog(
            backgroundColor: surfaceColor,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(22),
            ),
            titlePadding: const EdgeInsets.fromLTRB(22, 22, 22, 8),
            contentPadding: const EdgeInsets.fromLTRB(22, 4, 22, 8),
            actionsPadding: const EdgeInsets.fromLTRB(22, 8, 22, 20),
            title: Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: iconBg,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.account_balance_wallet_outlined,
                    color:
                        isDark ? const Color(0xFFEF4444) : Colors.red.shade700,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Saldo insuficiente',
                    style: TextStyle(
                      fontSize: 19,
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
                  '${_format(available)}. No podés registrar un gasto '
                  'mayor a ese monto.',
                  style: TextStyle(
                    fontSize: 12.5,
                    height: 1.5,
                    color: textColor,
                  ),
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: cardColor,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: borderColor,
                    ),
                  ),
                  child: Column(
                    children: [
                      _AmountDialogRow(
                        label: 'Saldo disponible',
                        value: _format(available),
                        valueColor: isDark
                            ? const Color(0xFF34D399)
                            : AppTheme.successDark,
                        labelColor: mutedColor,
                      ),
                      const SizedBox(height: 10),
                      _AmountDialogRow(
                        label: 'Monto intentado',
                        value: _format(attemptedAmount),
                        valueColor: isDark
                            ? const Color(0xFFF87171)
                            : Colors.red.shade700,
                        labelColor: mutedColor,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Reducí el monto del gasto para continuar.',
                  style: TextStyle(
                    fontSize: 11,
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
          ),
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
    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }

    final amount = _parseAmount(_amountController.text);
    if (amount == null) return;

    if (!isIncome && amount > _maximumAllowedExpense) {
      await _showInsufficientBalanceDialog(amount);
      return;
    }

    final transaction = MoneyTransaction(
      id: widget.transaction?.id ?? 'new',
      type: widget.type,
      category: _category,
      amount: amount,
      description: _descriptionController.text.trim(),
      date: _date,
      recognized: _recognized,
    );

    Navigator.pop(context, transaction);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = AppTheme.isDarkMode(context);
    final textColor = AppTheme.textColor(context);
    final mutedColor = AppTheme.mutedColor(context);
    final surfaceColor = AppTheme.cardBg(context);
    final borderColor = AppTheme.borderColor(context);
    final editing = widget.transaction != null;

    final accent = isIncome
        ? AppTheme.successColor(context)
        : AppTheme.primaryColor(context);

    final currencySymbol = CurrencyFormatter.symbolFor(widget.currency);

    return Dialog(
      backgroundColor: surfaceColor,
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
            autovalidateMode: AutovalidateMode.onUserInteraction,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: isIncome
                            ? (isDark
                                ? const Color(0xFF143825)
                                : const Color(0xFFE9FFF1))
                            : (isDark
                                ? const Color(0xFF162A45)
                                : const Color(0xFFEAF3FF)),
                        borderRadius: BorderRadius.circular(13),
                      ),
                      child: Icon(
                        isIncome
                            ? Icons.account_balance_wallet_outlined
                            : Icons.receipt_long_outlined,
                        color: accent,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            editing
                                ? isIncome
                                    ? 'Editar ingreso'
                                    : 'Editar gasto'
                                : isIncome
                                    ? 'Agregar ingreso'
                                    : 'Agregar gasto',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w900,
                              color: textColor,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            isIncome
                                ? 'Registrá dinero que recibiste en ${widget.currency}.'
                                : 'Registrá dinero que gastaste en ${widget.currency}.',
                            style: TextStyle(
                              fontSize: 11,
                              color: mutedColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      tooltip: 'Cerrar',
                      onPressed: () {
                        Navigator.pop(context);
                      },
                      icon: Icon(
                        Icons.close_rounded,
                        color: textColor,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                _Label(
                  text: 'Monto',
                  requiredField: true,
                  color: textColor,
                ),
                const SizedBox(height: 7),
                TextFormField(
                  controller: _amountController,
                  style: TextStyle(color: textColor),
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(
                      RegExp(r'[0-9.,]'),
                    ),
                  ],
                  decoration: InputDecoration(
                    prefixText: '$currencySymbol ',
                    prefixStyle: TextStyle(
                      fontWeight: FontWeight.w700,
                      color: textColor,
                    ),
                    hintText:
                        widget.currency == 'CRC' ? 'Ej. 85000' : 'Ej. 150',
                    prefixIcon: const Icon(
                      Icons.payments_outlined,
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Ingresá un monto';
                    }

                    final amount = _parseAmount(value);
                    if (amount == null) {
                      return 'Monto inválido';
                    }

                    if (amount <= 0) {
                      return 'El monto debe ser mayor a ${_format(0)}';
                    }

                    if (!isIncome && amount > _maximumAllowedExpense) {
                      return 'El máximo disponible es ${_format(_maximumAllowedExpense)}';
                    }

                    return null;
                  },
                  onChanged: (_) {
                    setState(() {});
                  },
                ),
                if (!isIncome) ...[
                  const SizedBox(height: 10),
                  Semantics(
                    liveRegion: true,
                    label: _expenseExceedsBalance
                        ? 'El monto ingresado supera el saldo disponible por ${_format(_amountOverBalance)}.'
                        : 'Máximo disponible para este gasto: ${_format(_maximumAllowedExpense)}.',
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 13,
                        vertical: 11,
                      ),
                      decoration: BoxDecoration(
                        color: _expenseExceedsBalance
                            ? (isDark
                                ? const Color(0xFF3B1818)
                                : const Color(0xFFFFF1F1))
                            : (isDark
                                ? const Color(0xFF143021)
                                : const Color(0xFFF0FFF6)),
                        borderRadius: BorderRadius.circular(13),
                        border: Border.all(
                          color: _expenseExceedsBalance
                              ? (isDark
                                  ? const Color(0xFFEF4444)
                                  : Colors.red.shade400)
                              : (isDark
                                  ? const Color(0xFF10B981)
                                  : const Color(0xFFBCEBCD)),
                        ),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(
                            _expenseExceedsBalance
                                ? Icons.warning_amber_rounded
                                : Icons.account_balance_wallet_outlined,
                            size: 19,
                            color: _expenseExceedsBalance
                                ? (isDark
                                    ? const Color(0xFFF87171)
                                    : Colors.red.shade700)
                                : (isDark
                                    ? const Color(0xFF34D399)
                                    : AppTheme.success),
                          ),
                          const SizedBox(width: 9),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _expenseExceedsBalance
                                      ? 'Este monto supera tu saldo disponible'
                                      : 'Máximo disponible para este gasto',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    color: _expenseExceedsBalance
                                        ? (isDark
                                            ? const Color(0xFFFCA5A5)
                                            : Colors.red.shade800)
                                        : mutedColor,
                                  ),
                                ),
                                if (_expenseExceedsBalance) ...[
                                  const SizedBox(height: 3),
                                  Text(
                                    'Reducí el gasto en ${_format(_amountOverBalance)} o más para poder guardarlo.',
                                    style: TextStyle(
                                      fontSize: 10,
                                      height: 1.3,
                                      color: isDark
                                          ? const Color(0xFFFCA5A5)
                                          : Colors.red.shade800,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            _format(_maximumAllowedExpense),
                            style: TextStyle(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w900,
                              color: _expenseExceedsBalance
                                  ? (isDark
                                      ? const Color(0xFFF87171)
                                      : Colors.red.shade700)
                                  : (isDark
                                      ? const Color(0xFF34D399)
                                      : AppTheme.successDark),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 18),
                _Label(
                  text: 'Categoría',
                  requiredField: true,
                  color: textColor,
                ),
                const SizedBox(height: 7),
                DropdownButtonFormField<String>(
                  value: _category,
                  isExpanded: true,
                  dropdownColor: surfaceColor,
                  style: TextStyle(color: textColor),
                  decoration: const InputDecoration(
                    prefixIcon: Icon(
                      Icons.category_outlined,
                    ),
                  ),
                  items: categories.map(
                    (category) {
                      return DropdownMenuItem(
                        value: category,
                        child: Text(
                          category,
                          style: TextStyle(color: textColor),
                        ),
                      );
                    },
                  ).toList(),
                  onChanged: (value) {
                    if (value == null) return;
                    setState(() {
                      _category = value;
                    });
                  },
                ),
                const SizedBox(height: 18),
                _Label(
                  text: 'Descripción',
                  color: textColor,
                ),
                const SizedBox(height: 7),
                TextFormField(
                  controller: _descriptionController,
                  maxLines: 3,
                  maxLength: 120,
                  style: TextStyle(color: textColor),
                  decoration: InputDecoration(
                    hintText: isIncome
                        ? 'Ej. Pago semanal, beca...'
                        : 'Ej. Almuerzo, gasolina...',
                    prefixIcon: const Icon(
                      Icons.notes_rounded,
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                _Label(
                  text: 'Fecha',
                  requiredField: true,
                  color: textColor,
                ),
                const SizedBox(height: 7),
                InkWell(
                  onTap: _selectDate,
                  borderRadius: BorderRadius.circular(14),
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
                      '${_date.day.toString().padLeft(2, '0')}/'
                      '${_date.month.toString().padLeft(2, '0')}/'
                      '${_date.year}',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        color: textColor,
                      ),
                    ),
                  ),
                ),
                if (!isIncome) ...[
                  const SizedBox(height: 18),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: isDark
                          ? const Color(0xFF16233B)
                          : const Color(0xFFF8FBFF),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: borderColor,
                      ),
                    ),
                    child: SwitchListTile.adaptive(
                      contentPadding: EdgeInsets.zero,
                      value: _recognized,
                      title: Text(
                        'Reconozco este movimiento',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                          color: textColor,
                        ),
                      ),
                      subtitle: Text(
                        _recognized
                            ? 'Movimiento reconocido'
                            : 'Movimiento no reconocido',
                        style: TextStyle(
                          fontSize: 11,
                          color: mutedColor,
                        ),
                      ),
                      onChanged: (value) {
                        setState(() {
                          _recognized = value;
                        });
                      },
                    ),
                  ),
                ],
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () {
                          Navigator.pop(context);
                        },
                        child: const Text('Cancelar'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: FilledButton.icon(
                        style: FilledButton.styleFrom(
                          backgroundColor: accent,
                        ),
                        onPressed: _save,
                        icon: const Icon(
                          Icons.save_outlined,
                        ),
                        label: Text(
                          editing
                              ? 'Guardar'
                              : isIncome
                                  ? 'Agregar ingreso'
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
}

class _AmountDialogRow extends StatelessWidget {
  final String label;
  final String value;
  final Color valueColor;
  final Color? labelColor;

  const _AmountDialogRow({
    required this.label,
    required this.value,
    required this.valueColor,
    this.labelColor,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              fontSize: 13,
              color: labelColor ?? AppTheme.mutedColor(context),
            ),
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 13.5,
            fontWeight: FontWeight.w900,
            color: valueColor,
          ),
        ),
      ],
    );
  }
}

class _Label extends StatelessWidget {
  final String text;
  final bool requiredField;
  final Color? color;

  const _Label({
    required this.text,
    this.requiredField = false,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          text,
          style: TextStyle(
            fontSize: 12.5,
            fontWeight: FontWeight.w800,
            color: color,
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
