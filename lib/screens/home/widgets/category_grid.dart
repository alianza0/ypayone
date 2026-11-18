import 'package:flutter/material.dart';

import '../../../core/app_colors.dart';
import '../../../core/app_text.dart';

class Category {
  final String name;
  final String? badge;
  final String? assetPath;
  final Widget Function(double size)? iconBuilder;

  const Category(
    this.name, {
    this.badge,
    this.assetPath,
    this.iconBuilder,
  });
}

/// Categorías del inicio idénticas al diseño de referencia.
/// Si agregas imágenes en assets, solo pasa `assetPath: 'assets/...'`.
final List<Category> homeCategories = [
  Category(
    'Recargar\ncelular',
    iconBuilder: (s) => Stack(
      alignment: Alignment.center,
      children: [
        Icon(Icons.smartphone_rounded, color: const Color(0xFF9C4DCC), size: s * 0.62),
        Positioned(
          right: s * 0.14,
          bottom: s * 0.18,
          child: _MiniBadge('S/', const Color(0xFF00C897)),
        ),
      ],
    ),
  ),
  Category(
    'Yapear\nservicios',
    iconBuilder: (s) => Stack(
      alignment: Alignment.center,
      children: [
        Positioned(
          left: s * 0.15,
          child: Icon(Icons.water_drop_rounded, color: const Color(0xFF29B6F6), size: s * 0.48),
        ),
        Positioned(
          right: s * 0.14,
          bottom: s * 0.16,
          child: Icon(Icons.lightbulb_rounded, color: const Color(0xFFFFA726), size: s * 0.42),
        ),
      ],
    ),
  ),
  Category(
    'Promos',
    badge: '¡Bomba!',
    iconBuilder: (s) => Stack(
      alignment: Alignment.center,
      children: [
        Icon(Icons.verified_rounded, color: const Color(0xFFFFB74D), size: s * 0.64),
        Text(
          '%',
          style: appFont(
            color: const Color(0xFF5D1970),
            fontSize: s * 0.3,
            fontWeight: FontWeight.w900,
          ),
        ),
      ],
    ),
  ),
  Category(
    'Aprobar\ncompras',
    iconBuilder: (s) => Stack(
      alignment: Alignment.center,
      children: [
        Icon(Icons.shopping_bag_rounded, color: const Color(0xFF7986CB), size: s * 0.58),
        Positioned(
          right: s * 0.14,
          bottom: s * 0.16,
          child: Icon(Icons.check_circle_rounded, color: const Color(0xFF00C897), size: s * 0.32),
        ),
      ],
    ),
  ),
  Category(
    'Créditos',
    iconBuilder: (s) => Container(
      width: s * 0.58,
      height: s * 0.42,
      decoration: BoxDecoration(
        color: const Color(0xFF00C897),
        borderRadius: BorderRadius.circular(6),
      ),
      alignment: Alignment.center,
      child: Text(
        'S/',
        style: appFont(
          color: const Color(0xFF4A148C),
          fontSize: s * 0.24,
          fontWeight: FontWeight.w800,
        ),
      ),
    ),
  ),
  Category(
    'Gaming',
    iconBuilder: (s) => Icon(
      Icons.sports_esports_rounded,
      color: const Color(0xFF7986CB),
      size: s * 0.6,
    ),
  ),
  Category(
    'Dólares',
    iconBuilder: (s) => Container(
      width: s * 0.52,
      height: s * 0.52,
      decoration: const BoxDecoration(
        color: Color(0xFF26A69A),
        shape: BoxShape.circle,
      ),
      alignment: Alignment.center,
      child: Text(
        '\$',
        style: appFont(
          color: const Color(0xFF4A148C),
          fontSize: s * 0.3,
          fontWeight: FontWeight.w900,
        ),
      ),
    ),
  ),
  Category(
    'Yapear\nal mundo',
    iconBuilder: (s) => Icon(
      Icons.public_rounded,
      color: const Color(0xFF29B6F6),
      size: s * 0.6,
    ),
  ),
  Category(
    'SOAT',
    iconBuilder: (s) => Transform.rotate(
      angle: 0.785,
      child: Container(
        width: s * 0.44,
        height: s * 0.44,
        decoration: BoxDecoration(
          color: const Color(0xFF1E88E5),
          borderRadius: BorderRadius.circular(5),
        ),
        alignment: Alignment.center,
        child: Transform.rotate(
          angle: -0.785,
          child: Text(
            'SOAT',
            style: appFont(
              color: Colors.white,
              fontSize: s * 0.14,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ),
    ),
  ),
  Category(
    'Recargar\nTransportes',
    iconBuilder: (s) => Stack(
      alignment: Alignment.center,
      children: [
        Icon(Icons.directions_bus_rounded, color: const Color(0xFF5C6BC0), size: s * 0.56),
        Positioned(
          right: s * 0.12,
          bottom: s * 0.14,
          child: Container(
            width: s * 0.28,
            height: s * 0.2,
            decoration: BoxDecoration(
              color: const Color(0xFFFFB300),
              borderRadius: BorderRadius.circular(3),
            ),
          ),
        ),
      ],
    ),
  ),
  Category(
    'Siempre\nListos',
    iconBuilder: (s) => Icon(
      Icons.medical_services_rounded,
      color: const Color(0xFF8E24AA),
      size: s * 0.56,
    ),
  ),
];

class _MiniBadge extends StatelessWidget {
  final String text;
  final Color color;
  const _MiniBadge(this.text, this.color);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
      ),
      child: Text(
        text,
        style: appFont(
          color: Colors.white,
          fontSize: 9,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class CategoryGrid extends StatelessWidget {
  final ValueChanged<Category> onTap;
  final VoidCallback onSeeAll;

  const CategoryGrid({super.key, required this.onTap, required this.onSeeAll});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final cell = constraints.maxWidth / 4;
        final tile = (cell * 0.68).clamp(56.0, 68.0);

        final items = <Widget>[
          for (final c in homeCategories)
            _CategoryItem(
              label: c.name,
              badge: c.badge,
              tile: tile,
              onTap: () => onTap(c),
              circle: false,
              child: c.assetPath != null
                  ? Padding(
                      padding: EdgeInsets.all(tile * 0.18),
                      child: Image.asset(c.assetPath!, fit: BoxFit.contain),
                    )
                  : (c.iconBuilder != null
                      ? c.iconBuilder!(tile)
                      : const SizedBox.shrink()),
            ),
          _CategoryItem(
            label: 'Ver todo',
            tile: tile,
            onTap: onSeeAll,
            circle: true,
            child: Icon(
              Icons.add_rounded,
              color: const Color(0xFF7B1FA2),
              size: tile * 0.56,
            ),
          ),
        ];

        return Wrap(
          runSpacing: 14,
          children: [
            for (final item in items) SizedBox(width: cell, child: item),
          ],
        );
      },
    );
  }
}

class _CategoryItem extends StatelessWidget {
  final String label;
  final String? badge;
  final double tile;
  final bool circle;
  final VoidCallback onTap;
  final Widget child;

  const _CategoryItem({
    required this.label,
    this.badge,
    required this.tile,
    required this.circle,
    required this.onTap,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.center,
            children: [
              Container(
                width: tile,
                height: tile,
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: circle ? BoxShape.circle : BoxShape.rectangle,
                  borderRadius: circle ? null : BorderRadius.circular(tile * 0.30),
                  border: circle
                      ? Border.all(
                          color: const Color(0xFFB388FF).withValues(alpha: 0.45),
                          width: 4,
                        )
                      : null,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.10),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Center(child: child),
              ),
              if (badge != null)
                Positioned(
                  top: -6,
                  right: -8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppColors.yapeYellow,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      badge!,
                      style: appFont(
                        color: const Color(0xFF3E0563),
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 6),
          SizedBox(
            height: 32,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Text(
                label,
                maxLines: 2,
                textAlign: TextAlign.center,
                overflow: TextOverflow.ellipsis,
                style: appFont(
                  color: Colors.white,
                  fontSize: 12.5,
                  fontWeight: FontWeight.w500,
                  height: 1.15,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}