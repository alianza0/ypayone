import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/app_text.dart';
import '../../core/navigation.dart';
import '../../widgets/app_message.dart';
import 'account_screen.dart';

/// Pantalla "Ajustes" (se abre desde el botón de perfil del inicio).
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  /// Versión que se muestra abajo. Cámbiala cuando publiques una nueva.
  static const String appVersion = 'v1.0.0 (Build 1)';

  static const _textDark = Color(0xFF1F1D2B);
  static const _chevron = Color(0xFF9A98A6);
  static const _divider = Color(0xFFF0EEF5);
  static const _red = Color(0xFFE5383B);
  static const _redBg = Color(0xFFFCDDE0);

  void _soon(BuildContext context, String what) {
    showAppMessage(context, '$what estará disponible pronto.', error: false);
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark,
      child: Scaffold(
        backgroundColor: const Color(0xFFF4F2FA),
        body: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFFF1F0FA), Color(0xFFF8F0F8), Color(0xFFF0F4FB)],
            ),
          ),
          child: SafeArea(
            child: Column(
              children: [
                _buildHeader(context),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(18, 16, 18, 24),
                    child: Column(
                      children: [
                        _group([
                          _Item(
                            icon: Icons.person_outline_rounded,
                            label: 'Mi Cuenta',
                            onTap: () => Navigator.of(context).push(
                              slideRoute(const AccountScreen()),
                            ),
                          ),
                          _Item(
                            icon: Icons.credit_card_rounded,
                            label: 'Auto-completado (BETA)',
                            onTap: () => _soon(context, 'Auto-completado'),
                          ),
                        ]),
                        const SizedBox(height: 15),
                        _group([
                          _Item(
                            icon: Icons.description_outlined,
                            label: 'Editar voucher',
                            onTap: () => _soon(context, 'Editar voucher'),
                          ),
                          _Item(
                            icon: Icons.people_outline_rounded,
                            label: 'Contactos guardados',
                            onTap: () => _soon(context, 'Contactos guardados'),
                          ),
                          _Item(
                            icon: Icons.notifications_none_rounded,
                            label: 'Notificaciones',
                            badge: 'Desactivado',
                            onTap: () => _soon(context, 'Notificaciones'),
                          ),
                        ]),
                        const SizedBox(height: 15),
                        _group([
                          _Item(
                            icon: Icons.help_outline_rounded,
                            label: 'Soporte técnico',
                            onTap: () => _soon(context, 'Soporte técnico'),
                          ),
                          _Item(
                            icon: Icons.article_outlined,
                            label: 'Legal y Privacidad',
                            onTap: () => _soon(context, 'Legal y Privacidad'),
                          ),
                        ]),
                      ],
                    ),
                  ),
                ),
                _buildVersion(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 64,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Positioned(
            left: 22,
            child: GestureDetector(
              onTap: () => Navigator.of(context).maybePop(),
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF2A2540).withValues(alpha: 0.06),
                      blurRadius: 10,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.arrow_back_rounded,
                  color: _textDark,
                  size: 22,
                ),
              ),
            ),
          ),
          Text(
            'Ajustes',
            style: appFont(
              fontSize: 17.5,
              fontWeight: FontWeight.w700,
              color: _textDark,
            ),
          ),
        ],
      ),
    );
  }

  /// Tarjeta blanca con varias filas separadas por líneas finas.
  Widget _group(List<_Item> items) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.85),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF6E4A9E).withValues(alpha: 0.05),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        children: [
          for (int i = 0; i < items.length; i++) ...[
            items[i],
            if (i < items.length - 1)
              Container(
                height: 1,
                margin: const EdgeInsets.symmetric(horizontal: 16),
                color: _divider,
              ),
          ],
        ],
      ),
    );
  }

  Widget _buildVersion() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16, top: 8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.7),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          appVersion,
          style: appFont(
            fontSize: 12.5,
            fontWeight: FontWeight.w500,
            color: const Color(0xFF7A7888),
          ),
        ),
      ),
    );
  }
}

/// Fila: icono en cuadrito blanco, texto, (badge) y flecha.
class _Item extends StatelessWidget {
  final IconData icon;
  final String label;
  final String? badge;
  final VoidCallback onTap;

  const _Item({
    required this.icon,
    required this.label,
    required this.onTap,
    this.badge,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(24),
      child: SizedBox(
        height: 67,
        child: Row(
          children: [
            const SizedBox(width: 16),
            Container(
              width: 37,
              height: 37,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(11),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF2A2540).withValues(alpha: 0.07),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Icon(icon, size: 21, color: SettingsScreen._textDark),
            ),
            const SizedBox(width: 15),
            Expanded(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: appFont(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: SettingsScreen._textDark,
                ),
              ),
            ),
            if (badge != null) ...[
              Container(
                padding: const EdgeInsets.fromLTRB(10, 5, 5, 5),
                decoration: BoxDecoration(
                  color: SettingsScreen._redBg,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      badge!,
                      style: appFont(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w700,
                        color: SettingsScreen._red,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Container(
                      width: 16,
                      height: 16,
                      alignment: Alignment.center,
                      decoration: const BoxDecoration(
                        color: SettingsScreen._red,
                        shape: BoxShape.circle,
                      ),
                      child: Text(
                        '!',
                        style: appFont(
                          fontSize: 11,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                          height: 1.1,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
            ],
            const Icon(
              Icons.chevron_right_rounded,
              color: SettingsScreen._chevron,
              size: 22,
            ),
            const SizedBox(width: 14),
          ],
        ),
      ),
    );
  }
}