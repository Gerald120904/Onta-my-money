import 'package:flutter/material.dart';

import '../core/theme/app_theme.dart';
import '../core/utils/formatters.dart';
import '../models/models.dart';
import '../providers/app_state.dart';
import '../widgets/account_selector.dart';
import '../widgets/prototype_ui.dart';
import 'commitments_screen.dart';
import 'goals_screen.dart';

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
  // INDICADORES MENSUALES (SEPARADOS DEL SALDO HISTÓRICO)
  // =========================================================

  double get _monthIncome {
    return _monthTransactions
        .where(
          (transaction) => transaction.type.toLowerCase() == 'income',
        )
        .fold<double>(
          0,
          (total, transaction) => total + transaction.amount,
        );
  }

  double get _monthExpenses {
    return _monthTransactions
        .where(
          (transaction) => transaction.type.toLowerCase() == 'expense',
        )
        .fold<double>(
          0,
          (total, transaction) => total + transaction.amount,
        );
  }

  double get _totalIncome => _monthIncome;
  double get _totalExpenses => _monthExpenses;

  // =========================================================
  // SALDO ACTUAL (HISTÓRICO REAL DE LA CUENTA ACTIVA)
  // =========================================================

  double get _currentBalance {
    return state.dashboard?.balance ?? state.currentBalance;
  }

  // =========================================================
  // DINERO COMPROMETIDO
  // =========================================================

  double get _committed {
    return state.dashboard?.committed ?? state.committedAmount;
  }

  // =========================================================
  // AHORRO RESERVADO
  // =========================================================

  double get _saved {
    return state.dashboard?.saved ?? state.savedAmount;
  }

  // =========================================================
  // DISPONIBLE REAL
  // =========================================================

  double get _available {
    return state.dashboard?.available ??
        (_currentBalance - _committed - _saved);
  }

  // =========================================================
  // BUILD
  // =========================================================

  @override
  @override
  Widget build(BuildContext context) {
    final isDark = AppTheme.isDarkMode(context);
    final textColor = AppTheme.textColor(context);
    final mutedColor = AppTheme.mutedColor(context);
    final borderColor = AppTheme.borderColor(context);
    final cardBg = AppTheme.cardBg(context);
    final balanceBg = AppTheme.tintPrimary(context);

    return RefreshIndicator(
      onRefresh: state.refreshAll,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(18, 18, 18, 22),
        children: [
          // ===================================================
          // HEADER
          // ===================================================

          const PrototypeHeader(
            title: '¿Dónde se fue\nmi plata?',
            showProfile: true,
          ),

          const SizedBox(height: 12),

          // ===================================================
          // SELECTOR DE CUENTA FINANCIERA (INMUTABLE)
          // ===================================================

          AccountSelectorBar(state: state),

          const SizedBox(height: 14),

          // ===================================================
          // ESTADO DEL SISTEMA (H1)
          // ===================================================

          if (state.loading) ...[
            Semantics(
              liveRegion: true,
              container: true,
              label: 'Actualizando información financiera.',
              child: const _LoadingStatusCard(),
            ),
            const SizedBox(height: 17),
          ],

          // ===================================================
          // RESUMEN DEL MES
          // ===================================================

          PrototypePanel(
            padding: const EdgeInsets.all(10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(
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
                            fontWeight: FontWeight.w900,
                            color: textColor,
                          ),
                        ),
                      ),
                      Icon(
                        Icons.visibility_outlined,
                        size: 18,
                        color:
                            isDark ? const Color(0xFF60A5FA) : AppTheme.primary,
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
                      'Saldo actual. ${money(_currentBalance)}. Dinero restante después de ingresos y gastos. Ingresos ${money(_totalIncome)}. Gastos ${money(_totalExpenses)}.',
                  child: ExcludeSemantics(
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(13),
                      decoration: BoxDecoration(
                        color: balanceBg,
                        borderRadius: BorderRadius.circular(13),
                        border: Border.all(
                          color: borderColor,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.account_balance_wallet_outlined,
                                size: 19,
                                color: isDark
                                    ? const Color(0xFF60A5FA)
                                    : AppTheme.primary,
                              ),
                              const SizedBox(width: 7),
                              Expanded(
                                child: Text(
                                  'Saldo actual',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w800,
                                    color: textColor,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Dinero restante después de ingresos y gastos',
                            style: TextStyle(
                              fontSize: 12.5,
                              height: 1.3,
                              color: mutedColor,
                            ),
                          ),
                          const SizedBox(height: 7),
                          Text(
                            money(_currentBalance),
                            style: TextStyle(
                              fontSize: 25,
                              height: 1.05,
                              fontWeight: FontWeight.w900,
                              color: _currentBalance >= 0
                                  ? textColor
                                  : (isDark
                                      ? const Color(0xFFF87171)
                                      : Colors.red.shade700),
                            ),
                          ),
                          const SizedBox(height: 10),
                          Wrap(
                            spacing: 8,
                            runSpacing: 7,
                            children: [
                              _BalanceDetail(
                                icon: Icons.add_circle_outline_rounded,
                                label: 'Ingreso',
                                amount: _totalIncome,
                                color: isDark
                                    ? const Color(0xFF4ADE80)
                                    : AppTheme.success,
                              ),
                              _BalanceDetail(
                                icon: Icons.remove_circle_outline_rounded,
                                label: 'Gasto',
                                amount: _totalExpenses,
                                color: isDark
                                    ? const Color(0xFFF87171)
                                    : Colors.red.shade700,
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
                  button: true,
                  container: true,
                  label:
                      'Dinero comprometido. ${money(_committed)}. Reservado para pagos y compromisos pendientes.',
                  child: ExcludeSemantics(
                    child: MoneyCard(
                      title: 'Dinero comprometido',
                      amount: _committed,
                      subtitle: 'Reservado para pagos y compromisos pendientes',
                      icon: Icons.event_note_outlined,
                      showArrow: true,
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => CommitmentsScreen(state: state),
                          ),
                        );
                      },
                    ),
                  ),
                ),

                const SizedBox(height: 9),

                // =================================================
                // AHORRO RESERVADO
                // =================================================

                Semantics(
                  button: true,
                  container: true,
                  label:
                      'Ahorro reservado. ${money(_saved)}. Dinero protegido para tus metas.',
                  child: ExcludeSemantics(
                    child: MoneyCard(
                      title: 'Ahorro reservado',
                      amount: _saved,
                      subtitle: 'Dinero protegido para tus metas',
                      icon: Icons.savings_outlined,
                      showArrow: true,
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => GoalsScreen(state: state),
                          ),
                        );
                      },
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
                      'Disponible real. ${money(_available)}. Dinero que podés utilizar sin afectar compromisos ni ahorro.',
                  child: ExcludeSemantics(
                    child: MoneyCard(
                      title: 'Disponible real',
                      amount: _available,
                      subtitle:
                          'Dinero que podés utilizar sin afectar compromisos ni ahorro',
                      icon: Icons.check_circle_outline_rounded,
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
            onPressed: state.loading ? null : onReview,
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

          if (_monthTransactions.isEmpty)
            Semantics(
              container: true,
              label: 'No hay movimientos registrados este mes.',
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: cardBg,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: borderColor,
                  ),
                ),
                child: Column(
                  children: [
                    Icon(
                      Icons.receipt_long_outlined,
                      size: 32,
                      color:
                          isDark ? const Color(0xFF60A5FA) : AppTheme.primary,
                    ),
                    const SizedBox(height: 9),
                    Text(
                      'No hay movimientos este mes',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w900,
                        color: textColor,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Cuando registrés un ingreso o un gasto, aparecerá aquí.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 13,
                        height: 1.35,
                        color: mutedColor,
                      ),
                    ),
                  ],
                ),
              ),
            )
          else ...[
            Text(
              'Últimos movimientos',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w900,
                color: textColor,
              ),
            ),
            const SizedBox(height: 10),
            ..._latestTransactions.map(
              (transaction) {
                final isIncome = transaction.type.toLowerCase() == 'income';
                final typeLabel = isIncome ? 'INGRESO' : 'GASTO';
                final accent = isIncome
                    ? (isDark ? const Color(0xFF4ADE80) : AppTheme.success)
                    : (isDark ? const Color(0xFFF87171) : Colors.red.shade700);
                final iconBg = isIncome
                    ? (isDark
                        ? const Color(0xFF0F3A2A)
                        : const Color(0xFFE9FFF2))
                    : (isDark
                        ? const Color(0xFF3F1218)
                        : const Color(0xFFFFF1F1));

                final semanticDescription =
                    transaction.description.trim().isEmpty
                        ? ''
                        : '. ${transaction.description}';

                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Semantics(
                    container: true,
                    label:
                        '$typeLabel. ${transaction.category}. ${money(transaction.amount)}$semanticDescription.',
                    child: ExcludeSemantics(
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 13,
                          vertical: 11,
                        ),
                        decoration: BoxDecoration(
                          color: cardBg,
                          borderRadius: BorderRadius.circular(13),
                          border: Border.all(
                            color: borderColor,
                          ),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color: iconBg,
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: accent.withOpacity(.25),
                                ),
                              ),
                              child: Icon(
                                isIncome
                                    ? Icons.add_rounded
                                    : Icons.remove_rounded,
                                color: accent,
                                size: 23,
                              ),
                            ),
                            const SizedBox(width: 11),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 7,
                                      vertical: 3,
                                    ),
                                    decoration: BoxDecoration(
                                      color: iconBg,
                                      borderRadius: BorderRadius.circular(20),
                                      border: Border.all(
                                        color: accent,
                                      ),
                                    ),
                                    child: Text(
                                      typeLabel,
                                      style: TextStyle(
                                        fontSize: 10.5,
                                        letterSpacing: .4,
                                        fontWeight: FontWeight.w900,
                                        color: accent,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 5),
                                  Text(
                                    transaction.category,
                                    style: TextStyle(
                                      fontSize: 14.5,
                                      fontWeight: FontWeight.w900,
                                      color: textColor,
                                    ),
                                  ),
                                  if (transaction.description
                                      .trim()
                                      .isNotEmpty) ...[
                                    const SizedBox(height: 2),
                                    Text(
                                      transaction.description,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: mutedColor,
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  isIncome
                                      ? '+${money(transaction.amount)}'
                                      : '-${money(transaction.amount)}',
                                  style: TextStyle(
                                    fontSize: 14.5,
                                    fontWeight: FontWeight.w900,
                                    color: isIncome ? accent : textColor,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  isIncome ? 'Recibido' : 'Gastado',
                                  style: TextStyle(
                                    fontSize: 11.5,
                                    color: mutedColor,
                                    fontWeight: FontWeight.w600,
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
    final list = List<MoneyTransaction>.from(_monthTransactions);
    list.sort((a, b) => b.date.compareTo(a.date));
    return list.take(3).toList();
  }
}

// =============================================================
// ESTADO DE CARGA (H1)
// =============================================================

class _LoadingStatusCard extends StatelessWidget {
  const _LoadingStatusCard();

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDark ? const Color(0xFF2D2005) : const Color(0xFFFFF8E8);
    final borderColor =
        isDark ? const Color(0xFFB45309) : const Color(0xFFE8C86B);
    final textColor = isDark ? const Color(0xFFFDE68A) : AppTheme.text;
    final progressColor = isDark ? const Color(0xFFFBBF24) : AppTheme.primary;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(
              strokeWidth: 2.4,
              color: progressColor,
            ),
          ),
          const SizedBox(width: 9),
          Expanded(
            child: Text(
              'Actualizando información...',
              style: TextStyle(
                fontSize: 11.5,
                fontWeight: FontWeight.w900,
                color: textColor,
              ),
            ),
          ),
        ],
      ),
    );
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
    final bg = AppTheme.cardBg(context).withOpacity(.85);
    final borderColor = AppTheme.borderColor(context);
    final textColor = AppTheme.textColor(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(9),
        border: Border.all(color: borderColor),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 15, color: color),
          const SizedBox(width: 5),
          Text(
            '$label: ${money(amount)}',
            style: TextStyle(
              fontSize: 12,
              color: textColor,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}
