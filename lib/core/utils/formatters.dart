import 'package:intl/intl.dart';

/// Sistema centralizado de formateo monetario dependiente de la cuenta activa.
/// Mantiene la identidad visual de ONTA MY MONEY y respeta las reglas ISO 4217.
class CurrencyFormatter {
  static String activeCurrency = 'CRC';

  /// Obtiene el símbolo o prefijo adecuado según el código ISO 4217.
  static String symbolFor(String currency) {
    switch (currency.toUpperCase().trim()) {
      case 'CRC':
        return '₡';
      case 'USD':
        return '\$';
      case 'EUR':
        return '€';
      case 'GBP':
        return '£';
      case 'JPY':
        return '¥';
      case 'BRL':
        return 'R\$';
      case 'MXN':
        return 'Mex\$';
      default:
        return currency.toUpperCase().trim();
    }
  }

  /// Define la cantidad estándar de decimales para la moneda.
  /// Colones (CRC) y Yenes (JPY) no suelen llevar decimales en visualización común.
  /// Dólares (USD), Euros (EUR), etc., llevan 2 decimales.
  static int decimalDigitsFor(String currency) {
    switch (currency.toUpperCase().trim()) {
      case 'CRC':
      case 'JPY':
        return 0;
      default:
        return 2;
    }
  }

  /// Formatea un valor monetario según la moneda dada o la moneda activa global.
  static String format(num value, {String? currency}) {
    final curr = (currency == null || currency.trim().isEmpty)
        ? activeCurrency
        : currency.toUpperCase().trim();
    final symbol = symbolFor(curr);
    final decimals = decimalDigitsFor(curr);
    final prefixSpace = symbol.length > 1 ? ' ' : '';

    final isNegative = value < 0;
    final absVal = value.abs();

    if (curr == 'CRC') {
      final rounded = absVal.round().toString();
      final buffer = StringBuffer();
      for (var i = 0; i < rounded.length; i++) {
        final pos = rounded.length - i;
        buffer.write(rounded[i]);
        if (pos > 1 && (pos - 1) % 3 == 0) buffer.write('.');
      }
      final sign = isNegative ? '-' : '';
      return '$sign$symbol$buffer';
    } else if (decimals == 0) {
      final formatter = NumberFormat('#,##0', 'en_US');
      final formatted = formatter.format(absVal);
      final sign = isNegative ? '-' : '';
      return '$sign$symbol$prefixSpace$formatted';
    } else {
      final formatter = NumberFormat('#,##0.00', 'en_US');
      final formatted = formatter.format(absVal);
      final sign = isNegative ? '-' : '';
      return '$sign$symbol$prefixSpace$formatted';
    }
  }

  /// Valida que el código de moneda cumpla con el estándar de 3 letras alfabéticas ISO 4217.
  static bool isValidIsoCurrency(String? code) {
    if (code == null) return false;
    final trimmed = code.trim();
    if (trimmed.length != 3) return false;
    return RegExp(r'^[A-Za-z]{3}$').hasMatch(trimmed);
  }
}

/// Formateador monetario global adaptativo.
/// Por defecto utiliza la moneda de la cuenta activa actual.
String money(num value, {String? currency}) =>
    CurrencyFormatter.format(value, currency: currency);

/// Formateador de fecha corta defensivo.
String shortDate(DateTime date) {
  try {
    return DateFormat('dd/MM/yyyy').format(date);
  } catch (_) {
    final d = date.day.toString().padLeft(2, '0');
    final m = date.month.toString().padLeft(2, '0');
    return '$d/$m/${date.year}';
  }
}
