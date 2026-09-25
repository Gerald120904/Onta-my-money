import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../core/theme/app_theme.dart';
import '../core/utils/formatters.dart';
import '../models/models.dart';
import '../models/review_result.dart';
import '../providers/app_state.dart';
import '../widgets/period_selector.dart';
import '../widgets/transaction_form.dart';

class ReviewScreen extends StatefulWidget {
  final AppState state;
  final VoidCallback onExit;
  final ValueChanged<ReviewResult> onCompleted;

  const ReviewScreen({
    super.key,
    required this.state,
    required this.onExit,
    required this.onCompleted,
  });

  @override
  State<ReviewScreen> createState() =>
      _ReviewScreenState();
}

class _ReviewScreenState extends State<ReviewScreen> {
  int step = 0;

  ReportPeriod period = ReportPeriod.week();

  final Set<String> selectedIds = <String>{};

  String decision = 'Mantener mi plan';

  // =========================================================
  // REDUCIR GASTO
  // =========================================================

  String? reduceCategory;

  final TextEditingController reduceAmountController =
      TextEditingController();

  String reducePeriodType = 'weeks';

  int reducePeriodValue = 4;

  DateTime? reduceTargetDate;

  // =========================================================
  // MANTENER PLAN
  // =========================================================

  String maintainPeriodType = 'weeks';

  int maintainPeriodValue = 2;

  DateTime? maintainTargetDate;

  // =========================================================
  // POSPONER COMPRA
  // =========================================================

  final TextEditingController purchaseNameController =
      TextEditingController();

  final TextEditingController purchaseAmountController =
      TextEditingController();

  DateTime? purchaseTargetDate;

  // =========================================================
  // AJUSTAR META
  // =========================================================

  final TextEditingController goalNameController =
      TextEditingController();

  final TextEditingController goalAmountController =
      TextEditingController();

  String goalPeriodType = 'months';

  int goalPeriodValue = 3;

  DateTime? goalTargetDate;

  static const List<String> _expenseCategories = [
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
  void dispose() {
    reduceAmountController.dispose();

    purchaseNameController.dispose();
    purchaseAmountController.dispose();

    goalNameController.dispose();
    goalAmountController.dispose();

    super.dispose();
  }

  // =========================================================
  // MOVIMIENTOS DEL PERÍODO
  // =========================================================

  List<MoneyTransaction> get _periodTransactions {
    final result = widget.state.transactions.where(
      (transaction) {
        return _insidePeriod(
          transaction.date,
        );
      },
    ).toList();

    result.sort(
      (a, b) => b.date.compareTo(a.date),
    );

    return result;
  }

  List<MoneyTransaction> get _selectedTransactions {
    return _periodTransactions.where(
      (transaction) {
        return selectedIds.contains(
          transaction.id,
        );
      },
    ).toList();
  }

  List<MoneyTransaction> get _selectedExpenses {
    return _selectedTransactions.where(
      (transaction) {
        return transaction.type.toLowerCase() ==
            'expense';
      },
    ).toList();
  }

  List<MoneyTransaction> get _selectedIncomes {
    return _selectedTransactions.where(
      (transaction) {
        return transaction.type.toLowerCase() ==
            'income';
      },
    ).toList();
  }

  bool _insidePeriod(
    DateTime date,
  ) {
    final afterStart =
        date.isAtSameMomentAs(period.start) ||
            date.isAfter(period.start);

    final beforeEnd =
        date.isAtSameMomentAs(period.end) ||
            date.isBefore(period.end);

    return afterStart && beforeEnd;
  }

  // =========================================================
  // TOTALES
  // =========================================================

  double get _totalIncome {
    return _selectedIncomes.fold<double>(
      0,
      (
        total,
        transaction,
      ) {
        return total + transaction.amount;
      },
    );
  }

  double get _totalExpenses {
    return _selectedExpenses.fold<double>(
      0,
      (
        total,
        transaction,
      ) {
        return total + transaction.amount;
      },
    );
  }

  double get _balance {
    return _totalIncome - _totalExpenses;
  }

  double get _currentMoney {
    return _balance;
  }

  double get _committed {
    return widget.state.dashboard?.committed ?? 0;
  }

  double get _saved {
    return widget.state.dashboard?.saved ?? 0;
  }

  double get _available {
    return _currentMoney - _committed - _saved;
  }

  // =========================================================
  // CATEGORÍAS
  // =========================================================

  Map<String, double> get _expensesByCategory {
    final result = <String, double>{};

    for (final expense in _selectedExpenses) {
      result[expense.category] =
          (result[expense.category] ?? 0) +
              expense.amount;
    }

    final entries = result.entries.toList()
      ..sort(
        (a, b) => b.value.compareTo(a.value),
      );

    return {
      for (final entry in entries)
        entry.key: entry.value,
    };
  }

  // =========================================================
  // PERÍODO
  // =========================================================

  void _setPeriod(
    ReportPeriod value,
  ) {
    setState(() {
      period = value;
      selectedIds.clear();
    });
  }

  Future<void> _selectCustomPeriod() async {
    final now = DateTime.now();

    final range = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime(
        now.year + 5,
        12,
        31,
      ),
      helpText: 'Elegir rango de fechas',
      cancelText: 'Cancelar',
      confirmText: 'Seleccionar',
    );

    if (range == null) return;
    if (!mounted) return;

    _setPeriod(
      ReportPeriod.custom(
        start: range.start,
        end: range.end,
      ),
    );
  }

  // =========================================================
  // INICIALIZAR SELECCIÓN
  // =========================================================

  void _initializeSelection() {
    selectedIds.clear();

    for (final transaction in _periodTransactions) {
      final isIncome =
          transaction.type.toLowerCase() == 'income';

      if (isIncome || transaction.recognized) {
        selectedIds.add(
          transaction.id,
        );
      }
    }
  }

  // =========================================================
  // AGREGAR MOVIMIENTO
  // =========================================================

  Future<void> _addTransaction() async {
    final type =
        await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      builder: (
        context,
      ) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              18,
              5,
              18,
              24,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Agregar movimiento',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                  ),
                ),

                const SizedBox(height: 18),

                ListTile(
                  shape: RoundedRectangleBorder(
                    borderRadius:
                        BorderRadius.circular(14),
                  ),
                  tileColor:
                      const Color(0xFFEAF3FF),
                  leading: const Icon(
                    Icons
                        .remove_circle_outline_rounded,
                    color: AppTheme.primary,
                  ),
                  title: const Text(
                    'Agregar gasto',
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  onTap: () {
                    Navigator.pop(
                      context,
                      'expense',
                    );
                  },
                ),

                const SizedBox(height: 10),

                ListTile(
                  shape: RoundedRectangleBorder(
                    borderRadius:
                        BorderRadius.circular(14),
                  ),
                  tileColor:
                      const Color(0xFFE9FFF2),
                  leading: const Icon(
                    Icons
                        .add_circle_outline_rounded,
                    color: AppTheme.success,
                  ),
                  title: const Text(
                    'Agregar ingreso',
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  onTap: () {
                    Navigator.pop(
                      context,
                      'income',
                    );
                  },
                ),
              ],
            ),
          ),
        );
      },
    );

    if (type == null) return;
    if (!mounted) return;

    final result = await TransactionForm.show(
      context,
      type: type,
      availableBalance: widget.state.currentBalance,
    );

    if (result == null) return;

    try {
      await widget.state.saveTransaction(
        result,
        create: true,
      );

      await widget.state.refreshAll();

      if (!mounted) return;

      MoneyTransaction? savedTransaction;

      for (final item
          in widget.state.transactions.reversed) {
        final sameDate =
            item.date.year == result.date.year &&
                item.date.month ==
                    result.date.month &&
                item.date.day == result.date.day;

        final sameTransaction =
            item.type == result.type &&
                item.category == result.category &&
                item.amount == result.amount &&
                sameDate;

        if (sameTransaction) {
          savedTransaction = item;
          break;
        }
      }

      setState(() {
        if (savedTransaction != null &&
            _insidePeriod(savedTransaction.date)) {
          selectedIds.add(
            savedTransaction.id,
          );
        }
      });

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Movimiento agregado correctamente.',
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            e.toString(),
          ),
        ),
      );
    }
  }

  // =========================================================
  // NAVEGACIÓN
  // =========================================================

  void _continue() {
    if (step == 0) {
      _initializeSelection();

      setState(() {
        step = 1;
      });

      return;
    }

    if (step == 1) {
      if (selectedIds.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Seleccioná al menos un movimiento para continuar.',
            ),
          ),
        );

        return;
      }

      setState(() {
        step = 2;
      });

      return;
    }

    if (step == 2) {
      if (reduceCategory == null &&
          _expensesByCategory.isNotEmpty) {
        reduceCategory =
            _expensesByCategory.keys.first;
      }

      setState(() {
        step = 3;
      });

      return;
    }

    _saveReview();
  }

  void _back() {
    if (step == 0) {
      widget.onExit();
      return;
    }

    setState(() {
      step--;
    });
  }

  // =========================================================
  // SELECTOR FECHA
  // =========================================================

  Future<DateTime?> _pickTargetDate({
    DateTime? initialDate,
  }) async {
    final now = DateTime.now();

    return showDatePicker(
      context: context,
      initialDate:
          initialDate ??
              now.add(
                const Duration(
                  days: 7,
                ),
              ),
      firstDate: now,
      lastDate: DateTime(
        now.year + 5,
        12,
        31,
      ),
      helpText: 'Seleccionar fecha',
      cancelText: 'Cancelar',
      confirmText: 'Seleccionar',
    );
  }

  // =========================================================
  // GUARDAR
  // =========================================================

  void _saveReview() {
    if (!_validateDecision()) {
      return;
    }

    final result = ReviewResult(
      start: period.start,
      end: period.end,
      periodTitle: period.title,
      periodSubtitle: period.subtitle,
      transactionIds: selectedIds.toList(),
      decision: decision,
      decisionDetails:
          _buildDecisionDetails(),
      createdAt: DateTime.now(),
    );

    widget.onCompleted(
      result,
    );

    widget.onExit();
  }

  bool _validateDecision() {
    switch (decision) {
      case 'Mantener mi plan':
        if (maintainPeriodType == 'date' &&
            maintainTargetDate == null) {
          _showDecisionError(
            'Seleccioná una fecha para revisar nuevamente tu plan.',
          );

          return false;
        }

        return true;

      case 'Reducir gasto':
        final amount = _parseAmount(
          reduceAmountController.text,
        );

        if (reduceCategory == null) {
          _showDecisionError(
            'Seleccioná la categoría que querés reducir.',
          );

          return false;
        }

        if (amount <= 0) {
          _showDecisionError(
            'Indicá cuánto dinero querés reducir.',
          );

          return false;
        }

        if (reducePeriodType == 'date' &&
            reduceTargetDate == null) {
          _showDecisionError(
            'Seleccioná la fecha límite para tu objetivo.',
          );

          return false;
        }

        return true;

      case 'Posponer una compra':
        if (purchaseNameController.text
            .trim()
            .isEmpty) {
          _showDecisionError(
            'Escribí cuál compra querés posponer.',
          );

          return false;
        }

        if (_parseAmount(
              purchaseAmountController.text,
            ) <=
            0) {
          _showDecisionError(
            'Indicá el precio aproximado de la compra.',
          );

          return false;
        }

        if (purchaseTargetDate == null) {
          _showDecisionError(
            'Seleccioná hasta qué fecha querés posponer la compra.',
          );

          return false;
        }

        return true;

      case 'Ajustar mi meta':
        if (goalNameController.text
            .trim()
            .isEmpty) {
          _showDecisionError(
            'Escribí cuál meta querés ajustar.',
          );

          return false;
        }

        if (_parseAmount(
              goalAmountController.text,
            ) <=
            0) {
          _showDecisionError(
            'Indicá el nuevo monto de tu meta.',
          );

          return false;
        }

        if (goalPeriodType == 'date' &&
            goalTargetDate == null) {
          _showDecisionError(
            'Seleccioná la fecha límite de tu meta.',
          );

          return false;
        }

        return true;

      default:
        return true;
    }
  }

  void _showDecisionError(
    String message,
  ) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
        ),
      ),
    );
  }

  Map<String, dynamic>
      _buildDecisionDetails() {
    switch (decision) {
      case 'Mantener mi plan':
        return {
          'periodType': maintainPeriodType,
          if (maintainPeriodType != 'date')
            'periodValue': maintainPeriodValue,
          if (maintainTargetDate != null)
            'targetDate': maintainTargetDate!
                .toIso8601String(),
        };

      case 'Reducir gasto':
        return {
          'category': reduceCategory,
          'targetAmount': _parseAmount(
            reduceAmountController.text,
          ),
          'periodType': reducePeriodType,
          if (reducePeriodType != 'date')
            'periodValue': reducePeriodValue,
          if (reduceTargetDate != null)
            'targetDate': reduceTargetDate!
                .toIso8601String(),
        };

      case 'Posponer una compra':
        return {
          'purchaseName':
              purchaseNameController.text.trim(),
          'purchaseAmount': _parseAmount(
            purchaseAmountController.text,
          ),
          'targetDate': purchaseTargetDate
              ?.toIso8601String(),
        };

      case 'Ajustar mi meta':
        return {
          'goalName':
              goalNameController.text.trim(),
          'targetAmount': _parseAmount(
            goalAmountController.text,
          ),
          'periodType': goalPeriodType,
          if (goalPeriodType != 'date')
            'periodValue': goalPeriodValue,
          if (goalTargetDate != null)
            'targetDate':
                goalTargetDate!.toIso8601String(),
        };

      default:
        return {};
    }
  }

  double _parseAmount(
    String value,
  ) {
    final cleaned = value.replaceAll(
      RegExp(
        r'[^0-9]',
      ),
      '',
    );

    if (cleaned.isEmpty) {
      return 0;
    }

    return double.tryParse(cleaned) ?? 0;
  }

  // =========================================================
  // BUILD
  // =========================================================

  @override
  Widget build(
    BuildContext context,
  ) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SafeArea(
        child: Column(
          children: [
            _ReviewHeader(
              step: step,
              onBack: _back,
            ),

            Expanded(
              child: AnimatedSwitcher(
                duration: const Duration(
                  milliseconds: 180,
                ),
                child: KeyedSubtree(
                  key: ValueKey(step),
                  child: _buildStep(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStep() {
    switch (step) {
      case 0:
        return _periodStep();

      case 1:
        return _movementStep();

      case 2:
        return _summaryStep();

      case 3:
        return _decisionStep();

      default:
        return const SizedBox();
    }
  }

  // =========================================================
  // PASO 1
  // =========================================================

  Widget _periodStep() {
    return ListView(
      padding: const EdgeInsets.fromLTRB(
        18,
        8,
        18,
        30,
      ),
      children: [
        const Text(
          'Elegir periodo',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w900,
            color: AppTheme.text,
          ),
        ),

        const SizedBox(height: 6),

        const Text(
          'Seleccioná los movimientos que querés revisar.',
          style: TextStyle(
            fontSize: 11.5,
            color: AppTheme.muted,
          ),
        ),

        const SizedBox(height: 22),

        _PeriodOption(
          title: 'Hoy',
          subtitle:
              ReportPeriod.today().subtitle,
          icon: Icons.today_outlined,
          selected:
              period.type ==
                  ReportPeriodType.today,
          onTap: () {
            _setPeriod(
              ReportPeriod.today(),
            );
          },
        ),

        const SizedBox(height: 10),

        _PeriodOption(
          title: 'Esta semana',
          subtitle:
              ReportPeriod.week().subtitle,
          icon: Icons.date_range_outlined,
          selected:
              period.type ==
                  ReportPeriodType.week,
          onTap: () {
            _setPeriod(
              ReportPeriod.week(),
            );
          },
        ),

        const SizedBox(height: 10),

        _PeriodOption(
          title: 'Este mes',
          subtitle:
              ReportPeriod.month().subtitle,
          icon:
              Icons.calendar_month_outlined,
          selected:
              period.type ==
                  ReportPeriodType.month,
          onTap: () {
            _setPeriod(
              ReportPeriod.month(),
            );
          },
        ),

        const SizedBox(height: 10),

        _PeriodOption(
          title: 'Rango de fechas',
          subtitle:
              period.type ==
                      ReportPeriodType.custom
                  ? period.subtitle
                  : 'Elegí una fecha inicial y final',
          icon:
              Icons.calendar_today_outlined,
          selected:
              period.type ==
                  ReportPeriodType.custom,
          onTap: _selectCustomPeriod,
        ),

        const SizedBox(height: 28),

        FilledButton(
          onPressed: _continue,
          child: const Row(
            mainAxisAlignment:
                MainAxisAlignment.center,
            children: [
              Text('Continuar'),
              SizedBox(width: 7),
              Icon(
                Icons.arrow_forward_rounded,
                size: 18,
              ),
            ],
          ),
        ),
      ],
    );
  }

  // =========================================================
  // PASO 2
  // =========================================================

  Widget _movementStep() {
    final movements = _periodTransactions;

    return ListView(
      padding: const EdgeInsets.fromLTRB(
        18,
        8,
        18,
        30,
      ),
      children: [
        const Text(
          'Confirmar movimientos',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w900,
            color: AppTheme.text,
          ),
        ),

        const SizedBox(height: 6),

        const Text(
          'Marcá los movimientos que reconocés y querés incluir en el reporte.',
          style: TextStyle(
            fontSize: 11.5,
            color: AppTheme.muted,
          ),
        ),

        const SizedBox(height: 6),

        Text(
          period.subtitle,
          style: const TextStyle(
            fontSize: 11,
            color: AppTheme.primary,
            fontWeight: FontWeight.w800,
          ),
        ),

        const SizedBox(height: 18),

        // ===================================================
        // SI NO HAY MOVIMIENTOS:
        // Solo aparece UN botón dentro de la tarjeta.
        // ===================================================

        if (movements.isEmpty)
          _EmptyMovements(
            onAdd: _addTransaction,
          )
        else ...[
          // =================================================
          // SI YA HAY MOVIMIENTOS:
          // Mostramos la lista + un botón para agregar otro.
          // =================================================

          ...movements.map(
            (transaction) {
              final selected =
                  selectedIds.contains(
                transaction.id,
              );

              return Padding(
                padding: const EdgeInsets.only(
                  bottom: 10,
                ),
                child: _MovementCard(
                  transaction: transaction,
                  selected: selected,
                  onTap: () {
                    setState(() {
                      if (selected) {
                        selectedIds.remove(
                          transaction.id,
                        );
                      } else {
                        selectedIds.add(
                          transaction.id,
                        );
                      }
                    });
                  },
                ),
              );
            },
          ),

          const SizedBox(height: 8),

          OutlinedButton.icon(
            onPressed: _addTransaction,
            icon: const Icon(
              Icons.add_rounded,
            ),
            label: const Text(
              'Agregar movimiento',
            ),
          ),
        ],

        const SizedBox(height: 12),

        FilledButton(
          onPressed: _continue,
          child: Text(
            'Continuar (${selectedIds.length})',
          ),
        ),
      ],
    );
  }

  // =========================================================
  // PASO 3
  // =========================================================

  Widget _summaryStep() {
    return ListView(
      padding: const EdgeInsets.fromLTRB(
        18,
        8,
        18,
        30,
      ),
      children: [
        const Text(
          '¿Dónde se fue?',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w900,
            color: AppTheme.text,
          ),
        ),

        const SizedBox(height: 5),

        Text(
          '${_selectedTransactions.length} movimientos confirmados',
          style: const TextStyle(
            fontSize: 11,
            color: AppTheme.muted,
          ),
        ),

        const SizedBox(height: 20),

        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius:
                BorderRadius.circular(18),
            border: Border.all(
              color: AppTheme.border,
            ),
          ),
          child: Column(
            children: [
              if (_selectedExpenses.isEmpty)
                const Padding(
                  padding:
                      EdgeInsets.symmetric(
                    vertical: 28,
                  ),
                  child: Text(
                    'No seleccionaste gastos para analizar.',
                    style: TextStyle(
                      color: AppTheme.muted,
                    ),
                  ),
                )
              else ...[
                _ReviewDonut(
                  values: _expensesByCategory,
                  total: _totalExpenses,
                ),

                const SizedBox(height: 22),

                ..._buildCategoryRows(),
              ],
            ],
          ),
        ),

        const SizedBox(height: 14),

        _MoneyInfoCard(
          title: 'Dinero actual',
          subtitle:
              'Saldo después de tus movimientos confirmados',
          value: _currentMoney,
          icon: Icons
              .account_balance_wallet_outlined,
          emphasized: true,
        ),

        const SizedBox(height: 10),

        _MoneyInfoCard(
          title: 'Dinero comprometido',
          subtitle:
              'Pagos y gastos que ya tenés previstos',
          value: _committed,
          icon: Icons.wallet_outlined,
        ),

        const SizedBox(height: 10),

        _MoneyInfoCard(
          title: 'Ahorro reservado',
          subtitle:
              'Dinero separado para tus metas',
          value: _saved,
          icon: Icons.savings_outlined,
        ),

        const SizedBox(height: 10),

        _MoneyInfoCard(
          title: 'Disponible real',
          subtitle:
              'Lo que realmente podés utilizar',
          value: _available,
          icon: Icons
              .account_balance_wallet_outlined,
          success: true,
        ),

        const SizedBox(height: 20),

        FilledButton(
          onPressed: _continue,
          child: const Text(
            'Tomar una decisión',
          ),
        ),
      ],
    );
  }

  List<Widget> _buildCategoryRows() {
    final entries =
        _expensesByCategory.entries.toList();

    return List.generate(
      entries.length,
      (
        index,
      ) {
        final entry = entries[index];

        final percentage =
            _totalExpenses == 0
                ? 0.0
                : entry.value /
                    _totalExpenses *
                    100;

        return Padding(
          padding: const EdgeInsets.only(
            bottom: 11,
          ),
          child: _CategoryRow(
            name: entry.key,
            amount: entry.value,
            percentage: percentage,
            color: _reviewColors[
                index % _reviewColors.length],
          ),
        );
      },
    );
  }

  // =========================================================
  // PASO 4
  // =========================================================

  Widget _decisionStep() {
    return ListView(
      padding: const EdgeInsets.fromLTRB(
        18,
        8,
        18,
        30,
      ),
      children: [
        const Text(
          'Tomar una decisión',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w900,
            color: AppTheme.text,
          ),
        ),

        const SizedBox(height: 6),

        const Text(
          'Convertí el análisis en una acción concreta.',
          style: TextStyle(
            fontSize: 11.5,
            color: AppTheme.muted,
          ),
        ),

        const SizedBox(height: 18),

        Container(
          padding: const EdgeInsets.all(15),
          decoration: BoxDecoration(
            color:
                const Color(0xFFEAF3FF),
            borderRadius:
                BorderRadius.circular(16),
            border: Border.all(
              color: AppTheme.primary,
            ),
          ),
          child: const Row(
            children: [
              Icon(
                Icons.assessment_outlined,
                color: AppTheme.primary,
              ),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Con esta información, ¿qué querés hacer?',
                  style: TextStyle(
                    fontWeight: FontWeight.w900,
                    color: AppTheme.text,
                  ),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 16),

        _DecisionOption(
          title: 'Mantener mi plan',
          subtitle:
              'Todo sigue en orden',
          icon: Icons.check_rounded,
          selected:
              decision == 'Mantener mi plan',
          success: true,
          onTap: () {
            setState(() {
              decision =
                  'Mantener mi plan';
            });
          },
        ),

        const SizedBox(height: 10),

        _DecisionOption(
          title: 'Reducir gasto',
          subtitle:
              'Definí cuánto querés reducir y en qué plazo',
          icon:
              Icons.arrow_downward_rounded,
          selected:
              decision == 'Reducir gasto',
          onTap: () {
            setState(() {
              decision =
                  'Reducir gasto';

              reduceCategory ??=
                  _expensesByCategory.isNotEmpty
                      ? _expensesByCategory
                          .keys
                          .first
                      : _expenseCategories
                          .first;
            });
          },
        ),

        const SizedBox(height: 10),

        _DecisionOption(
          title:
              'Posponer una compra',
          subtitle:
              'Esperá hasta una fecha más conveniente',
          icon: Icons.schedule_rounded,
          selected:
              decision ==
                  'Posponer una compra',
          onTap: () {
            setState(() {
              decision =
                  'Posponer una compra';
            });
          },
        ),

        const SizedBox(height: 10),

        _DecisionOption(
          title: 'Ajustar mi meta',
          subtitle:
              'Establecé un nuevo monto o plazo',
          icon:
              Icons.track_changes_rounded,
          selected:
              decision == 'Ajustar mi meta',
          onTap: () {
            setState(() {
              decision =
                  'Ajustar mi meta';
            });
          },
        ),

        const SizedBox(height: 18),

        AnimatedSwitcher(
          duration: const Duration(
            milliseconds: 180,
          ),
          child:
              _decisionDetailsForm(),
        ),

        const SizedBox(height: 18),

        _DecisionSummaryCard(
          text:
              _decisionSummaryText(),
        ),

        const SizedBox(height: 24),

        FilledButton.icon(
          onPressed: _continue,
          icon: const Icon(
            Icons
                .check_circle_outline_rounded,
          ),
          label: const Text(
            'Guardar decisión',
          ),
        ),
      ],
    );
  }

  // =========================================================
  // FORMULARIO SEGÚN DECISIÓN
  // =========================================================

  Widget _decisionDetailsForm() {
    switch (decision) {
      case 'Reducir gasto':
        return _reduceExpenseForm();

      case 'Posponer una compra':
        return _postponePurchaseForm();

      case 'Ajustar mi meta':
        return _adjustGoalForm();

      case 'Mantener mi plan':
      default:
        return _maintainPlanForm();
    }
  }

  Widget _maintainPlanForm() {
    return _DecisionFormCard(
      key: const ValueKey(
        'maintain',
      ),
      title: 'Próxima revisión',
      subtitle:
          'Elegí cuándo querés revisar nuevamente cómo van tus finanzas.',
      children: [
        _PlanPeriodSelector(
          value:
              maintainPeriodType,
          onChanged: (
            value,
          ) {
            setState(() {
              maintainPeriodType =
                  value;
            });
          },
        ),

        const SizedBox(height: 14),

        if (maintainPeriodType ==
            'weeks')
          _PeriodQuantitySelector(
            label:
                'Cantidad de semanas',
            value:
                maintainPeriodValue,
            max: 12,
            suffix: 'semanas',
            onChanged: (
              value,
            ) {
              setState(() {
                maintainPeriodValue =
                    value;
              });
            },
          ),

        if (maintainPeriodType ==
            'months')
          _PeriodQuantitySelector(
            label:
                'Cantidad de meses',
            value:
                maintainPeriodValue,
            max: 12,
            suffix: 'meses',
            onChanged: (
              value,
            ) {
              setState(() {
                maintainPeriodValue =
                    value;
              });
            },
          ),

        if (maintainPeriodType ==
            'date')
          _DateSelector(
            value:
                maintainTargetDate,
            label:
                'Fecha de próxima revisión',
            onTap: () async {
              final date =
                  await _pickTargetDate(
                initialDate:
                    maintainTargetDate,
              );

              if (date == null ||
                  !mounted) {
                return;
              }

              setState(() {
                maintainTargetDate =
                    date;
              });
            },
          ),
      ],
    );
  }

  Widget _reduceExpenseForm() {
    return _DecisionFormCard(
      key: const ValueKey(
        'reduce',
      ),
      title:
          'Objetivo de reducción',
      subtitle:
          'Definí exactamente qué querés reducir.',
      children: [
        DropdownButtonFormField<String>(
          value: reduceCategory,
          decoration:
              const InputDecoration(
            labelText: 'Categoría',
            prefixIcon: Icon(
              Icons.category_outlined,
            ),
          ),
          items:
              _expenseCategories.map(
            (
              category,
            ) {
              return DropdownMenuItem<
                  String>(
                value: category,
                child: Text(
                  category,
                ),
              );
            },
          ).toList(),
          onChanged: (
            value,
          ) {
            setState(() {
              reduceCategory =
                  value;
            });
          },
        ),

        const SizedBox(height: 14),

        TextField(
          controller:
              reduceAmountController,
          keyboardType:
              TextInputType.number,
          inputFormatters: [
            FilteringTextInputFormatter
                .digitsOnly,
          ],
          decoration:
              const InputDecoration(
            labelText:
                'Monto que querés reducir',
            hintText: '15000',
            prefixText: '₡ ',
            prefixIcon: Icon(
              Icons.payments_outlined,
            ),
          ),
          onChanged: (_) {
            setState(() {});
          },
        ),

        const SizedBox(height: 16),

        const Text(
          'Plazo',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w900,
            color: AppTheme.text,
          ),
        ),

        const SizedBox(height: 8),

        _PlanPeriodSelector(
          value:
              reducePeriodType,
          onChanged: (
            value,
          ) {
            setState(() {
              reducePeriodType =
                  value;
            });
          },
        ),

        const SizedBox(height: 14),

        if (reducePeriodType ==
            'weeks')
          _PeriodQuantitySelector(
            label:
                'Cantidad de semanas',
            value:
                reducePeriodValue,
            max: 12,
            suffix: 'semanas',
            onChanged: (
              value,
            ) {
              setState(() {
                reducePeriodValue =
                    value;
              });
            },
          ),

        if (reducePeriodType ==
            'months')
          _PeriodQuantitySelector(
            label:
                'Cantidad de meses',
            value:
                reducePeriodValue,
            max: 12,
            suffix: 'meses',
            onChanged: (
              value,
            ) {
              setState(() {
                reducePeriodValue =
                    value;
              });
            },
          ),

        if (reducePeriodType ==
            'date')
          _DateSelector(
            value:
                reduceTargetDate,
            label: 'Fecha límite',
            onTap: () async {
              final date =
                  await _pickTargetDate(
                initialDate:
                    reduceTargetDate,
              );

              if (date == null ||
                  !mounted) {
                return;
              }

              setState(() {
                reduceTargetDate =
                    date;
              });
            },
          ),
      ],
    );
  }

  Widget _postponePurchaseForm() {
    return _DecisionFormCard(
      key: const ValueKey(
        'purchase',
      ),
      title: 'Compra a posponer',
      subtitle:
          'Registrá qué compra querés esperar antes de realizar.',
      children: [
        TextField(
          controller:
              purchaseNameController,
          decoration:
              const InputDecoration(
            labelText:
                '¿Qué querés comprar?',
            hintText: 'Ej. Audífonos',
            prefixIcon: Icon(
              Icons.shopping_bag_outlined,
            ),
          ),
          onChanged: (_) {
            setState(() {});
          },
        ),

        const SizedBox(height: 14),

        TextField(
          controller:
              purchaseAmountController,
          keyboardType:
              TextInputType.number,
          inputFormatters: [
            FilteringTextInputFormatter
                .digitsOnly,
          ],
          decoration:
              const InputDecoration(
            labelText:
                'Costo aproximado',
            hintText: '45000',
            prefixText: '₡ ',
            prefixIcon: Icon(
              Icons.payments_outlined,
            ),
          ),
          onChanged: (_) {
            setState(() {});
          },
        ),

        const SizedBox(height: 14),

        _DateSelector(
          value:
              purchaseTargetDate,
          label: 'Posponer hasta',
          onTap: () async {
            final date =
                await _pickTargetDate(
              initialDate:
                  purchaseTargetDate,
            );

            if (date == null ||
                !mounted) {
              return;
            }

            setState(() {
              purchaseTargetDate =
                  date;
            });
          },
        ),
      ],
    );
  }

  Widget _adjustGoalForm() {
    return _DecisionFormCard(
      key: const ValueKey(
        'goal',
      ),
      title: 'Nuevo objetivo',
      subtitle:
          'Definí el monto y el plazo de la meta que querés ajustar.',
      children: [
        TextField(
          controller:
              goalNameController,
          decoration:
              const InputDecoration(
            labelText:
                'Nombre de la meta',
            hintText:
                'Ej. Fondo de emergencia',
            prefixIcon: Icon(
              Icons.flag_outlined,
            ),
          ),
          onChanged: (_) {
            setState(() {});
          },
        ),

        const SizedBox(height: 14),

        TextField(
          controller:
              goalAmountController,
          keyboardType:
              TextInputType.number,
          inputFormatters: [
            FilteringTextInputFormatter
                .digitsOnly,
          ],
          decoration:
              const InputDecoration(
            labelText:
                'Nuevo monto objetivo',
            hintText: '300000',
            prefixText: '₡ ',
            prefixIcon: Icon(
              Icons.savings_outlined,
            ),
          ),
          onChanged: (_) {
            setState(() {});
          },
        ),

        const SizedBox(height: 16),

        const Text(
          'Plazo',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w900,
          ),
        ),

        const SizedBox(height: 8),

        _PlanPeriodSelector(
          value: goalPeriodType,
          onChanged: (
            value,
          ) {
            setState(() {
              goalPeriodType =
                  value;
            });
          },
        ),

        const SizedBox(height: 14),

        if (goalPeriodType ==
            'weeks')
          _PeriodQuantitySelector(
            label:
                'Cantidad de semanas',
            value:
                goalPeriodValue,
            max: 12,
            suffix: 'semanas',
            onChanged: (
              value,
            ) {
              setState(() {
                goalPeriodValue =
                    value;
              });
            },
          ),

        if (goalPeriodType ==
            'months')
          _PeriodQuantitySelector(
            label:
                'Cantidad de meses',
            value:
                goalPeriodValue,
            max: 24,
            suffix: 'meses',
            onChanged: (
              value,
            ) {
              setState(() {
                goalPeriodValue =
                    value;
              });
            },
          ),

        if (goalPeriodType ==
            'date')
          _DateSelector(
            value: goalTargetDate,
            label: 'Fecha límite',
            onTap: () async {
              final date =
                  await _pickTargetDate(
                initialDate:
                    goalTargetDate,
              );

              if (date == null ||
                  !mounted) {
                return;
              }

              setState(() {
                goalTargetDate =
                    date;
              });
            },
          ),
      ],
    );
  }

  // =========================================================
  // TEXTO RESUMEN DE DECISIÓN
  // =========================================================

  String _decisionSummaryText() {
    switch (decision) {
      case 'Mantener mi plan':
        return 'Mantener el plan actual y revisar nuevamente ${_periodDescription(
          maintainPeriodType,
          maintainPeriodValue,
          maintainTargetDate,
        )}.';

      case 'Reducir gasto':
        final amount = _parseAmount(
          reduceAmountController.text,
        );

        if (reduceCategory == null ||
            amount <= 0) {
          return 'Completá la categoría, el monto y el plazo para crear tu objetivo.';
        }

        return 'Reducir ${reduceCategory!} en ${money(amount)} ${_periodDescription(
          reducePeriodType,
          reducePeriodValue,
          reduceTargetDate,
        )}.';

      case 'Posponer una compra':
        final name =
            purchaseNameController.text.trim();

        final amount = _parseAmount(
          purchaseAmountController.text,
        );

        if (name.isEmpty ||
            amount <= 0 ||
            purchaseTargetDate == null) {
          return 'Indicá la compra, su precio aproximado y hasta cuándo querés posponerla.';
        }

        return 'Posponer $name (${money(amount)}) hasta ${_formatDate(
          purchaseTargetDate!,
        )}.';

      case 'Ajustar mi meta':
        final name =
            goalNameController.text.trim();

        final amount = _parseAmount(
          goalAmountController.text,
        );

        if (name.isEmpty ||
            amount <= 0) {
          return 'Indicá la meta, el nuevo monto objetivo y el plazo.';
        }

        return 'Ajustar "$name" a ${money(amount)} ${_periodDescription(
          goalPeriodType,
          goalPeriodValue,
          goalTargetDate,
        )}.';

      default:
        return decision;
    }
  }

  String _periodDescription(
    String type,
    int value,
    DateTime? date,
  ) {
    switch (type) {
      case 'weeks':
        return value == 1
            ? 'durante 1 semana'
            : 'durante $value semanas';

      case 'months':
        return value == 1
            ? 'durante 1 mes'
            : 'durante $value meses';

      case 'date':
        if (date == null) {
          return 'hasta una fecha por definir';
        }

        return 'hasta el ${_formatDate(date)}';

      default:
        return '';
    }
  }

  String _formatDate(
    DateTime date,
  ) {
    final day = date.day
        .toString()
        .padLeft(
          2,
          '0',
        );

    final month = date.month
        .toString()
        .padLeft(
          2,
          '0',
        );

    return '$day/$month/${date.year}';
  }
}

// =============================================================
// HEADER
// =============================================================

class _ReviewHeader extends StatelessWidget {
  final int step;
  final VoidCallback onBack;

  const _ReviewHeader({
    required this.step,
    required this.onBack,
  });

  @override
  Widget build(
    BuildContext context,
  ) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        8,
        8,
        14,
        6,
      ),
      child: Row(
        children: [
          IconButton(
            onPressed: onBack,
            icon: const Icon(
              Icons.arrow_back_rounded,
            ),
          ),

          Expanded(
            child: LinearProgressIndicator(
              value: (step + 1) / 4,
              minHeight: 6,
              backgroundColor:
                  AppTheme.border,
            ),
          ),

          const SizedBox(width: 12),

          Text(
            '${step + 1}/4',
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              color: AppTheme.muted,
            ),
          ),
        ],
      ),
    );
  }
}

// =============================================================
// PERÍODO
// =============================================================

class _PeriodOption extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  const _PeriodOption({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(
    BuildContext context,
  ) {
    return Material(
      color: selected
          ? const Color(0xFFEAF3FF)
          : Colors.white,
      borderRadius:
          BorderRadius.circular(15),
      child: InkWell(
        onTap: onTap,
        borderRadius:
            BorderRadius.circular(15),
        child: Container(
          padding:
              const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius:
                BorderRadius.circular(15),
            border: Border.all(
              width: selected ? 1.6 : 1,
              color: selected
                  ? AppTheme.primary
                  : AppTheme.border,
            ),
          ),
          child: Row(
            children: [
              Icon(
                icon,
                color: AppTheme.primary,
              ),

              const SizedBox(width: 12),

              Expanded(
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontWeight:
                            FontWeight.w900,
                      ),
                    ),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        fontSize: 10,
                        color:
                            AppTheme.muted,
                      ),
                    ),
                  ],
                ),
              ),

              Icon(
                selected
                    ? Icons
                        .radio_button_checked_rounded
                    : Icons
                        .radio_button_off_rounded,
                color: selected
                    ? AppTheme.primary
                    : AppTheme.muted,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// =============================================================
// MOVIMIENTO
// =============================================================

class _MovementCard extends StatelessWidget {
  final MoneyTransaction transaction;
  final bool selected;
  final VoidCallback onTap;

  const _MovementCard({
    required this.transaction,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(
    BuildContext context,
  ) {
    final income =
        transaction.type.toLowerCase() ==
            'income';

    final color = income
        ? AppTheme.success
        : AppTheme.primary;

    return Material(
      color: Colors.white,
      borderRadius:
          BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius:
            BorderRadius.circular(14),
        child: Container(
          padding:
              const EdgeInsets.all(12),
          decoration: BoxDecoration(
            borderRadius:
                BorderRadius.circular(14),
            border: Border.all(
              width: selected ? 1.5 : 1,
              color: selected
                  ? color
                  : AppTheme.border,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color:
                      color.withOpacity(0.10),
                  borderRadius:
                      BorderRadius.circular(10),
                ),
                child: Icon(
                  income
                      ? Icons.payments_outlined
                      : _expenseIcon(
                          transaction.category,
                        ),
                  color: color,
                  size: 20,
                ),
              ),

              const SizedBox(width: 11),

              Expanded(
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    Text(
                      transaction.category,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight:
                            FontWeight.w900,
                      ),
                    ),

                    if (transaction.description
                        .trim()
                        .isNotEmpty)
                      Text(
                        transaction.description,
                        maxLines: 1,
                        overflow:
                            TextOverflow.ellipsis,
                        style:
                            const TextStyle(
                          fontSize: 10,
                          color:
                              AppTheme.muted,
                        ),
                      ),

                    if (!income &&
                        !transaction.recognized)
                      const Text(
                        'No reconocido',
                        style: TextStyle(
                          fontSize: 9.5,
                          color: Colors.orange,
                          fontWeight:
                              FontWeight.w700,
                        ),
                      ),
                  ],
                ),
              ),

              Text(
                '${income ? '+' : '-'}${money(transaction.amount)}',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight:
                      FontWeight.w900,
                  color: color,
                ),
              ),

              const SizedBox(width: 8),

              Icon(
                selected
                    ? Icons.check_box_rounded
                    : Icons
                        .check_box_outline_blank_rounded,
                color: selected
                    ? color
                    : AppTheme.muted,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// =============================================================
// DECISIÓN
// =============================================================

class _DecisionOption extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final bool selected;
  final bool success;
  final VoidCallback onTap;

  const _DecisionOption({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.selected,
    required this.onTap,
    this.success = false,
  });

  @override
  Widget build(
    BuildContext context,
  ) {
    final color = success
        ? AppTheme.success
        : AppTheme.primary;

    return Material(
      color: Colors.white,
      borderRadius:
          BorderRadius.circular(15),
      child: InkWell(
        onTap: onTap,
        borderRadius:
            BorderRadius.circular(15),
        child: Container(
          padding:
              const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius:
                BorderRadius.circular(15),
            border: Border.all(
              width: selected ? 1.5 : 1,
              color: selected
                  ? color
                  : AppTheme.border,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 39,
                height: 39,
                decoration: BoxDecoration(
                  color:
                      color.withOpacity(0.10),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  icon,
                  color: color,
                ),
              ),

              const SizedBox(width: 12),

              Expanded(
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight:
                            FontWeight.w900,
                      ),
                    ),

                    Text(
                      subtitle,
                      style: const TextStyle(
                        fontSize: 10,
                        color:
                            AppTheme.muted,
                      ),
                    ),
                  ],
                ),
              ),

              Icon(
                selected
                    ? Icons
                        .check_circle_rounded
                    : Icons
                        .chevron_right_rounded,
                color: selected
                    ? color
                    : AppTheme.primary,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// =============================================================
// FORMULARIO DE DECISIÓN
// =============================================================

class _DecisionFormCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final List<Widget> children;

  const _DecisionFormCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.children,
  });

  @override
  Widget build(
    BuildContext context,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius:
            BorderRadius.circular(16),
        border: Border.all(
          color: AppTheme.border,
        ),
      ),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w900,
              color: AppTheme.text,
            ),
          ),

          const SizedBox(height: 4),

          Text(
            subtitle,
            style: const TextStyle(
              fontSize: 10.5,
              color: AppTheme.muted,
            ),
          ),

          const SizedBox(height: 16),

          ...children,
        ],
      ),
    );
  }
}

// =============================================================
// SEMANAS / MESES / FECHA
// =============================================================

class _PlanPeriodSelector
    extends StatelessWidget {
  final String value;
  final ValueChanged<String> onChanged;

  const _PlanPeriodSelector({
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(
    BuildContext context,
  ) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        _PeriodChoiceChip(
          title: 'Semanas',
          selected: value == 'weeks',
          onTap: () {
            onChanged('weeks');
          },
        ),
        _PeriodChoiceChip(
          title: 'Meses',
          selected: value == 'months',
          onTap: () {
            onChanged('months');
          },
        ),
        _PeriodChoiceChip(
          title: 'Fecha',
          selected: value == 'date',
          onTap: () {
            onChanged('date');
          },
        ),
      ],
    );
  }
}

class _PeriodChoiceChip
    extends StatelessWidget {
  final String title;
  final bool selected;
  final VoidCallback onTap;

  const _PeriodChoiceChip({
    required this.title,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(
    BuildContext context,
  ) {
    return InkWell(
      onTap: onTap,
      borderRadius:
          BorderRadius.circular(20),
      child: Container(
        padding:
            const EdgeInsets.symmetric(
          horizontal: 15,
          vertical: 9,
        ),
        decoration: BoxDecoration(
          color: selected
              ? const Color(0xFFEAF3FF)
              : Colors.white,
          borderRadius:
              BorderRadius.circular(20),
          border: Border.all(
            color: selected
                ? AppTheme.primary
                : AppTheme.border,
          ),
        ),
        child: Text(
          title,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w800,
            color: selected
                ? AppTheme.primary
                : AppTheme.text,
          ),
        ),
      ),
    );
  }
}

// =============================================================
// CANTIDAD
// =============================================================

class _PeriodQuantitySelector
    extends StatelessWidget {
  final String label;
  final int value;
  final int max;
  final String suffix;
  final ValueChanged<int> onChanged;

  const _PeriodQuantitySelector({
    required this.label,
    required this.value,
    required this.max,
    required this.suffix,
    required this.onChanged,
  });

  @override
  Widget build(
    BuildContext context,
  ) {
    return DropdownButtonFormField<int>(
      value: value,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: const Icon(
          Icons.schedule_outlined,
        ),
      ),
      items: List.generate(
        max,
        (
          index,
        ) {
          final number = index + 1;

          return DropdownMenuItem<int>(
            value: number,
            child: Text(
              '$number $suffix',
            ),
          );
        },
      ),
      onChanged: (
        value,
      ) {
        if (value != null) {
          onChanged(value);
        }
      },
    );
  }
}

// =============================================================
// FECHA
// =============================================================

class _DateSelector extends StatelessWidget {
  final DateTime? value;
  final String label;
  final VoidCallback onTap;

  const _DateSelector({
    required this.value,
    required this.label,
    required this.onTap,
  });

  String _formatDate(
    DateTime date,
  ) {
    final day = date.day
        .toString()
        .padLeft(2, '0');

    final month = date.month
        .toString()
        .padLeft(2, '0');

    return '$day/$month/${date.year}';
  }

  @override
  Widget build(
    BuildContext context,
  ) {
    return InkWell(
      onTap: onTap,
      borderRadius:
          BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          borderRadius:
              BorderRadius.circular(14),
          border: Border.all(
            color: value != null
                ? AppTheme.primary
                : AppTheme.border,
          ),
        ),
        child: Row(
          children: [
            const Icon(
              Icons.calendar_today_outlined,
              color: AppTheme.primary,
            ),

            const SizedBox(width: 12),

            Expanded(
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: const TextStyle(
                      fontSize: 10,
                      color: AppTheme.muted,
                    ),
                  ),

                  const SizedBox(height: 2),

                  Text(
                    value == null
                        ? 'Seleccionar fecha'
                        : _formatDate(value!),
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight:
                          FontWeight.w900,
                    ),
                  ),
                ],
              ),
            ),

            const Icon(
              Icons.chevron_right_rounded,
              color: AppTheme.primary,
            ),
          ],
        ),
      ),
    );
  }
}

// =============================================================
// RESUMEN DECISIÓN
// =============================================================

class _DecisionSummaryCard
    extends StatelessWidget {
  final String text;

  const _DecisionSummaryCard({
    required this.text,
  });

  @override
  Widget build(
    BuildContext context,
  ) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color:
            const Color(0xFFF0FFF6),
        borderRadius:
            BorderRadius.circular(15),
        border: Border.all(
          color:
              const Color(0xFF9EEAC1),
        ),
      ),
      child: Row(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.flag_outlined,
            color: AppTheme.success,
          ),

          const SizedBox(width: 10),

          Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                const Text(
                  'Tu decisión',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight:
                        FontWeight.w900,
                    color:
                        AppTheme.successDark,
                  ),
                ),

                const SizedBox(height: 4),

                Text(
                  text,
                  style: const TextStyle(
                    fontSize: 11,
                    height: 1.4,
                    fontWeight:
                        FontWeight.w700,
                    color: AppTheme.text,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// =============================================================
// TARJETA DINERO
// =============================================================

class _MoneyInfoCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final double value;
  final IconData icon;
  final bool success;
  final bool emphasized;

  const _MoneyInfoCard({
    required this.title,
    required this.subtitle,
    required this.value,
    required this.icon,
    this.success = false,
    this.emphasized = false,
  });

  @override
  Widget build(
    BuildContext context,
  ) {
    final color = success
        ? AppTheme.success
        : AppTheme.primary;

    Color backgroundColor =
        Colors.white;

    Color borderColor =
        AppTheme.border;

    if (success) {
      backgroundColor =
          const Color(0xFFF0FFF6);

      borderColor =
          const Color(0xFF9EEAC1);
    }

    if (emphasized) {
      backgroundColor =
          const Color(0xFFEAF3FF);

      borderColor =
          const Color(0xFFB8D3FF);
    }

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius:
            BorderRadius.circular(15),
        border: Border.all(
          color: borderColor,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color:
                  color.withOpacity(0.10),
              borderRadius:
                  BorderRadius.circular(10),
            ),
            child: Icon(
              icon,
              color: color,
              size: 20,
            ),
          ),

          const SizedBox(width: 11),

          Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight:
                        FontWeight.w800,
                  ),
                ),

                Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: 9.5,
                    color: AppTheme.muted,
                  ),
                ),
              ],
            ),
          ),

          Text(
            money(value),
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w900,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

// =============================================================
// VACÍO
// =============================================================

class _EmptyMovements
    extends StatelessWidget {
  final VoidCallback onAdd;

  const _EmptyMovements({
    required this.onAdd,
  });

  @override
  Widget build(
    BuildContext context,
  ) {
    return Container(
      padding: const EdgeInsets.all(25),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius:
            BorderRadius.circular(16),
        border: Border.all(
          color: AppTheme.border,
        ),
      ),
      child: Column(
        children: [
          const Icon(
            Icons.receipt_long_outlined,
            size: 48,
            color: AppTheme.border,
          ),

          const SizedBox(height: 12),

          const Text(
            'No encontramos movimientos',
            style: TextStyle(
              fontWeight: FontWeight.w900,
            ),
          ),

          const SizedBox(height: 5),

          const Text(
            'Podés agregar manualmente un movimiento que recordés.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 10.5,
              color: AppTheme.muted,
            ),
          ),

          const SizedBox(height: 15),

          OutlinedButton.icon(
            onPressed: onAdd,
            icon: const Icon(
              Icons.add_rounded,
            ),
            label: const Text(
              'Agregar movimiento',
            ),
          ),
        ],
      ),
    );
  }
}

// =============================================================
// GRÁFICO
// =============================================================

const List<Color> _reviewColors = [
  Color(0xFF0A55F4),
  Color(0xFF3478F6),
  Color(0xFF6598FA),
  Color(0xFF8CB4FB),
  Color(0xFFB2CEFD),
  Color(0xFF6C63FF),
  Color(0xFF00A85A),
  Color(0xFFFFA000),
];

class _ReviewDonut extends StatelessWidget {
  final Map<String, double> values;
  final double total;

  const _ReviewDonut({
    required this.values,
    required this.total,
  });

  @override
  Widget build(
    BuildContext context,
  ) {
    return SizedBox(
      width: 185,
      height: 185,
      child: Stack(
        alignment: Alignment.center,
        children: [
          CustomPaint(
            size: const Size(
              185,
              185,
            ),
            painter: _ReviewDonutPainter(
              values:
                  values.values.toList(),
            ),
          ),

          Column(
            mainAxisSize:
                MainAxisSize.min,
            children: [
              const Text(
                'Gastos',
                style: TextStyle(
                  fontSize: 10,
                  color: AppTheme.muted,
                ),
              ),

              Text(
                money(total),
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight:
                      FontWeight.w900,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ReviewDonutPainter
    extends CustomPainter {
  final List<double> values;

  _ReviewDonutPainter({
    required this.values,
  });

  @override
  void paint(
    Canvas canvas,
    Size size,
  ) {
    final total = values.fold<double>(
      0,
      (
        a,
        b,
      ) =>
          a + b,
    );

    if (total <= 0) {
      return;
    }

    final center = Offset(
      size.width / 2,
      size.height / 2,
    );

    final radius = math.min(
          size.width,
          size.height,
        ) /
        2;

    const strokeWidth = 27.0;

    double startAngle =
        -math.pi / 2;

    for (var i = 0;
        i < values.length;
        i++) {
      final sweep =
          values[i] /
              total *
              math.pi *
              2;

      final paint = Paint()
        ..color = _reviewColors[
            i % _reviewColors.length]
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.butt;

      canvas.drawArc(
        Rect.fromCircle(
          center: center,
          radius:
              radius - strokeWidth / 2,
        ),
        startAngle,
        sweep,
        false,
        paint,
      );

      startAngle += sweep;
    }
  }

  @override
  bool shouldRepaint(
    covariant _ReviewDonutPainter
        oldDelegate,
  ) {
    return true;
  }
}

// =============================================================
// CATEGORÍA
// =============================================================

class _CategoryRow extends StatelessWidget {
  final String name;
  final double amount;
  final double percentage;
  final Color color;

  const _CategoryRow({
    required this.name,
    required this.amount,
    required this.percentage,
    required this.color,
  });

  @override
  Widget build(
    BuildContext context,
  ) {
    return Row(
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),

        const SizedBox(width: 8),

        Expanded(
          child: Text(
            name,
            style: const TextStyle(
              fontSize: 11.5,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),

        Text(
          '${percentage.toStringAsFixed(0)}%',
          style: const TextStyle(
            fontSize: 10.5,
            color: AppTheme.muted,
          ),
        ),

        const SizedBox(width: 12),

        Text(
          money(amount),
          style: const TextStyle(
            fontSize: 11.5,
            fontWeight: FontWeight.w900,
          ),
        ),
      ],
    );
  }
}

// =============================================================
// ICONO GASTO
// =============================================================

IconData _expenseIcon(
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
      return Icons.medical_services_outlined;

    case 'educación':
      return Icons.school_outlined;

    default:
      return Icons.payments_outlined;
  }
}