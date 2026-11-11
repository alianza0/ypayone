import 'package:flutter/material.dart';

import '../../core/navigation.dart';
import '../../services/auth_service.dart';
import '../../services/session_service.dart';
import '../../widgets/app_input.dart';
import '../../widgets/app_message.dart';
import '../../widgets/auth_scaffold.dart';
import '../../widgets/primary_button.dart';
import '../home/home_screen.dart';
import 'login_screen.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _vendorCtrl = TextEditingController();
  final _userCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  bool _loading = false;

  @override
  void dispose() {
    _vendorCtrl.dispose();
    _userCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) return;

    setState(() => _loading = true);
    try {
      await AuthService.instance.register(
        vendorCode: _vendorCtrl.text,
        username: _userCtrl.text,
        password: _passCtrl.text,
      );
      await SessionService.saveLogin(
        remember: true,
        username: _userCtrl.text.trim().toUpperCase(),
      );
      if (!mounted) return;
      Navigator.of(context).pushAndRemoveUntil(
        fadeRoute(const HomeScreen()),
        (_) => false,
      );
    } catch (e) {
      if (mounted) showAppMessage(context, AuthService.messageFor(e));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AuthScaffold(
      eyebrow: 'CREAR CUENTA',
      title: 'Envía y recibe dinero\nal instante.',
      onBack: () => Navigator.of(context)
          .pushReplacement(instantRoute(const LoginScreen())),
      formKey: _formKey,
      children: [
        const SheetLabel('REGISTRO'),
        const SizedBox(height: 12),
        const SheetSubtitle(
          'Configura tu perfil para empezar a operar de inmediato.',
        ),
        const SizedBox(height: 30),
        AppInput(
          controller: _vendorCtrl,
          label: 'Código de vendedor',
          validator: (v) => (v == null || v.trim().isEmpty)
              ? 'Ingresa tu código de vendedor'
              : null,
        ),
        const SizedBox(height: 18),
        AppInput(
          controller: _userCtrl,
          label: 'Nombre de usuario',
          isUsername: true,
          validator: (v) {
            if (v == null || v.trim().isEmpty) return 'Ingresa un usuario';
            if (!AuthService.instance.isValidUsername(v)) {
              return 'De 3 a 20 caracteres: letras, números, punto o guion';
            }
            return null;
          },
        ),
        const SizedBox(height: 18),
        AppInput(
          controller: _passCtrl,
          label: 'Contraseña (Solo números)',
          isPassword: true,
          numeric: true,
          action: TextInputAction.done,
          validator: (v) =>
              (v == null || v.length < 6) ? 'Mínimo 6 dígitos' : null,
        ),
        const SizedBox(height: 32),
        PrimaryButton(
          text: 'Registrarse',
          loading: _loading,
          onPressed: _submit,
        ),
      ],
    );
  }
}
