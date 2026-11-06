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

  final _emailController = TextEditingController();

  final _passwordController = TextEditingController();

  Future<void> _requestPasswordReset() async {
    final email = _emailController.text.trim();
    if (email.isEmpty || !email.contains('@')) {
      AppAlerts.error(context, 'Ingresá primero tu correo electrónico.');
      return;
    }
    try {
      await widget.state.api
          .post('/api/auth/forgot-password', {'email': email});
      if (mounted) {
        AppAlerts.success(context,
            'Si la cuenta existe, recibirás un enlace de recuperación.');
      }
    } catch (error) {
      if (mounted) AppAlerts.error(context, error.toString());
    }
  }

  Future<void> _resendVerification() async {
    final email = _emailController.text.trim();
    if (email.isEmpty || !email.contains('@')) {
      AppAlerts.error(context, 'Ingresá primero tu correo electrónico.');
      return;
    }
    try {
      await widget.state.api
          .post('/api/auth/resend-verification', {'email': email});
      if (mounted) {
        AppAlerts.success(context,
            'Si tu cuenta requiere verificación, recibirás un enlace.');
      }
    } catch (error) {
      if (mounted) AppAlerts.error(context, error.toString());
    }
  }

  Future<void> _verifyEmail(String token) async {
    try {
      await widget.state.api.post('/api/auth/verify-email', {'token': token});
      if (mounted) {
        AppAlerts.success(context, 'Correo verificado. Ya podés ingresar.');
      }
    } catch (error) {
      if (mounted) AppAlerts.error(context, error.toString());
    }
  }

  Future<void> _resetPassword(String token) async {
    final password = TextEditingController();
    final confirmation = TextEditingController();
    try {
      final submitted = await showDialog<bool>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: const Text('Restablecer contraseña'),
          content: Column(mainAxisSize: MainAxisSize.min, children: [
            TextField(
                controller: password,
                obscureText: true,
                decoration:
                    const InputDecoration(labelText: 'Nueva contraseña')),
            TextField(
                controller: confirmation,
                obscureText: true,
                decoration:
                    const InputDecoration(labelText: 'Confirmar contraseña')),
          ]),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(dialogContext, false),
                child: const Text('Cancelar')),
            FilledButton(
                onPressed: () => Navigator.pop(dialogContext, true),
                child: const Text('Restablecer')),
          ],
        ),
      );
      if (submitted != true || !mounted) return;
      if (password.text.length < 10 || password.text != confirmation.text) {
        AppAlerts.error(
            context, 'Usá al menos 10 caracteres y confirmá la contraseña.');
        return;
      }
      await widget.state.api.post('/api/auth/reset-password', {
        'token': token,
        'new_password': password.text,
      });
      if (mounted) {
        AppAlerts.success(
            context, 'Contraseña actualizada. Ya podés ingresar.');
      }
    } catch (error) {
      if (mounted) AppAlerts.error(context, error.toString());
    } finally {
      password.dispose();
      confirmation.dispose();
    }
  }

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
                if (value == null || value.length < 10) {
                  return 'Mínimo 10 caracteres';
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
        'Cuenta creada. Revisá tu correo para verificarla antes de ingresar.',
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
    final resetToken = Uri.base.queryParameters['reset_token'];
    final verifyToken = Uri.base.queryParameters['verify_token'];

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

                      TextButton(
                        onPressed:
                            widget.state.loading ? null : _requestPasswordReset,
                        child: const Text('Olvidé mi contraseña'),
                      ),
                      TextButton(
                        onPressed:
                            widget.state.loading ? null : _resendVerification,
                        child: const Text('Reenviar verificación'),
                      ),
                      if (verifyToken != null && verifyToken.isNotEmpty)
                        FilledButton.tonal(
                          onPressed: () => _verifyEmail(verifyToken),
                          child: const Text('Verificar correo desde el enlace'),
                        ),
                      if (resetToken != null && resetToken.isNotEmpty)
                        FilledButton.tonal(
                          onPressed: () => _resetPassword(resetToken),
                          child: const Text(
                              'Restablecer contraseña desde el enlace'),
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
