import 'package:intl/intl.dart';
final _currency = NumberFormat.currency(locale: 'es_CR', symbol: '₡', decimalDigits: 0);
String money(num value) => _currency.format(value).replaceAll('\u00a0', ' ');
String shortDate(DateTime date) => DateFormat('dd/MM/yyyy').format(date);
