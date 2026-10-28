import 'package:flutter/material.dart';

import '../core/theme/app_theme.dart';

enum ReportPeriodType {
  today,
  week,
  month,
  custom,
}

class ReportPeriod {
  final ReportPeriodType type;
  final DateTime start;
  final DateTime end;

  const ReportPeriod({
    required this.type,
    required this.start,
    required this.end,
  });

  // =========================================================
  // HOY
  // =========================================================

  factory ReportPeriod.today() {
    final now = DateTime.now();

    return ReportPeriod(
      type: ReportPeriodType.today,
      start: DateTime(
        now.year,
        now.month,
        now.day,
      ),
      end: DateTime(
        now.year,
        now.month,
        now.day,
        23,
        59,
        59,
        999,
      ),
    );
  }

  // =========================================================
  // SEMANA ACTUAL
  // Lunes - Domingo
  // =========================================================

  factory ReportPeriod.week() {
    final now = DateTime.now();

    final today = DateTime(
      now.year,
      now.month,
      now.day,
    );

    final monday = today.subtract(
      Duration(
        days: today.weekday - 1,
      ),
    );

    final sunday = monday.add(
      const Duration(
        days: 6,
      ),
    );

    return ReportPeriod(
      type: ReportPeriodType.week,
      start: monday,
      end: DateTime(
        sunday.year,
        sunday.month,
        sunday.day,
        23,
        59,
        59,
        999,
      ),
    );
  }

  // =========================================================
  // MES ACTUAL
  // =========================================================

  factory ReportPeriod.month() {
    final now = DateTime.now();

    final firstDay = DateTime(
      now.year,
      now.month,
      1,
    );

    final lastDay = DateTime(
      now.year,
      now.month + 1,
      0,
    );

    return ReportPeriod(
      type: ReportPeriodType.month,
      start: firstDay,
      end: DateTime(
        lastDay.year,
        lastDay.month,
        lastDay.day,
        23,
        59,
        59,
        999,
      ),
    );
  }

  // =========================================================
  // PERSONALIZADO
  // =========================================================

  factory ReportPeriod.custom({
    required DateTime start,
    required DateTime end,
  }) {
    return ReportPeriod(
      type: ReportPeriodType.custom,
      start: DateTime(
        start.year,
        start.month,
        start.day,
      ),
      end: DateTime(
        end.year,
        end.month,
        end.day,
        23,
        59,
        59,
        999,
      ),
    );
  }

  // =========================================================
  // TÍTULO
  // =========================================================

  String get title {
    switch (type) {
      case ReportPeriodType.today:
        return 'Hoy';

      case ReportPeriodType.week:
        return 'Esta semana';

      case ReportPeriodType.month:
        return 'Este mes';

      case ReportPeriodType.custom:
        return 'Rango de fechas';
    }
  }

  // =========================================================
  // SUBTÍTULO
  // =========================================================

  String get subtitle {
    switch (type) {
      case ReportPeriodType.today:
        return _formatDate(start);

      case ReportPeriodType.week:
        return '${_formatDate(start)} - ${_formatDate(end)}';

      case ReportPeriodType.month:
        return '${start.month.toString().padLeft(2, '0')}/${start.year}';

      case ReportPeriodType.custom:
        return '${_formatDate(start)} - ${_formatDate(end)}';
    }
  }

  static String _formatDate(
    DateTime date,
  ) {
    return '${date.day.toString().padLeft(2, '0')}/'
        '${date.month.toString().padLeft(2, '0')}/'
        '${date.year}';
  }
}

// =============================================================
// ABRIR SELECTOR
// =============================================================

class PeriodSelector {
  static Future<ReportPeriod?> show(
    BuildContext context, {
    required ReportPeriod current,
  }) {
    return showDialog<ReportPeriod>(
      context: context,
      barrierDismissible: true,
      builder: (_) {
        return _PeriodSelectorDialog(
          current: current,
        );
      },
    );
  }
}

// =============================================================
// DIÁLOGO
// =============================================================

class _PeriodSelectorDialog extends StatefulWidget {
  final ReportPeriod current;

  const _PeriodSelectorDialog({
    required this.current,
  });

  @override
  State<_PeriodSelectorDialog> createState() => _PeriodSelectorDialogState();
}

class _PeriodSelectorDialogState extends State<_PeriodSelectorDialog> {
  late ReportPeriodType selected;

  DateTimeRange? customRange;

  @override
  void initState() {
    super.initState();

    selected = widget.current.type;

    if (widget.current.type == ReportPeriodType.custom) {
      customRange = DateTimeRange(
        start: widget.current.start,
        end: widget.current.end,
      );
    }
  }

  // =========================================================
  // RANGO PERSONALIZADO
  // =========================================================

  Future<void> _selectCustomRange() async {
    final now = DateTime.now();

    final range = await showDateRangePicker(
      context: context,
      firstDate: DateTime(
        2020,
        1,
        1,
      ),
      lastDate: DateTime(
        now.year + 5,
        12,
        31,
      ),
      initialDateRange: customRange,
      helpText: 'Seleccionar período',
      cancelText: 'Cancelar',
      confirmText: 'Seleccionar',
      saveText: 'Seleccionar',
      builder: (
        context,
        child,
      ) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(context).colorScheme.copyWith(
                  primary: AppTheme.primary,
                ),
          ),
          child: child!,
        );
      },
    );

    if (range == null) return;

    setState(() {
      selected = ReportPeriodType.custom;

      customRange = range;
    });
  }

  // =========================================================
  // CONTINUAR
  // =========================================================

  Future<void> _continue() async {
    ReportPeriod result;

    switch (selected) {
      case ReportPeriodType.today:
        result = ReportPeriod.today();
        break;

      case ReportPeriodType.week:
        result = ReportPeriod.week();
        break;

      case ReportPeriodType.month:
        result = ReportPeriod.month();
        break;

      case ReportPeriodType.custom:
        if (customRange == null) {
          await _selectCustomRange();

          if (customRange == null) {
            return;
          }
        }

        result = ReportPeriod.custom(
          start: customRange!.start,
          end: customRange!.end,
        );

        break;
    }

    if (!mounted) return;

    Navigator.of(context).pop(
      result,
    );
  }

  // =========================================================
  // BUILD
  // =========================================================

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();

    return Dialog(
      insetPadding: const EdgeInsets.symmetric(
        horizontal: 18,
        vertical: 24,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
      ),
      clipBehavior: Clip.antiAlias,
      child: ConstrainedBox(
        constraints: const BoxConstraints(
          maxWidth: 460,
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // =================================================
              // HEADER
              // =================================================

              Row(
                children: [
                  IconButton(
                    onPressed: () {
                      Navigator.of(
                        context,
                      ).pop();
                    },
                    icon: Icon(
                      Icons.arrow_back_rounded,
                      color: AppTheme.textColor(context),
                    ),
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      'Elegir periodo',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                        color: AppTheme.textColor(context),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Text(
                  'Seleccioná el período que querés analizar.',
                  style: TextStyle(
                    fontSize: 13,
                    color: AppTheme.mutedColor(context),
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // =================================================
              // HOY
              // =================================================

              _PeriodOption(
                title: 'Hoy',
                subtitle: _formatDate(now),
                icon: Icons.today_outlined,
                selected: selected == ReportPeriodType.today,
                onTap: () {
                  setState(() {
                    selected = ReportPeriodType.today;
                  });
                },
              ),

              const SizedBox(
                height: 10,
              ),

              // =================================================
              // SEMANA
              // =================================================

              _PeriodOption(
                title: 'Esta semana',
                subtitle: ReportPeriod.week().subtitle,
                icon: Icons.date_range_outlined,
                selected: selected == ReportPeriodType.week,
                onTap: () {
                  setState(() {
                    selected = ReportPeriodType.week;
                  });
                },
              ),

              const SizedBox(
                height: 10,
              ),

              // =================================================
              // MES
              // =================================================

              _PeriodOption(
                title: 'Este mes',
                subtitle: '${now.month.toString().padLeft(2, '0')}/${now.year}',
                icon: Icons.calendar_month_outlined,
                selected: selected == ReportPeriodType.month,
                onTap: () {
                  setState(() {
                    selected = ReportPeriodType.month;
                  });
                },
              ),

              const SizedBox(
                height: 10,
              ),

              // =================================================
              // PERSONALIZADO
              // =================================================

              _PeriodOption(
                title: 'Rango de fechas',
                subtitle: customRange == null
                    ? 'Elegí una fecha de inicio y final'
                    : '${_formatDate(customRange!.start)} - '
                        '${_formatDate(customRange!.end)}',
                icon: Icons.calendar_today_outlined,
                selected: selected == ReportPeriodType.custom,
                onTap: () async {
                  setState(() {
                    selected = ReportPeriodType.custom;
                  });

                  await _selectCustomRange();
                },
              ),

              const SizedBox(
                height: 22,
              ),

              // =================================================
              // CONTINUAR
              // =================================================

              FilledButton(
                onPressed: _continue,
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Continuar',
                    ),
                    SizedBox(
                      width: 7,
                    ),
                    Icon(
                      Icons.arrow_forward_rounded,
                      size: 18,
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

  static String _formatDate(
    DateTime date,
  ) {
    return '${date.day.toString().padLeft(2, '0')}/'
        '${date.month.toString().padLeft(2, '0')}/'
        '${date.year}';
  }
}

// =============================================================
// OPCIÓN DE PERÍODO
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
  Widget build(BuildContext context) {
    final isDark = AppTheme.isDarkMode(context);
    final cardBg =
        selected ? AppTheme.tintPrimary(context) : AppTheme.cardBg(context);
    final cardBorder = selected
        ? AppTheme.primaryColor(context)
        : AppTheme.borderColor(context);
    final primaryColor = AppTheme.primaryColor(context);
    final textColor = AppTheme.textColor(context);
    final mutedColor = AppTheme.mutedColor(context);

    return Material(
      color: cardBg,
      borderRadius: BorderRadius.circular(15),
      child: InkWell(
        borderRadius: BorderRadius.circular(15),
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 140),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(15),
            border: Border.all(
              width: selected ? 1.75 : 1.15,
              color: cardBorder,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color:
                      selected ? primaryColor : AppTheme.tintPrimary(context),
                  borderRadius: BorderRadius.circular(11),
                ),
                child: Icon(
                  icon,
                  size: 21,
                  color: selected ? Colors.white : primaryColor,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w900,
                        color: textColor,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 12,
                        color: mutedColor,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                width: 22,
                height: 22,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: selected ? primaryColor : Colors.transparent,
                  border: Border.all(
                    width: 2,
                    color: selected
                        ? primaryColor
                        : (isDark
                            ? const Color(0xFF64748B)
                            : AppTheme.borderColor(context)),
                  ),
                ),
                child: selected
                    ? const Icon(
                        Icons.check_rounded,
                        size: 15,
                        color: Colors.white,
                      )
                    : null,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
