import 'package:flutter/material.dart';

import '../../../core/app_text.dart';

/// Barra superior: perfil, buscador, soporte y notificaciones.
class HomeTopBar extends StatelessWidget {
  final VoidCallback onProfile;
  final VoidCallback onSearch;
  final VoidCallback onSupport;
  final VoidCallback onNotifications;

  const HomeTopBar({
    super.key,
    required this.onProfile,
    required this.onSearch,
    required this.onSupport,
    required this.onNotifications,
  });

  @override
  Widget build(BuildContext context) {
    final soft = Colors.white.withValues(alpha: 0.85);

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      child: Row(
        children: [
          _CircleButton(icon: Icons.person_rounded, onTap: onProfile),
          const SizedBox(width: 10),
          Expanded(
            child: GestureDetector(
              onTap: onSearch,
              child: Container(
                height: 46,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.13),
                  borderRadius: BorderRadius.circular(23),
                ),
                child: Row(
                  children: [
                    Icon(Icons.search_rounded, color: soft, size: 24),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        '¿Qué desea buscar?',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: appFont(color: soft, fontSize: 17),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          _CircleButton(icon: Icons.headset_mic_rounded, onTap: onSupport),
          const SizedBox(width: 8),
          _CircleButton(
            icon: Icons.notifications_rounded,
            onTap: onNotifications,
          ),
        ],
      ),
    );
  }
}

class _CircleButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _CircleButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 46,
        height: 46,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.2),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: Colors.white, size: 24),
      ),
    );
  }
}
