import 'package:flutter/material.dart';

/// Colores de ypayone. Cambia aquí y se actualiza en toda la app.
class AppColors {
  AppColors._();

  static const Color primaryDark = Color(0xFF3E0563); // fondo de cabecera
  static const Color primary = Color(0xFF5B1A7A);
  static const Color accent = Color(0xFF7E2E9C); // etiquetas, enlaces
  static const Color title = Color(0xFF4B1263); // "ACCESO"
  static const Color headerLabel = Color(0xFFD9B8F0); // "INICIAR SESIÓN"
  static const Color chip = Color(0xFFF3E6F5); // fondo del botón "Mostrar"
  static const Color border = Color(0xFFE2E2E2);
  static const Color textDark = Color(0xFF222222);
  static const Color textGrey = Color(0xFF6E6E6E);
  static const Color hint = Color(0xFF9A9A9A);
  static const Color error = Color(0xFFD64545);

  static const LinearGradient button = LinearGradient(
    colors: [Color(0xFF6F2A8A), primaryDark],
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
  );

  static const LinearGradient splash = LinearGradient(
    colors: [primary, primaryDark],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}
