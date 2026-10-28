import 'package:flutter/material.dart';

class AppAlerts {
  static void success(BuildContext c, String m) => _show(c, m, Icons.check_circle_outline, Colors.green);
  static void error(BuildContext c, String m) => _show(c, m, Icons.error_outline, Colors.red);
  static void info(BuildContext c, String m) => _show(c, m, Icons.info_outline, Colors.blue);

  static void _show(BuildContext context, String message, IconData icon, Color color) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          backgroundColor: color,
          content: Row(
            children: [
              Icon(icon, color: Colors.white),
              const SizedBox(width: 10),
              Expanded(child: Text(message)),
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
  }) async =>
      await showDialog<bool>(
        context: context,
        builder: (context) {
          final isDark = Theme.of(context).brightness == Brightness.dark;
          final cardBg = isDark ? const Color(0xFF14213D) : Colors.white;
          final textColor = isDark ? const Color(0xFFF8FAFC) : const Color(0xFF07152F);

          return AlertDialog(
            backgroundColor: cardBg,
            title: Text(title, style: TextStyle(color: textColor, fontWeight: FontWeight.w800)),
            content: Text(message, style: TextStyle(color: textColor)),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancelar'),
              ),
              FilledButton(
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
          final isDark = Theme.of(context).brightness == Brightness.dark;
          final cardBg = isDark ? const Color(0xFF14213D) : Colors.white;
          final textColor = isDark ? const Color(0xFFF8FAFC) : const Color(0xFF07152F);

          return Dialog(
            backgroundColor: cardBg,
            insetPadding: const EdgeInsets.all(16),
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
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w800,
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? const Color(0xFFF8FAFC) : const Color(0xFF07152F);

    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        validator: validator,
        obscureText: obscureText,
        maxLines: maxLines,
        style: TextStyle(color: textColor),
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? const Color(0xFFF8FAFC) : const Color(0xFF07152F);
    final subtitleColor = isDark ? const Color(0xFF94A3B8) : Colors.grey.shade600;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w900,
                      color: textColor,
                    ),
              ),
              const SizedBox(height: 6),
              Text(
                subtitle,
                style: TextStyle(color: subtitleColor),
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? const Color(0xFFF8FAFC) : const Color(0xFF07152F);
    final subtitleColor = isDark ? const Color(0xFF94A3B8) : Colors.grey.shade600;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 48),
      child: Center(
        child: Column(
          children: [
            Icon(Icons.inbox_outlined, size: 48, color: isDark ? const Color(0xFF64748B) : Colors.grey.shade400),
            const SizedBox(height: 12),
            Text(
              title,
              style: TextStyle(fontWeight: FontWeight.w800, color: textColor),
            ),
            const SizedBox(height: 4),
            Text(
              message,
              style: TextStyle(color: subtitleColor),
            ),
          ],
        ),
      ),
    );
  }
}
