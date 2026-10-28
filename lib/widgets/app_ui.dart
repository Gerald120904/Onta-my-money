import 'package:flutter/material.dart';

import '../core/theme/app_theme.dart';

class AppAlerts {
  static void success(BuildContext c, String m) =>
      _show(c, m, Icons.check_circle_outline, AppTheme.successColor(c));
  static void error(BuildContext c, String m) =>
      _show(c, m, Icons.error_outline, AppTheme.errorColor(c));
  static void info(BuildContext c, String m) =>
      _show(c, m, Icons.info_outline, AppTheme.primaryColor(c));

  static void _show(
      BuildContext context, String message, IconData icon, Color color) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          backgroundColor: color,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          content: Row(
            children: [
              Icon(icon, color: Colors.white, size: 22),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  message,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
  }
}

class AppDialogs {
  static Future<bool> confirm(
    BuildContext context, {
    required String title,
    required String message,
    String confirmText = 'Eliminar',
    bool isDestructive = true,
  }) async =>
      await showDialog<bool>(
        context: context,
        builder: (context) {
          final cardBg = AppTheme.cardBg(context);
          final textColor = AppTheme.textColor(context);
          final mutedColor = AppTheme.mutedColor(context);
          final confirmBg = isDestructive
              ? AppTheme.errorColor(context)
              : AppTheme.primaryColor(context);

          return AlertDialog(
            backgroundColor: cardBg,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(18),
              side:
                  BorderSide(color: AppTheme.borderColor(context), width: 1.15),
            ),
            title: Text(
              title,
              style: TextStyle(
                color: textColor,
                fontWeight: FontWeight.w800,
                fontSize: 18,
              ),
            ),
            content: Text(
              message,
              style: TextStyle(
                color: mutedColor,
                fontSize: 14,
                height: 1.4,
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: Text(
                  'Cancelar',
                  style:
                      TextStyle(color: mutedColor, fontWeight: FontWeight.w700),
                ),
              ),
              FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: confirmBg,
                  foregroundColor: Colors.white,
                ),
                onPressed: () => Navigator.pop(context, true),
                child: Text(confirmText),
              ),
            ],
          );
        },
      ) ??
      false;

  static Future<T?> form<T>(
    BuildContext context, {
    required String title,
    required Widget child,
  }) =>
      showDialog<T>(
        context: context,
        builder: (context) {
          final cardBg = AppTheme.cardBg(context);
          final textColor = AppTheme.textColor(context);

          return Dialog(
            backgroundColor: cardBg,
            insetPadding: const EdgeInsets.all(16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(18),
              side:
                  BorderSide(color: AppTheme.borderColor(context), width: 1.15),
            ),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 520),
              child: Padding(
                padding: const EdgeInsets.all(22),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 20,
                        color: textColor,
                      ),
                    ),
                    const SizedBox(height: 18),
                    ConstrainedBox(
                      constraints: const BoxConstraints(maxHeight: 560),
                      child: SingleChildScrollView(child: child),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      );
}

class AppField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String? hint;
  final TextInputType? keyboardType;
  final String? Function(String?)? validator;
  final bool obscureText;
  final int maxLines;

  const AppField({
    super.key,
    required this.controller,
    required this.label,
    this.hint,
    this.keyboardType,
    this.validator,
    this.obscureText = false,
    this.maxLines = 1,
  });

  @override
  Widget build(BuildContext context) {
    final textColor = AppTheme.textColor(context);

    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        validator: validator,
        obscureText: obscureText,
        maxLines: maxLines,
        style: TextStyle(color: textColor, fontSize: 15),
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
        ),
      ),
    );
  }
}

class PageHeader extends StatelessWidget {
  final String title, subtitle;
  final Widget? action;

  const PageHeader({
    super.key,
    required this.title,
    required this.subtitle,
    this.action,
  });

  @override
  Widget build(BuildContext context) {
    final textColor = AppTheme.textColor(context);
    final subtitleColor = AppTheme.mutedColor(context);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                  color: textColor,
                ),
              ),
              const SizedBox(height: 5),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 13.5,
                  color: subtitleColor,
                  height: 1.35,
                ),
              ),
            ],
          ),
        ),
        if (action != null) ...[
          const SizedBox(width: 12),
          action!,
        ],
      ],
    );
  }
}

class EmptyState extends StatelessWidget {
  final String title, message;

  const EmptyState({
    super.key,
    required this.title,
    required this.message,
  });

  @override
  Widget build(BuildContext context) {
    final textColor = AppTheme.textColor(context);
    final subtitleColor = AppTheme.mutedColor(context);
    final primaryColor = AppTheme.primaryColor(context);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 44),
      child: Center(
        child: Column(
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: AppTheme.tintPrimary(context),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.inbox_outlined, size: 32, color: primaryColor),
            ),
            const SizedBox(height: 14),
            Text(
              title,
              style: TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 16,
                color: textColor,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                color: subtitleColor,
                height: 1.35,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
