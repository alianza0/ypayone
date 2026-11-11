import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../../../core/app_text.dart';
import 'amount_display.dart';

/// Cuadro "Enviando" con TODA la pantalla oscurecida (incluida la parte de arriba).
void showSendingOverlay(BuildContext context) {
  showGeneralDialog<void>(
    context: context,
    useRootNavigator: true,
    barrierDismissible: false,
    barrierColor: Colors.black.withValues(alpha: 0.72),
    transitionDuration: const Duration(milliseconds: 200),
    pageBuilder: (_, __, ___) => PopScope(
      canPop: false,
      child: Center(
        child: Material(
          color: Colors.transparent,
          child: Container(
            width: 112,
            padding: const EdgeInsets.fromLTRB(12, 18, 12, 16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const CupertinoActivityIndicator(
                  radius: 16,
                  color: sendPurple,
                ),
                const SizedBox(height: 12),
                Text(
                  'Enviando',
                  style: appFont(
                    fontSize: 16,
                    color: const Color(0xFF2A2540),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    ),
    transitionBuilder: (_, animation, __, child) =>
        FadeTransition(opacity: animation, child: child),
  );
}
