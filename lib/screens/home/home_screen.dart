import 'package:flutter/material.dart';

import '../../core/app_colors.dart';
import '../../core/navigation.dart';
import '../../services/auth_service.dart';
import '../auth/login_screen.dart';

/// Home provisional: solo confirma que la sesión funciona.
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  Future<void> _logout(BuildContext context) async {
    await AuthService.instance.signOut();
    if (!context.mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      fadeRoute(const LoginScreen()),
      (_) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = AuthService.instance;
    final user = auth.currentUser;
    final name = user != null ? auth.usernameOf(user) : '';

    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.primaryDark,
        foregroundColor: Colors.white,
        title: const Text(
          'ypayone',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
        actions: [
          IconButton(
            tooltip: 'Cerrar sesión',
            icon: const Icon(Icons.logout_rounded),
            onPressed: () => _logout(context),
          ),
        ],
      ),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.check_circle_rounded,
              size: 64,
              color: AppColors.accent,
            ),
            const SizedBox(height: 16),
            Text(
              'Hola, $name',
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w700,
                color: AppColors.title,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Sesión iniciada. Aquí irá el Home.',
              style: TextStyle(color: AppColors.textGrey),
            ),
          ],
        ),
      ),
    );
  }
}
