import 'package:flutter/material.dart';

import '../core/app_colors.dart';
import '../core/app_text.dart';

/// "Recuérdame" con un interruptor morado (el círculo lleva un check al activarse).
class RememberCheck extends StatelessWidget {
  final bool value;
  final ValueChanged<bool> onChanged;

  const RememberCheck({super.key, required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    const duration = Duration(milliseconds: 220);

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => onChanged(!value),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          AnimatedContainer(
            duration: duration,
            curve: Curves.easeOut,
            width: 48,
            height: 28,
            padding: const EdgeInsets.all(3),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              gradient: value ? AppColors.button : null,
              color: value ? null : const Color(0xFFE6E6E6),
            ),
            child: AnimatedAlign(
              duration: duration,
              curve: Curves.easeOut,
              alignment: value ? Alignment.centerRight : Alignment.centerLeft,
              child: Container(
                width: 22,
                height: 22,
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.18),
                      blurRadius: 4,
                      offset: const Offset(0, 1),
                    ),
                  ],
                ),
                child: AnimatedOpacity(
                  duration: duration,
                  opacity: value ? 1 : 0,
                  child: const Icon(
                    Icons.check_rounded,
                    size: 15,
                    color: AppColors.accent,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          AnimatedDefaultTextStyle(
            duration: duration,
            style: appFont(
              fontSize: 16,
              fontWeight: value ? FontWeight.w600 : FontWeight.w400,
              color: value ? AppColors.textDark : AppColors.textGrey,
            ),
            child: const Text('Recuérdame'),
          ),
        ],
      ),
    );
  }
}
