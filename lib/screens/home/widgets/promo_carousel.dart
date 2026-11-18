import 'package:flutter/material.dart';

import '../../../core/app_colors.dart';
import '../../../core/app_text.dart';

class Promo {
  final String chip;
  final String title;
  final String subtitle;
  final String? imageAsset;
  final String emoji;

  const Promo({
    required this.chip,
    required this.title,
    required this.subtitle,
    this.imageAsset,
    this.emoji = '📢',
  });
}

/// Banners del carrusel.
/// Para poner tus propias imágenes, coloca la ruta en `imageAsset: 'assets/...'`.
const List<Promo> homePromos = [
  Promo(
    chip: 'Siempre Listos',
    title: '¿HAY UNA\nEMERGENCIA\nCERCA DE TI?',
    subtitle: 'Repórtala aquí',
    imageAsset: null, // <-- Pon aquí tu imagen, ej: 'assets/promo1.png'
    emoji: '🚨',
  ),
  Promo(
    chip: 'Gaming',
    title: 'Recarga 100 d...\n+ 10% BO...',
    subtitle: 'Desde S/3.90',
    imageAsset: null, // <-- Pon aquí tu imagen, ej: 'assets/promo2.png'
    emoji: '🎮',
  ),
  Promo(
    chip: 'Promos',
    title: 'PIZZA PARA\nCOMPARTIR',
    subtitle: '2x1 todos los martes',
    imageAsset: null,
    emoji: '🍕',
  ),
  Promo(
    chip: 'Créditos',
    title: 'CRÉDITO AL\nINSTANTE',
    subtitle: 'Pídelo sin papeleos',
    imageAsset: null,
    emoji: '💸',
  ),
  Promo(
    chip: 'Recargas',
    title: 'RECARGA TU\nCELULAR HOY',
    subtitle: 'Sin comisiones extras',
    imageAsset: null,
    emoji: '📱',
  ),
  Promo(
    chip: 'Servicios',
    title: 'PAGA TUS\nRECIBOS AQUÍ',
    subtitle: 'Luz, agua e internet',
    imageAsset: null,
    emoji: '💡',
  ),
  Promo(
    chip: 'SOAT',
    title: 'COMPRA TU\nSOAT DIGITAL',
    subtitle: 'En menos de 2 minutos',
    imageAsset: null,
    emoji: '🚗',
  ),
  Promo(
    chip: 'Dólares',
    title: 'CAMBIA TUS\nDÓLARES YA',
    subtitle: 'Con un súper tipo de cambio',
    imageAsset: null,
    emoji: '💵',
  ),
];

/// Carrusel infinito: mecánica original intacta.
class PromoCarousel extends StatefulWidget {
  final ValueChanged<Promo> onTap;

  const PromoCarousel({super.key, required this.onTap});

  @override
  State<PromoCarousel> createState() => _PromoCarouselState();
}

class _PromoCarouselState extends State<PromoCarousel>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  static const _slideTime = Duration(seconds: 4);
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
          height: 142,
          child: NotificationListener<ScrollNotification>(
            onNotification: _onScroll,
            child: PageView.builder(
              controller: _controller,
              padEnds: false,
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
        const SizedBox(height: 12),
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

class _Dot extends StatelessWidget {
  final bool active;
  final Animation<double> progress;

  const _Dot({required this.active, required this.progress});

  static const double _size = 7;
  static const double _activeWidth = 34;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOut,
      margin: const EdgeInsets.symmetric(horizontal: 3.5),
      width: active ? _activeWidth : _size,
      height: _size,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.35),
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
      borderRadius: BorderRadius.circular(18),
      child: Container(
        color: Colors.white,
        child: Row(
          children: [
            Expanded(
              flex: 11,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(14, 12, 8, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.promoChip,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        promo.chip,
                        style: appFont(
                          color: Colors.white,
                          fontSize: 11.5,
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
                          fontSize: 16,
                          fontWeight: FontWeight.w900,
                          height: 1.08,
                          letterSpacing: -0.3,
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      promo.subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: appFont(
                        color: const Color(0xFF2B2B2B),
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Expanded(
              flex: 10,
              child: promo.imageAsset != null
                  ? Image.asset(
                      promo.imageAsset!,
                      fit: BoxFit.cover,
                      height: double.infinity,
                    )
                  : Container(
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Color(0xFF8E24AA), Color(0xFF4A148C)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                      ),
                      child: Center(
                        child: Text(
                          promo.emoji,
                          style: const TextStyle(fontSize: 52),
                        ),
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}