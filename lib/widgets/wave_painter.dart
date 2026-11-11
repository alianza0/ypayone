import 'package:flutter/material.dart';

/// Ondas suaves de la parte superior de la cabecera morada.
class WavePainter extends CustomPainter {
  const WavePainter();

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    final back = Path()
      ..moveTo(0, 0)
      ..lineTo(0, h * 0.42)
      ..cubicTo(w * 0.28, h * 0.62, w * 0.55, h * 0.30, w, h * 0.46)
      ..lineTo(w, 0)
      ..close();
    canvas.drawPath(back, Paint()..color = Colors.white.withValues(alpha: 0.06));

    final front = Path()
      ..moveTo(0, 0)
      ..lineTo(0, h * 0.26)
      ..cubicTo(w * 0.30, h * 0.50, w * 0.60, h * 0.18, w, h * 0.32)
      ..lineTo(w, 0)
      ..close();
    canvas.drawPath(front, Paint()..color = Colors.white.withValues(alpha: 0.07));
  }

  @override
  bool shouldRepaint(WavePainter oldDelegate) => false;
}
