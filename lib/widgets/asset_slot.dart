import 'package:flutter/material.dart';

/// Espacio reservado para una imagen tuya (PNG en assets/icons/).
/// Mientras no exista el archivo, se queda como un hueco vacío del mismo tamaño.
class AssetSlot extends StatelessWidget {
  final String path;
  final double size;

  const AssetSlot(this.path, {super.key, required this.size});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: Image.asset(
        path,
        fit: BoxFit.contain,
        errorBuilder: (_, __, ___) => const SizedBox.shrink(),
      ),
    );
  }
}
