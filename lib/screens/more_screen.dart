import 'package:flutter/material.dart';

import '../core/theme/app_theme.dart';
import '../providers/app_state.dart';
import '../widgets/app_logo.dart';
import '../widgets/prototype_ui.dart';
import 'notifications_screen.dart';
import 'profile_screen.dart';
import 'settings_screen.dart';
import 'sync_screen.dart';

class MoreScreen extends StatelessWidget {
  final AppState state;

  const MoreScreen({
    super.key,
    required this.state,
  });

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(
        18,
        18,
        18,
        30,
      ),
      children: [
        const PrototypeHeader(
          title: 'Más',
        ),
        const SizedBox(height: 24),
        PrototypePanel(
          child: Column(
            children: [
              _OptionTile(
                icon: Icons.sync_rounded,
                title: 'Sincronización y datos locales',
                subtitle: 'Historial de cambios, modo offline y sincronización',
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => SyncScreen(state: state),
                    ),
                  );
                },
              ),
              const Divider(
                height: 1,
                color: AppTheme.border,
              ),
              _OptionTile(
                icon: Icons.person_outline_rounded,
                title: 'Mi perfil',
                subtitle: 'Información de tu cuenta',
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => ProfileScreen(state: state),
                    ),
                  );
                },
              ),
              const Divider(
                height: 1,
                color: AppTheme.border,
              ),
              _OptionTile(
                icon: Icons.notifications_none_rounded,
                title: 'Notificaciones',
                subtitle: 'Administrar recordatorios',
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => NotificationsScreen(state: state),
                    ),
                  );
                },
              ),
              const Divider(
                height: 1,
                color: AppTheme.border,
              ),
              _OptionTile(
                icon: Icons.settings_outlined,
                title: 'Configuración',
                subtitle: 'Preferencias de la aplicación',
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => SettingsScreen(state: state),
                    ),
                  );
                },
              ),
              const Divider(
                height: 1,
                color: AppTheme.border,
              ),
              _OptionTile(
                icon: Icons.help_outline_rounded,
                title: 'Ayuda',
                subtitle: 'Guía rápida para usar la aplicación',
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const _HelpScreen(),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        PrototypePanel(
          child: _OptionTile(
            icon: Icons.info_outline_rounded,
            title: 'Acerca de',
            subtitle: '¿Dónde se fue mi plata?',
            onTap: () {
              showDialog<void>(
                context: context,
                barrierDismissible: true,
                builder: (dialogContext) {
                  return AlertDialog(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(
                        20,
                      ),
                    ),
                    title: const Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        AppLogo.dialog(size: 90),
                        SizedBox(height: 14),
                        Text(
                          '¿Dónde se fue mi plata?',
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                    content: const Text(
                      'Aplicación para ayudar a comprender tus ingresos, '
                      'gastos, saldo actual, dinero comprometido, ahorro '
                      'reservado y disponible real.',
                      textAlign: TextAlign.center,
                    ),
                    actions: [
                      FilledButton(
                        onPressed: () {
                          Navigator.pop(
                            dialogContext,
                          );
                        },
                        child: const Text(
                          'Entendido',
                        ),
                      ),
                    ],
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }
}

class _OptionTile extends StatefulWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _OptionTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  State<_OptionTile> createState() => _OptionTileState();
}

class _OptionTileState extends State<_OptionTile> {
  bool _focused = false;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final titleColor = isDark ? AppTheme.textDark : AppTheme.text;
    final mutedColor = isDark ? AppTheme.mutedDark : AppTheme.muted;
    final iconBg = isDark ? const Color(0xFF1E2D4A) : const Color(0xFFEAF3FF);
    final iconColor = isDark ? AppTheme.primaryDarkTheme : AppTheme.primary;

    return Semantics(
      button: true,
      label: '${widget.title}. ${widget.subtitle}',
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: widget.onTap,
          canRequestFocus: true,
          focusColor: AppTheme.primary.withOpacity(.10),
          onFocusChange: (focused) {
            setState(() {
              _focused = focused;
            });
          },
          child: AnimatedContainer(
            duration: const Duration(
              milliseconds: 120,
            ),
            padding: const EdgeInsets.symmetric(
              horizontal: 10,
              vertical: 14,
            ),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                width: _focused ? 3 : 1,
                color: _focused
                    ? (isDark ? AppTheme.focusDark : AppTheme.primaryDark)
                    : Colors.transparent,
              ),
              boxShadow: _focused
                  ? [
                      BoxShadow(
                        color: AppTheme.primary.withOpacity(.16),
                        blurRadius: 0,
                        spreadRadius: 2,
                      ),
                    ]
                  : const [],
            ),
            child: Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: iconBg,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    widget.icon,
                    color: iconColor,
                  ),
                ),
                const SizedBox(width: 13),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.title,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w900,
                          color: titleColor,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        widget.subtitle,
                        style: TextStyle(
                          fontSize: 11,
                          color: mutedColor,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.chevron_right_rounded,
                  color: iconColor,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _HelpScreen extends StatelessWidget {
  const _HelpScreen();

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? AppTheme.backgroundDark : AppTheme.background;
    final textColor = isDark ? AppTheme.textDark : AppTheme.text;
    final mutedColor = isDark ? AppTheme.mutedDark : AppTheme.muted;
    final cardBg = isDark ? AppTheme.surfaceDark : Colors.white;
    final bannerBg = isDark ? const Color(0xFF162544) : const Color(0xFFEAF3FF);
    final primaryColor = isDark ? AppTheme.primaryDarkTheme : AppTheme.primary;

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: cardBg,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        title: Text(
          'Ayuda y documentación',
          style: TextStyle(
            fontWeight: FontWeight.w900,
            color: textColor,
          ),
        ),
      ),
      body: SafeArea(
        child: Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              maxWidth: 760,
            ),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(
                18,
                16,
                18,
                40,
              ),
              children: [
                Text(
                  'Guía rápida y documentación',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    color: textColor,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Consultá el funcionamiento del sistema financiero, '
                  'cuentas con moneda fija, registro de movimientos, decisiones, '
                  'modo sin conexión y accesibilidad.',
                  style: TextStyle(
                    fontSize: 12,
                    height: 1.5,
                    color: mutedColor,
                  ),
                ),
                const SizedBox(height: 22),

                // 1. Conceptos principales
                _HelpSectionTitle(
                  icon: Icons.account_balance_wallet_outlined,
                  title: 'Conceptos financieros principales',
                  isDark: isDark,
                ),
                const SizedBox(height: 10),
                _HelpItem(
                  title: '¿Qué es el saldo actual?',
                  content:
                      'Es la suma total del dinero disponible en la cuenta, '
                      'partiendo del saldo inicial más los ingresos y restando '
                      'los gastos registrados.',
                  isDark: isDark,
                ),
                const SizedBox(height: 8),
                _HelpItem(
                  title: '¿Qué es el dinero comprometido?',
                  content:
                      'Es el dinero que ya tenés reservado para obligaciones, '
                      'pagos fijos o deudas próximas que sabés que debés cubrir.',
                  isDark: isDark,
                ),
                const SizedBox(height: 8),
                _HelpItem(
                  title: '¿Qué es el ahorro reservado?',
                  content:
                      'Es el dinero que decidiste proteger para cumplir tus '
                      'metas de ahorro. No forma parte del dinero gastable en el día a día.',
                  isDark: isDark,
                ),
                const SizedBox(height: 8),
                _HelpItem(
                  title: '¿Qué es el disponible real y cómo se calcula?',
                  content:
                      'Es la cantidad real de dinero que podés gastar hoy sin '
                      'poner en riesgo tus compromisos ni tus metas:\n\n'
                      'Disponible real = Saldo actual - Dinero comprometido - Ahorro reservado.',
                  isDark: isDark,
                ),
                const SizedBox(height: 24),

                // 2. Cuentas y moneda inmutable
                _HelpSectionTitle(
                  icon: Icons.monetization_on_outlined,
                  title: 'Cuentas financieras y monedas',
                  isDark: isDark,
                ),
                const SizedBox(height: 10),
                _HelpItem(
                  title: '¿Cómo funcionan las cuentas financieras?',
                  content:
                      'Podés organizar tu dinero en múltiples cuentas independientes '
                      '(por ejemplo: Efectivo Costa Rica en CRC, Cuenta de ahorros en USD '
                      'o Viaje a Europa en EUR). Cada cuenta mantiene su propio saldo, '
                      'ingresos, gastos, metas y compromisos totalmente separados.',
                  isDark: isDark,
                ),
                const SizedBox(height: 8),
                _HelpItem(
                  title: '¿Por qué la moneda de una cuenta es inmutable?',
                  content:
                      'Al crear una cuenta, su código de moneda (CRC, USD, EUR u otro código '
                      'ISO 4217) queda fijado para siempre. Esto garantiza la integridad y '
                      'consistencia contable de tus registros históricos y evita mezclas '
                      'erróneas de divisas sin respaldo.\n\n'
                      'Si requerís manejar otra moneda, simplemente seleccioná "Crear otra cuenta".',
                  isDark: isDark,
                ),
                const SizedBox(height: 8),
                _HelpItem(
                  title: '¿Cómo creo una nueva cuenta?',
                  content:
                      'Tocá el selector de cuentas en el Inicio o en Configuración, '
                      'presioná "Crear otra cuenta", ingresá un nombre representativo, '
                      'elegí la moneda deseada e indicá el saldo inicial.',
                  isDark: isDark,
                ),
                const SizedBox(height: 24),

                // 3. Movimientos
                _HelpSectionTitle(
                  icon: Icons.receipt_long_outlined,
                  title: 'Movimientos y transacciones',
                  isDark: isDark,
                ),
                const SizedBox(height: 10),
                _HelpItem(
                  title: '¿Cómo registro un ingreso?',
                  content:
                      'En Movimientos, tocá "Agregar movimiento" y elegí Ingreso. '
                      'Indicá el monto, seleccioná la categoría, la fecha y una descripción opcional.',
                  isDark: isDark,
                ),
                const SizedBox(height: 8),
                _HelpItem(
                  title: '¿Cómo registro un gasto y cuál es el límite?',
                  content:
                      'En Movimientos, tocá "Agregar movimiento" y elegí Gasto. '
                      'El sistema previene errores validando que el monto no exceda '
                      'tu saldo disponible en la cuenta activa. Si intentás registrar un gasto '
                      'mayor al disponible, la aplicación te informará el monto máximo permitido.',
                  isDark: isDark,
                ),
                const SizedBox(height: 8),
                _HelpItem(
                  title: '¿Qué significa "movimiento no reconocido"?',
                  content:
                      'Indica un gasto que requiere tu verificación antes de ser confirmado. '
                      'En la pantalla Movimientos podés utilizar el botón rápido "Confirmar reconocidos" '
                      'para aprobar todos los gastos pendientes con un solo toque.',
                  isDark: isDark,
                ),
                const SizedBox(height: 24),

                // 4. Revisión y decisiones
                _HelpSectionTitle(
                  icon: Icons.analytics_outlined,
                  title: 'Revisar mi dinero y decisiones',
                  isDark: isDark,
                ),
                const SizedBox(height: 10),
                _HelpItem(
                  title: '¿Cuáles son los pasos de la revisión?',
                  content:
                      'La revisión periódica consta de 4 pasos guiados:\n\n'
                      '1. Seleccionar el periodo a evaluar (semana o mes).\n'
                      '2. Confirmar los movimientos reconocidos.\n'
                      '3. Analizar dónde se fue el dinero y los porcentajes por categoría.\n'
                      '4. Tomar una decisión financiera concreta.',
                  isDark: isDark,
                ),
                const SizedBox(height: 8),
                _HelpItem(
                  title: '¿Qué decisiones puedo tomar?',
                  content:
                      '• Mantener mi plan: continuar con el ritmo actual.\n'
                      '• Reducir gasto: establecer una meta para recortar gastos en una categoría específica.\n'
                      '• Posponer una compra: aplazar un gasto no urgente hasta una fecha futura.\n'
                      '• Ajustar mi meta: actualizar el valor objetivo de tu meta de ahorro.',
                  isDark: isDark,
                ),
                const SizedBox(height: 24),

                // 5. Modo sin conexión y sincronización
                _HelpSectionTitle(
                  icon: Icons.sync_rounded,
                  title: 'Modo sin conexión y sincronización',
                  isDark: isDark,
                ),
                const SizedBox(height: 10),
                _HelpItem(
                  title: '¿Puedo usar la aplicación sin internet?',
                  content:
                      'Sí. ONTA MY MONEY funciona con arquitectura Offline-First. '
                      'Todas tus cuentas, ingresos, gastos y metas se guardan de inmediato '
                      'en la base de datos local de tu dispositivo (SQLite en Android, IndexedDB en Web). '
                      'Podés registrar y consultar tus finanzas aun en modo avión.',
                  isDark: isDark,
                ),
                const SizedBox(height: 8),
                _HelpItem(
                  title: '¿Cómo y cuándo se sincronizan los datos?',
                  content:
                      'Al recuperar la conexión a internet, la aplicación sincroniza '
                      'automáticamente los cambios pendientes con la nube de forma segura y '
                      'cifrada. Las operaciones emplean control de versiones e idempotencia '
                      'para resolver cualquier conflicto sin perder información.',
                  isDark: isDark,
                ),
                const SizedBox(height: 24),

                // 6. Errores y recuperación
                _HelpSectionTitle(
                  icon: Icons.warning_amber_rounded,
                  title: 'Prevención de errores y validaciones',
                  isDark: isDark,
                ),
                const SizedBox(height: 10),
                _HelpItem(
                  title: '¿Qué ocurre si hay un error en un formulario?',
                  content:
                      'La aplicación muestra mensajes explicativos directamente en la pantalla, '
                      'detallando con exactitud qué campo requiere atención sin borrar la '
                      'información que ya completaste. Al corregir el campo, el mensaje de error '
                      'se retira automáticamente.',
                  isDark: isDark,
                ),
                const SizedBox(height: 8),
                _HelpItem(
                  title: '¿Cómo evito borrar datos por accidente?',
                  content:
                      'Cualquier acción de eliminación o descarte de cambios no guardados '
                      'solicita confirmación explícita mediante un diálogo antes de aplicarse.',
                  isDark: isDark,
                ),
                const SizedBox(height: 24),

                // 7. Accesibilidad y teclado
                _HelpSectionTitle(
                  icon: Icons.keyboard_outlined,
                  title: 'Uso con teclado y accesibilidad',
                  isDark: isDark,
                ),
                const SizedBox(height: 10),
                _HelpItem(
                  title: 'Atajos y navegación por teclado',
                  content:
                      '• Tab: avanzar al siguiente control interactivo.\n'
                      '• Shift + Tab: retroceder al control anterior.\n'
                      '• Enter o Espacio: activar botones, casillas y selectores.\n'
                      '• Escape (Esc): cerrar diálogos, modales o cancelar operaciones.',
                  isDark: isDark,
                ),
                const SizedBox(height: 26),

                // Banner de consejo
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: bannerBg,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: primaryColor.withOpacity(.35),
                    ),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        Icons.lightbulb_outline_rounded,
                        color: primaryColor,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Consejo financiero: consultá siempre tu "Disponible real" '
                          'antes de realizar gastos imprevistos para asegurar que tus '
                          'compromisos y metas estén protegidos.',
                          style: TextStyle(
                            fontSize: 12,
                            height: 1.5,
                            fontWeight: FontWeight.w700,
                            color: textColor,
                          ),
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

class _HelpSectionTitle extends StatelessWidget {
  final IconData icon;
  final String title;
  final bool isDark;

  const _HelpSectionTitle({
    required this.icon,
    required this.title,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final iconBg = isDark ? const Color(0xFF1E2D4A) : const Color(0xFFEAF3FF);
    final iconColor = isDark ? AppTheme.primaryDarkTheme : AppTheme.primary;
    final textColor = isDark ? AppTheme.textDark : AppTheme.text;

    return Row(
      children: [
        Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: iconBg,
            borderRadius: BorderRadius.circular(11),
          ),
          child: Icon(
            icon,
            color: iconColor,
            size: 20,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            title,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w900,
              color: textColor,
            ),
          ),
        ),
      ],
    );
  }
}

class _HelpItem extends StatelessWidget {
  final String title;
  final String content;
  final bool isDark;

  const _HelpItem({
    required this.title,
    required this.content,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final cardBg = isDark ? AppTheme.surfaceDark : Colors.white;
    final borderColor = isDark ? AppTheme.borderDark : AppTheme.border;
    final textColor = isDark ? AppTheme.textDark : AppTheme.text;
    final mutedColor = isDark ? AppTheme.mutedDark : AppTheme.muted;

    return Container(
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: borderColor,
        ),
      ),
      child: ExpansionTile(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
        ),
        collapsedShape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
        ),
        tilePadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 3,
        ),
        childrenPadding: const EdgeInsets.fromLTRB(
          14,
          0,
          14,
          16,
        ),
        iconColor: isDark ? AppTheme.primaryDarkTheme : AppTheme.primary,
        collapsedIconColor: mutedColor,
        title: Text(
          title,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w900,
            color: textColor,
          ),
        ),
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              content,
              style: TextStyle(
                fontSize: 12,
                height: 1.55,
                color: mutedColor,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
