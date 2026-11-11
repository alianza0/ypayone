import 'package:flutter/material.dart';

/// Etiqueta compartida del botón "volver": al cambiar de pantalla,
/// el botón se queda fijo encima mientras el contenido entra.
const String navBackHeroTag = 'nav-back-button';

/// Botón redondo lila con icono (volver, cerrar…).
class CircleIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final double size;
  final double iconSize;
  final Color background;
  final Color color;
  final String? heroTag;

  const CircleIconButton({
    super.key,
    required this.icon,
    required this.onTap,
    this.size = 34,
    this.iconSize = 20,
    this.background = const Color(0xFFF1EFF8),
    this.color = Colors.black,
    this.heroTag,
  });

  @override
  Widget build(BuildContext context) {
    Widget button = GestureDetector(
      onTap: onTap,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(color: background, shape: BoxShape.circle),
        child: Icon(icon, color: color, size: iconSize),
      ),
    );

    if (heroTag != null) {
      button = Hero(
        tag: heroTag!,
        transitionOnUserGestures: true,
        child: button,
      );
    }
    return button;
  }
}
