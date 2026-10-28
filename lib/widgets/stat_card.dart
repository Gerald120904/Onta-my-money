import 'package:flutter/material.dart';

import '../core/theme/app_theme.dart';
import '../core/utils/formatters.dart';

class StatCard extends StatelessWidget {
  final String label;
  final double value;
  final IconData icon;
  final Color color;
  final bool emphasized;
  final String? description;

  const StatCard({
    super.key,
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
    this.emphasized = false,
    this.description,
  });

  @override
  Widget build(BuildContext context) {
    final textColor = AppTheme.textColor(context);
    final mutedColor = AppTheme.mutedColor(context);
    final borderColor = AppTheme.borderColor(context);
    final isDark = AppTheme.isDarkMode(context);

    final cardBg = emphasized
        ? (isDark ? color.withOpacity(0.18) : color.withOpacity(0.08))
        : AppTheme.cardBg(context);

    final semanticDescription =
        description == null || description!.trim().isEmpty
            ? ''
            : '. ${description!}';

    return Semantics(
      container: true,
      label: '$label. ${money(value)}$semanticDescription',
      child: ExcludeSemantics(
        child: Container(
          decoration: BoxDecoration(
            color: cardBg,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: emphasized ? color.withOpacity(0.35) : borderColor,
              width: 1.15,
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    icon,
                    color: color,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        label,
                        style: TextStyle(
                          color: textColor,
                          fontWeight: FontWeight.w800,
                          fontSize: 13,
                        ),
                      ),
                      if (description != null &&
                          description!.trim().isNotEmpty) ...[
                        const SizedBox(height: 3),
                        Text(
                          description!,
                          style: TextStyle(
                            fontSize: 12,
                            height: 1.25,
                            color: mutedColor,
                          ),
                        ),
                      ],
                      const SizedBox(height: 4),
                      Text(
                        money(value),
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w900,
                          color: textColor,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
