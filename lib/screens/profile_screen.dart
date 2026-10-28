import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../core/theme/app_theme.dart';
import '../providers/app_state.dart';
import '../widgets/prototype_ui.dart';

class ProfileScreen extends StatefulWidget {
  final AppState state;

  const ProfileScreen({
    super.key,
    required this.state,
  });

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _nameController = TextEditingController();
  final _currentPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _isEditingName = false;
  bool _savingName = false;
  bool _changingPassword = false;
  bool _revokeOtherSessions = true;

  bool _obscureCurrent = true;
  bool _obscureNew = true;
  bool _obscureConfirm = true;

  @override
  void initState() {
    super.initState();
    _nameController.text = widget.state.currentUserName ?? '';
  }

  @override
  void dispose() {
    _nameController.dispose();
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  String _formatDate(String? isoString) {
    if (isoString == null || isoString.isEmpty) return 'No disponible';
    try {
      final dt = DateTime.parse(isoString).toLocal();
      return DateFormat('d \'de\' MMMM, yyyy', 'es_CR').format(dt);
    } catch (_) {
      return isoString;
    }
  }

  Future<void> _handleSaveName() async {
    final newName = _nameController.text.trim();
    if (newName.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('El nombre no puede estar vacío.')),
      );
      return;
    }

    setState(() => _savingName = true);
    try {
      await widget.state.updateUserName(newName);
      if (!mounted) return;
      setState(() => _isEditingName = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
              'Nombre actualizado correctamente. Guardado localmente y sincronizado.'),
          backgroundColor: AppTheme.success,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al actualizar nombre: $e'),
          backgroundColor: Colors.red.shade700,
        ),
      );
    } finally {
      if (mounted) setState(() => _savingName = false);
    }
  }

  Future<void> _handleChangePassword() async {
    if (!widget.state.isAuthenticated) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No hay sesión activa. Inicia sesión nuevamente.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final currentPass = _currentPasswordController.text;
    final newPass = _newPasswordController.text;
    final confirmPass = _confirmPasswordController.text;

    if (currentPass.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ingresá tu contraseña actual.')),
      );
      return;
    }

    if (newPass.length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content:
                Text('La nueva contraseña debe tener al menos 6 caracteres.')),
      );
      return;
    }

    if (newPass != confirmPass) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('La confirmación de la contraseña no coincide.')),
      );
      return;
    }

    setState(() => _changingPassword = true);
    try {
      final res = await widget.state.changePassword(
        currentPassword: currentPass,
        newPassword: newPass,
        confirmPassword: confirmPass,
        revokeOtherSessions: _revokeOtherSessions,
      );

      if (!mounted) return;
      _currentPasswordController.clear();
      _newPasswordController.clear();
      _confirmPasswordController.clear();

      showDialog<void>(
        context: context,
        builder: (ctx) => AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text('Contraseña actualizada'),
          content: Text(res['message']?.toString() ??
              'Tu contraseña ha sido actualizada exitosamente.'),
          actions: [
            FilledButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Entendido'),
            ),
          ],
        ),
      );
    } catch (e) {
      if (!mounted) return;
      final msg = e.toString().replaceAll('Exception: ', '');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(msg),
          backgroundColor: Colors.red.shade700,
        ),
      );
    } finally {
      if (mounted) setState(() => _changingPassword = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final textColor = AppTheme.textColor(context);
    final mutedColor = AppTheme.mutedColor(context);
    final cardBg = AppTheme.cardBg(context);
    final borderColor = AppTheme.borderColor(context);
    final isDark = AppTheme.isDarkMode(context);
    final user = widget.state;

    final displayName = user.currentUserName?.isNotEmpty == true
        ? user.currentUserName!
        : 'Usuario';
    final initial = displayName.isNotEmpty ? displayName[0].toUpperCase() : 'U';

    return Scaffold(
      backgroundColor: AppTheme.bg(context),
      appBar: AppBar(
        backgroundColor: AppTheme.cardBg(context),
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_rounded, color: textColor),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'Mi perfil',
          style: TextStyle(
            fontWeight: FontWeight.w900,
            fontSize: 20,
            color: textColor,
          ),
        ),
      ),
      body: SafeArea(
        child: Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 720),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(18, 12, 18, 36),
              children: [
                // ==========================================
                // CABECERA DE PERFIL / AVATAR
                // ==========================================
                PrototypePanel(
                  background: cardBg,
                  borderColor: borderColor,
                  padding: const EdgeInsets.all(20),
                  child: Row(
                    children: [
                      Container(
                        width: 64,
                        height: 64,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF0A55F4), Color(0xFF061747)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: AppTheme.primaryColor(context)
                                  .withOpacity(.25),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Center(
                          child: Text(
                            initial,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 26,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              displayName,
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w900,
                                color: textColor,
                              ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              user.currentUserEmail ?? 'correo@ejemplo.com',
                              style: TextStyle(
                                fontSize: 13.5,
                                color: mutedColor,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: AppTheme.tintSuccess(context),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.check_circle_rounded,
                                      size: 13,
                                      color: AppTheme.successColor(context)),
                                  const SizedBox(width: 4),
                                  Text(
                                    'Sesión activa',
                                    style: TextStyle(
                                      color: AppTheme.successColor(context),
                                      fontSize: 12,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // ==========================================
                // INFORMACIÓN GENERAL DE LA CUENTA
                // ==========================================
                Text(
                  'Datos de la cuenta',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w900,
                    color: textColor,
                  ),
                ),
                const SizedBox(height: 10),
                PrototypePanel(
                  background: cardBg,
                  borderColor: borderColor,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: Column(
                    children: [
                      // Nombre con edición
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Icon(Icons.badge_outlined,
                              color: AppTheme.primary, size: 22),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _isEditingName
                                ? TextField(
                                    controller: _nameController,
                                    autofocus: true,
                                    style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w700,
                                        color: textColor),
                                    decoration: InputDecoration(
                                      isDense: true,
                                      contentPadding:
                                          const EdgeInsets.symmetric(
                                              horizontal: 10, vertical: 8),
                                      hintText: 'Tu nombre completo',
                                      border: OutlineInputBorder(
                                          borderRadius:
                                              BorderRadius.circular(8)),
                                    ),
                                  )
                                : Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text('Nombre',
                                          style: TextStyle(
                                              fontSize: 11, color: mutedColor)),
                                      Text(
                                        displayName,
                                        style: TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w800,
                                            color: textColor),
                                      ),
                                    ],
                                  ),
                          ),
                          const SizedBox(width: 8),
                          if (_isEditingName) ...[
                            IconButton(
                              icon: _savingName
                                  ? const SizedBox(
                                      width: 18,
                                      height: 18,
                                      child: CircularProgressIndicator(
                                          strokeWidth: 2))
                                  : const Icon(Icons.check_circle_rounded,
                                      color: AppTheme.success, size: 24),
                              onPressed: _savingName ? null : _handleSaveName,
                              tooltip: 'Guardar nombre',
                            ),
                            IconButton(
                              icon: const Icon(Icons.cancel_outlined,
                                  color: Colors.grey, size: 24),
                              onPressed: () {
                                setState(() {
                                  _isEditingName = false;
                                  _nameController.text =
                                      widget.state.currentUserName ?? '';
                                });
                              },
                              tooltip: 'Cancelar',
                            ),
                          ] else ...[
                            TextButton.icon(
                              onPressed: () {
                                setState(() {
                                  _isEditingName = true;
                                  _nameController.text =
                                      widget.state.currentUserName ?? '';
                                });
                              },
                              icon: const Icon(Icons.edit_outlined, size: 16),
                              label: const Text('Editar',
                                  style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700)),
                            ),
                          ],
                        ],
                      ),
                      Divider(height: 20, color: borderColor),

                      // Correo electrónico
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Icon(Icons.email_outlined,
                              color: AppTheme.primary, size: 22),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Correo electrónico',
                                    style: TextStyle(
                                        fontSize: 11, color: mutedColor)),
                                Text(
                                  user.currentUserEmail ?? 'No disponible',
                                  style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w800,
                                      color: textColor),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: isDark
                                  ? const Color(0xFF1E2D4A)
                                  : const Color(0xFFEAF3FF),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              'Principal',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w800,
                                color: isDark
                                    ? AppTheme.primaryDarkTheme
                                    : AppTheme.primary,
                              ),
                            ),
                          ),
                        ],
                      ),
                      Divider(height: 20, color: borderColor),

                      // Fecha de registro
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Icon(Icons.calendar_month_outlined,
                              color: AppTheme.primary, size: 22),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Cuenta creada el',
                                    style: TextStyle(
                                        fontSize: 11, color: mutedColor)),
                                Text(
                                  _formatDate(user.currentUserCreatedAt),
                                  style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w800,
                                      color: textColor),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      Divider(height: 20, color: borderColor),

                      // Identificador seguro del usuario
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Icon(Icons.fingerprint_rounded,
                              color: AppTheme.primary, size: 22),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('ID de cuenta (estable)',
                                    style: TextStyle(
                                        fontSize: 11, color: mutedColor)),
                                Text(
                                  user.currentUserId ?? 'Local',
                                  style: TextStyle(
                                      fontSize: 11,
                                      fontFamily: 'monospace',
                                      color: mutedColor),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),

                // Aviso sobre cambio de correo
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isDark
                        ? const Color(0xFF16233B)
                        : const Color(0xFFF0F5FF),
                    borderRadius: BorderRadius.circular(12),
                    border:
                        Border.all(color: AppTheme.primary.withOpacity(.25)),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.security_rounded,
                          size: 18,
                          color: isDark
                              ? AppTheme.primaryDarkTheme
                              : AppTheme.primary),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'El cambio de correo electrónico requiere validación con el servidor y se procesa mediante confirmación.',
                          style: TextStyle(
                            fontSize: 11,
                            color: textColor,
                            height: 1.35,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // ==========================================
                // SEGURIDAD & CAMBIO DE CONTRASEÑA
                // ==========================================
                Text(
                  'Seguridad y contraseña',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w900,
                    color: textColor,
                  ),
                ),
                const SizedBox(height: 10),
                PrototypePanel(
                  background: cardBg,
                  borderColor: borderColor,
                  padding: const EdgeInsets.all(18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Actualizar contraseña',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w900,
                          color: textColor,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Ingresá tu contraseña actual y la nueva que deseás utilizar.',
                        style: TextStyle(fontSize: 11.5, color: mutedColor),
                      ),
                      const SizedBox(height: 16),

                      // Campo: Contraseña actual
                      Text('Contraseña actual',
                          style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: textColor)),
                      const SizedBox(height: 6),
                      TextField(
                        controller: _currentPasswordController,
                        obscureText: _obscureCurrent,
                        decoration: InputDecoration(
                          hintText: 'Tu contraseña actual',
                          suffixIcon: IconButton(
                            icon: Icon(_obscureCurrent
                                ? Icons.visibility_outlined
                                : Icons.visibility_off_outlined),
                            onPressed: () => setState(
                                () => _obscureCurrent = !_obscureCurrent),
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),

                      // Campo: Nueva contraseña
                      Text('Nueva contraseña',
                          style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: textColor)),
                      const SizedBox(height: 6),
                      TextField(
                        controller: _newPasswordController,
                        obscureText: _obscureNew,
                        decoration: InputDecoration(
                          hintText: 'Mínimo 6 caracteres',
                          suffixIcon: IconButton(
                            icon: Icon(_obscureNew
                                ? Icons.visibility_outlined
                                : Icons.visibility_off_outlined),
                            onPressed: () =>
                                setState(() => _obscureNew = !_obscureNew),
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),

                      // Campo: Confirmar contraseña
                      Text('Confirmar nueva contraseña',
                          style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: textColor)),
                      const SizedBox(height: 6),
                      TextField(
                        controller: _confirmPasswordController,
                        obscureText: _obscureConfirm,
                        decoration: InputDecoration(
                          hintText: 'Repetí la nueva contraseña',
                          suffixIcon: IconButton(
                            icon: Icon(_obscureConfirm
                                ? Icons.visibility_outlined
                                : Icons.visibility_off_outlined),
                            onPressed: () => setState(
                                () => _obscureConfirm = !_obscureConfirm),
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),

                      // Checkbox: Revocar otras sesiones
                      Material(
                        type: MaterialType.transparency,
                        child: SwitchListTile(
                          contentPadding: EdgeInsets.zero,
                          title: Text(
                            'Cerrar sesiones en otros dispositivos',
                            style: TextStyle(
                                fontSize: 12.5,
                                fontWeight: FontWeight.w700,
                                color: textColor),
                          ),
                          subtitle: Text(
                            'Mantiene únicamente esta sesión activa por seguridad.',
                            style: TextStyle(fontSize: 11, color: mutedColor),
                          ),
                          value: _revokeOtherSessions,
                          onChanged: (val) =>
                              setState(() => _revokeOtherSessions = val),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Botón cambiar contraseña
                      FilledButton(
                        onPressed:
                            _changingPassword ? null : _handleChangePassword,
                        child: _changingPassword
                            ? const SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(
                                    color: Colors.white, strokeWidth: 2))
                            : const Text('Guardar nueva contraseña'),
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
