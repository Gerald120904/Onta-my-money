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
                subtitle: 'Información y soporte',
                onTap: () {
                  _showComingSoon(
                    context,
                    'Ayuda',
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
                      'Aplicación para ayudar a comprender gastos, '
                      'dinero comprometido, ahorro reservado y '
                      'dinero realmente disponible.',
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

class _OptionTile extends StatelessWidget {
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
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          vertical: 14,
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
                icon,
                color: AppTheme.primary,
              ),
            ),

            const SizedBox(width: 13),

            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w900,
                      color: AppTheme.text,
                    ),
                  ),

                  const SizedBox(height: 2),

                  Text(
                    subtitle,
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
    );
  }
}