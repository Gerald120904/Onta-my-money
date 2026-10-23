import 'package:flutter/material.dart';

/// Componente visual reutilizable para el Logo oficial de ¿Dónde se fue mi plata?
class AppLogo extends StatelessWidget {
  final double size;
  final bool showBadgeBackground;
  final VoidCallback? onTap;

  const AppLogo({
    super.key,
    this.size = 80,
    this.showBadgeBackground = false,
    this.onTap,
  });

  /// Variante para la pantalla de inicio de sesión (tamaño destacado)
  const AppLogo.login({
    super.key,
    this.size = 110,
    this.showBadgeBackground = true,
    this.onTap,
  });

  /// Variante para barras de navegación o encabezados
  const AppLogo.small({
    super.key,
    this.size = 40,
    this.showBadgeBackground = false,
    this.onTap,
  });

  /// Variante para modales ("Acerca de")
  const AppLogo.dialog({
    super.key,
    this.size = 90,
    this.showBadgeBackground = true,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    Widget imageWidget = Image.asset(
      'assets/images/logo.png',
      width: size,
      height: size,
      fit: BoxFit.contain,
      filterQuality: FilterQuality.high,
      errorBuilder: (context, error, stackTrace) {
        // Fallback a red o ícono en entornos de test sin asset bundle
        return Image.network(
          'https://res.cloudinary.com/dqqnhxhcp/image/upload/v1792774584/image-removebg-preview_2_lql7is.png',
          width: size,
          height: size,
          fit: BoxFit.contain,
          errorBuilder: (_, __, ___) => Icon(
            Icons.account_balance_wallet_rounded,
            size: size * 0.6,
            color: isDark ? const Color(0xFF60A5FA) : const Color(0xFF061747),
          ),
        );
      },
    );

    if (showBadgeBackground) {
      imageWidget = Container(
        width: size + 20,
        height: size + 20,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E293B) : Colors.white,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: isDark
                  ? Colors.black.withValues(alpha: 0.4)
                  : const Color(0xFF0F172A).withValues(alpha: 0.08),
              blurRadius: 18,
              offset: const Offset(0, 6),
            ),
          ],
          border: Border.all(
            color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
            width: 2,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(6.0),
          child: imageWidget,
        ),
      );
    }

    if (onTap != null) {
      return GestureDetector(
        onTap: onTap,
        child: imageWidget,
      );
    }

    return imageWidget;
  }
}
