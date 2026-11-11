import 'package:flutter/material.dart';

import '../../../core/app_text.dart';
import '../../../models/app_contact.dart';
import 'contacts_colors.dart';

/// Tarjeta de sugeridos: máximo 5, en columnas iguales.
/// "Editar" muestra la ✕ en cada círculo para quitarlo; "Guardar" termina.
class SuggestedContacts extends StatefulWidget {
  final List<AppContact> contacts;
  final ValueChanged<AppContact> onTap;

  /// Se llama al pulsar "Guardar" con la lista que quedó.
  final ValueChanged<List<AppContact>>? onSaved;

  const SuggestedContacts({
    super.key,
    required this.contacts,
    required this.onTap,
    this.onSaved,
  });

  static const int maxItems = 5;

  @override
  State<SuggestedContacts> createState() => _SuggestedContactsState();
}

class _SuggestedContactsState extends State<SuggestedContacts> {
  late List<AppContact> _items =
      widget.contacts.take(SuggestedContacts.maxItems).toList();
  bool _editing = false;

  void _toggleEdit() {
    if (_editing) widget.onSaved?.call(List.unmodifiable(_items));
    setState(() => _editing = !_editing);
  }

  @override
  Widget build(BuildContext context) {
    if (_items.isEmpty && !_editing) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.fromLTRB(0, 18, 0, 18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(36),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 17),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    'Lista sugeridos',
                    style: appFont(
                      fontSize: 16.5,
                      fontWeight: FontWeight.w700,
                      color: ContactsColors.textDark,
                    ),
                  ),
                ),
                GestureDetector(
                  onTap: _toggleEdit,
                  child: Text(
                    _editing ? 'Guardar' : 'Editar',
                    style: appFont(
                      fontSize: 14.5,
                      fontWeight: FontWeight.w500,
                      color: ContactsColors.edit,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (int i = 0; i < SuggestedContacts.maxItems; i++)
                  Expanded(
                    child: i < _items.length
                        ? _SuggestedItem(
                            contact: _items[i],
                            editing: _editing,
                            onTap: () => widget.onTap(_items[i]),
                            onRemove: () =>
                                setState(() => _items.removeAt(i)),
                          )
                        : const SizedBox.shrink(),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SuggestedItem extends StatelessWidget {
  final AppContact contact;
  final bool editing;
  final VoidCallback onTap;
  final VoidCallback onRemove;

  const _SuggestedItem({
    required this.contact,
    required this.editing,
    required this.onTap,
    required this.onRemove,
  });

  static const double _circle = 58;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: editing ? null : onTap,
      behavior: HitTestBehavior.opaque,
      child: Column(
        children: [
          SizedBox(
            width: _circle + 16,
            height: _circle,
            child: Stack(
              clipBehavior: Clip.none,
              alignment: Alignment.center,
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 220),
                  width: _circle,
                  height: _circle,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: editing ? Colors.white : ContactsColors.soft,
                    shape: BoxShape.circle,
                    boxShadow: editing
                        ? [
                            BoxShadow(
                              color: const Color(0xFF2A2540)
                                  .withValues(alpha: 0.08),
                              blurRadius: 18,
                              offset: const Offset(0, 6),
                            ),
                          ]
                        : const [],
                  ),
                  child: Text(
                    contact.initials,
                    style: appFont(
                      fontSize: 16,
                      color: ContactsColors.textDark,
                    ),
                  ),
                ),
                // ✕ para quitar (solo en modo editar)
                Positioned(
                  top: -8,
                  right: 0,
                  child: AnimatedScale(
                    duration: const Duration(milliseconds: 200),
                    scale: editing ? 1 : 0,
                    child: GestureDetector(
                      onTap: onRemove,
                      child: Container(
                        width: 22,
                        height: 22,
                        decoration: const BoxDecoration(
                          color: Color(0xFFECEBF0),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.close_rounded,
                          size: 16,
                          color: ContactsColors.textDark,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 17),
          // Alto fijo de 2 líneas para que los números queden alineados.
          SizedBox(
            height: 29,
            child: Text(
              contact.maskedName,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: appFont(
                fontSize: 12.5,
                fontWeight: FontWeight.w500,
                color: ContactsColors.textDark,
                height: 1.15,
              ),
            ),
          ),
          const SizedBox(height: 6),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              contact.maskedPhone,
              maxLines: 1,
              style: appFont(
                fontSize: 12.5,
                color: ContactsColors.textGrey,
                letterSpacing: 0.3,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
