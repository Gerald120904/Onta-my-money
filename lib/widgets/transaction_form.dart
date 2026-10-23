import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../core/theme/app_theme.dart';
import '../core/utils/formatters.dart';
import '../models/models.dart';

class TransactionForm extends StatefulWidget {
  final String type;
  final MoneyTransaction? transaction;
  final double availableBalance;

  const TransactionForm({
    super.key,
    required this.type,
    this.transaction,
    required this.availableBalance,
  });

  static Future<MoneyTransaction?> show(
    BuildContext context, {
    required String type,
    MoneyTransaction? transaction,
    required double availableBalance,
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
          ),
        );
      },
    );
  }

  @override
  State<TransactionForm> createState() =>
      _TransactionFormState();
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
          : transaction.amount.toStringAsFixed(0),
    );

    _descriptionController = TextEditingController(
      text: transaction?.description ?? '',
    );

    _category = transaction?.category ??
        (isIncome ? 'Salario' : 'Comida');

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
    final normalized = value
        .replaceAll('₡', '')
        .replaceAll(' ', '')
        .replaceAll(',', '.');

    return double.tryParse(normalized);
  }

  double? get _enteredAmount {
    return _parseAmount(
      _amountController.text,
    );
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

    return (_enteredAmount ?? 0) -
        _maximumAllowedExpense;
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

  Future<void> _showInsufficientBalanceDialog(
    double attemptedAmount,
  ) async {
    final available = _maximumAllowedExpense;

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

    final amount = _parseAmount(
      _amountController.text,
    );

    if (amount == null) return;

    if (!isIncome && amount > _maximumAllowedExpense) {
      await _showInsufficientBalanceDialog(
        amount,
      );
      return;
    }

    final transaction = MoneyTransaction(
      id: widget.transaction?.id ?? 'new',
      type: widget.type,
      category: _category,
      amount: amount,
      description:
          _descriptionController.text.trim(),
      date: _date,
      recognized: _recognized,
    );

    Navigator.pop(
      context,
      transaction,
    );
  }

  @override
  Widget build(BuildContext context) {
    final editing = widget.transaction != null;

    final accent = isIncome
        ? AppTheme.success
        : AppTheme.primary;

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
            autovalidateMode:
                AutovalidateMode.onUserInteraction,
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
                        color: isIncome
                            ? const Color(0xFFE9FFF1)
                            : const Color(0xFFEAF3FF),
                        borderRadius:
                            BorderRadius.circular(13),
                      ),
                      child: Icon(
                        isIncome
                            ? Icons
                                .account_balance_wallet_outlined
                            : Icons
                                .receipt_long_outlined,
                        color: accent,
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
                                ? isIncome
                                    ? 'Editar ingreso'
                                    : 'Editar gasto'
                                : isIncome
                                    ? 'Agregar ingreso'
                                    : 'Agregar gasto',
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight:
                                  FontWeight.w900,
                            ),
                          ),

                          const SizedBox(height: 3),

                          Text(
                            isIncome
                                ? 'Registrá dinero que recibiste.'
                                : 'Registrá dinero que gastaste.',
                            style: const TextStyle(
                              fontSize: 11,
                              color: AppTheme.muted,
                            ),
                          ),
                        ],
                      ),
                    ),

                    IconButton(
                      onPressed: () {
                        Navigator.pop(context);
                      },
                      icon: const Icon(
                        Icons.close_rounded,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 24),

                const _Label(
                  text: 'Monto',
                  requiredField: true,
                ),

                const SizedBox(height: 7),

                TextFormField(
                  controller: _amountController,
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
                    prefixText: '₡ ',
                    hintText: 'Ej. 85000',
                    prefixIcon: Icon(
                      Icons.payments_outlined,
                    ),
                  ),
                  validator: (value) {
                    if (value == null ||
                        value.trim().isEmpty) {
                      return 'Ingresá un monto';
                    }

                    final amount = _parseAmount(value);

                    if (amount == null) {
                      return 'Monto inválido';
                    }

                    if (amount <= 0) {
                      return 'El monto debe ser mayor a ₡0';
                    }

                    if (!isIncome &&
                        amount >
                            _maximumAllowedExpense) {
                      return 'El máximo disponible es ${money(_maximumAllowedExpense)}';
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
                        ? 'El monto ingresado supera el saldo disponible por ${money(_amountOverBalance)}.'
                        : 'Máximo disponible para este gasto: ${money(_maximumAllowedExpense)}.',
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 13,
                        vertical: 11,
                      ),
                      decoration: BoxDecoration(
                        color: _expenseExceedsBalance
                            ? const Color(0xFFFFF1F1)
                            : const Color(0xFFF0FFF6),
                        borderRadius:
                            BorderRadius.circular(13),
                        border: Border.all(
                          color: _expenseExceedsBalance
                              ? Colors.red.shade400
                              : const Color(0xFFBCEBCD),
                        ),
                      ),
                      child: Row(
                        crossAxisAlignment:
                            CrossAxisAlignment.start,
                        children: [
                          Icon(
                            _expenseExceedsBalance
                                ? Icons.warning_amber_rounded
                                : Icons
                                    .account_balance_wallet_outlined,
                            size: 19,
                            color: _expenseExceedsBalance
                                ? Colors.red.shade700
                                : AppTheme.success,
                          ),
                          const SizedBox(width: 9),
                          Expanded(
                            child: Column(
                              crossAxisAlignment:
                                  CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _expenseExceedsBalance
                                      ? 'Este monto supera tu saldo disponible'
                                      : 'Máximo disponible para este gasto',
                                  style: TextStyle(
                                    fontSize: 10.5,
                                    fontWeight:
                                        FontWeight.w700,
                                    color: _expenseExceedsBalance
                                        ? Colors.red.shade800
                                        : AppTheme.muted,
                                  ),
                                ),
                                if (_expenseExceedsBalance) ...[
                                  const SizedBox(height: 3),
                                  Text(
                                    'Reducí el gasto en ${money(_amountOverBalance)} o más para poder guardarlo.',
                                    style: TextStyle(
                                      fontSize: 9.5,
                                      height: 1.3,
                                      color:
                                          Colors.red.shade800,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            money(_maximumAllowedExpense),
                            style: TextStyle(
                              fontSize: 12.5,
                              fontWeight:
                                  FontWeight.w900,
                              color: _expenseExceedsBalance
                                  ? Colors.red.shade700
                                  : AppTheme.successDark,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],

                const SizedBox(height: 18),

                const _Label(
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
                  items: categories.map(
                    (category) {
                      return DropdownMenuItem(
                        value: category,
                        child: Text(
                          category,
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

                const _Label(
                  text: 'Descripción',
                ),

                const SizedBox(height: 7),

                TextFormField(
                  controller:
                      _descriptionController,
                  maxLines: 3,
                  maxLength: 120,
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

                const _Label(
                  text: 'Fecha',
                  requiredField: true,
                ),

                const SizedBox(height: 7),

                InkWell(
                  onTap: _selectDate,
                  borderRadius:
                      BorderRadius.circular(14),
                  child: InputDecorator(
                    decoration:
                        const InputDecoration(
                      prefixIcon: Icon(
                        Icons
                            .calendar_month_outlined,
                      ),
                      suffixIcon: Icon(
                        Icons
                            .chevron_right_rounded,
                      ),
                    ),
                    child: Text(
                      '${_date.day.toString().padLeft(2, '0')}/'
                      '${_date.month.toString().padLeft(2, '0')}/'
                      '${_date.year}',
                      style: const TextStyle(
                        fontWeight:
                            FontWeight.w700,
                      ),
                    ),
                  ),
                ),

                if (!isIncome) ...[
                  const SizedBox(height: 18),

                  Container(
                    padding:
                        const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color:
                          const Color(0xFFF8FBFF),
                      borderRadius:
                          BorderRadius.circular(14),
                      border: Border.all(
                        color: AppTheme.border,
                      ),
                    ),
                    child:
                        SwitchListTile.adaptive(
                      contentPadding:
                          EdgeInsets.zero,
                      value: _recognized,
                      title: const Text(
                        'Reconozco este movimiento',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight:
                              FontWeight.w800,
                        ),
                      ),
                      subtitle: Text(
                        _recognized
                            ? 'Movimiento reconocido'
                            : 'Movimiento no reconocido',
                        style: const TextStyle(
                          fontSize: 10.5,
                          color: AppTheme.muted,
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
                        child: const Text(
                          'Cancelar',
                        ),
                      ),
                    ),

                    const SizedBox(width: 12),

                    Expanded(
                      child: FilledButton.icon(
                        style:
                            FilledButton.styleFrom(
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

class _Label extends StatelessWidget {
  final String text;
  final bool requiredField;

  const _Label({
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