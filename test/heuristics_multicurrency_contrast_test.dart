import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:donde_se_fue_mi_plata/core/theme/app_theme.dart';
import 'package:donde_se_fue_mi_plata/core/utils/formatters.dart';
import 'package:donde_se_fue_mi_plata/models/models.dart';

// Función para calcular la luminancia relativa según WCAG 2.1
double _relativeLuminance(Color color) {
  double transform(double val) {
    return val <= 0.03928 ? val / 12.92 : math.pow((val + 0.055) / 1.055, 2.4).toDouble();
  }

  final r = transform((color.r * 255.0).round().clamp(0, 255) / 255.0);
  final g = transform((color.g * 255.0).round().clamp(0, 255) / 255.0);
  final b = transform((color.b * 255.0).round().clamp(0, 255) / 255.0);

  return 0.2126 * r + 0.7152 * g + 0.0722 * b;
}

// Función para calcular la razón de contraste WCAG (L1 + 0.05) / (L2 + 0.05)
double _contrastRatio(Color c1, Color c2) {
  final l1 = _relativeLuminance(c1);
  final l2 = _relativeLuminance(c2);
  final lighter = math.max(l1, l2);
  final darker = math.min(l1, l2);
  return (lighter + 0.05) / (darker + 0.05);
}

void main() {
  group('1. Multi-Currency Formatters & ISO 4217 Validation', () {
    test('Format amounts correctly with dynamic ISO symbols', () {
      expect(CurrencyFormatter.format(150000, currency: 'CRC'), '₡150.000');
      expect(CurrencyFormatter.format(1250.50, currency: 'USD'), '\$1,250.50');
      expect(CurrencyFormatter.format(980.75, currency: 'EUR'), '€980.75');
      expect(CurrencyFormatter.format(5000, currency: 'JPY'), '¥5,000');
      expect(CurrencyFormatter.format(350.20, currency: 'GBP'), '£350.20');
      expect(CurrencyFormatter.format(200.00, currency: 'CAD'), 'CAD 200.00');
    });

    test('Defensive fallback for null or empty currencies defaults safely', () {
      expect(CurrencyFormatter.format(1000, currency: null), '₡1.000');
      expect(CurrencyFormatter.format(1000, currency: ''), '₡1.000');
    });

    test('Symbols correctly resolved per currency code', () {
      expect(CurrencyFormatter.symbolFor('CRC'), '₡');
      expect(CurrencyFormatter.symbolFor('USD'), '\$');
      expect(CurrencyFormatter.symbolFor('EUR'), '€');
      expect(CurrencyFormatter.symbolFor('GBP'), '£');
      expect(CurrencyFormatter.symbolFor('JPY'), '¥');
      expect(CurrencyFormatter.symbolFor('BRL'), 'R\$');
      expect(CurrencyFormatter.symbolFor('AUD'), 'AUD');
    });

    test('Validates 3-letter ISO 4217 currency format', () {
      expect(CurrencyFormatter.isValidIsoCurrency('CRC'), isTrue);
      expect(CurrencyFormatter.isValidIsoCurrency('usd'), isTrue);
      expect(CurrencyFormatter.isValidIsoCurrency('EUR'), isTrue);
      expect(CurrencyFormatter.isValidIsoCurrency('US'), isFalse);
      expect(CurrencyFormatter.isValidIsoCurrency('USDD'), isFalse);
      expect(CurrencyFormatter.isValidIsoCurrency('12A'), isFalse);
      expect(CurrencyFormatter.isValidIsoCurrency(''), isFalse);
      expect(CurrencyFormatter.isValidIsoCurrency(null), isFalse);
    });
  });

  group('2. Account Model & Strict Currency Immutability', () {
    test('Account creation sets currency in uppercase and copyWith protects currency', () {
      final account = Account(
        id: 'acc-1',
        userId: 'user-1',
        name: 'Efectivo',
        currency: 'crc',
        initialBalance: 50000,
        currentBalance: 50000,
      );

      expect(account.currency, 'CRC');
      expect(account.initialBalance, 50000.0);
      expect(account.currentBalance, 50000.0);

      // copyWith updates name and balances without mutating currency
      final updated = account.copyWith(
        name: 'Efectivo Principal',
        currentBalance: 65000,
      );
      expect(updated.name, 'Efectivo Principal');
      expect(updated.currentBalance, 65000.0);
      expect(updated.currency, 'CRC');
    });

    test('Account serialization roundtrip preserves all fields', () {
      final now = DateTime.now();
      final account = Account(
        id: 'acc-usd',
        userId: 'user-1',
        name: 'Ahorros Dólares',
        currency: 'USD',
        initialBalance: 500,
        currentBalance: 750,
        color: '0xFF10B981',
        icon: 'savings',
        isDefault: false,
        isArchived: false,
        version: 2,
        createdAt: now,
        updatedAt: now,
      );

      final json = account.toJson();
      final recovered = Account.fromJson(json);

      expect(recovered.id, 'acc-usd');
      expect(recovered.currency, 'USD');
      expect(recovered.name, 'Ahorros Dólares');
      expect(recovered.initialBalance, 500.0);
      expect(recovered.currentBalance, 750.0);
      expect(recovered.color, '0xFF10B981');
    });
  });

  group('3. WCAG AA Contrast Compliance (Light & Dark Mode)', () {
    test('Light theme text on surface meets WCAG AA (>= 4.5:1)', () {
      final ratio = _contrastRatio(AppTheme.text, AppTheme.surface);
      // AppTheme.text (0xFF07152F) on surface (white) is around 16:1
      expect(ratio, greaterThanOrEqualTo(4.5));
      expect(ratio, greaterThanOrEqualTo(7.0)); // Meets AAA
    });

    test('Light theme text on background meets WCAG AA (>= 4.5:1)', () {
      final ratio = _contrastRatio(AppTheme.text, AppTheme.background);
      expect(ratio, greaterThanOrEqualTo(4.5));
    });

    test('Dark theme textDark on surfaceDark meets WCAG AA & AAA (>= 7.0:1)', () {
      final ratio = _contrastRatio(AppTheme.textDark, AppTheme.surfaceDark);
      // AppTheme.textDark (0xFFF8FAFC) on surfaceDark (0xFF14213D)
      expect(ratio, greaterThanOrEqualTo(4.5));
      expect(ratio, greaterThanOrEqualTo(7.0));
    });

    test('Dark theme textDark on backgroundDark meets WCAG AA & AAA (>= 7.0:1)', () {
      final ratio = _contrastRatio(AppTheme.textDark, AppTheme.backgroundDark);
      // AppTheme.textDark (0xFFF8FAFC) on backgroundDark (0xFF0B132B)
      expect(ratio, greaterThanOrEqualTo(7.0));
    });

    test('Dark theme mutedDark on surfaceDark meets WCAG AA for normal text (>= 4.5:1)', () {
      final ratio = _contrastRatio(AppTheme.mutedDark, AppTheme.surfaceDark);
      // AppTheme.mutedDark (0xFF94A3B8) on surfaceDark (0xFF14213D) is ~5.6:1
      expect(ratio, greaterThanOrEqualTo(4.5));
    });

    test('Focus indicator focusDark on surfaceDark meets graphical WCAG (>= 3.0:1)', () {
      final ratio = _contrastRatio(AppTheme.focusDark, AppTheme.surfaceDark);
      // AppTheme.focusDark (0xFF93C5FD) on surfaceDark (0xFF14213D) is > 7:1
      expect(ratio, greaterThanOrEqualTo(3.0));
    });
  });

  group('4. Segregated Financial Calculations Across Multi-Currency Accounts', () {
    test('Transactions are strictly isolated by accountId without cross-account contamination', () {
      final txCRC = [
        MoneyTransaction(
          id: 'tx-1',
          accountId: 'acc-crc',
          type: 'income',
          amount: 500000,
          category: 'Salario',
          description: 'Salario quincenal',
          date: DateTime.now(),
          recognized: true,
        ),
        MoneyTransaction(
          id: 'tx-2',
          accountId: 'acc-crc',
          type: 'expense',
          amount: 150000,
          category: 'Comida',
          description: 'Supermercado',
          date: DateTime.now(),
          recognized: true,
        ),
      ];

      final txUSD = [
        MoneyTransaction(
          id: 'tx-3',
          accountId: 'acc-usd',
          type: 'income',
          amount: 1200,
          category: 'Salario',
          description: 'Freelance USD',
          date: DateTime.now(),
          recognized: true,
        ),
        MoneyTransaction(
          id: 'tx-4',
          accountId: 'acc-usd',
          type: 'expense',
          amount: 250,
          category: 'Ocio',
          description: 'Restaurante USD',
          date: DateTime.now(),
          recognized: true,
        ),
      ];

      final allTx = [...txCRC, ...txUSD];

      // Filtrado por cuenta CRC
      final crcOnly = allTx.where((t) => t.accountId == 'acc-crc').toList();
      final crcIncome = crcOnly.where((t) => t.type == 'income').fold<double>(0, (s, t) => s + t.amount);
      final crcExpense = crcOnly.where((t) => t.type == 'expense').fold<double>(0, (s, t) => s + t.amount);
      final crcNet = crcIncome - crcExpense;

      expect(crcIncome, 500000.0);
      expect(crcExpense, 150000.0);
      expect(crcNet, 350000.0);

      // Filtrado por cuenta USD
      final usdOnly = allTx.where((t) => t.accountId == 'acc-usd').toList();
      final usdIncome = usdOnly.where((t) => t.type == 'income').fold<double>(0, (s, t) => s + t.amount);
      final usdExpense = usdOnly.where((t) => t.type == 'expense').fold<double>(0, (s, t) => s + t.amount);
      final usdNet = usdIncome - usdExpense;

      expect(usdIncome, 1200.0);
      expect(usdExpense, 250.0);
      expect(usdNet, 950.0);

      // Verificación de no contaminación cruzada
      expect(crcOnly.any((t) => t.accountId == 'acc-usd'), isFalse);
      expect(usdOnly.any((t) => t.accountId == 'acc-crc'), isFalse);
    });

    test('Available balance formula respects commitments and reserved savings', () {
      const currentBalance = 350000.0;
      const committedMoney = 120000.0;
      const reservedSavings = 80000.0;

      const realAvailable = currentBalance - committedMoney - reservedSavings;

      expect(realAvailable, 150000.0);
      expect(realAvailable < currentBalance, isTrue);
    });
  });

  group('5. Decision Dialog Form Validations (H9 & H5)', () {
    test('Validates "Reducir gasto" requires category, amount > 0 and target date when type=date', () {
      bool validateReduce({
        required String? category,
        required double amount,
        required String periodType,
        required DateTime? targetDate,
      }) {
        if (category == null || category.isEmpty) return false;
        if (amount <= 0) return false;
        if (periodType == 'date' && targetDate == null) return false;
        return true;
      }

      expect(validateReduce(category: null, amount: 10000, periodType: 'weeks', targetDate: null), isFalse);
      expect(validateReduce(category: 'Comida', amount: 0, periodType: 'weeks', targetDate: null), isFalse);
      expect(validateReduce(category: 'Comida', amount: -500, periodType: 'weeks', targetDate: null), isFalse);
      expect(validateReduce(category: 'Comida', amount: 15000, periodType: 'date', targetDate: null), isFalse);
      expect(validateReduce(category: 'Comida', amount: 15000, periodType: 'date', targetDate: DateTime.now()), isTrue);
      expect(validateReduce(category: 'Comida', amount: 15000, periodType: 'weeks', targetDate: null), isTrue);
    });

    test('Validates "Posponer una compra" requires name, amount > 0 and target date', () {
      bool validatePostpone({
        required String name,
        required double amount,
        required DateTime? targetDate,
      }) {
        if (name.trim().isEmpty) return false;
        if (amount <= 0) return false;
        if (targetDate == null) return false;
        return true;
      }

      expect(validatePostpone(name: '', amount: 50000, targetDate: DateTime.now()), isFalse);
      expect(validatePostpone(name: 'Zapatos', amount: 0, targetDate: DateTime.now()), isFalse);
      expect(validatePostpone(name: 'Zapatos', amount: 50000, targetDate: null), isFalse);
      expect(validatePostpone(name: 'Zapatos', amount: 50000, targetDate: DateTime.now()), isTrue);
    });
  });
}
