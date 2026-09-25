import 'package:flutter/material.dart';

import '../core/theme/app_theme.dart';
import '../core/utils/formatters.dart';
import '../models/models.dart';
import '../providers/app_state.dart';
import '../widgets/app_ui.dart';
import '../widgets/prototype_ui.dart';
import '../widgets/transaction_form.dart';

class TransactionsScreen extends StatefulWidget {
  final AppState state;

  const TransactionsScreen({
    super.key,
    required this.state,
  });

  @override
  State<TransactionsScreen> createState() =>
      _TransactionsScreenState();
}

class _TransactionsScreenState extends State<TransactionsScreen> {
  String typeFilter = 'Todos';
  String categoryFilter = 'Todos';

  // =========================================================
  // AGREGAR / EDITAR MOVIMIENTO
  // =========================================================

  Future<void> _openTransactionForm({
    required String type,
    MoneyTransaction? transaction,
  }) async {
    final result = await TransactionForm.show(
      context,
      type: type,
      transaction: transaction,
      availableBalance: widget.state.currentBalance,
    );

    if (result == null) return;
    if (!mounted) return;

    try {
      await widget.state.saveTransaction(
        result,
        create: transaction == null,
      );

      await widget.state.refreshAll();

      if (!mounted) return;

      setState(() {});

      final isIncome = result.type.toLowerCase() == 'income';

      AppAlerts.success(
        context,
        transaction == null
            ? isIncome
                ? 'Ingreso agregado correctamente.'
                : 'Gasto agregado correctamente.'
            : isIncome
                ? 'Ingreso actualizado correctamente.'
                : 'Gasto actualizado correctamente.',
      );
    } catch (e) {
      if (!mounted) return;

      AppAlerts.error(
        context,
        e.toString(),
      );
    }
  }

  // =========================================================
  // ELIMINAR MOVIMIENTO
  // =========================================================

  Future<void> _deleteTransaction(
    MoneyTransaction transaction,
  ) async {
    final isIncome =
        transaction.type.toLowerCase() == 'income';

    final confirmed = await AppDialogs.confirm(
      context,
      title: isIncome
          ? 'Eliminar ingreso'
          : 'Eliminar gasto',
      message:
          '¿Querés eliminar ${transaction.category} por ${money(transaction.amount)}?',
      confirmText: 'Eliminar',
    );

    if (!confirmed) return;
    if (!mounted) return;

    try {
      await widget.state.deleteTransaction(
        transaction.id,
      );

      await widget.state.refreshAll();

      if (!mounted) return;

      setState(() {});

      AppAlerts.success(
        context,
        isIncome
            ? 'Ingreso eliminado correctamente.'
            : 'Gasto eliminado correctamente.',
      );
    } catch (e) {
      if (!mounted) return;

      AppAlerts.error(
        context,
        e.toString(),
      );
    }
  }

  // =========================================================
  // REFRESCAR
  // =========================================================

  Future<void> _refresh() async {
    try {
      await widget.state.refreshAll();

      if (!mounted) return;

      setState(() {});
    } catch (e) {
      if (!mounted) return;

      AppAlerts.error(
        context,
        e.toString(),
      );
    }
  }

  // =========================================================
  // DATOS
  // =========================================================

  List<MoneyTransaction> get _transactions {
    final list = List<MoneyTransaction>.from(
      widget.state.transactions,
    );

    list.sort(
      (a, b) => b.date.compareTo(a.date),
    );

    return list;
  }

  List<MoneyTransaction> get _expenses {
    return _transactions
        .where(
          (transaction) =>
              transaction.type.toLowerCase() == 'expense',
        )
        .toList();
  }

  List<MoneyTransaction> get _incomes {
    return _transactions
        .where(
          (transaction) =>
              transaction.type.toLowerCase() == 'income',
        )
        .toList();
  }

  List<MoneyTransaction> get _filteredTransactions {
    var result = _transactions;

    // Filtrar por tipo
    if (typeFilter == 'Gastos') {
      result = result
          .where(
            (transaction) =>
                transaction.type.toLowerCase() ==
                'expense',
          )
          .toList();
    }

    if (typeFilter == 'Ingresos') {
      result = result
          .where(
            (transaction) =>
                transaction.type.toLowerCase() ==
                'income',
          )
          .toList();
    }

    // Filtrar por categoría
    if (categoryFilter != 'Todos') {
      result = result
          .where(
            (transaction) =>
                transaction.category.toLowerCase() ==
                categoryFilter.toLowerCase(),
          )
          .toList();
    }

    return result;
  }

  double get _totalExpenses {
    return _expenses.fold<double>(
      0,
      (total, transaction) =>
          total + transaction.amount,
    );
  }

  double get _totalIncome {
    return _incomes.fold<double>(
      0,
      (total, transaction) =>
          total + transaction.amount,
    );
  }

  double get _balance {
    return _totalIncome - _totalExpenses;
  }

  // =========================================================
  // CATEGORÍAS
  // =========================================================

  List<String> get _availableCategories {
    if (typeFilter == 'Ingresos') {
      return const [
        'Todos',
        'Salario',
        'Beca',
        'Ayuda familiar',
        'Trabajo extra',
        'Venta',
        'Transferencia',
        'Otros',
      ];
    }

    if (typeFilter == 'Gastos') {
      return const [
        'Todos',
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

    return const [
      'Todos',
      'Comida',
      'Transporte',
      'Compras',
      'Ocio',
      'Servicios',
      'Salud',
      'Educación',
      'Salario',
      'Beca',
      'Ayuda familiar',
      'Trabajo extra',
      'Venta',
      'Transferencia',
      'Otros',
    ];
  }

  // =========================================================
  // ICONOS
  // =========================================================

  IconData _iconForCategory(
    String category,
  ) {
    switch (category.toLowerCase()) {
      // -------------------------
      // GASTOS
      // -------------------------

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

      // -------------------------
      // INGRESOS
      // -------------------------

      case 'salario':
        return Icons.work_outline_rounded;

      case 'beca':
        return Icons.school_rounded;

      case 'ayuda familiar':
        return Icons.family_restroom_rounded;

      case 'trabajo extra':
        return Icons.business_center_outlined;

      case 'venta':
        return Icons.sell_outlined;

      case 'transferencia':
        return Icons.swap_horiz_rounded;

      default:
        return Icons.payments_outlined;
    }
  }

  // =========================================================
  // BUILD
  // =========================================================

  @override
  Widget build(BuildContext context) {
    final transactions = _filteredTransactions;

    return RefreshIndicator(
      onRefresh: _refresh,
      child: ListView(
        physics:
            const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(
          18,
          18,
          18,
          30,
        ),
        children: [
          const PrototypeHeader(
            title: 'Movimientos',
          ),

          const SizedBox(height: 20),

          // ===================================================
          // RESUMEN
          // ===================================================

          _SummarySection(
            income: _totalIncome,
            expenses: _totalExpenses,
            balance: _balance,
          ),

          const SizedBox(height: 20),

          // ===================================================
          // BOTONES AGREGAR
          // ===================================================

          Row(
            children: [
              Expanded(
                child: FilledButton.icon(
                  style: FilledButton.styleFrom(
                    backgroundColor:
                        AppTheme.primary,
                  ),
                  onPressed: widget.state.loading
                      ? null
                      : () {
                          _openTransactionForm(
                            type: 'expense',
                          );
                        },
                  icon: const Icon(
                    Icons
                        .remove_circle_outline_rounded,
                  ),
                  label: const Text(
                    'Gasto',
                  ),
                ),
              ),

              const SizedBox(width: 10),

              Expanded(
                child: FilledButton.icon(
                  style: FilledButton.styleFrom(
                    backgroundColor:
                        AppTheme.success,
                  ),
                  onPressed: widget.state.loading
                      ? null
                      : () {
                          _openTransactionForm(
                            type: 'income',
                          );
                        },
                  icon: const Icon(
                    Icons
                        .add_circle_outline_rounded,
                  ),
                  label: const Text(
                    'Ingreso',
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 24),

          // ===================================================
          // FILTRO POR TIPO
          // ===================================================

          const Text(
            'Tipo de movimiento',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w900,
              color: AppTheme.text,
            ),
          ),

          const SizedBox(height: 10),

          Row(
            children: [
              Expanded(
                child: _TypeFilterButton(
                  label: 'Todos',
                  selected:
                      typeFilter == 'Todos',
                  onTap: () {
                    setState(() {
                      typeFilter = 'Todos';
                      categoryFilter = 'Todos';
                    });
                  },
                ),
              ),

              const SizedBox(width: 8),

              Expanded(
                child: _TypeFilterButton(
                  label: 'Gastos',
                  selected:
                      typeFilter == 'Gastos',
                  onTap: () {
                    setState(() {
                      typeFilter = 'Gastos';
                      categoryFilter = 'Todos';
                    });
                  },
                ),
              ),

              const SizedBox(width: 8),

              Expanded(
                child: _TypeFilterButton(
                  label: 'Ingresos',
                  selected:
                      typeFilter == 'Ingresos',
                  green: true,
                  onTap: () {
                    setState(() {
                      typeFilter = 'Ingresos';
                      categoryFilter = 'Todos';
                    });
                  },
                ),
              ),
            ],
          ),

          const SizedBox(height: 22),

          // ===================================================
          // FILTRO CATEGORÍA
          // ===================================================

          const Text(
            'Filtrar por categoría',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w900,
              color: AppTheme.text,
            ),
          ),

          const SizedBox(height: 10),

          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                for (final category
                    in _availableCategories)
                  _CategoryChip(
                    label: category,
                    selected:
                        categoryFilter ==
                        category,
                    onTap: () {
                      setState(() {
                        categoryFilter =
                            category;
                      });
                    },
                  ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // ===================================================
          // CABECERA
          // ===================================================

          Row(
            children: [
              const Expanded(
                child: Text(
                  'Movimientos',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight:
                        FontWeight.w900,
                    color: AppTheme.text,
                  ),
                ),
              ),

              Container(
                padding:
                    const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color:
                      const Color(0xFFEAF3FF),
                  borderRadius:
                      BorderRadius.circular(20),
                ),
                child: Text(
                  '${transactions.length}',
                  style: const TextStyle(
                    fontSize: 11,
                    color:
                        AppTheme.primary,
                    fontWeight:
                        FontWeight.w900,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // ===================================================
          // LISTA
          // ===================================================

          if (transactions.isEmpty)
            _EmptyTransactions(
              filter: typeFilter,
              onAddExpense: () {
                _openTransactionForm(
                  type: 'expense',
                );
              },
              onAddIncome: () {
                _openTransactionForm(
                  type: 'income',
                );
              },
            )
          else
            ...transactions.map(
              (transaction) {
                return Padding(
                  padding:
                      const EdgeInsets.only(
                    bottom: 10,
                  ),
                  child:
                      _TransactionCard(
                    icon:
                        _iconForCategory(
                      transaction.category,
                    ),
                    transaction:
                        transaction,
                    onEdit: () {
                      _openTransactionForm(
                        type:
                            transaction.type,
                        transaction:
                            transaction,
                      );
                    },
                    onDelete: () {
                      _deleteTransaction(
                        transaction,
                      );
                    },
                  ),
                );
              },
            ),
        ],
      ),
    );
  }
}

// =============================================================
// RESUMEN
// =============================================================

class _SummarySection extends StatelessWidget {
  final double income;
  final double expenses;
  final double balance;

  const _SummarySection({
    required this.income,
    required this.expenses,
    required this.balance,
  });

  @override
  Widget build(BuildContext context) {
    return PrototypePanel(
      padding: const EdgeInsets.all(15),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(
                Icons
                    .account_balance_wallet_outlined,
                color: AppTheme.primary,
                size: 21,
              ),
              SizedBox(width: 8),
              Text(
                'Resumen de movimientos',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight:
                      FontWeight.w900,
                  color: AppTheme.text,
                ),
              ),
            ],
          ),

          const SizedBox(height: 15),

          Row(
            children: [
              Expanded(
                child: _SummaryValue(
                  icon: Icons
                      .arrow_downward_rounded,
                  title: 'Ingresos',
                  amount: income,
                  color:
                      AppTheme.success,
                  background:
                      const Color(
                    0xFFE9FFF2,
                  ),
                ),
              ),

              const SizedBox(width: 10),

              Expanded(
                child: _SummaryValue(
                  icon: Icons
                      .arrow_upward_rounded,
                  title: 'Gastos',
                  amount: expenses,
                  color:
                      AppTheme.primary,
                  background:
                      const Color(
                    0xFFEAF3FF,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 10),

          Container(
            width: double.infinity,
            padding:
                const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 12,
            ),
            decoration: BoxDecoration(
              color:
                  const Color(0xFFF8FAFD),
              borderRadius:
                  BorderRadius.circular(14),
              border: Border.all(
                color: AppTheme.border,
              ),
            ),
            child: Row(
              children: [
                const Expanded(
                  child: Text(
                    'Balance de movimientos',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight:
                          FontWeight.w800,
                    ),
                  ),
                ),
                Text(
                  money(balance),
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight:
                        FontWeight.w900,
                    color: balance >= 0
                        ? AppTheme.success
                        : Colors.red.shade700,
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

class _SummaryValue extends StatelessWidget {
  final IconData icon;
  final String title;
  final double amount;
  final Color color;
  final Color background;

  const _SummaryValue({
    required this.icon,
    required this.title,
    required this.amount,
    required this.color,
    required this.background,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: background,
        borderRadius:
            BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                icon,
                size: 17,
                color: color,
              ),
              const SizedBox(width: 5),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight:
                        FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 7),

          FittedBox(
            fit: BoxFit.scaleDown,
            alignment:
                Alignment.centerLeft,
            child: Text(
              money(amount),
              style: TextStyle(
                fontSize: 18,
                fontWeight:
                    FontWeight.w900,
                color: color,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// =============================================================
// TARJETA DE MOVIMIENTO
// =============================================================

class _TransactionCard extends StatelessWidget {
  final IconData icon;
  final MoneyTransaction transaction;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _TransactionCard({
    required this.icon,
    required this.transaction,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final isIncome =
        transaction.type.toLowerCase() ==
        'income';

    final accent = isIncome
        ? AppTheme.success
        : AppTheme.primary;

    final iconBackground = isIncome
        ? const Color(0xFFE9FFF2)
        : const Color(0xFFEAF3FF);

    return Material(
      color: Colors.white,
      borderRadius:
          BorderRadius.circular(14),
      child: InkWell(
        borderRadius:
            BorderRadius.circular(14),
        onTap: onEdit,
        child: Container(
          padding:
              const EdgeInsets.symmetric(
            horizontal: 13,
            vertical: 12,
          ),
          decoration: BoxDecoration(
            borderRadius:
                BorderRadius.circular(14),
            border: Border.all(
              color: AppTheme.border,
            ),
          ),
          child: Row(
            children: [
              // ICONO

              Container(
                width: 43,
                height: 43,
                decoration: BoxDecoration(
                  color: iconBackground,
                  borderRadius:
                      BorderRadius.circular(
                    11,
                  ),
                ),
                child: Icon(
                  icon,
                  color: accent,
                  size: 22,
                ),
              ),

              const SizedBox(width: 12),

              // INFORMACIÓN

              Expanded(
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            transaction.category,
                            maxLines: 1,
                            overflow:
                                TextOverflow
                                    .ellipsis,
                            style:
                                const TextStyle(
                              fontSize: 14,
                              fontWeight:
                                  FontWeight
                                      .w900,
                              color:
                                  AppTheme.text,
                            ),
                          ),
                        ),

                        const SizedBox(width: 6),

                        Container(
                          padding:
                              const EdgeInsets
                                  .symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration:
                              BoxDecoration(
                            color:
                                iconBackground,
                            borderRadius:
                                BorderRadius
                                    .circular(20),
                          ),
                          child: Text(
                            isIncome
                                ? 'Ingreso'
                                : 'Gasto',
                            style:
                                TextStyle(
                              fontSize: 8.5,
                              fontWeight:
                                  FontWeight
                                      .w800,
                              color: accent,
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 4),

                    Text(
                      transaction.description
                              .trim()
                              .isEmpty
                          ? shortDate(
                              transaction.date,
                            )
                          : '${transaction.description} • ${shortDate(transaction.date)}',
                      maxLines: 1,
                      overflow:
                          TextOverflow.ellipsis,
                      style:
                          const TextStyle(
                        fontSize: 10.5,
                        color:
                            AppTheme.muted,
                      ),
                    ),

                    if (!isIncome &&
                        !transaction.recognized)
                      const Padding(
                        padding:
                            EdgeInsets.only(
                          top: 4,
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons
                                  .help_outline_rounded,
                              size: 13,
                              color:
                                  Colors.orange,
                            ),
                            SizedBox(width: 4),
                            Text(
                              'No reconocido',
                              style:
                                  TextStyle(
                                fontSize: 10,
                                color:
                                    Colors.orange,
                                fontWeight:
                                    FontWeight
                                        .w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),

              const SizedBox(width: 8),

              // MONTO

              Text(
                isIncome
                    ? '+${money(transaction.amount)}'
                    : '-${money(transaction.amount)}',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight:
                      FontWeight.w900,
                  color: isIncome
                      ? AppTheme.success
                      : AppTheme.text,
                ),
              ),

              // MENÚ

              PopupMenuButton<String>(
                tooltip: 'Opciones',
                icon: const Icon(
                  Icons.more_vert_rounded,
                  color: AppTheme.muted,
                ),
                onSelected: (value) {
                  if (value == 'edit') {
                    onEdit();
                  }

                  if (value == 'delete') {
                    onDelete();
                  }
                },
                itemBuilder: (_) => const [
                  PopupMenuItem(
                    value: 'edit',
                    child: Row(
                      children: [
                        Icon(
                          Icons.edit_outlined,
                          size: 19,
                        ),
                        SizedBox(width: 10),
                        Text('Editar'),
                      ],
                    ),
                  ),

                  PopupMenuItem(
                    value: 'delete',
                    child: Row(
                      children: [
                        Icon(
                          Icons
                              .delete_outline_rounded,
                          size: 19,
                          color: Colors.red,
                        ),
                        SizedBox(width: 10),
                        Text(
                          'Eliminar',
                          style: TextStyle(
                            color: Colors.red,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// =============================================================
// FILTRO TIPO
// =============================================================

class _TypeFilterButton extends StatelessWidget {
  final String label;
  final bool selected;
  final bool green;
  final VoidCallback onTap;

  const _TypeFilterButton({
    required this.label,
    required this.selected,
    required this.onTap,
    this.green = false,
  });

  @override
  Widget build(BuildContext context) {
    final accent = green
        ? AppTheme.success
        : AppTheme.primary;

    return InkWell(
      borderRadius:
          BorderRadius.circular(12),
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(
          milliseconds: 150,
        ),
        height: 43,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected
              ? accent
              : Colors.white,
          borderRadius:
              BorderRadius.circular(12),
          border: Border.all(
            color: selected
                ? accent
                : AppTheme.border,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight:
                FontWeight.w800,
            color: selected
                ? Colors.white
                : AppTheme.text,
          ),
        ),
      ),
    );
  }
}

// =============================================================
// FILTRO CATEGORÍA
// =============================================================

class _CategoryChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _CategoryChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding:
          const EdgeInsets.only(
        right: 8,
      ),
      child: InkWell(
        borderRadius:
            BorderRadius.circular(50),
        onTap: onTap,
        child: AnimatedContainer(
          duration:
              const Duration(
            milliseconds: 150,
          ),
          padding:
              const EdgeInsets.symmetric(
            horizontal: 15,
            vertical: 9,
          ),
          decoration: BoxDecoration(
            color: selected
                ? AppTheme.primary
                : Colors.white,
            borderRadius:
                BorderRadius.circular(50),
            border: Border.all(
              color: selected
                  ? AppTheme.primary
                  : AppTheme.border,
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight:
                  FontWeight.w800,
              color: selected
                  ? Colors.white
                  : AppTheme.text,
            ),
          ),
        ),
      ),
    );
  }
}

// =============================================================
// ESTADO VACÍO
// =============================================================

class _EmptyTransactions
    extends StatelessWidget {
  final String filter;

  final VoidCallback onAddExpense;
  final VoidCallback onAddIncome;

  const _EmptyTransactions({
    required this.filter,
    required this.onAddExpense,
    required this.onAddIncome,
  });

  @override
  Widget build(BuildContext context) {
    String title;
    String description;

    if (filter == 'Gastos') {
      title = 'No hay gastos';
      description =
          'Los gastos que registrés aparecerán aquí.';
    } else if (filter == 'Ingresos') {
      title = 'No hay ingresos';
      description =
          'Registrá dinero que recibís para comenzar.';
    } else {
      title = 'No hay movimientos';
      description =
          'Agregá un gasto o un ingreso para comenzar.';
    }

    return Container(
      width: double.infinity,
      padding:
          const EdgeInsets.symmetric(
        horizontal: 25,
        vertical: 38,
      ),
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
          Container(
            width: 65,
            height: 65,
            decoration: BoxDecoration(
              color:
                  const Color(0xFFEAF3FF),
              borderRadius:
                  BorderRadius.circular(18),
            ),
            child: const Icon(
              Icons
                  .account_balance_wallet_outlined,
              color: AppTheme.primary,
              size: 32,
            ),
          ),

          const SizedBox(height: 16),

          Text(
            title,
            textAlign:
                TextAlign.center,
            style:
                const TextStyle(
              fontSize: 16,
              fontWeight:
                  FontWeight.w900,
            ),
          ),

          const SizedBox(height: 7),

          Text(
            description,
            textAlign:
                TextAlign.center,
            style:
                const TextStyle(
              fontSize: 12,
              height: 1.4,
              color: AppTheme.muted,
            ),
          ),

          const SizedBox(height: 18),

          if (filter == 'Ingresos')
            FilledButton.icon(
              style:
                  FilledButton.styleFrom(
                backgroundColor:
                    AppTheme.success,
              ),
              onPressed: onAddIncome,
              icon: const Icon(
                Icons.add_rounded,
              ),
              label: const Text(
                'Agregar ingreso',
              ),
            )
          else if (filter == 'Gastos')
            FilledButton.icon(
              onPressed: onAddExpense,
              icon: const Icon(
                Icons.add_rounded,
              ),
              label: const Text(
                'Agregar gasto',
              ),
            )
          else
            Row(
              children: [
                Expanded(
                  child:
                      FilledButton.icon(
                    onPressed:
                        onAddExpense,
                    icon: const Icon(
                      Icons
                          .remove_circle_outline_rounded,
                    ),
                    label:
                        const Text(
                      'Gasto',
                    ),
                  ),
                ),

                const SizedBox(
                  width: 10,
                ),

                Expanded(
                  child:
                      FilledButton.icon(
                    style:
                        FilledButton.styleFrom(
                      backgroundColor:
                          AppTheme.success,
                    ),
                    onPressed:
                        onAddIncome,
                    icon: const Icon(
                      Icons
                          .add_circle_outline_rounded,
                    ),
                    label:
                        const Text(
                      'Ingreso',
                    ),
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }
}