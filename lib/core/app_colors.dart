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

  // Pantalla principal (Home - Estilo Yape)
  static const Color yapePurple = Color(0xFF74007B);
  static const Color yapeDarkPurple = Color(0xFF5A0060);
  static const Color yapeCardText = Color(0xFF6A1B7A);
  static const Color yapeTeal = Color(0xFF00BFA5);
  static const Color yapeYellow = Color(0xFFFFB800);

  // Compatibilidad con el resto de pantallas
  static const Color orange = yapePurple;
  static const Color orangeText = yapeCardText;
  static const Color purpleAction = yapeCardText;
  static const Color promoChip = Color(0xFF7B2CBF);
  static const Color promoBg = Color(0xFFFFFFFF);
  static const Color promoTitle = Color(0xFF1F1F2E);
  static const Color teal = yapeTeal;
  static const Color blue = yapeTeal;

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