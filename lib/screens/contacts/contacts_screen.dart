import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/app_text.dart';
import '../../core/phone_utils.dart';
import '../../data/sample_contacts.dart';
import '../../models/app_contact.dart';
import '../../widgets/app_message.dart';
import '../../widgets/circle_icon_button.dart';
import '../send/send_amount_screen.dart';
import 'widgets/contact_tile.dart';
import 'widgets/contacts_colors.dart';
import 'widgets/suggested_contacts.dart';

/// Pantalla "Lista": buscador, nuevo número, sugeridos y todos los contactos.
/// Al bajar, el título grande sube y aparece "Lista" junto al botón de regreso.
class ContactsScreen extends StatefulWidget {
  const ContactsScreen({super.key});

  @override
  State<ContactsScreen> createState() => _ContactsScreenState();
}

class _ContactsScreenState extends State<ContactsScreen> {
  final _searchCtrl = TextEditingController();
  final _scroll = ScrollController();
  String _query = '';
  double _offset = 0;
  List<AppContact> _suggested =
      sampleSuggested.take(SuggestedContacts.maxItems).toList();

  /// Cuánto hay que bajar para que el título termine de subir.
  static const double _titleExtent = 52;
  static const double _searchExtent = 56;

  @override
  void initState() {
    super.initState();
    _scroll.addListener(() => setState(() => _offset = _scroll.offset));
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    _scroll.dispose();
    super.dispose();
  }

  bool get _searching => _query.trim().isNotEmpty;

  List<AppContact> get _filtered {
    final q = _query.trim().toLowerCase();
    if (q.isEmpty) return sampleContacts;
    // Para números: solo dígitos y sin +51.
    final digits =
        PhoneUtils.stripCountryCode(PhoneUtils.digitsOnly(q));
    return sampleContacts
        .where((c) =>
            c.name.toLowerCase().contains(q) ||
            (digits.length >= 3 && c.phone.contains(digits)))
        .toList();
  }

  /// Si se suelta a medio camino, termina de subir o vuelve a su lugar.
  void _snapTitle() {
    if (!_scroll.hasClients) return;
    final o = _scroll.offset;
    if (o > 0 && o < _titleExtent) {
      final target = o < _titleExtent / 2 ? 0.0 : _titleExtent;
      Future.microtask(() => _scroll.animateTo(
            target,
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOutCubic,
          ));
    }
  }

  void _openSend(AppContact contact) {
    FocusScope.of(context).unfocus();
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => SendAmountScreen(contact: contact)),
    );
  }

  void _soon(String what) {
    showAppMessage(context, '$what estará disponible pronto.', error: false);
  }

  @override
  Widget build(BuildContext context) {
    final contacts = _filtered;
    final newNumber =
        _searching ? PhoneUtils.extractMobile(_query) : null;
    final collapse = (_offset / _titleExtent).clamp(0.0, 1.0);

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark,
      child: Scaffold(
        backgroundColor: ContactsColors.background,
        // Pie blanco fijo: la lista pasa por detrás y no llega al borde.
        bottomNavigationBar: Container(
          color: Colors.white,
          height: MediaQuery.paddingOf(context).bottom + 12,
        ),
        body: Column(
          children: [
            _buildTopBar(collapse),
            Expanded(
              child: GestureDetector(
                onTap: () => FocusScope.of(context).unfocus(),
                behavior: HitTestBehavior.translucent,
                child: NotificationListener<ScrollEndNotification>(
                  onNotification: (_) {
                    _snapTitle();
                    return false;
                  },
                  child: CustomScrollView(
                    controller: _scroll,
                    keyboardDismissBehavior:
                        ScrollViewKeyboardDismissBehavior.onDrag,
                    slivers: [
                      SliverToBoxAdapter(child: _buildBigTitle(collapse)),
                      SliverPersistentHeader(
                        pinned: true,
                        delegate: _FixedHeader(
                          extent: _searchExtent,
                          child: _buildSearchBar(),
                        ),
                      ),
                      SliverToBoxAdapter(child: _buildNewNumber()),
                      if (!_searching) ...[
                        const SliverToBoxAdapter(child: SizedBox(height: 8)),
                        SliverToBoxAdapter(
                          child: SuggestedContacts(
                            contacts: _suggested,
                            onTap: _openSend,
                            onSaved: (list) =>
                                setState(() => _suggested = list),
                          ),
                        ),
                      ],
                      const SliverToBoxAdapter(child: SizedBox(height: 8)),
                      if (contacts.isEmpty && newNumber != null)
                        SliverFillRemaining(
                          hasScrollBody: false,
                          child: _buildNewNumberResult(newNumber),
                        )
                      else if (contacts.isEmpty)
                        SliverFillRemaining(
                          hasScrollBody: false,
                          child: _buildNoResults(),
                        )
                      else ...[
                        SliverToBoxAdapter(child: _buildContactsHeader()),
                        SliverList.builder(
                          itemCount: contacts.length,
                          itemBuilder: (_, i) => Material(
                            color: Colors.white,
                            child: ContactTile(
                              contact: contacts[i],
                              onTap: () => _openSend(contacts[i]),
                            ),
                          ),
                        ),
                        const SliverToBoxAdapter(
                          child: ColoredBox(
                            color: Colors.white,
                            child: SizedBox(height: 8, width: double.infinity),
                          ),
                        ),
                        const SliverToBoxAdapter(child: SizedBox(height: 110)),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Barra fija: botón de regreso + "Lista" pequeño (aparece al bajar).
  Widget _buildTopBar(double collapse) {
    // El título pequeño aparece en la segunda mitad del recorrido.
    final t = ((collapse - 0.5) / 0.5).clamp(0.0, 1.0);

    return Container(
      color: Colors.white,
      child: SafeArea(
        bottom: false,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
              child: Row(
                children: [
                  CircleIconButton(
                    icon: Icons.arrow_back_rounded,
                    heroTag: navBackHeroTag,
                    onTap: () => Navigator.of(context).maybePop(),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Opacity(
                      opacity: t,
                      child: Transform.translate(
                        offset: Offset(0, (1 - t) * 14),
                        child: Text(
                          _searching ? 'Enviar' : 'Lista',
                          maxLines: 1,
                          style: appFont(
                            fontSize: 28,
                            fontWeight: FontWeight.w400,
                            color: Colors.black,
                            height: 1.0,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // Línea fina que aparece cuando el título ya subió.
            Container(
              height: 1,
              color: ContactsColors.divider.withValues(alpha: collapse),
            ),
          ],
        ),
      ),
    );
  }

  /// Título grande: sube y se desvanece al bajar.
  Widget _buildBigTitle(double collapse) {
    return Container(
      color: Colors.white,
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 6),
      child: Opacity(
        opacity: 1 - collapse,
        child: Transform.translate(
          offset: Offset(0, -collapse * 10),
          child: Text(
            _searching ? 'Enviar' : 'Lista',
            style: _searching
                ? appFont(
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFF7B0E9B),
                  )
                : appFont(
                    fontSize: 30,
                    fontWeight: FontWeight.w900,
                    color: Colors.black,
                    letterSpacing: -0.5,
                  ),
          ),
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      child: Container(
        height: 40,
        padding: const EdgeInsets.only(left: 14, right: 6),
        decoration: BoxDecoration(
          color: ContactsColors.soft,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          children: [
            const Icon(
              Icons.search_rounded,
              color: ContactsColors.textDark,
              size: 21,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: TextField(
                controller: _searchCtrl,
                onChanged: (v) => setState(() => _query = v),
                textInputAction: TextInputAction.search,
                style: appFont(fontSize: 14.5, color: ContactsColors.textDark),
                decoration: InputDecoration(
                  isCollapsed: true,
                  border: InputBorder.none,
                  hintText: 'Busca el celular o contacto',
                  hintStyle:
                      appFont(fontSize: 14.5, color: ContactsColors.hint),
                ),
              ),
            ),
            if (_query.isNotEmpty)
              GestureDetector(
                onTap: () {
                  _searchCtrl.clear();
                  setState(() => _query = '');
                },
                child: Container(
                  width: 28,
                  height: 28,
                  decoration: const BoxDecoration(
                    color: Color(0xFFE4E2EC),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.close_rounded,
                    color: ContactsColors.textDark,
                    size: 17,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  /// "Nuevo número" (se oculta mientras buscas) y cierre redondeado de la parte blanca.
  Widget _buildNewNumber() {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(36)),
      ),
      padding: const EdgeInsets.fromLTRB(16, 2, 16, 8),
      child: _searching
          ? const SizedBox(height: 4)
          : InkWell(
              onTap: () => _soon('Nuevo número'),
              borderRadius: BorderRadius.circular(16),
              child: SizedBox(
                height: 56,
                child: Row(
                  children: [
                    const SizedBox(width: 12),
                    const Icon(
                      Icons.smartphone_outlined,
                      color: ContactsColors.phoneIcon,
                      size: 24,
                    ),
                    const SizedBox(width: 22),
                    Expanded(
                      child: Text(
                        'Nuevo número',
                        style: appFont(
                          fontSize: 15.5,
                          fontWeight: FontWeight.w500,
                          color: ContactsColors.textDark,
                        ),
                      ),
                    ),
                    const Icon(
                      Icons.chevron_right_rounded,
                      color: ContactsColors.hint,
                      size: 26,
                    ),
                    const SizedBox(width: 4),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildContactsHeader() {
    // Al buscar, la tarjeta empieza directo con los resultados (sin título).
    if (_searching) {
      return Container(
        height: 6,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(36)),
        ),
      );
    }
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 22, 16, 14),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(36)),
      ),
      child: Text(
        _searching ? 'Resultados' : 'Todos tus contactos',
        style: appFont(
          fontSize: 16.5,
          fontWeight: FontWeight.w700,
          color: ContactsColors.textDark,
        ),
      ),
    );
  }

  /// "A nuevo celular": el número escrito no está en tus contactos.
  Widget _buildNewNumberResult(String phone) {
    final contact = AppContact.number(phone);
    return Container(
      width: double.infinity,
      alignment: Alignment.topLeft,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(36)),
      ),
      padding: const EdgeInsets.fromLTRB(16, 6, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InkWell(
            onTap: () => _openSend(contact),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 13),
              decoration: const BoxDecoration(
                border: Border(
                  bottom: BorderSide(color: ContactsColors.divider),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'A nuevo celular',
                          style: appFont(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                            color: ContactsColors.textDark,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          contact.formattedPhone,
                          style: appFont(
                            fontSize: 15.5,
                            color: ContactsColors.textGrey,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const _SendBadge(),
                ],
              ),
            ),
          ),
          const SizedBox(height: 14),
          Text(
            'No necesitas guardarlo en tus contactos.',
            style: appFont(fontSize: 14.5, color: ContactsColors.hint),
          ),
        ],
      ),
    );
  }

  /// Tarjeta blanca "Sin resultados" que llega hasta abajo.
  Widget _buildNoResults() {
    return Container(
      width: double.infinity,
      alignment: Alignment.topCenter,
      padding: const EdgeInsets.only(top: 18),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(36)),
      ),
      child: Text(
        'Sin resultados',
        style: appFont(
          fontSize: 16.5,
          fontWeight: FontWeight.w500,
          color: ContactsColors.textDark,
        ),
      ),
    );
  }
}

/// Iconito morado "S/" de la fila "A nuevo celular".
class _SendBadge extends StatelessWidget {
  const _SendBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 30,
      height: 30,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: ContactsColors.phoneIcon, width: 2),
      ),
      child: Text(
        'S/',
        style: appFont(
          fontSize: 11,
          fontWeight: FontWeight.w800,
          color: ContactsColors.phoneIcon,
        ),
      ),
    );
  }
}

/// Encabezado fijo (el buscador se queda pegado arriba al bajar).
class _FixedHeader extends SliverPersistentHeaderDelegate {
  final double extent;
  final Widget child;

  _FixedHeader({required this.extent, required this.child});

  @override
  double get minExtent => extent;

  @override
  double get maxExtent => extent;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlaps) =>
      SizedBox.expand(child: child);

  @override
  bool shouldRebuild(_FixedHeader oldDelegate) => true;
}
