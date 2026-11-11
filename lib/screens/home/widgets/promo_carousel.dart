import 'dart:async';

import 'package:flutter/material.dart';

import '../../../core/app_colors.dart';
import '../../../core/app_text.dart';

class Promo {
  final String title;
  final String subtitle;
  final String emoji;
  const Promo(this.title, this.subtitle, this.emoji);
}

/// Banners del carrusel. Más adelante se pueden poner fotos reales.
const List<Promo> homePromos = [
  Promo('¡SABORES QUE\nENAMORAN!', 'Pide tus favoritos hoy', '🍔'),
  Promo('PIZZA PARA\nCOMPARTIR', '2x1 todos los martes', '🍕'),
  Promo('CRUJIENTE\nY DORADO', 'Pollo frito al punto', '🍗'),
  Promo('ANTOJO\nMEXICANO', 'Tacos recién hechos', '🌮'),
  Promo('SABOR\nORIENTAL', 'Chifa a tu puerta', '🍛'),
  Promo('FRESCO\nY RICO', 'Sushi del día', '🍣'),
  Promo('ALGO\nDULCE', 'Postres irresistibles', '🍨'),
  Promo('LLEGA\nRÁPIDO', 'Delivery en minutos', '🛵'),
];

/// Carrusel que avanza solo cada 4 segundos y también se desliza con el dedo.
class PromoCarousel extends StatefulWidget {
  final ValueChanged<Promo> onTap;

  const PromoCarousel({super.key, required this.onTap});

  @override
  State<PromoCarousel> createState() => _PromoCarouselState();
}

class _PromoCarouselState extends State<PromoCarousel> {
  final _controller = PageController(viewportFraction: 0.88);
  Timer? _timer;
  int _page = 0;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 4), (_) {
      if (!_controller.hasClients) return;
      final next = (_page + 1) % homePromos.length;
      _controller.animateToPage(
        next,
        duration: const Duration(milliseconds: 450),
        curve: Curves.easeOutCubic,
      );
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          height: 150,
          child: PageView.builder(
            controller: _controller,
            padEnds: false,
            itemCount: homePromos.length,
            onPageChanged: (i) => setState(() => _page = i),
            itemBuilder: (_, i) => Padding(
              padding: const EdgeInsets.only(left: 16),
              child: GestureDetector(
                onTap: () => widget.onTap(homePromos[i]),
                child: _PromoCard(promo: homePromos[i]),
              ),
            ),
          ),
        ),
        const SizedBox(height: 14),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            for (int i = 0; i < homePromos.length; i++)
              AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                margin: const EdgeInsets.symmetric(horizontal: 4),
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: i == _page
                      ? Colors.white
                      : Colors.white.withValues(alpha: 0.45),
                ),
              ),
          ],
        ),
      ],
    );
  }
}

class _PromoCard extends StatelessWidget {
  final Promo promo;
  const _PromoCard({required this.promo});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(22),
      child: Container(
        color: AppColors.promoBg,
        child: Row(
          children: [
            Expanded(
              flex: 11,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(14, 12, 8, 14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.promoChip,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Text(
                        'Pide ahora',
                        style: appFont(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const Spacer(),
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: Text(
                        promo.title,
                        style: appFont(
                          color: AppColors.promoTitle,
                          fontSize: 22,
                          fontWeight: FontWeight.w900,
                          height: 1.0,
                          letterSpacing: -0.5,
                        ),
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      promo.subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: appFont(
                        color: const Color(0xFF2B2B2B),
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Expanded(
              flex: 9,
              child: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFF6B4532), Color(0xFF2A1A12)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Center(
                  child: Text(promo.emoji, style: const TextStyle(fontSize: 64)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
