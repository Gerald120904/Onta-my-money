import 'package:flutter/material.dart';

import '../core/theme/app_theme.dart';
import '../core/utils/formatters.dart';
import '../models/models.dart';
import '../providers/app_state.dart';
import '../widgets/prototype_ui.dart';

class DashboardScreen extends StatelessWidget {
  final AppState state;
  final VoidCallback onReview;

  const DashboardScreen({
    super.key,
    required this.state,
    required this.onReview,
  });

  // =========================================================
  // MOVIMIENTOS DEL MES ACTUAL
  // =========================================================

  List<MoneyTransaction> get _monthTransactions {
    final now = DateTime.now();

    return state.transactions.where(
      (transaction) {
        return transaction.date.year == now.year &&
            transaction.date.month == now.month;
      },
    ).toList();
  }

  // =========================================================
  // TOTAL INGRESOS
  // =========================================================

  double get _totalIncome {
    return _monthTransactions
        .where(
          (transaction) =>
              transaction.type.toLowerCase() ==
              'income',
        )
        .fold<double>(
          0,
          (total, transaction) =>
              total + transaction.amount,
        );
  }

  // =========================================================
  // TOTAL GASTOS
  // =========================================================

  double get _totalExpenses {
    return _monthTransactions
        .where(
          (transaction) =>
              transaction.type.toLowerCase() ==
              'expense',
        )
        .fold<double>(
          0,
          (total, transaction) =>
              total + transaction.amount,
        );
  }

  // =========================================================
  // SALDO ACTUAL
  // =========================================================

  double get _currentBalance {
    return _totalIncome - _totalExpenses;
  }

  // =========================================================
  // DINERO COMPROMETIDO
  // =========================================================

  double get _committed {
    return state.dashboard?.committed ?? 0;
  }

  // =========================================================
  // AHORRO RESERVADO
  // =========================================================

  double get _saved {
    return state.dashboard?.saved ?? 0;
  }

  // =========================================================
  // DISPONIBLE REAL
  // =========================================================

  double get _available {
    final result =
        _currentBalance - _committed - _saved;

    return result;
  }

  // =========================================================
  // BUILD
  // =========================================================

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: state.refreshAll,
      child: ListView(
        physics:
            const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(
          18,
          18,
          18,
          22,
        ),
        children: [
          // ===================================================
          // HEADER
          // ===================================================

          const PrototypeHeader(
            title: '¿Dónde se fue\nmi plata?',
            showProfile: true,
          ),

          const SizedBox(height: 17),

          // ===================================================
          // RESUMEN DEL MES
          // ===================================================

          PrototypePanel(
            padding: const EdgeInsets.all(10),
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                const Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: 4,
                    vertical: 2,
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Resumen del mes',
                          style: TextStyle(
                            fontSize: 12.5,
                            fontWeight:
                                FontWeight.w900,
                          ),
                        ),
                      ),
                      Icon(
                        Icons.visibility_outlined,
                        size: 18,
                        color: AppTheme.primary,
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 8),

                // =================================================
                // SALDO ACTUAL
                // =================================================

                Semantics(
                  container: true,
                  label:
                      'Saldo actual. '
                      '${money(_currentBalance)}. '
                      'Dinero restante después de ingresos y gastos. '
                      'Ingresos ${money(_totalIncome)}. '
                      'Gastos ${money(_totalExpenses)}.',
                  child: ExcludeSemantics(
                    child: Container(
                      width: double.infinity,
                      padding:
                          const EdgeInsets.fromLTRB(
                        13,
                        13,
                        13,
                        13,
                      ),
                      decoration: BoxDecoration(
                        color:
                            const Color(0xFFE7F2FF),
                        borderRadius:
                            BorderRadius.circular(13),
                        border: Border.all(
                          color: AppTheme.border,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment:
                            CrossAxisAlignment.start,
                        children: [
                          const Row(
                            children: [
                              Icon(
                                Icons
                                    .account_balance_wallet_outlined,
                                size: 19,
                                color:
                                    AppTheme.primary,
                              ),
                              SizedBox(width: 7),
                              Expanded(
                                child: Text(
                                  'Saldo actual',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight:
                                        FontWeight
                                            .w800,
                                    color:
                                        AppTheme.text,
                                  ),
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 4),

                          const Text(
                            'Dinero restante después de ingresos y gastos',
                            style: TextStyle(
                              fontSize: 10.5,
                              height: 1.3,
                              color: AppTheme.muted,
                            ),
                          ),

                          const SizedBox(height: 7),

                          Text(
                            money(_currentBalance),
                            style: TextStyle(
                              fontSize: 25,
                              height: 1.05,
                              fontWeight:
                                  FontWeight.w900,
                              color:
                                  _currentBalance >= 0
                                      ? AppTheme.text
                                      : Colors
                                          .red.shade700,
                            ),
                          ),

                          const SizedBox(height: 10),

                          Wrap(
                            spacing: 8,
                            runSpacing: 7,
                            children: [
                              _BalanceDetail(
                                icon: Icons
                                    .add_circle_outline_rounded,
                                label: 'Ingreso',
                                amount:
                                    _totalIncome,
                                color:
                                    AppTheme.success,
                              ),
                              _BalanceDetail(
                                icon: Icons
                                    .remove_circle_outline_rounded,
                                label: 'Gasto',
                                amount:
                                    _totalExpenses,
                                color:
                                    Colors.red.shade700,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 10),

                // =================================================
                // COMPROMETIDO
                // =================================================

                Semantics(
                  container: true,
                  label:
                      'Dinero comprometido. '
                      '${money(_committed)}. '
                      'Dinero reservado para pagos y compromisos pendientes.',
                  child: ExcludeSemantics(
                    child: MoneyCard(
                      title:
                          'Dinero comprometido',
                      amount: _committed,
                      subtitle:
                          'Reservado para pagos y compromisos pendientes',
                      icon: Icons
                          .event_note_outlined,
                      showArrow: false,
                    ),
                  ),
                ),

                const SizedBox(height: 9),

                // =================================================
                // AHORRO RESERVADO
                // =================================================

                Semantics(
                  container: true,
                  label:
                      'Ahorro reservado. '
                      '${money(_saved)}. '
                      'Dinero protegido para tus metas.',
                  child: ExcludeSemantics(
                    child: MoneyCard(
                      title: 'Ahorro reservado',
                      amount: _saved,
                      subtitle:
                          'Dinero protegido para tus metas',
                      icon:
                          Icons.savings_outlined,
                      showArrow: false,
                    ),
                  ),
                ),

                const SizedBox(height: 9),

                // =================================================
                // DISPONIBLE REAL
                // =================================================

                Semantics(
                  container: true,
                  label:
                      'Disponible real. '
                      '${money(_available)}. '
                      'Dinero que podés utilizar sin afectar compromisos ni ahorro.',
                  child: ExcludeSemantics(
                    child: MoneyCard(
                      title: 'Disponible real',
                      amount: _available,
                      subtitle:
                          'Dinero que podés utilizar sin afectar compromisos ni ahorro',
                      icon:
                          Icons.check_circle_outline_rounded,
                      green: _available >= 0,
                      showArrow: false,
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 17),

          // ===================================================
          // REVISAR DINERO
          // ===================================================

          FilledButton.icon(
            onPressed: onReview,
            icon: const Icon(
              Icons.add_circle_outline_rounded,
              size: 20,
            ),
            label: const Text(
              'Revisar mi dinero',
            ),
          ),

          const SizedBox(height: 20),

          // ===================================================
          // ÚLTIMOS MOVIMIENTOS
          // ===================================================

          if (_monthTransactions.isNotEmpty) ...[
            const Text(
              'Últimos movimientos',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w900,
                color: AppTheme.text,
              ),
            ),

            const SizedBox(height: 4),

            const Text(
              'Cada movimiento indica por texto si corresponde a un ingreso o un gasto.',
              style: TextStyle(
                fontSize: 10.5,
                height: 1.3,
                color: AppTheme.muted,
              ),
            ),

            const SizedBox(height: 10),

            ..._latestTransactions.map(
              (transaction) {
                final isIncome =
                    transaction.type.toLowerCase() ==
                        'income';

                final typeLabel =
                    isIncome ? 'INGRESO' : 'GASTO';

                final semanticDescription =
                    transaction.description
                            .trim()
                            .isEmpty
                        ? ''
                        : '. ${transaction.description}';

                return Padding(
                  padding:
                      const EdgeInsets.only(
                    bottom: 8,
                  ),
                  child: Semantics(
                    container: true,
                    label:
                        '$typeLabel. '
                        '${transaction.category}. '
                        '${money(transaction.amount)}'
                        '$semanticDescription.',
                    child: ExcludeSemantics(
                      child: Container(
                        padding:
                            const EdgeInsets.symmetric(
                          horizontal: 13,
                          vertical: 11,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius:
                              BorderRadius.circular(
                            13,
                          ),
                          border: Border.all(
                            color:
                                AppTheme.border,
                          ),
                        ),
                        child: Row(
                          children: [
                            // =====================================
                            // ICONO
                            // =====================================

                            Container(
                              width: 40,
                              height: 40,
                              decoration:
                                  BoxDecoration(
                                color: isIncome
                                    ? const Color(
                                        0xFFE9FFF2,
                                      )
                                    : const Color(
                                        0xFFFFF1F1,
                                      ),
                                borderRadius:
                                    BorderRadius
                                        .circular(10),
                                border:
                                    Border.all(
                                  color: isIncome
                                      ? AppTheme
                                          .success
                                          .withOpacity(
                                            .25,
                                          )
                                      : Colors
                                          .red
                                          .shade700
                                          .withOpacity(
                                            .25,
                                          ),
                                ),
                              ),
                              child: Icon(
                                isIncome
                                    ? Icons
                                        .add_rounded
                                    : Icons
                                        .remove_rounded,
                                color: isIncome
                                    ? AppTheme
                                        .success
                                    : Colors
                                        .red
                                        .shade700,
                                size: 23,
                              ),
                            ),

                            const SizedBox(
                              width: 11,
                            ),

                            // =====================================
                            // INFORMACIÓN
                            // =====================================

                            Expanded(
                              child: Column(
                                crossAxisAlignment:
                                    CrossAxisAlignment
                                        .start,
                                children: [
                                  // =================================
                                  // ETIQUETA EXPLÍCITA
                                  // =================================

                                  Container(
                                    padding:
                                        const EdgeInsets
                                            .symmetric(
                                      horizontal: 7,
                                      vertical: 3,
                                    ),
                                    decoration:
                                        BoxDecoration(
                                      color: isIncome
                                          ? const Color(
                                              0xFFE9FFF2,
                                            )
                                          : const Color(
                                              0xFFFFF1F1,
                                            ),
                                      borderRadius:
                                          BorderRadius
                                              .circular(
                                        20,
                                      ),
                                      border:
                                          Border.all(
                                        color: isIncome
                                            ? AppTheme
                                                .success
                                            : Colors
                                                .red
                                                .shade700,
                                      ),
                                    ),
                                    child: Text(
                                      typeLabel,
                                      style:
                                          TextStyle(
                                        fontSize: 8.5,
                                        letterSpacing:
                                            .4,
                                        fontWeight:
                                            FontWeight
                                                .w900,
                                        color: isIncome
                                            ? AppTheme
                                                .success
                                            : Colors
                                                .red
                                                .shade700,
                                      ),
                                    ),
                                  ),

                                  const SizedBox(
                                    height: 5,
                                  ),

                                  Text(
                                    transaction
                                        .category,
                                    style:
                                        const TextStyle(
                                      fontSize: 13,
                                      fontWeight:
                                          FontWeight
                                              .w900,
                                      color:
                                          AppTheme.text,
                                    ),
                                  ),

                                  if (transaction
                                      .description
                                      .trim()
                                      .isNotEmpty) ...[
                                    const SizedBox(
                                      height: 2,
                                    ),
                                    Text(
                                      transaction
                                          .description,
                                      maxLines: 1,
                                      overflow:
                                          TextOverflow
                                              .ellipsis,
                                      style:
                                          const TextStyle(
                                        fontSize: 10,
                                        color:
                                            AppTheme
                                                .muted,
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),

                            const SizedBox(
                              width: 8,
                            ),

                            // =====================================
                            // MONTO
                            // =====================================

                            Column(
                              crossAxisAlignment:
                                  CrossAxisAlignment
                                      .end,
                              children: [
                                Text(
                                  isIncome
                                      ? '+${money(transaction.amount)}'
                                      : '-${money(transaction.amount)}',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight:
                                        FontWeight
                                            .w900,
                                    color: isIncome
                                        ? AppTheme
                                            .success
                                        : AppTheme
                                            .text,
                                  ),
                                ),

                                const SizedBox(
                                  height: 2,
                                ),

                                Text(
                                  isIncome
                                      ? 'Recibido'
                                      : 'Gastado',
                                  style:
                                      const TextStyle(
                                    fontSize: 9,
                                    color:
                                        AppTheme.muted,
                                    fontWeight:
                                        FontWeight
                                            .w600,
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
              },
            ),
          ],
        ],
      ),
    );
  }

  // =========================================================
  // ÚLTIMOS 3 MOVIMIENTOS
  // =========================================================

  List<MoneyTransaction> get _latestTransactions {
    final list =
        List<MoneyTransaction>.from(
      _monthTransactions,
    );

    list.sort(
      (a, b) =>
          b.date.compareTo(a.date),
    );

    return list.take(3).toList();
  }
}

// =============================================================
// DETALLE DE INGRESOS / GASTOS
// =============================================================

class _BalanceDetail extends StatelessWidget {
  final IconData icon;
  final String label;
  final double amount;
  final Color color;

  const _BalanceDetail({
    required this.icon,
    required this.label,
    required this.amount,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 8,
        vertical: 6,
      ),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(.75),
        borderRadius:
            BorderRadius.circular(9),
        border: Border.all(
          color: AppTheme.border,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 14,
            color: color,
          ),

          const SizedBox(width: 4),

          Text(
            '$label: ${money(amount)}',
            style: const TextStyle(
              fontSize: 10.5,
              color: AppTheme.text,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}