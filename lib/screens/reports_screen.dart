import 'package:flutter/material.dart';

import '../core/theme/app_theme.dart';
import '../core/utils/formatters.dart';
import '../models/models.dart';
import '../models/review_result.dart';
import '../providers/app_state.dart';

class ReportsScreen extends StatelessWidget {
  final AppState state;
  final VoidCallback onCreateReview;

  const ReportsScreen({
    super.key,
    required this.state,
    required this.onCreateReview,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: state,
      builder: (context, _) {
        final reports = state.reviews;

        return ListView(
          padding: const EdgeInsets.fromLTRB(
            18,
            18,
            18,
            40,
          ),
          children: [
            // =================================================
            // ENCABEZADO
            // =================================================

            const Text(
              'Reportes',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w900,
                color: AppTheme.text,
              ),
            ),

            const SizedBox(height: 4),

            const Text(
              'Revisá tus reportes anteriores y las decisiones que has tomado.',
              style: TextStyle(
                fontSize: 11,
                color: AppTheme.muted,
              ),
            ),

            const SizedBox(height: 18),

            // =================================================
            // ÚNICO BOTÓN PARA CREAR REPORTE
            // =================================================

            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: onCreateReview,
                icon: const Icon(
                  Icons.add_chart_rounded,
                ),
                label: Text(
                  reports.isEmpty
                      ? 'Hacer mi primer reporte'
                      : 'Hacer un nuevo reporte',
                ),
              ),
            ),

            const SizedBox(height: 26),

            if (reports.isEmpty)
              const _EmptyReports()
            else ...[
              // ===============================================
              // DECISIONES
              // ===============================================

              _DecisionSection(
                state: state,
                reports: reports,
              ),

              const SizedBox(height: 28),

              // ===============================================
              // HISTORIAL
              // ===============================================

              Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Historial de reportes',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w900,
                        color: AppTheme.text,
                      ),
                    ),
                  ),

                  Container(
                    padding: const EdgeInsets.symmetric(
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
                      '${reports.length} ${reports.length == 1 ? 'reporte' : 'reportes'}',
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        color: AppTheme.primary,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 5),

              const Text(
                'Tocá un reporte para revisar nuevamente sus movimientos y la decisión tomada.',
                style: TextStyle(
                  fontSize: 10.5,
                  color: AppTheme.muted,
                ),
              ),

              const SizedBox(height: 14),

              ...reports.map(
                (report) {
                  return Padding(
                    padding: const EdgeInsets.only(
                      bottom: 12,
                    ),
                    child: _ReportHistoryCard(
                      report: report,
                      onTap: () {
                        _openReport(
                          context,
                          state,
                          report,
                        );
                      },
                    ),
                  );
                },
              ),
            ],
          ],
        );
      },
    );
  }

  void _openReport(
    BuildContext context,
    AppState state,
    ReviewResult report,
  ) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) {
          return _ReportDetailScreen(
            state: state,
            report: report,
          );
        },
      ),
    );
  }
}

// =============================================================
// DECISIONES TOMADAS
// =============================================================

class _DecisionSection extends StatelessWidget {
  final AppState state;
  final List<ReviewResult> reports;

  const _DecisionSection({
    required this.state,
    required this.reports,
  });

  @override
  Widget build(BuildContext context) {
    final reduce = reports
        .where(
          (report) =>
              report.decision ==
              'Reducir gasto',
        )
        .toList();

    final postpone = reports
        .where(
          (report) =>
              report.decision ==
              'Posponer una compra',
        )
        .toList();

    final goals = reports
        .where(
          (report) =>
              report.decision ==
              'Ajustar mi meta',
        )
        .toList();

    final maintain = reports
        .where(
          (report) =>
              report.decision ==
              'Mantener mi plan',
        )
        .toList();

    return Column(
      crossAxisAlignment:
          CrossAxisAlignment.start,
      children: [
        const Text(
          'Decisiones tomadas',
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w900,
            color: AppTheme.text,
          ),
        ),

        const SizedBox(height: 5),

        const Text(
          'Tus decisiones se organizan automáticamente según el tipo de acción.',
          style: TextStyle(
            fontSize: 10.5,
            color: AppTheme.muted,
          ),
        ),

        const SizedBox(height: 14),

        if (reduce.isNotEmpty)
          _DecisionGroup(
            title: 'Reducir gastos',
            subtitle:
                'Objetivos para gastar menos en determinadas categorías.',
            icon:
                Icons.trending_down_rounded,
            color: AppTheme.primary,
            reports: reduce,
            state: state,
          ),

        if (postpone.isNotEmpty) ...[
          const SizedBox(height: 10),

          _DecisionGroup(
            title: 'Compras pospuestas',
            subtitle:
                'Compras que decidiste dejar para más adelante.',
            icon: Icons.schedule_rounded,
            color:
                const Color(0xFFFF8A00),
            reports: postpone,
            state: state,
          ),
        ],

        if (goals.isNotEmpty) ...[
          const SizedBox(height: 10),

          _DecisionGroup(
            title: 'Metas ajustadas',
            subtitle:
                'Objetivos financieros cuyo monto o plazo modificaste.',
            icon:
                Icons.track_changes_rounded,
            color:
                const Color(0xFF6C63FF),
            reports: goals,
            state: state,
          ),
        ],

        if (maintain.isNotEmpty) ...[
          const SizedBox(height: 10),

          _DecisionGroup(
            title: 'Mantener el plan',
            subtitle:
                'Revisiones donde decidiste continuar sin cambios.',
            icon: Icons
                .check_circle_outline_rounded,
            color: AppTheme.success,
            reports: maintain,
            state: state,
          ),
        ],
      ],
    );
  }
}

// =============================================================
// GRUPO DE DECISIONES
// =============================================================

class _DecisionGroup extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;

  final List<ReviewResult> reports;

  final AppState state;

  const _DecisionGroup({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.reports,
    required this.state,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius:
            BorderRadius.circular(16),
        border: Border.all(
          color: AppTheme.border,
        ),
      ),
      child: ExpansionTile(
        initiallyExpanded: true,
        tilePadding:
            const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 5,
        ),
        childrenPadding:
            const EdgeInsets.fromLTRB(
          12,
          0,
          12,
          12,
        ),
        leading: Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color:
                color.withOpacity(0.10),
            borderRadius:
                BorderRadius.circular(11),
          ),
          child: Icon(
            icon,
            color: color,
          ),
        ),
        title: Text(
          title,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w900,
            color: AppTheme.text,
          ),
        ),
        subtitle: Text(
          '${reports.length} ${reports.length == 1 ? 'decisión' : 'decisiones'}',
          style: const TextStyle(
            fontSize: 10,
            color: AppTheme.muted,
          ),
        ),
        children: [
          Align(
            alignment:
                Alignment.centerLeft,
            child: Padding(
              padding:
                  const EdgeInsets.only(
                left: 2,
                right: 2,
                bottom: 5,
              ),
              child: Text(
                subtitle,
                style: const TextStyle(
                  fontSize: 9.5,
                  color: AppTheme.muted,
                ),
              ),
            ),
          ),

          ...reports.map(
            (report) {
              return Padding(
                padding:
                    const EdgeInsets.only(
                  top: 7,
                ),
                child: _DecisionCard(
                  report: report,
                  color: color,
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) {
                          return _ReportDetailScreen(
                            state: state,
                            report: report,
                          );
                        },
                      ),
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
// TARJETA DE DECISIÓN
// =============================================================

class _DecisionCard extends StatelessWidget {
  final ReviewResult report;
  final Color color;
  final VoidCallback onTap;

  const _DecisionCard({
    required this.report,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: color.withOpacity(
        0.05,
      ),
      borderRadius:
          BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius:
            BorderRadius.circular(12),
        child: Padding(
          padding:
              const EdgeInsets.all(12),
          child: Row(
            crossAxisAlignment:
                CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    Text(
                      _decisionSummary(
                        report,
                      ),
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight:
                            FontWeight.w800,
                        color: AppTheme.text,
                        height: 1.4,
                      ),
                    ),

                    const SizedBox(height: 5),

                    Text(
                      'Decisión tomada el ${_formatDate(report.createdAt)}',
                      style: const TextStyle(
                        fontSize: 9,
                        color: AppTheme.muted,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 8),

              Icon(
                Icons.chevron_right_rounded,
                color: color,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// =============================================================
// TARJETA DE HISTORIAL
// =============================================================

class _ReportHistoryCard
    extends StatelessWidget {
  final ReviewResult report;
  final VoidCallback onTap;

  const _ReportHistoryCard({
    required this.report,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final decisionColor =
        _decisionColor(
      report.decision,
    );

    return Material(
      color: Colors.white,
      borderRadius:
          BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius:
            BorderRadius.circular(16),
        child: Container(
          padding:
              const EdgeInsets.all(15),
          decoration: BoxDecoration(
            borderRadius:
                BorderRadius.circular(16),
            border: Border.all(
              color: AppTheme.border,
            ),
          ),
          child: Row(
            crossAxisAlignment:
                CrossAxisAlignment.start,
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color:
                      const Color(0xFFEAF3FF),
                  borderRadius:
                      BorderRadius.circular(
                    12,
                  ),
                ),
                child: const Icon(
                  Icons.insert_chart_outlined,
                  color: AppTheme.primary,
                ),
              ),

              const SizedBox(width: 12),

              Expanded(
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            report.periodTitle,
                            style:
                                const TextStyle(
                              fontSize: 13,
                              fontWeight:
                                  FontWeight.w900,
                              color: AppTheme.text,
                            ),
                          ),
                        ),

                        Text(
                          _formatDate(
                            report.createdAt,
                          ),
                          style:
                              const TextStyle(
                            fontSize: 9,
                            color:
                                AppTheme.muted,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 3),

                    Text(
                      report.periodSubtitle,
                      style: const TextStyle(
                        fontSize: 9.5,
                        color: AppTheme.muted,
                      ),
                    ),

                    const SizedBox(height: 8),

                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: [
                        _SmallChip(
                          text:
                              '${report.transactionIds.length} movimientos',
                          color:
                              AppTheme.primary,
                        ),

                        _SmallChip(
                          text:
                              report.decision,
                          color:
                              decisionColor,
                        ),
                      ],
                    ),

                    const SizedBox(height: 8),

                    Text(
                      _decisionSummary(
                        report,
                      ),
                      maxLines: 2,
                      overflow:
                          TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 10.5,
                        fontWeight:
                            FontWeight.w700,
                        color: AppTheme.text,
                        height: 1.35,
                      ),
                    ),

                    const SizedBox(height: 7),

                    const Text(
                      'Ver reporte completo →',
                      style: TextStyle(
                        fontSize: 9.5,
                        fontWeight:
                            FontWeight.w800,
                        color: AppTheme.primary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// =============================================================
// DETALLE DEL REPORTE
// =============================================================

class _ReportDetailScreen
    extends StatelessWidget {
  final AppState state;
  final ReviewResult report;

  const _ReportDetailScreen({
    required this.state,
    required this.report,
  });

  @override
  Widget build(BuildContext context) {
    final transactions =
        state.transactions.where(
      (transaction) {
        return report.transactionIds.contains(
          transaction.id,
        );
      },
    ).toList();

    final incomes =
        transactions.where(
      (transaction) {
        return transaction.type.toLowerCase() ==
            'income';
      },
    ).toList();

    final expenses =
        transactions.where(
      (transaction) {
        return transaction.type.toLowerCase() ==
            'expense';
      },
    ).toList();

    final totalIncome =
        incomes.fold<double>(
      0,
      (
        total,
        transaction,
      ) {
        return total + transaction.amount;
      },
    );

    final totalExpenses =
        expenses.fold<double>(
      0,
      (
        total,
        transaction,
      ) {
        return total + transaction.amount;
      },
    );

    final balance =
        totalIncome - totalExpenses;

    final categories =
        <String, double>{};

    for (final expense in expenses) {
      categories[expense.category] =
          (categories[expense.category] ?? 0) +
              expense.amount;
    }

    final categoryEntries =
        categories.entries.toList()
          ..sort(
            (a, b) {
              return b.value.compareTo(
                a.value,
              );
            },
          );

    final decisionColor =
        _decisionColor(
      report.decision,
    );

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor:
            AppTheme.background,
        surfaceTintColor:
            Colors.transparent,
        elevation: 0,
        title: const Text(
          'Detalle del reporte',
          style: TextStyle(
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
      body: SafeArea(
        child: Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints:
                const BoxConstraints(
              maxWidth: 760,
            ),
            child: ListView(
              padding:
                  const EdgeInsets.fromLTRB(
                18,
                10,
                18,
                40,
              ),
              children: [
                Text(
                  report.periodTitle,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight:
                        FontWeight.w900,
                    color: AppTheme.text,
                  ),
                ),

                const SizedBox(height: 4),

                Text(
                  report.periodSubtitle,
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppTheme.muted,
                  ),
                ),

                const SizedBox(height: 4),

                Text(
                  'Reporte creado el ${_formatDateTime(report.createdAt)}',
                  style: const TextStyle(
                    fontSize: 10,
                    color: AppTheme.muted,
                  ),
                ),

                const SizedBox(height: 24),

                const Text(
                  'Resumen',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight:
                        FontWeight.w900,
                    color: AppTheme.text,
                  ),
                ),

                const SizedBox(height: 10),

                Row(
                  children: [
                    Expanded(
                      child: _SummaryCard(
                        title: 'Ingresos',
                        value:
                            money(totalIncome),
                        color:
                            AppTheme.success,
                        icon: Icons
                            .arrow_upward_rounded,
                      ),
                    ),

                    const SizedBox(width: 10),

                    Expanded(
                      child: _SummaryCard(
                        title: 'Gastos',
                        value:
                            money(totalExpenses),
                        color:
                            AppTheme.primary,
                        icon: Icons
                            .arrow_downward_rounded,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 10),

                Row(
                  children: [
                    Expanded(
                      child: _SummaryCard(
                        title: 'Balance',
                        value: money(balance),
                        color: balance >= 0
                            ? AppTheme.success
                            : Colors.red,
                        icon: Icons
                            .account_balance_wallet_outlined,
                      ),
                    ),

                    const SizedBox(width: 10),

                    Expanded(
                      child: _SummaryCard(
                        title: 'Movimientos',
                        value:
                            '${report.transactionIds.length}',
                        color:
                            AppTheme.primary,
                        icon: Icons
                            .receipt_long_outlined,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 26),

                const Text(
                  'Gastos por categoría',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight:
                        FontWeight.w900,
                    color: AppTheme.text,
                  ),
                ),

                const SizedBox(height: 10),

                if (categoryEntries.isEmpty)
                  const _InfoCard(
                    text:
                        'Este reporte no contiene gastos.',
                  )
                else
                  Container(
                    padding:
                        const EdgeInsets.all(
                      15,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius:
                          BorderRadius.circular(
                        16,
                      ),
                      border: Border.all(
                        color: AppTheme.border,
                      ),
                    ),
                    child: Column(
                      children:
                          categoryEntries.map(
                        (entry) {
                          final percentage =
                              totalExpenses == 0
                                  ? 0.0
                                  : entry.value /
                                      totalExpenses;

                          return Padding(
                            padding:
                                const EdgeInsets
                                    .only(
                              bottom: 14,
                            ),
                            child:
                                _CategoryDetailRow(
                              name: entry.key,
                              amount: entry.value,
                              percentage:
                                  percentage,
                            ),
                          );
                        },
                      ).toList(),
                    ),
                  ),

                const SizedBox(height: 26),

                const Text(
                  'Decisión tomada',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight:
                        FontWeight.w900,
                    color: AppTheme.text,
                  ),
                ),

                const SizedBox(height: 10),

                Container(
                  padding:
                      const EdgeInsets.all(
                    16,
                  ),
                  decoration: BoxDecoration(
                    color: decisionColor
                        .withOpacity(0.06),
                    borderRadius:
                        BorderRadius.circular(
                      16,
                    ),
                    border: Border.all(
                      color: decisionColor
                          .withOpacity(0.35),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 42,
                            height: 42,
                            decoration:
                                BoxDecoration(
                              color: decisionColor
                                  .withOpacity(
                                0.12,
                              ),
                              borderRadius:
                                  BorderRadius
                                      .circular(
                                12,
                              ),
                            ),
                            child: Icon(
                              _decisionIcon(
                                report.decision,
                              ),
                              color:
                                  decisionColor,
                            ),
                          ),

                          const SizedBox(
                            width: 12,
                          ),

                          Expanded(
                            child: Text(
                              report.decision,
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
                        ],
                      ),

                      const SizedBox(
                        height: 14,
                      ),

                      Text(
                        _decisionSummary(
                          report,
                        ),
                        style: const TextStyle(
                          fontSize: 12,
                          height: 1.5,
                          fontWeight:
                              FontWeight.w700,
                          color: AppTheme.text,
                        ),
                      ),

                      const SizedBox(
                        height: 14,
                      ),

                      ..._decisionDetailRows(
                        report,
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 26),

                const Text(
                  'Movimientos confirmados',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight:
                        FontWeight.w900,
                    color: AppTheme.text,
                  ),
                ),

                const SizedBox(height: 10),

                if (transactions.isEmpty)
                  const _InfoCard(
                    text:
                        'Los movimientos de este reporte ya no están disponibles.',
                  )
                else
                  ...transactions.map(
                    (transaction) {
                      return Padding(
                        padding:
                            const EdgeInsets.only(
                          bottom: 9,
                        ),
                        child:
                            _TransactionCard(
                          transaction:
                              transaction,
                        ),
                      );
                    },
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// =============================================================
// RESUMEN
// =============================================================

class _SummaryCard extends StatelessWidget {
  final String title;
  final String value;
  final Color color;
  final IconData icon;

  const _SummaryCard({
    required this.title,
    required this.value,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius:
            BorderRadius.circular(14),
        border: Border.all(
          color: AppTheme.border,
        ),
      ),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            color: color,
            size: 20,
          ),

          const SizedBox(height: 8),

          Text(
            title,
            style: const TextStyle(
              fontSize: 9.5,
              color: AppTheme.muted,
            ),
          ),

          const SizedBox(height: 2),

          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 15,
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
// CATEGORÍA
// =============================================================

class _CategoryDetailRow
    extends StatelessWidget {
  final String name;
  final double amount;
  final double percentage;

  const _CategoryDetailRow({
    required this.name,
    required this.amount,
    required this.percentage,
  });

  @override
  Widget build(BuildContext context) {
    final safeValue =
        percentage.clamp(
      0.0,
      1.0,
    ).toDouble();

    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                name,
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight:
                      FontWeight.w800,
                  color: AppTheme.text,
                ),
              ),
            ),

            Text(
              '${(safeValue * 100).toStringAsFixed(0)}%',
              style: const TextStyle(
                fontSize: 10,
                color: AppTheme.muted,
              ),
            ),

            const SizedBox(width: 12),

            Text(
              money(amount),
              style: const TextStyle(
                fontSize: 11,
                fontWeight:
                    FontWeight.w900,
                color: AppTheme.text,
              ),
            ),
          ],
        ),

        const SizedBox(height: 6),

        ClipRRect(
          borderRadius:
              BorderRadius.circular(10),
          child: LinearProgressIndicator(
            minHeight: 7,
            value: safeValue,
            backgroundColor:
                const Color(0xFFEAF3FF),
          ),
        ),
      ],
    );
  }
}

// =============================================================
// MOVIMIENTO
// =============================================================

class _TransactionCard
    extends StatelessWidget {
  final MoneyTransaction transaction;

  const _TransactionCard({
    required this.transaction,
  });

  @override
  Widget build(BuildContext context) {
    final income =
        transaction.type.toLowerCase() ==
            'income';

    final color = income
        ? AppTheme.success
        : AppTheme.primary;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius:
            BorderRadius.circular(13),
        border: Border.all(
          color: AppTheme.border,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color:
                  color.withOpacity(0.10),
              borderRadius:
                  BorderRadius.circular(10),
            ),
            child: Icon(
              income
                  ? Icons.arrow_upward_rounded
                  : Icons
                      .arrow_downward_rounded,
              color: color,
              size: 18,
            ),
          ),

          const SizedBox(width: 10),

          Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Text(
                  transaction.category,
                  style: const TextStyle(
                    fontSize: 11.5,
                    fontWeight:
                        FontWeight.w900,
                    color: AppTheme.text,
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
                    style: const TextStyle(
                      fontSize: 9.5,
                      color: AppTheme.muted,
                    ),
                  ),
              ],
            ),
          ),

          Text(
            '${income ? '+' : '-'}${money(transaction.amount)}',
            style: TextStyle(
              fontSize: 11.5,
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
// CHIP
// =============================================================

class _SmallChip extends StatelessWidget {
  final String text;
  final Color color;

  const _SmallChip({
    required this.text,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding:
          const EdgeInsets.symmetric(
        horizontal: 8,
        vertical: 4,
      ),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius:
            BorderRadius.circular(20),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 9,
          fontWeight: FontWeight.w800,
          color: color,
        ),
      ),
    );
  }
}

// =============================================================
// MENSAJE INFORMACIÓN
// =============================================================

class _InfoCard extends StatelessWidget {
  final String text;

  const _InfoCard({
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius:
            BorderRadius.circular(15),
        border: Border.all(
          color: AppTheme.border,
        ),
      ),
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: const TextStyle(
          fontSize: 10.5,
          color: AppTheme.muted,
        ),
      ),
    );
  }
}

// =============================================================
// SIN REPORTES
// =============================================================

class _EmptyReports extends StatelessWidget {
  const _EmptyReports();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding:
          const EdgeInsets.fromLTRB(
        24,
        35,
        24,
        35,
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
            width: 70,
            height: 70,
            decoration:
                const BoxDecoration(
              color: Color(0xFFEAF3FF),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.insert_chart_outlined,
              size: 34,
              color: AppTheme.primary,
            ),
          ),

          const SizedBox(height: 16),

          const Text(
            'Todavía no tenés reportes',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w900,
              color: AppTheme.text,
            ),
          ),

          const SizedBox(height: 6),

          const Text(
            'Hacé una revisión de tus movimientos para descubrir dónde se fue tu dinero y tomar una decisión.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 10.5,
              height: 1.5,
              color: AppTheme.muted,
            ),
          ),
        ],
      ),
    );
  }
}

// =============================================================
// DETALLES DECISIÓN
// =============================================================

List<Widget> _decisionDetailRows(
  ReviewResult report,
) {
  final details =
      report.decisionDetails;

  final rows = <Widget>[];

  void addRow(
    String label,
    String value,
  ) {
    if (value.trim().isEmpty) {
      return;
    }

    rows.add(
      Padding(
        padding:
            const EdgeInsets.only(
          bottom: 8,
        ),
        child: Row(
          crossAxisAlignment:
              CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 115,
              child: Text(
                label,
                style: const TextStyle(
                  fontSize: 10,
                  color: AppTheme.muted,
                ),
              ),
            ),

            Expanded(
              child: Text(
                value,
                style: const TextStyle(
                  fontSize: 10.5,
                  fontWeight:
                      FontWeight.w800,
                  color: AppTheme.text,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  switch (report.decision) {
    case 'Reducir gasto':
      addRow(
        'Categoría',
        details['category']?.toString() ??
            '',
      );

      addRow(
        'Objetivo',
        money(
          _asDouble(
            details['targetAmount'],
          ),
        ),
      );

      addRow(
        'Plazo',
        _periodDescription(
          details,
        ),
      );

      break;

    case 'Posponer una compra':
      addRow(
        'Compra',
        details['purchaseName']
                ?.toString() ??
            '',
      );

      addRow(
        'Precio',
        money(
          _asDouble(
            details['purchaseAmount'],
          ),
        ),
      );

      final date = _parseDate(
        details['targetDate'],
      );

      if (date != null) {
        addRow(
          'Posponer hasta',
          _formatDate(date),
        );
      }

      break;

    case 'Ajustar mi meta':
      addRow(
        'Meta',
        details['goalName']?.toString() ??
            '',
      );

      addRow(
        'Nuevo objetivo',
        money(
          _asDouble(
            details['targetAmount'],
          ),
        ),
      );

      addRow(
        'Plazo',
        _periodDescription(
          details,
        ),
      );

      break;

    case 'Mantener mi plan':
      addRow(
        'Próxima revisión',
        _periodDescription(
          details,
        ),
      );

      break;
  }

  return rows;
}

// =============================================================
// RESUMEN DECISIÓN
// =============================================================

String _decisionSummary(
  ReviewResult report,
) {
  final details =
      report.decisionDetails;

  switch (report.decision) {
    case 'Reducir gasto':
      final category =
          details['category']?.toString() ??
              'gastos';

      final amount =
          _asDouble(
        details['targetAmount'],
      );

      if (amount <= 0) {
        return 'Reducir gastos en $category.';
      }

      return 'Reducir $category en ${money(amount)} ${_periodDescription(details)}.';

    case 'Posponer una compra':
      final name =
          details['purchaseName']
                  ?.toString() ??
              'Compra';

      final amount =
          _asDouble(
        details['purchaseAmount'],
      );

      final date = _parseDate(
        details['targetDate'],
      );

      if (date == null) {
        return 'Posponer $name.';
      }

      return 'Posponer $name (${money(amount)}) hasta ${_formatDate(date)}.';

    case 'Ajustar mi meta':
      final name =
          details['goalName']?.toString() ??
              'Meta';

      final amount =
          _asDouble(
        details['targetAmount'],
      );

      return 'Ajustar $name a ${money(amount)} ${_periodDescription(details)}.';

    case 'Mantener mi plan':
      return 'Mantener el plan y revisar nuevamente ${_periodDescription(details)}.';

    default:
      return report.decision;
  }
}

// =============================================================
// PLAZO
// =============================================================

String _periodDescription(
  Map<String, dynamic> details,
) {
  final type =
      details['periodType']?.toString() ??
          '';

  final value =
      int.tryParse(
            details['periodValue']
                    ?.toString() ??
                '',
          ) ??
          0;

  switch (type) {
    case 'weeks':
      if (value == 1) {
        return 'durante 1 semana';
      }

      if (value <= 0) {
        return 'por varias semanas';
      }

      return 'durante $value semanas';

    case 'months':
      if (value == 1) {
        return 'durante 1 mes';
      }

      if (value <= 0) {
        return 'por varios meses';
      }

      return 'durante $value meses';

    case 'date':
      final date = _parseDate(
        details['targetDate'],
      );

      if (date == null) {
        return 'hasta una fecha por definir';
      }

      return 'hasta el ${_formatDate(date)}';

    default:
      return 'sin plazo definido';
  }
}

// =============================================================
// ICONOS / COLORES
// =============================================================

IconData _decisionIcon(
  String decision,
) {
  switch (decision) {
    case 'Reducir gasto':
      return Icons.trending_down_rounded;

    case 'Posponer una compra':
      return Icons.schedule_rounded;

    case 'Ajustar mi meta':
      return Icons.track_changes_rounded;

    case 'Mantener mi plan':
    default:
      return Icons
          .check_circle_outline_rounded;
  }
}

Color _decisionColor(
  String decision,
) {
  switch (decision) {
    case 'Reducir gasto':
      return AppTheme.primary;

    case 'Posponer una compra':
      return const Color(0xFFFF8A00);

    case 'Ajustar mi meta':
      return const Color(0xFF6C63FF);

    case 'Mantener mi plan':
    default:
      return AppTheme.success;
  }
}

// =============================================================
// FECHAS
// =============================================================

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

String _formatDateTime(
  DateTime date,
) {
  final minute = date.minute
      .toString()
      .padLeft(
        2,
        '0',
      );

  return '${_formatDate(date)} • ${date.hour}:$minute';
}

DateTime? _parseDate(
  dynamic value,
) {
  if (value == null) {
    return null;
  }

  return DateTime.tryParse(
    value.toString(),
  );
}

// =============================================================
// NÚMEROS
// =============================================================

double _asDouble(
  dynamic value,
) {
  if (value is num) {
    return value.toDouble();
  }

  return double.tryParse(
        value?.toString() ?? '',
      ) ??
      0;
}