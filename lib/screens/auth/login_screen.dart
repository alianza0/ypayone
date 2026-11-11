import 'package:flutter/material.dart';

import '../../core/app_colors.dart';
import '../../core/app_text.dart';
import '../../core/navigation.dart';
import '../../services/auth_service.dart';
import '../../services/session_service.dart';
import '../../widgets/app_input.dart';
import '../../widgets/app_message.dart';
import '../../widgets/auth_scaffold.dart';
import '../../widgets/primary_button.dart';
import '../../widgets/remember_check.dart';
import '../home/home_screen.dart';
import 'recover_screen.dart';
import 'register_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _userCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  bool _remember = true;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    SessionService.lastUsername().then((u) {
      if (u != null && mounted) _userCtrl.text = u.toUpperCase();
    });
  }

  @override
  void dispose() {
    _userCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) return;

    setState(() => _loading = true);
    try {
      await AuthService.instance.signIn(_userCtrl.text, _passCtrl.text);
      await SessionService.saveLogin(
        remember: _remember,
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

  void _goTo(Widget page) {
    Navigator.of(context).pushReplacement(instantRoute(page));
  }

  @override
  Widget build(BuildContext context) {
    return AuthScaffold(
      eyebrow: 'INICIAR SESIÓN',
      title: 'Gestiona tus finanzas\ncon seguridad.',
      formKey: _formKey,
      children: [
        const SheetLabel('BIENVENIDO'),
        const SizedBox(height: 4),
        Text(
          'ACCESO',
          style: appFont(
            color: AppColors.title,
            fontSize: 38,
            fontWeight: FontWeight.w800,
            letterSpacing: -1.2,
          ),
        ),
        const SizedBox(height: 6),
        const SheetSubtitle('Ingresa tus credenciales para continuar.'),
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
          controller: _passCtrl,
          label: 'Contraseña (PIN)',
          isPassword: true,
          numeric: true,
          action: TextInputAction.done,
          validator: (v) =>
              (v == null || v.isEmpty) ? 'Ingresa tu contraseña' : null,
        ),
        const SizedBox(height: 26),
        Row(
          children: [
            RememberCheck(
              value: _remember,
              onChanged: (v) => setState(() => _remember = v),
            ),
            const Spacer(),
            GestureDetector(
              onTap: () => _goTo(const RecoverScreen()),
              child: Text(
                '¿Olvidaste tu contraseña?',
                style: appFont(
                  color: AppColors.accent,
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 32),
        PrimaryButton(text: 'Ingresar', loading: _loading, onPressed: _submit),
        const SizedBox(height: 40),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              '¿No tienes una cuenta? ',
              style: appFont(color: AppColors.textGrey, fontSize: 16),
            ),
            GestureDetector(
              onTap: () => _goTo(const RegisterScreen()),
              child: Text(
                'Regístrate aquí',
                style: appFont(
                  color: AppColors.accent,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
