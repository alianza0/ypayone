import 'package:flutter/material.dart';

import '../../../core/app_colors.dart';
import '../../../core/app_text.dart';

/// Barra inferior fija: "Abrir QR" y "Locales".
class HomeBottomBar extends StatelessWidget {
  final VoidCallback onQr;
  final VoidCallback onLocales;

  const HomeBottomBar({super.key, required this.onQr, required this.onLocales});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Color(0xFFEDEDED))),
      ),
      child: SafeArea(
        top: false,
        minimum: const EdgeInsets.only(bottom: 10),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 4),
          child: Row(
            children: [
              Expanded(
                child: _BarButton(
                  icon: Icons.qr_code_2_rounded,
                  label: 'Abrir QR',
                  color: AppColors.teal,
                  filled: false,
                  onTap: onQr,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: _BarButton(
                  icon: Icons.map_rounded,
                  label: 'Locales',
                  color: AppColors.blue,
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
  final String label;
  final Color color;
  final bool filled;
  final VoidCallback onTap;

  const _BarButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.filled,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(12);
    final fg = filled ? Colors.white : color;

    return Material(
      color: filled ? color : Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: radius,
        side: filled ? BorderSide.none : BorderSide(color: color, width: 2),
      ),
      child: InkWell(
        borderRadius: radius,
        onTap: onTap,
        child: SizedBox(
          height: 56,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: fg, size: 26),
              const SizedBox(width: 10),
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: appFont(
                    color: fg,
                    fontSize: 19,
                    fontWeight: FontWeight.w500,
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
