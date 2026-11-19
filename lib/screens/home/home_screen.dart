import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/app_colors.dart';
import '../../core/app_text.dart';
import '../../core/navigation.dart';
import '../../services/account_prefs_service.dart';
import '../../widgets/app_message.dart';
import '../contacts/contacts_screen.dart';
import '../qr/qr_scan_screen.dart';
import '../settings/settings_screen.dart';
import 'widgets/category_grid.dart';
import 'widgets/home_action_card.dart';
import 'widgets/home_bottom_bar.dart';
import 'widgets/home_top_bar.dart';
import 'widgets/promo_carousel.dart';

/// Pantalla principal después de iniciar sesión.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool _showBalance = false;

  void _soon([String? what]) {
    showAppMessage(
      context,
      '${what?.replaceAll('\n', ' ') ?? 'Esta opción'} estará disponible pronto.',
      error: false,
    );
  }

  /// Abre una pantalla entrando desde la derecha.
  void _open(Widget screen) {
    Navigator.of(context).push(slideRoute(screen));
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: AnimatedBuilder(
        animation: AccountPrefsService.instance,
        builder: (context, _) {
          final prefs = AccountPrefsService.instance;

          return Scaffold(
            backgroundColor: AppColors.yapePurple,
            bottomNavigationBar: HomeBottomBar(
              onQr: () => _open(const QrScanScreen()),
              onLocales: () => _open(const ContactsScreen()),
            ),
            body: SafeArea(
              bottom: false,
              child: Column(
                children: [
                  HomeTopBar(
                    onProfile: () => _open(const SettingsScreen()),
                    onSearch: () => _soon('La búsqueda'),
                    onSupport: () => _soon('Soporte'),
                    onNotifications: () => _soon('Notificaciones'),
                  ),
                  Expanded(
                    child: CustomScrollView(
                      slivers: [
                        SliverToBoxAdapter(
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(8, 12, 8, 16),
                            child: CategoryGrid(
                              onTap: (c) => _soon(c.name),
                              onSeeAll: () => _soon('Ver todo'),
                            ),
                          ),
                        ),
                        if (prefs.showHomeBanners)
                          SliverToBoxAdapter(
                            child: PromoCarousel(onTap: (p) => _soon(p.chip)),
                          ),
                        SliverFillRemaining(
                          hasScrollBody: false,
                          child: Container(
                            margin: const EdgeInsets.only(top: 16),
                            padding: const EdgeInsets.fromLTRB(16, 18, 16, 16),
                            decoration: const BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.vertical(
                                top: Radius.circular(24),
                              ),
                            ),
                            child: Column(
                              children: [
                                HomeActionCard(
                                  icon: _showBalance
                                      ? Icons.visibility_off_rounded
                                      : Icons.visibility_rounded,
                                  label: _showBalance
                                      ? 'Ocultar saldo'
                                      : 'Mostrar saldo',
                                  color: AppColors.yapeCardText,
                                  onTap: () => setState(
                                    () => _showBalance = !_showBalance,
                                  ),
                                  trailing: AnimatedSwitcher(
                                    duration: const Duration(milliseconds: 200),
                                    child: _showBalance
                                        ? Text(
                                            prefs.homeBalanceText,
                                            key: const ValueKey('saldo'),
                                            style: appFont(
                                              color: AppColors.yapeCardText,
                                              fontSize: 18,
                                              fontWeight: FontWeight.w700,
                                            ),
                                          )
                                        : const SizedBox.shrink(),
                                  ),
                                ),
                                const SizedBox(height: 12),
                                HomeActionCard(
                                  icon: Icons.receipt_long_rounded,
                                  label: 'Mostrar movimientos',
                                  color: AppColors.yapeCardText,
                                  onTap: () => _soon('Movimientos'),
                                  trailing: const Icon(
                                    Icons.keyboard_arrow_down_rounded,
                                    color: Color(0xFF9E9E9E),
                                    size: 26,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}