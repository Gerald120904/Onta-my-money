import 'package:flutter/material.dart';

import '../core/theme/app_theme.dart';
import '../providers/app_state.dart';
import '../widgets/app_logo.dart';
import '../widgets/app_ui.dart';

class LoginScreen extends StatefulWidget {
  final AppState state;

  const LoginScreen({
    super.key,
    required this.state,
  });

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();

  final _emailController = TextEditingController(
    text: 'demo@plata.app',
  );

  final _passwordController = TextEditingController(
    text: '123456',
  );

  // =========================================================
  // LOGIN
  // =========================================================

  Future<void> _submit() async {
    final valid = _formKey.currentState?.validate() ?? false;

    if (!valid) return;

    try {
      await widget.state.login(
        _emailController.text.trim(),
        _passwordController.text,
      );
    } catch (e) {
      if (!mounted) return;

      AppAlerts.error(
        context,
        e.toString(),
      );
    }
  }

  // =========================================================
  // REGISTRO
  // =========================================================

  Future<void> _register() async {
    final registerFormKey = GlobalKey<FormState>();

    final nameController = TextEditingController();
    final mailController = TextEditingController();
    final passController = TextEditingController();

    final created = await AppDialogs.form<bool>(
      context,
      title: 'Crear cuenta',
      child: Form(
        key: registerFormKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AppField(
              controller: nameController,
              label: 'Nombre',
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Campo obligatorio';
                }

                return null;
              },
            ),
            AppField(
              controller: mailController,
              label: 'Correo',
              keyboardType: TextInputType.emailAddress,
              validator: (value) {
                if (value == null ||
                    value.trim().isEmpty ||
                    !value.contains('@')) {
                  return 'Correo inválido';
                }

                return null;
              },
            ),
            AppField(
              controller: passController,
              label: 'Contraseña',
              obscureText: true,
              validator: (value) {
                if (value == null || value.length < 6) {
                  return 'Mínimo 6 caracteres';
                }

                return null;
              },
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      Navigator.of(context).pop(false);
                    },
                    child: const Text(
                      'Cancelar',
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: FilledButton(
                    onPressed: () async {
                      final valid =
                          registerFormKey.currentState?.validate() ?? false;

                      if (!valid) return;

                      try {
                        await widget.state.register(
                          nameController.text.trim(),
                          mailController.text.trim(),
                          passController.text,
                        );

                        if (!mounted) return;

                        Navigator.of(context).pop(true);
                      } catch (e) {
                        if (!mounted) return;

                        AppAlerts.error(
                          context,
                          e.toString(),
                        );
                      }
                    },
                    child: const Text(
                      'Crear cuenta',
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );

    if (!mounted) {
      nameController.dispose();
      mailController.dispose();
      passController.dispose();
      return;
    }

    if (created == true) {
      _emailController.text = mailController.text.trim();
      _passwordController.text = passController.text;

      AppAlerts.success(
        context,
        'Cuenta creada. Ya podés ingresar.',
      );
    }

    nameController.dispose();
    mailController.dispose();
    passController.dispose();
  }

  // =========================================================
  // DISPOSE
  // =========================================================

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();

    super.dispose();
  }

  // =========================================================
  // UI
  // =========================================================

  @override
  Widget build(BuildContext context) {
    final cardBg = AppTheme.cardBg(context);
    final borderColor = AppTheme.borderColor(context);
    final titleColor = AppTheme.textColor(context);
    final subtitleColor = AppTheme.mutedColor(context);
    final demoBg = AppTheme.tintPrimary(context);

    return Scaffold(
      backgroundColor: AppTheme.bg(context),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(22),
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              maxWidth: 430,
            ),
            child: Card(
              color: cardBg,
              elevation: 0,
              clipBehavior: Clip.antiAlias,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
                side: BorderSide(
                  color: borderColor,
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.all(28),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // =================================================
                      // LOGO OFICIAL
                      // =================================================

                      const Center(
                        child: AppLogo.login(
                          size: 110,
                        ),
                      ),

                      const SizedBox(height: 22),

                      // =================================================
                      // TITULO
                      // =================================================

                      Text(
                        '¿Dónde se fue mi plata?',
                        textAlign: TextAlign.center,
                        style:
                            Theme.of(context).textTheme.headlineSmall?.copyWith(
                                  fontWeight: FontWeight.w900,
                                  color: titleColor,
                                ),
                      ),

                      const SizedBox(height: 8),

                      Text(
                        'Entendé dónde se fue tu dinero y cuánto podés usar realmente.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: subtitleColor,
                          height: 1.4,
                        ),
                      ),

                      const SizedBox(height: 30),

                      // =================================================
                      // CORREO
                      // =================================================

                      AppField(
                        controller: _emailController,
                        label: 'Correo',
                        keyboardType: TextInputType.emailAddress,
                        validator: (value) {
                          if (value == null ||
                              value.trim().isEmpty ||
                              !value.contains('@')) {
                            return 'Ingresá un correo válido';
                          }

                          return null;
                        },
                      ),

                      // =================================================
                      // CONTRASEÑA
                      // =================================================

                      AppField(
                        controller: _passwordController,
                        label: 'Contraseña',
                        obscureText: true,
                        validator: (value) {
                          if (value == null || value.length < 6) {
                            return 'Mínimo 6 caracteres';
                          }

                          return null;
                        },
                      ),

                      const SizedBox(height: 4),

                      // =================================================
                      // LOGIN
                      // =================================================

                      FilledButton(
                        onPressed: widget.state.loading ? null : _submit,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            vertical: 14,
                          ),
                          child: widget.state.loading
                              ? const SizedBox.square(
                                  dimension: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : const Text(
                                  'Ingresar',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                        ),
                      ),

                      const SizedBox(height: 10),

                      // =================================================
                      // REGISTRO
                      // =================================================

                      OutlinedButton(
                        onPressed: widget.state.loading ? null : _register,
                        child: const Text(
                          'Crear cuenta',
                          style: TextStyle(
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),

                      const SizedBox(height: 18),

                      // =================================================
                      // CREDENCIALES DEMO
                      // =================================================

                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          color: demoBg,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          'Demo: demo@plata.app / 123456',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: subtitleColor,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
