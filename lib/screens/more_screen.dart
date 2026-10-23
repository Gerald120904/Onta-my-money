import 'package:flutter/material.dart';

import '../core/theme/app_theme.dart';
import '../providers/app_state.dart';
import '../widgets/prototype_ui.dart';

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
                icon: Icons.person_outline_rounded,
                title: 'Mi perfil',
                subtitle: 'Información de tu cuenta',
                onTap: () {
                  _showComingSoon(
                    context,
                    'Mi perfil',
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
                  _showComingSoon(
                    context,
                    'Notificaciones',
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
                  _showComingSoon(
                    context,
                    'Configuración',
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
                    title: const Text(
                      '¿Dónde se fue mi plata?',
                    ),
                    content: const Text(
                      'Aplicación para ayudar a comprender tus ingresos, '
                      'gastos, saldo actual, dinero comprometido, ahorro '
                      'reservado y disponible real.',
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

  void _showComingSoon(
    BuildContext context,
    String title,
  ) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          '$title estará disponible próximamente.',
        ),
      ),
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
                    ? AppTheme.primaryDark
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
                    color: const Color(0xFFEAF3FF),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    widget.icon,
                    color: AppTheme.primary,
                  ),
                ),
                const SizedBox(width: 13),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.title,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w900,
                          color: AppTheme.text,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        widget.subtitle,
                        style: const TextStyle(
                          fontSize: 11,
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
      ),
    );
  }
}

class _HelpScreen extends StatelessWidget {
  const _HelpScreen();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: AppTheme.background,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'Ayuda',
          style: TextStyle(
            fontWeight: FontWeight.w900,
            color: AppTheme.text,
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
                8,
                18,
                40,
              ),
              children: [
                const Text(
                  'Guía rápida',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                    color: AppTheme.text,
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Consultá aquí el significado de los principales conceptos '
                  'y cómo realizar las tareas más importantes.',
                  style: TextStyle(
                    fontSize: 11.5,
                    height: 1.5,
                    color: AppTheme.muted,
                  ),
                ),
                const SizedBox(height: 22),
                const _HelpSectionTitle(
                  icon: Icons.account_balance_wallet_outlined,
                  title: 'Conceptos principales',
                ),
                const SizedBox(height: 10),
                const _HelpItem(
                  title: '¿Qué es el saldo actual?',
                  content:
                      'Es el dinero restante después de comparar los ingresos '
                      'y los gastos registrados.',
                ),
                const SizedBox(height: 8),
                const _HelpItem(
                  title: '¿Qué es el dinero comprometido?',
                  content:
                      'Es el dinero que ya tenés reservado para pagos, '
                      'compromisos o gastos que sabés que debés realizar.',
                ),
                const SizedBox(height: 8),
                const _HelpItem(
                  title: '¿Qué es el ahorro reservado?',
                  content:
                      'Es el dinero que decidiste proteger para cumplir tus '
                      'metas y que no debería utilizarse para gastos normales.',
                ),
                const SizedBox(height: 8),
                const _HelpItem(
                  title: '¿Qué es el disponible real?',
                  content:
                      'Es el dinero que realmente podés utilizar sin afectar '
                      'tus compromisos ni tu ahorro reservado.\n\n'
                      'Saldo actual - Dinero comprometido - Ahorro reservado '
                      '= Disponible real.',
                ),
                const SizedBox(height: 26),
                const _HelpSectionTitle(
                  icon: Icons.receipt_long_outlined,
                  title: 'Movimientos',
                ),
                const SizedBox(height: 10),
                const _HelpItem(
                  title: '¿Cómo registro un ingreso?',
                  content:
                      'Entrá a Movimientos, seleccioná Agregar movimiento y '
                      'elegí Ingreso. Después completá el monto, la categoría, '
                      'la descripción y la fecha.',
                ),
                const SizedBox(height: 8),
                const _HelpItem(
                  title: '¿Cómo registro un gasto?',
                  content:
                      'Entrá a Movimientos, seleccioná Agregar movimiento y '
                      'elegí Gasto. Indicá el monto, la categoría, la '
                      'descripción y la fecha. La aplicación evita registrar '
                      'un gasto superior al saldo disponible permitido.',
                ),
                const SizedBox(height: 8),
                const _HelpItem(
                  title: '¿Qué significa “movimiento no reconocido”?',
                  content:
                      'Indica que todavía no confirmaste que ese gasto sea '
                      'tuyo. Podés revisarlo antes de incluirlo en un reporte.',
                ),
                const SizedBox(height: 26),
                const _HelpSectionTitle(
                  icon: Icons.analytics_outlined,
                  title: 'Revisar mi dinero',
                ),
                const SizedBox(height: 10),
                const _HelpItem(
                  title: '¿Cómo funciona la revisión?',
                  content:
                      'La revisión tiene cuatro pasos:\n\n'
                      '1. Elegir un periodo.\n'
                      '2. Confirmar los movimientos.\n'
                      '3. Revisar dónde se fue el dinero.\n'
                      '4. Tomar una decisión.',
                ),
                const SizedBox(height: 8),
                const _HelpItem(
                  title: '¿Qué decisiones puedo tomar?',
                  content:
                      'Podés mantener tu plan, reducir un gasto, posponer una '
                      'compra o ajustar una meta. La decisión queda guardada '
                      'junto con el reporte.',
                ),
                const SizedBox(height: 26),
                const _HelpSectionTitle(
                  icon: Icons.warning_amber_rounded,
                  title: 'Errores y validaciones',
                ),
                const SizedBox(height: 10),
                const _HelpItem(
                  title: '¿Qué hago si aparece “Saldo insuficiente”?',
                  content:
                      'Revisá el monto que intentás registrar y reducí el '
                      'gasto hasta que sea igual o menor al saldo disponible '
                      'indicado por la aplicación.',
                ),
                const SizedBox(height: 8),
                const _HelpItem(
                  title: '¿Por qué no puedo continuar?',
                  content:
                      'Revisá que hayas completado los campos solicitados. '
                      'Cuando falta información, la aplicación muestra un '
                      'mensaje explicando qué debés corregir.',
                ),
                const SizedBox(height: 26),
                const _HelpSectionTitle(
                  icon: Icons.keyboard_outlined,
                  title: 'Uso con teclado',
                ),
                const SizedBox(height: 10),
                const _HelpItem(
                  title: '¿Cómo navego sin usar el mouse?',
                  content:
                      'Usá Tab para avanzar entre controles y Shift + Tab '
                      'para retroceder. Enter o Espacio permiten activar '
                      'botones y opciones. En ventanas emergentes podés usar '
                      'Esc para cerrarlas cuando corresponda.',
                ),
                const SizedBox(height: 24),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEAF3FF),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: AppTheme.primary.withOpacity(.35),
                    ),
                  ),
                  child: const Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        Icons.lightbulb_outline_rounded,
                        color: AppTheme.primary,
                      ),
                      SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Consejo: revisá periódicamente tus movimientos y '
                          'tu disponible real antes de tomar una decisión de '
                          'gasto.',
                          style: TextStyle(
                            fontSize: 11.5,
                            height: 1.5,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.text,
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

  const _HelpSectionTitle({
    required this.icon,
    required this.title,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: const Color(0xFFEAF3FF),
            borderRadius: BorderRadius.circular(11),
          ),
          child: Icon(
            icon,
            color: AppTheme.primary,
            size: 20,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w900,
              color: AppTheme.text,
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

  const _HelpItem({
    required this.title,
    required this.content,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: AppTheme.border,
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
        title: Text(
          title,
          style: const TextStyle(
            fontSize: 12.5,
            fontWeight: FontWeight.w900,
            color: AppTheme.text,
          ),
        ),
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              content,
              style: const TextStyle(
                fontSize: 11.5,
                height: 1.55,
                color: AppTheme.muted,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
