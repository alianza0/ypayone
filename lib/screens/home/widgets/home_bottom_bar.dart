import 'package:flutter/material.dart';

import '../../../core/app_colors.dart';
import '../../../core/app_text.dart';

/// Barra inferior fija: "Escanear QR" y "Yapear".
class HomeBottomBar extends StatelessWidget {
  final VoidCallback onQr;
  final VoidCallback onLocales;

  const HomeBottomBar({super.key, required this.onQr, required this.onLocales});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      child: SafeArea(
        top: false,
        minimum: const EdgeInsets.only(bottom: 10),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
          child: Row(
            children: [
              Expanded(
                child: _BarButton(
                  icon: Icons.qr_code_scanner_rounded,
                  label: 'Escanear QR',
                  color: AppColors.yapeTeal,
                  filled: false,
                  onTap: onQr,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: _BarButton(
                  icon: Icons.send_rounded,
                  rotateIcon: -0.6,
                  label: 'Yapear',
                  color: AppColors.yapeTeal,
                  filled: true,
                  onTap: onLocales,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BarButton extends StatelessWidget {
  final IconData icon;
  final double rotateIcon;
  final String label;
  final Color color;
  final bool filled;
  final VoidCallback onTap;

  const _BarButton({
    required this.icon,
    this.rotateIcon = 0,
    required this.label,
    required this.color,
    required this.filled,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(10);
    final fg = filled ? Colors.white : color;

    return Material(
      color: filled ? color : Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: radius,
        side: filled ? BorderSide.none : BorderSide(color: color, width: 1.6),
      ),
      child: InkWell(
        borderRadius: radius,
        onTap: onTap,
        child: SizedBox(
          height: 50,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Transform.rotate(
                angle: rotateIcon,
                child: Icon(icon, color: fg, size: 22),
              ),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: appFont(
                    color: fg,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
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