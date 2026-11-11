import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/app_colors.dart';
import '../../core/app_text.dart';
import '../../core/navigation.dart';
import '../../services/auth_service.dart';
import '../../services/session_service.dart';
import '../../widgets/wave_painter.dart';
import '../auth/login_screen.dart';
import '../home/home_screen.dart';

/// Pantalla de carga: revisa si hay sesión y manda a Home o a Login.
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1100),
  )..forward();

  @override
  void initState() {
    super.initState();
    _route();
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  Future<void> _route() async {
    final results = await Future.wait<Object?>([
      Future<void>.delayed(const Duration(milliseconds: 1800)),
      FirebaseAuth.instance.authStateChanges().first,
      SessionService.shouldRemember(),
    ]);

    User? user = results[1] as User?;
    final remember = results[2] as bool;

    if (user != null && !remember) {
      await AuthService.instance.signOut();
      user = null;
    }

    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      user != null
          ? fadeRoute(const HomeScreen())
          : instantRoute(const LoginScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final anim = _c.drive(CurveTween(curve: Curves.easeOutCubic));

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        body: Container(
          decoration: const BoxDecoration(gradient: AppColors.splash),
          child: Stack(
            children: [
              const Positioned(
                top: 0,
                left: 0,
                right: 0,
                height: 320,
                child: CustomPaint(painter: WavePainter()),
              ),
              Center(
                child: FadeTransition(
                  opacity: anim,
                  child: ScaleTransition(
                    scale: anim.drive(Tween(begin: 0.85, end: 1.0)),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'ypayone',
                          style: appFont(
                            color: Colors.white,
                            fontSize: 46,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -1,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Tu dinero, al instante',
                          style: appFont(
                            color: AppColors.headerLabel,
                            fontSize: 15,
                          ),
                        ),
                        const SizedBox(height: 48),
                        const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white70,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
