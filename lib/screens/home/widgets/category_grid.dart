import 'package:flutter/material.dart';

import '../../../core/app_colors.dart';
import '../../../core/app_text.dart';

class Category {
  final String name;
  final String emoji;
  const Category(this.name, this.emoji);
}

/// Categorías del inicio. Para cambiar o agregar, edita esta lista.
/// (Más adelante se pueden reemplazar los emojis por imágenes propias.)
const List<Category> homeCategories = [
  Category('Hamburguesas', '🍔'),
  Category('Pizzas', '🍕'),
  Category('Pollo frito', '🍗'),
  Category('Tacos', '🌮'),
  Category('Chifa', '🍛'),
  Category('Sushi', '🍣'),
  Category('Postres', '🍨'),
  Category('Bebidas', '☕'),
  Category('Snacks', '🍟'),
  Category('Sándwiches', '🥪'),
  Category('Delivery', '🛵'),
];

/// Cuadrícula de 4 columnas. Los cuadros se adaptan al ancho del celular.
class CategoryGrid extends StatelessWidget {
  final ValueChanged<Category> onTap;
  final VoidCallback onSeeAll;

  const CategoryGrid({super.key, required this.onTap, required this.onSeeAll});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final cell = constraints.maxWidth / 4;
        final tile = (cell * 0.74).clamp(56.0, 76.0);

        final items = <Widget>[
          for (final c in homeCategories)
            _CategoryItem(
              label: c.name,
              tile: tile,
              onTap: () => onTap(c),
              circle: false,
              child: Text(c.emoji, style: TextStyle(fontSize: tile * 0.52)),
            ),
          _CategoryItem(
            label: 'Ver todo',
            tile: tile,
            onTap: onSeeAll,
            circle: true,
            child: Icon(
              Icons.add_rounded,
              color: AppColors.orange,
              size: tile * 0.6,
            ),
          ),
        ];

        return Wrap(
          runSpacing: 16,
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
  final double tile;
  final bool circle;
  final VoidCallback onTap;
  final Widget child;

  const _CategoryItem({
    required this.label,
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
        children: [
          Container(
            width: tile,
            height: tile,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(circle ? tile : tile * 0.32),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.08),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Center(child: child),
          ),
          const SizedBox(height: 7),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 2),
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                label,
                maxLines: 1,
                style: appFont(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
