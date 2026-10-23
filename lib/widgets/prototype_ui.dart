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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? const Color(0xFFF8FAFC) : AppTheme.text;

    if (onBack != null) {
      return SizedBox(
        height: 52,
        child: Row(
          children: [
            InkWell(
              borderRadius: BorderRadius.circular(50),
              onTap: onBack,
              child: SizedBox(
                width: 42,
                height: 42,
                child: Icon(
                  Icons.arrow_back_rounded,
                  color: textColor,
                  size: 27,
                ),
              ),
            ),
            const SizedBox(width: 5),
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
      height: 62,
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
              style: const TextStyle(
                fontSize: 21,
                height: 1.05,
                fontWeight: FontWeight.w900,
                color: AppTheme.text,
              ),
            ),
          ),
          if (showProfile)
            IconButton(
              onPressed: () {},
              icon: const Icon(
                Icons.person_outline_rounded,
                color: AppTheme.primaryDark,
                size: 27,
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
    this.radius = 15,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final defaultBg = isDark ? const Color(0xFF14213D) : Colors.white;
    final defaultBorder = isDark ? const Color(0xFF263859) : AppTheme.border;

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

  const MoneyCard({
    super.key,
    required this.title,
    required this.amount,
    required this.subtitle,
    required this.icon,
    this.green = false,
    this.blueFill = false,
    this.showArrow = true,
  });

  @override
  Widget build(BuildContext context) {
    final accent =
        green ? AppTheme.success : AppTheme.primary;

    final background = green
        ? const Color(0xFFF1FFF6)
        : blueFill
            ? const Color(0xFFEAF3FF)
            : Colors.white;

    final border = green
        ? const Color(0xFF9DEBC2)
        : AppTheme.border;

    return PrototypePanel(
      background: background,
      borderColor: border,
      padding: const EdgeInsets.symmetric(
        horizontal: 13,
        vertical: 12,
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: green
                  ? const Color(0xFFE3FBEF)
                  : const Color(0xFFEDF4FF),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              icon,
              color: accent,
              size: 22,
            ),
          ),
          const SizedBox(width: 11),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w800,
                    color: AppTheme.text,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  money(amount),
                  style: TextStyle(
                    fontSize: 19,
                    height: 1,
                    fontWeight: FontWeight.w900,
                    color: green
                        ? const Color(0xFF008943)
                        : AppTheme.text,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: 10.5,
                    color: AppTheme.muted,
                    height: 1.15,
                  ),
                ),
              ],
            ),
          ),
          if (showArrow)
            const Icon(
              Icons.chevron_right_rounded,
              color: AppTheme.primary,
              size: 24,
            ),
        ],
      ),
    );
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
            color: selected
                ? const Color(0xFFF5F9FF)
                : Colors.white,
            borderRadius: BorderRadius.circular(15),
            border: Border.all(
              color: selected
                  ? AppTheme.primary
                  : AppTheme.border,
              width: selected ? 1.5 : 1.15,
            ),
          ),
          child: Row(
            children: [
              if (icon == null)
                Container(
                  width: 23,
                  height: 23,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: selected
                          ? AppTheme.primary
                          : const Color(0xFF345078),
                      width: 1.6,
                    ),
                  ),
                  child: selected
                      ? Center(
                          child: Container(
                            width: 11,
                            height: 11,
                            decoration: const BoxDecoration(
                              shape: BoxShape.circle,
                              color: AppTheme.primary,
                            ),
                          ),
                        )
                      : null,
                )
              else
                Icon(
                  icon,
                  color: AppTheme.primaryDark,
                  size: 25,
                ),
              const SizedBox(width: 15),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: selected
                        ? FontWeight.w800
                        : FontWeight.w600,
                    color: selected
                        ? AppTheme.primary
                        : AppTheme.text,
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
    return Container(
      height: 58,
      padding: const EdgeInsets.symmetric(
        horizontal: 12,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(13),
        border: Border.all(
          color: AppTheme.border,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 35,
            height: 35,
            decoration: BoxDecoration(
              color: const Color(0xFFE9F3FF),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              icon,
              color: AppTheme.primary,
              size: 21,
            ),
          ),
          const SizedBox(width: 11),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          Text(
            money(amount),
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(width: 7),
          Transform.scale(
            scale: .95,
            child: Checkbox(
              value: checked,
              activeColor: AppTheme.primary,
              checkColor: Colors.white,
              side: const BorderSide(
                color: Color(0xFF7C9BC5),
                width: 1.3,
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
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(15),
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(
            horizontal: 13,
            vertical: 12,
          ),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(15),
            border: Border.all(
              color: selected
                  ? AppTheme.primary
                  : AppTheme.border,
              width: selected ? 1.5 : 1.1,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 39,
                height: 39,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: selected
                      ? const Color(0xFFE9FFF2)
                      : const Color(0xFFE9F3FF),
                ),
                child: Icon(
                  selected
                      ? Icons.check_rounded
                      : icon,
                  color: selected
                      ? AppTheme.success
                      : AppTheme.primary,
                  size: 23,
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
                        fontSize: 14,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        fontSize: 10.5,
                        color: AppTheme.muted,
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
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _DonutPainter(),
      ),
    );
  }
}

class _DonutPainter extends CustomPainter {
  static const values = [
    34.0,
    18.0,
    16.0,
    14.0,
    18.0,
  ];

  static const colors = [
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

    for (var i = 0; i < values.length; i++) {
      final sweep =
          values[i] / 100 * math.pi * 2;

      paint.color = colors[i];

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
  bool shouldRepaint(
    covariant CustomPainter oldDelegate,
  ) =>
      false;
}