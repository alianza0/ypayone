import 'package:flutter/material.dart';

import '../../core/navigation.dart';
import '../../services/auth_service.dart';
import '../../widgets/app_input.dart';
import '../../widgets/app_message.dart';
import '../../widgets/auth_scaffold.dart';
import '../../widgets/primary_button.dart';
import 'login_screen.dart';

class RecoverScreen extends StatefulWidget {
  const RecoverScreen({super.key});

  @override
  State<RecoverScreen> createState() => _RecoverScreenState();
}

class _RecoverScreenState extends State<RecoverScreen> {
  final _formKey = GlobalKey<FormState>();
  final _userCtrl = TextEditingController();
  final _currentCtrl = TextEditingController();
  final _newCtrl = TextEditingController();
  bool _loading = false;

  @override
  void dispose() {
    _userCtrl.dispose();
    _currentCtrl.dispose();
    _newCtrl.dispose();
    super.dispose();
  }

  void _backToLogin() {
    Navigator.of(context).pushReplacement(instantRoute(const LoginScreen()));
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) return;

    setState(() => _loading = true);
    try {
      await AuthService.instance.changePassword(
        username: _userCtrl.text,
        currentPassword: _currentCtrl.text,
        newPassword: _newCtrl.text,
      );
      if (!mounted) return;
      showAppMessage(
        context,
        'Contraseña actualizada. Ingresa con tu nueva contraseña.',
        error: false,
      );
      _backToLogin();
    } catch (e) {
      if (mounted) showAppMessage(context, AuthService.messageFor(e));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AuthScaffold(
      eyebrow: 'SEGURIDAD',
      title: 'Recupera el acceso\na tu cuenta.',
      onBack: _backToLogin,
      formKey: _formKey,
      children: [
        const SheetLabel('RESTABLECER'),
        const SizedBox(height: 12),
        const SheetSubtitle(
          'Actualiza tu contraseña para seguir operando con seguridad.',
        ),
        const SizedBox(height: 30),
        AppInput(
          controller: _userCtrl,
          label: 'Nombre de usuario',
          isUsername: true,
          validator: (v) =>
              (v == null || v.trim().isEmpty) ? 'Ingresa tu usuario' : null,
        ),
        const SizedBox(height: 18),
        AppInput(
          controller: _currentCtrl,
          label: 'Contraseña actual',
          isPassword: true,
          numeric: true,
          validator: (v) =>
              (v == null || v.isEmpty) ? 'Ingresa tu contraseña actual' : null,
        ),
        const SizedBox(height: 18),
        AppInput(
          controller: _newCtrl,
          label: 'Contraseña nueva',
          isPassword: true,
          numeric: true,
          action: TextInputAction.done,
          validator: (v) {
            if (v == null || v.length < 6) return 'Mínimo 6 dígitos';
            if (v == _currentCtrl.text) return 'Debe ser distinta a la actual';
            return null;
          },
        ),
        const SizedBox(height: 40),
        PrimaryButton(
          text: 'Cambiar Contraseña',
          loading: _loading,
          onPressed: _submit,
        ),
      ],
    );
  }
}
