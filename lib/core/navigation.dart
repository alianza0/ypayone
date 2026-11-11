import 'package:flutter/material.dart';

/// Cambio de pantalla instantáneo (sin desvanecido ni deslizamiento).
/// Se usa entre Splash / Login / Registro / Recuperar: el fondo morado es el mismo,
/// así que solo se nota el panel blanco subiendo desde abajo.
Route<T> instantRoute<T>(Widget page) {
  return PageRouteBuilder<T>(
    transitionDuration: Duration.zero,
    reverseTransitionDuration: Duration.zero,
    pageBuilder: (_, __, ___) => page,
  );
}

/// Transición con desvanecido (para entrar al Home o salir de él).
Route<T> fadeRoute<T>(Widget page) {
  return PageRouteBuilder<T>(
    transitionDuration: const Duration(milliseconds: 400),
    pageBuilder: (_, __, ___) => page,
    transitionsBuilder: (_, animation, __, child) =>
        FadeTransition(opacity: animation, child: child),
  );
}
