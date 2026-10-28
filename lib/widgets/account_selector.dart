import 'package:flutter/material.dart';

import '../core/theme/app_theme.dart';
import '../core/utils/formatters.dart';
import '../providers/app_state.dart';

/// Barra accesible de selección de cuenta financiera activa.
/// Muestra el nombre, divisa inmutable y saldo actual de la cuenta activa.
class AccountSelectorBar extends StatelessWidget {
  final AppState state;

  const AccountSelectorBar({
    super.key,
    required this.state,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final activeAccount = state.activeAccount;
    final accountName = activeAccount?.name ?? 'Cuenta Principal';
    final currency = activeAccount?.currency ?? state.activeCurrency;

    final bgColor = AppTheme.cardBg(context);
    final borderColor = AppTheme.borderColor(context);
    final textColor = AppTheme.textColor(context);
    final mutedColor = AppTheme.mutedColor(context);
    final badgeBg = AppTheme.tintPrimary(context);
    final badgeColor = AppTheme.primaryColor(context);

    return Semantics(
      container: true,
      button: true,
      label:
          'Cuenta activa: $accountName en $currency. Saldo: ${money(state.currentBalance)}. Tocá para cambiar o crear cuenta.',
      child: Material(
        color: bgColor,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: () => showModalBottomSheet(
            context: context,
            isScrollControlled: true,
            backgroundColor: AppTheme.cardBg(context),
            shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
            builder: (ctx) => AccountSwitcherSheet(state: state),
          ),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: borderColor, width: 1.15),
            ),
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: badgeBg,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Center(
                    child: Text(
                      CurrencyFormatter.symbolFor(currency).trim(),
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                        color: badgeColor,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              accountName,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 13.5,
                                fontWeight: FontWeight.w900,
                                color: textColor,
                              ),
                            ),
                          ),
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: badgeBg,
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(
                                color: badgeColor.withOpacity(0.3),
                                width: 0.8,
                              ),
                            ),
                            child: Text(
                              currency,
                              style: TextStyle(
                                fontSize: 9.5,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 0.5,
                                color: badgeColor,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Saldo: ${money(state.currentBalance)}',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: mutedColor,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.unfold_more_rounded,
                  color: isDark ? const Color(0xFF60A5FA) : AppTheme.primary,
                  size: 22,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Hoja modal accesible para cambiar de cuenta o crear una nueva.
class AccountSwitcherSheet extends StatelessWidget {
  final AppState state;

  const AccountSwitcherSheet({
    super.key,
    required this.state,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? const Color(0xFFF8FAFC) : AppTheme.text;
    final mutedColor = isDark ? const Color(0xFF94A3B8) : AppTheme.muted;
    final cardBg = isDark ? const Color(0xFF14213D) : const Color(0xFFF8FAFD);
    final borderColor = isDark ? const Color(0xFF263859) : AppTheme.border;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(18, 16, 18, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: isDark
                      ? const Color(0xFF334155)
                      : const Color(0xFFCBD5E1),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Cuentas financieras',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                      color: textColor,
                    ),
                  ),
                ),
                IconButton(
                  tooltip: 'Cerrar',
                  onPressed: () => Navigator.pop(context),
                  icon: Icon(
                    Icons.close_rounded,
                    color: isDark ? const Color(0xFFF8FAFC) : AppTheme.text,
                  ),
                ),
              ],
            ),
            Text(
              'Cada cuenta mantiene su propia divisa inmutable, movimientos y disponible real separado.',
              style: TextStyle(
                fontSize: 13,
                color: mutedColor,
                height: 1.35,
              ),
            ),
            const SizedBox(height: 14),
            ConstrainedBox(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.45,
              ),
              child: ListView.separated(
                shrinkWrap: true,
                itemCount: state.accounts.length,
                separatorBuilder: (_, __) => const SizedBox(height: 8),
                itemBuilder: (context, index) {
                  final acc = state.accounts[index];
                  final isSelected = acc.id == state.activeAccount?.id;
                  final symbol =
                      CurrencyFormatter.symbolFor(acc.currency).trim();

                  return Material(
                    color: isSelected
                        ? (isDark
                            ? const Color(0xFF1E3A8A)
                            : const Color(0xFFEAF3FF))
                        : cardBg,
                    borderRadius: BorderRadius.circular(12),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(12),
                      onTap: () {
                        state.setActiveAccount(acc);
                        Navigator.pop(context);
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 12),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isSelected
                                ? (isDark
                                    ? const Color(0xFF60A5FA)
                                    : AppTheme.primary)
                                : borderColor,
                            width: isSelected ? 1.6 : 1.0,
                          ),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 38,
                              height: 38,
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? (isDark
                                        ? const Color(0xFF2563EB)
                                        : AppTheme.primary)
                                    : (isDark
                                        ? const Color(0xFF1E293B)
                                        : const Color(0xFFE2E8F0)),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Center(
                                child: Text(
                                  symbol,
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w900,
                                    color:
                                        isSelected ? Colors.white : textColor,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Flexible(
                                        child: Text(
                                          acc.name,
                                          style: TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w900,
                                            color: textColor,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 6),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 6, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: isDark
                                              ? const Color(0xFF0F172A)
                                              : const Color(0xFFE2E8F0),
                                          borderRadius:
                                              BorderRadius.circular(6),
                                        ),
                                        child: Text(
                                          acc.currency,
                                          style: TextStyle(
                                            fontSize: 9.5,
                                            fontWeight: FontWeight.w900,
                                            color: isDark
                                                ? const Color(0xFF93C5FD)
                                                : AppTheme.primaryDark,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    'Saldo: ${money(acc.currentBalance, currency: acc.currency)}',
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: mutedColor,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            if (isSelected)
                              Icon(
                                Icons.check_circle_rounded,
                                color: isDark
                                    ? const Color(0xFF4ADE80)
                                    : AppTheme.success,
                                size: 22,
                              ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: OutlinedButton.icon(
                onPressed: () {
                  Navigator.pop(context);
                  showDialog(
                    context: context,
                    builder: (ctx) => CreateAccountDialog(state: state),
                  );
                },
                icon: const Icon(Icons.add_rounded, size: 20),
                label: const Text(
                  'Crear otra cuenta',
                  style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Diálogo accesible para crear una cuenta financiera con moneda inmutable.
class CreateAccountDialog extends StatefulWidget {
  final AppState state;

  const CreateAccountDialog({
    super.key,
    required this.state,
  });

  @override
  State<CreateAccountDialog> createState() => _CreateAccountDialogState();
}

class _CreateAccountDialogState extends State<CreateAccountDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _balanceController = TextEditingController(text: '0');
  String _selectedCurrency = 'CRC';
  final _customCurrencyController = TextEditingController();
  bool _isCustomCurrency = false;
  bool _loading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _nameController.dispose();
    _balanceController.dispose();
    _customCurrencyController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final name = _nameController.text.trim();
    final currency = _isCustomCurrency
        ? _customCurrencyController.text.trim().toUpperCase()
        : _selectedCurrency;

    final balanceText = _balanceController.text.trim().replaceAll(',', '.');
    final balance = double.tryParse(balanceText) ?? 0.0;

    if (currency.length != 3) {
      setState(() {
        _errorMessage =
            'El código de moneda debe tener 3 letras ISO 4217 (ej. CRC, USD, EUR).';
      });
      return;
    }

    setState(() {
      _loading = true;
      _errorMessage = null;
    });

    try {
      await widget.state.createAccount(
        name: name,
        currency: currency,
        initialBalance: balance,
      );
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Cuenta "$name" creada exitosamente ($currency).'),
            backgroundColor: AppTheme.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString().replaceAll('Exception:', '').trim();
          _loading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = AppTheme.isDarkMode(context);
    final dialogBg = AppTheme.cardBg(context);
    final textColor = AppTheme.textColor(context);
    final mutedColor = AppTheme.mutedColor(context);

    return AlertDialog(
      backgroundColor: dialogBg,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      title: Row(
        children: [
          Icon(
            Icons.account_balance_rounded,
            color: isDark ? const Color(0xFF60A5FA) : AppTheme.primary,
            size: 24,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Nueva cuenta financiera',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w900,
                color: textColor,
              ),
            ),
          ),
        ],
      ),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Nombre de la cuenta',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  color: textColor,
                ),
              ),
              const SizedBox(height: 6),
              TextFormField(
                controller: _nameController,
                style: TextStyle(color: textColor, fontSize: 14),
                decoration: const InputDecoration(
                  hintText: 'Ej. Efectivo, Ahorros dólares, Tarjeta',
                ),
                validator: (val) {
                  if (val == null || val.trim().isEmpty) {
                    return 'Ingresá el nombre de la cuenta';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 14),
              Text(
                'Moneda (Inmutable)',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  color: textColor,
                ),
              ),
              const SizedBox(height: 6),
              Wrap(
                spacing: 8,
                children: [
                  ChoiceChip(
                    label: const Text('CRC (₡)'),
                    selected: !_isCustomCurrency && _selectedCurrency == 'CRC',
                    onSelected: (sel) {
                      if (sel) {
                        setState(() {
                          _selectedCurrency = 'CRC';
                          _isCustomCurrency = false;
                        });
                      }
                    },
                  ),
                  ChoiceChip(
                    label: const Text('USD (\$)'),
                    selected: !_isCustomCurrency && _selectedCurrency == 'USD',
                    onSelected: (sel) {
                      if (sel) {
                        setState(() {
                          _selectedCurrency = 'USD';
                          _isCustomCurrency = false;
                        });
                      }
                    },
                  ),
                  ChoiceChip(
                    label: const Text('EUR (€)'),
                    selected: !_isCustomCurrency && _selectedCurrency == 'EUR',
                    onSelected: (sel) {
                      if (sel) {
                        setState(() {
                          _selectedCurrency = 'EUR';
                          _isCustomCurrency = false;
                        });
                      }
                    },
                  ),
                  ChoiceChip(
                    label: const Text('Otra...'),
                    selected: _isCustomCurrency,
                    onSelected: (sel) {
                      setState(() {
                        _isCustomCurrency = sel;
                      });
                    },
                  ),
                ],
              ),
              if (_isCustomCurrency) ...[
                const SizedBox(height: 8),
                TextFormField(
                  controller: _customCurrencyController,
                  textCapitalization: TextCapitalization.characters,
                  maxLength: 3,
                  style: TextStyle(color: textColor, fontSize: 14),
                  decoration: const InputDecoration(
                    hintText: 'Código ISO 4217 (ej. JPY, GBP, CAD)',
                    counterText: '',
                  ),
                  validator: (val) {
                    if (_isCustomCurrency &&
                        (val == null || val.trim().length != 3)) {
                      return 'Ingresá 3 letras ISO válidas';
                    }
                    return null;
                  },
                ),
              ],
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(9),
                decoration: BoxDecoration(
                  color: isDark
                      ? const Color(0xFF1E293B)
                      : const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.lock_outline_rounded,
                      size: 15,
                      color:
                          isDark ? const Color(0xFF93C5FD) : AppTheme.primary,
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        'La moneda queda fijada para siempre al crear la cuenta para garantizar precisión contable sin pérdidas.',
                        style: TextStyle(
                          fontSize: 10,
                          height: 1.3,
                          color: mutedColor,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              Text(
                'Saldo inicial',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  color: textColor,
                ),
              ),
              const SizedBox(height: 6),
              TextFormField(
                controller: _balanceController,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                style: TextStyle(color: textColor, fontSize: 14),
                decoration: InputDecoration(
                  prefixText:
                      '${CurrencyFormatter.symbolFor(_isCustomCurrency ? _customCurrencyController.text : _selectedCurrency)} ',
                  hintText: '0',
                ),
                validator: (val) {
                  if (val == null || val.trim().isEmpty) {
                    return 'Ingresá el saldo inicial (puede ser 0)';
                  }
                  final parsed =
                      double.tryParse(val.trim().replaceAll(',', '.'));
                  if (parsed == null) {
                    return 'Ingresá un número válido';
                  }
                  return null;
                },
              ),
              if (_errorMessage != null) ...[
                const SizedBox(height: 10),
                Text(
                  _errorMessage!,
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.red.shade400,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _loading ? null : () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          onPressed: _loading ? null : _submit,
          child: _loading
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                      strokeWidth: 2, color: Colors.white),
                )
              : const Text('Crear cuenta'),
        ),
      ],
    );
  }
}
