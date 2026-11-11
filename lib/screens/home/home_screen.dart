import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/app_colors.dart';
import '../../core/app_text.dart';
import '../../widgets/app_message.dart';
import '../contacts/contacts_screen.dart';
import 'widgets/category_grid.dart';
import 'widgets/home_action_card.dart';
import 'widgets/home_bottom_bar.dart';
import 'widgets/home_top_bar.dart';
import 'widgets/profile_sheet.dart';
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
      '${what ?? 'Esta opción'} estará disponible pronto.',
      error: false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: AppColors.orange,
        bottomNavigationBar: HomeBottomBar(
          onQr: () => _soon('Abrir QR'),
          onLocales: () => _soon('Locales'),
        ),
        body: SafeArea(
          bottom: false,
          child: Column(
            children: [
              HomeTopBar(
                onProfile: () => showProfileSheet(context),
                onSearch: () => _soon('La búsqueda'),
                onSupport: () => _soon('Soporte'),
                onNotifications: () => _soon('Notificaciones'),
              ),
              Expanded(
                child: CustomScrollView(
                  slivers: [
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(8, 18, 8, 22),
                        child: CategoryGrid(
                          onTap: (c) => _soon(c.name),
                          onSeeAll: () => _soon('Ver todo'),
                        ),
                      ),
                    ),
                    SliverToBoxAdapter(
                      child: PromoCarousel(onTap: (p) => _soon('Esta promo')),
                    ),
                    SliverFillRemaining(
                      hasScrollBody: false,
                      child: Container(
                        margin: const EdgeInsets.only(top: 20),
                        padding: const EdgeInsets.fromLTRB(16, 22, 16, 24),
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          borderRadius:
                              BorderRadius.vertical(top: Radius.circular(28)),
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
                              color: AppColors.orangeText,
                              onTap: () =>
                                  setState(() => _showBalance = !_showBalance),
                              trailing: AnimatedSwitcher(
                                duration: const Duration(milliseconds: 200),
                                child: _showBalance
                                    ? Text(
                                        'S/ 0.00',
                                        key: const ValueKey('saldo'),
                                        style: appFont(
                                          color: AppColors.orangeText,
                                          fontSize: 20,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      )
                                    : const SizedBox.shrink(),
                              ),
                            ),
                            const SizedBox(height: 14),
                            HomeActionCard(
                              icon: Icons.list_alt_rounded,
                              label: 'Mostrar movimientos',
                              color: AppColors.purpleAction,
                              // Provisional: abre la pantalla "Lista".
                              onTap: () => Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) => const ContactsScreen(),
                                ),
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
      ),
    );
  }
}
