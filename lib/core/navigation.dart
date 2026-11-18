import 'package:flutter/cupertino.dart';
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

/// Entra desde la derecha y sale hacia la derecha (estilo iPhone),
/// pero SIN el gesto de deslizar desde el borde para volver:
/// solo se regresa con los botones de la app.
Route<T> slideRoute<T>(Widget page) {
  return PageRouteBuilder<T>(
    transitionDuration: const Duration(milliseconds: 400),
    reverseTransitionDuration: const Duration(milliseconds: 400),
    pageBuilder: (_, __, ___) => page,
    transitionsBuilder: (_, animation, secondaryAnimation, child) =>
        CupertinoPageTransition(
      primaryRouteAnimation: animation,
      secondaryRouteAnimation: secondaryAnimation,
      linearTransition: false,
      child: child,
    ),
  );
}
