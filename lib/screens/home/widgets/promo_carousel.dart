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

/// Carrusel infinito: avanza solo cada 4 segundos, siempre hacia adelante
/// (después del último sigue el primero, sin salto hacia atrás).
/// El punto activo es una barrita que se va llenando con el tiempo.
/// Si la app pasa a segundo plano, todo se detiene y luego sigue donde quedó.
class PromoCarousel extends StatefulWidget {
  final ValueChanged<Promo> onTap;

  const PromoCarousel({super.key, required this.onTap});

  @override
  State<PromoCarousel> createState() => _PromoCarouselState();
}

class _PromoCarouselState extends State<PromoCarousel>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  /// Tiempo que se muestra cada banner.
  static const _slideTime = Duration(seconds: 4);

  /// Empieza en una página muy alta para poder deslizar hacia ambos lados.
  static final int _startPage = homePromos.length * 1000;

  late final PageController _controller =
      PageController(viewportFraction: 0.88, initialPage: _startPage);
  late final AnimationController _progress =
      AnimationController(vsync: this, duration: _slideTime);

  int _page = _startPage;
  bool _dragging = false;
  bool _appActive = true;

  int get _index => _page % homePromos.length;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _progress.addStatusListener((status) {
      if (status == AnimationStatus.completed && _controller.hasClients) {
        _controller.animateToPage(
          _page + 1,
          duration: const Duration(milliseconds: 450),
          curve: Curves.easeOutCubic,
        );
      }
    });
    _progress.forward();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _progress.dispose();
    _controller.dispose();
    super.dispose();
  }

  /// Pausa al salir de la app y continúa al volver, desde el mismo punto.
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _appActive = state == AppLifecycleState.resumed;
    if (_appActive) {
      _resume();
    } else {
      _progress.stop();
    }
  }

  void _resume() {
    if (!_appActive || _dragging) return;
    if (_progress.value >= 1) {
      _progress.forward(from: 0);
    } else {
      _progress.forward();
    }
  }

  void _onPageChanged(int page) {
    setState(() => _page = page);
    _progress.value = 0;
    _resume();
  }

  bool _onScroll(ScrollNotification n) {
    if (n is ScrollStartNotification && n.dragDetails != null) {
      // El usuario está deslizando con el dedo: se pausa el tiempo.
      _dragging = true;
      _progress.stop();
    } else if (n is ScrollEndNotification && _dragging) {
      _dragging = false;
      _resume();
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          height: 150,
          child: NotificationListener<ScrollNotification>(
            onNotification: _onScroll,
            child: PageView.builder(
              controller: _controller,
              padEnds: false,
              // Sin itemCount: no tiene final.
              onPageChanged: _onPageChanged,
              itemBuilder: (_, i) {
                final promo = homePromos[i % homePromos.length];
                return Padding(
                  padding: const EdgeInsets.only(left: 16),
                  child: GestureDetector(
                    onTap: () => widget.onTap(promo),
                    child: _PromoCard(promo: promo),
                  ),
                );
              },
            ),
          ),
        ),
        const SizedBox(height: 14),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            for (int i = 0; i < homePromos.length; i++)
              _Dot(active: i == _index, progress: _progress),
          ],
        ),
      ],
    );
  }
}

/// Punto del carrusel. El activo se estira y se llena con el tiempo.
class _Dot extends StatelessWidget {
  final bool active;
  final Animation<double> progress;

  const _Dot({required this.active, required this.progress});

  static const double _size = 8;
  static const double _activeWidth = 36;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOut,
      margin: const EdgeInsets.symmetric(horizontal: 4),
      width: active ? _activeWidth : _size,
      height: _size,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.45),
        borderRadius: BorderRadius.circular(_size / 2),
      ),
      alignment: Alignment.centerLeft,
      child: active
          ? AnimatedBuilder(
              animation: progress,
              builder: (_, __) => Container(
                width: _size + (_activeWidth - _size) * progress.value,
                height: _size,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(_size / 2),
                ),
              ),
            )
          : null,
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
