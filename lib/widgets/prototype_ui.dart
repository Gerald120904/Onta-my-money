import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../core/theme/app_theme.dart';
import '../core/utils/formatters.dart';
import 'app_logo.dart';

class PrototypeHeader extends StatelessWidget {
  final String title;
  final VoidCallback? onBack;
  final bool showProfile;

  const PrototypeHeader({
    super.key,
    required this.title,
    this.onBack,
    this.showProfile = false,
  });

  @override
  Widget build(BuildContext context) {
    final textColor = AppTheme.textColor(context);
    final primaryColor = AppTheme.primaryColor(context);

    if (onBack != null) {
      return SizedBox(
        height: 54,
        child: Row(
          children: [
            InkWell(
              borderRadius: BorderRadius.circular(50),
              onTap: onBack,
              child: SizedBox(
                width: 48,
                height: 48,
                child: Icon(
                  Icons.arrow_back_rounded,
                  color: textColor,
                  size: 26,
                ),
              ),
            ),
            const SizedBox(width: 4),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                  color: textColor,
                ),
              ),
            ),
          ],
        ),
      );
    }

    return SizedBox(
      height: 64,
      child: Row(
        children: [
          const AppLogo(
            size: 44,
            showBadgeBackground: true,
          ),
          const SizedBox(width: 13),
          Expanded(
            child: Text(
              title,
              style: TextStyle(
                fontSize: 21,
                height: 1.1,
                fontWeight: FontWeight.w900,
                color: textColor,
              ),
            ),
          ),
          if (showProfile)
            IconButton(
              onPressed: () {},
              icon: Icon(
                Icons.person_outline_rounded,
                color: primaryColor,
                size: 26,
              ),
            ),
        ],
      ),
    );
  }
}

class PrototypePanel extends StatelessWidget {
  final Widget child;
  final Color? background;
  final Color? borderColor;
  final EdgeInsetsGeometry padding;
  final double radius;

  const PrototypePanel({
    super.key,
    required this.child,
    this.background,
    this.borderColor,
    this.padding = const EdgeInsets.all(14),
    this.radius = 16,
  });

  @override
  Widget build(BuildContext context) {
    final defaultBg = AppTheme.cardBg(context);
    final defaultBorder = AppTheme.borderColor(context);

    return Container(
      width: double.infinity,
      padding: padding,
      decoration: BoxDecoration(
        color: background ?? defaultBg,
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(
          color: borderColor ?? defaultBorder,
          width: 1.15,
        ),
      ),
      child: child,
    );
  }
}

class MoneyCard extends StatelessWidget {
  final String title;
  final double amount;
  final String subtitle;
  final IconData icon;

  final bool green;
  final bool blueFill;
  final bool showArrow;
  final VoidCallback? onTap;

  const MoneyCard({
    super.key,
    required this.title,
    required this.amount,
    required this.subtitle,
    required this.icon,
    this.green = false,
    this.blueFill = false,
    this.showArrow = true,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = AppTheme.isDarkMode(context);
    final accent =
        green ? AppTheme.successColor(context) : AppTheme.primaryColor(context);

    final background = green
        ? AppTheme.tintSuccess(context)
        : blueFill
            ? AppTheme.tintPrimary(context)
            : AppTheme.cardBg(context);

    final border = green
        ? (isDark ? const Color(0xFF166534) : const Color(0xFF9DEBC2))
        : AppTheme.borderColor(context);

    final textColor = AppTheme.textColor(context);
    final mutedColor = AppTheme.mutedColor(context);

    final card = PrototypePanel(
      background: background,
      borderColor: border,
      padding: const EdgeInsets.symmetric(
        horizontal: 14,
        vertical: 13,
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: green
                  ? (isDark ? const Color(0xFF14532D) : const Color(0xFFD1FAE5))
                  : (isDark
                      ? const Color(0xFF1E3A8A)
                      : const Color(0xFFDBEAFE)),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              icon,
              color: accent,
              size: 22,
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
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: textColor,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  money(amount),
                  style: TextStyle(
                    fontSize: 19,
                    height: 1.1,
                    fontWeight: FontWeight.w900,
                    color: green ? accent : textColor,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 12,
                    color: mutedColor,
                    height: 1.25,
                  ),
                ),
              ],
            ),
          ),
          if (showArrow)
            Icon(
              Icons.chevron_right_rounded,
              color: accent,
              size: 24,
            ),
        ],
      ),
    );

    if (onTap != null) {
      return Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: card,
        ),
      );
    }

    return card;
  }
}

class ChoiceCard extends StatelessWidget {
  final String title;
  final bool selected;
  final VoidCallback onTap;
  final IconData? icon;

  const ChoiceCard({
    super.key,
    required this.title,
    required this.selected,
    required this.onTap,
    this.icon,
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

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(15),
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 140),
          height: 64,
          padding: const EdgeInsets.symmetric(
            horizontal: 17,
          ),
          decoration: BoxDecoration(
            color: cardBg,
            borderRadius: BorderRadius.circular(15),
            border: Border.all(
              color: cardBorder,
              width: selected ? 1.75 : 1.15,
            ),
          ),
          child: Row(
            children: [
              if (icon == null)
                Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: selected
                          ? primaryColor
                          : (isDark
                              ? const Color(0xFF64748B)
                              : const Color(0xFF6B7280)),
                      width: 1.8,
                    ),
                  ),
                  child: selected
                      ? Center(
                          child: Container(
                            width: 12,
                            height: 12,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: primaryColor,
                            ),
                          ),
                        )
                      : null,
                )
              else
                Icon(
                  icon,
                  color: primaryColor,
                  size: 24,
                ),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
                    color: selected ? primaryColor : textColor,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class MovementCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final double amount;
  final bool checked;
  final ValueChanged<bool> onChanged;

  const MovementCard({
    super.key,
    required this.icon,
    required this.label,
    required this.amount,
    required this.checked,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = AppTheme.isDarkMode(context);
    final cardBg = AppTheme.cardBg(context);
    final cardBorder = AppTheme.borderColor(context);
    final textColor = AppTheme.textColor(context);
    final primaryColor = AppTheme.primaryColor(context);

    return Container(
      height: 60,
      padding: const EdgeInsets.symmetric(
        horizontal: 14,
      ),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(13),
        border: Border.all(
          color: cardBorder,
          width: 1.15,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: AppTheme.tintPrimary(context),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              icon,
              color: primaryColor,
              size: 21,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w800,
                color: textColor,
              ),
            ),
          ),
          Text(
            money(amount),
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w900,
              color: textColor,
            ),
          ),
          const SizedBox(width: 8),
          Transform.scale(
            scale: 1.0,
            child: Checkbox(
              value: checked,
              activeColor: primaryColor,
              checkColor: Colors.white,
              side: BorderSide(
                color:
                    isDark ? const Color(0xFF64748B) : const Color(0xFF6B7280),
                width: 1.5,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(4),
              ),
              onChanged: (value) {
                onChanged(value ?? false);
              },
            ),
          ),
        ],
      ),
    );
  }
}

class DecisionCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  const DecisionCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cardBg = AppTheme.cardBg(context);
    final cardBorder = selected
        ? AppTheme.primaryColor(context)
        : AppTheme.borderColor(context);
    final primaryColor = AppTheme.primaryColor(context);
    final successColor = AppTheme.successColor(context);
    final textColor = AppTheme.textColor(context);
    final mutedColor = AppTheme.mutedColor(context);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(15),
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(
            horizontal: 14,
            vertical: 13,
          ),
          decoration: BoxDecoration(
            color: cardBg,
            borderRadius: BorderRadius.circular(15),
            border: Border.all(
              color: cardBorder,
              width: selected ? 1.75 : 1.15,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: selected
                      ? AppTheme.tintSuccess(context)
                      : AppTheme.tintPrimary(context),
                ),
                child: Icon(
                  selected ? Icons.check_rounded : icon,
                  color: selected ? successColor : primaryColor,
                  size: 22,
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
                        fontSize: 14.5,
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
                        height: 1.25,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                color: selected ? successColor : primaryColor,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class DonutChart extends StatelessWidget {
  final double size;

  const DonutChart({
    super.key,
    this.size = 140,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = AppTheme.isDarkMode(context);

    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _DonutPainter(isDark: isDark),
      ),
    );
  }
}

class _DonutPainter extends CustomPainter {
  final bool isDark;

  const _DonutPainter({this.isDark = false});

  static const values = [
    34.0,
    18.0,
    16.0,
    14.0,
    18.0,
  ];

  List<Color> get colors => isDark
      ? const [
          Color(0xFF3B82F6),
          Color(0xFF60A5FA),
          Color(0xFF93C5FD),
          Color(0xFF38BDF8),
          Color(0xFF818CF8),
        ]
      : const [
          Color(0xFF0755DC),
          Color(0xFF1576F5),
          Color(0xFF4094F5),
          Color(0xFF6FB0FA),
          Color(0xFFA9CDF7),
        ];

  @override
  void paint(
    Canvas canvas,
    Size size,
  ) {
    final center = Offset(
      size.width / 2,
      size.height / 2,
    );

    final radius = size.width / 2 - 10;

    final rect = Rect.fromCircle(
      center: center,
      radius: radius,
    );

    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = size.width * .23
      ..strokeCap = StrokeCap.butt;

    var start = -math.pi / 2;

    final palette = colors;
    for (var i = 0; i < values.length; i++) {
      final sweep = values[i] / 100 * math.pi * 2;
      paint.color = palette[i % palette.length];

      canvas.drawArc(
        rect,
        start,
        sweep,
        false,
        paint,
      );

      start += sweep;
    }
  }

  @override
  bool shouldRepaint(covariant _DonutPainter oldDelegate) =>
      oldDelegate.isDark != isDark;
}
