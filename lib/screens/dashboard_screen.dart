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
              transaction.type.toLowerCase() == 'income',
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
              transaction.type.toLowerCase() == 'expense',
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
        physics: const AlwaysScrollableScrollPhysics(),
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

                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.fromLTRB(
                    13,
                    13,
                    13,
                    13,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE7F2FF),
                    borderRadius:
                        BorderRadius.circular(13),
                  ),
                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Saldo actual',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight:
                              FontWeight.w700,
                          color: AppTheme.text,
                        ),
                      ),

                      const SizedBox(height: 4),

                      Text(
                        money(_currentBalance),
                        style: TextStyle(
                          fontSize: 25,
                          height: 1.05,
                          fontWeight:
                              FontWeight.w900,
                          color: _currentBalance >= 0
                              ? AppTheme.text
                              : Colors.red.shade700,
                        ),
                      ),

                      const SizedBox(height: 8),

                      Row(
                        children: [
                          const Icon(
                            Icons
                                .arrow_downward_rounded,
                            size: 14,
                            color: AppTheme.success,
                          ),

                          const SizedBox(width: 3),

                          Text(
                            'Ingresos: ${money(_totalIncome)}',
                            style: const TextStyle(
                              fontSize: 10.5,
                              color:
                                  AppTheme.success,
                              fontWeight:
                                  FontWeight.w700,
                            ),
                          ),

                          const SizedBox(width: 12),

                          Icon(
                            Icons
                                .arrow_upward_rounded,
                            size: 14,
                            color:
                                Colors.red.shade700,
                          ),

                          const SizedBox(width: 3),

                          Flexible(
                            child: Text(
                              'Gastos: ${money(_totalExpenses)}',
                              overflow:
                                  TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 10.5,
                                color:
                                    Colors.red.shade700,
                                fontWeight:
                                    FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 10),

                // =================================================
                // COMPROMETIDO
                // =================================================

                MoneyCard(
                  title: 'Dinero comprometido',
                  amount: _committed,
                  subtitle:
                      'Pagos y compromisos pendientes',
                  icon: Icons
                      .account_balance_wallet_outlined,
                  showArrow: false,
                ),

                const SizedBox(height: 9),

                // =================================================
                // AHORRO
                // =================================================

                MoneyCard(
                  title: 'Ahorro reservado',
                  amount: _saved,
                  subtitle:
                      'Dinero separado para tus metas',
                  icon:
                      Icons.savings_outlined,
                  showArrow: false,
                ),

                const SizedBox(height: 9),

                // =================================================
                // DISPONIBLE
                // =================================================

                MoneyCard(
                  title: 'Disponible real',
                  amount: _available,
                  subtitle:
                      'Lo que podés utilizar sin afectar compromisos ni ahorro',
                  icon:
                      Icons.wallet_outlined,
                  green: _available >= 0,
                  showArrow: false,
                ),
              ],
            ),
          ),

          const SizedBox(height: 17),

          // ===================================================
          // REGISTRAR AVANCE
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

            const SizedBox(height: 10),

            ..._latestTransactions.map(
              (transaction) {
                final isIncome =
                    transaction.type.toLowerCase() ==
                        'income';

                return Padding(
                  padding:
                      const EdgeInsets.only(
                    bottom: 8,
                  ),
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(
                      horizontal: 13,
                      vertical: 11,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius:
                          BorderRadius.circular(13),
                      border: Border.all(
                        color:
                            AppTheme.border,
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 38,
                          height: 38,
                          decoration:
                              BoxDecoration(
                            color: isIncome
                                ? const Color(
                                    0xFFE9FFF2,
                                  )
                                : const Color(
                                    0xFFEAF3FF,
                                  ),
                            borderRadius:
                                BorderRadius
                                    .circular(10),
                          ),
                          child: Icon(
                            isIncome
                                ? Icons
                                    .arrow_downward_rounded
                                : Icons
                                    .arrow_upward_rounded,
                            color: isIncome
                                ? AppTheme.success
                                : AppTheme.primary,
                          ),
                        ),

                        const SizedBox(width: 11),

                        Expanded(
                          child: Column(
                            crossAxisAlignment:
                                CrossAxisAlignment
                                    .start,
                            children: [
                              Text(
                                transaction.category,
                                style:
                                    const TextStyle(
                                  fontSize: 13,
                                  fontWeight:
                                      FontWeight
                                          .w900,
                                ),
                              ),

                              if (transaction
                                  .description
                                  .trim()
                                  .isNotEmpty)
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
                                        AppTheme.muted,
                                  ),
                                ),
                            ],
                          ),
                        ),

                        const SizedBox(width: 8),

                        Text(
                          isIncome
                              ? '+${money(transaction.amount)}'
                              : '-${money(transaction.amount)}',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight:
                                FontWeight.w900,
                            color: isIncome
                                ? AppTheme.success
                                : AppTheme.text,
                          ),
                        ),
                      ],
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