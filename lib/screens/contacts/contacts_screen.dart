import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/app_text.dart';
import '../../data/sample_contacts.dart';
import '../../models/app_contact.dart';
import '../../widgets/app_message.dart';
import 'widgets/contact_tile.dart';
import 'widgets/contacts_colors.dart';
import 'widgets/suggested_contacts.dart';

/// Pantalla "Lista": buscador, nuevo número, sugeridos y todos los contactos.
class ContactsScreen extends StatefulWidget {
  const ContactsScreen({super.key});

  @override
  State<ContactsScreen> createState() => _ContactsScreenState();
}

class _ContactsScreenState extends State<ContactsScreen> {
  final _searchCtrl = TextEditingController();
  String _query = '';
  List<AppContact> _suggested =
      sampleSuggested.take(SuggestedContacts.maxItems).toList();

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  List<AppContact> get _filtered {
    final q = _query.trim().toLowerCase();
    if (q.isEmpty) return sampleContacts;
    final digits = q.replaceAll(' ', '');
    return sampleContacts
        .where((c) =>
            c.name.toLowerCase().contains(q) || c.phone.contains(digits))
        .toList();
  }

  void _soon(String what) {
    showAppMessage(context, '$what estará disponible pronto.', error: false);
  }

  @override
  Widget build(BuildContext context) {
    final contacts = _filtered;
    final searching = _query.trim().isNotEmpty;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark,
      child: Scaffold(
        backgroundColor: ContactsColors.background,
        // Pie blanco fijo: la lista pasa por detrás y no llega al borde de la pantalla.
        bottomNavigationBar: Container(
          color: Colors.white,
          height: MediaQuery.paddingOf(context).bottom + 12,
        ),
        body: GestureDetector(
          onTap: () => FocusScope.of(context).unfocus(),
          behavior: HitTestBehavior.translucent,
          child: CustomScrollView(
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            slivers: [
              SliverToBoxAdapter(child: _buildTop()),
              if (!searching) ...[
                const SliverToBoxAdapter(child: SizedBox(height: 8)),
                SliverToBoxAdapter(
                  child: SuggestedContacts(
                    contacts: _suggested,
                    onTap: (c) => _soon('Enviar a ${c.maskedName}'),
                    onSaved: (list) => setState(() => _suggested = list),
                  ),
                ),
              ],
              const SliverToBoxAdapter(child: SizedBox(height: 8)),
              SliverToBoxAdapter(child: _buildContactsHeader(searching)),
              SliverList.builder(
                itemCount: contacts.length,
                itemBuilder: (_, i) => Material(
                  color: Colors.white,
                  child: ContactTile(
                    contact: contacts[i],
                    onTap: () => _soon('Enviar a ${contacts[i].name}'),
                  ),
                ),
              ),
              if (contacts.isEmpty)
                SliverToBoxAdapter(
                  child: Container(
                    color: Colors.white,
                    padding: const EdgeInsets.all(24),
                    child: Text(
                      'No se encontraron contactos.',
                      style: appFont(
                        fontSize: 16,
                        color: ContactsColors.textGrey,
                      ),
                    ),
                  ),
                ),
              // Cierre blanco de la lista y espacio lila al final.
              const SliverToBoxAdapter(
                child: ColoredBox(
                  color: Colors.white,
                  child: SizedBox(height: 8, width: double.infinity),
                ),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 110)),
            ],
          ),
        ),
      ),
    );
  }

  /// Parte blanca de arriba: volver, título, buscador y "Nuevo número".
  Widget _buildTop() {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(36)),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              GestureDetector(
                onTap: () => Navigator.of(context).maybePop(),
                child: Container(
                  width: 34,
                  height: 34,
                  decoration: const BoxDecoration(
                    color: ContactsColors.soft,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.arrow_back_rounded,
                    color: Colors.black,
                    size: 20,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Lista',
                style: appFont(
                  fontSize: 30,
                  fontWeight: FontWeight.w900,
                  color: Colors.black,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 18),
              Container(
                height: 40,
                padding: const EdgeInsets.symmetric(horizontal: 14),
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
                        style: appFont(
                          fontSize: 14.5,
                          color: ContactsColors.textDark,
                        ),
                        decoration: InputDecoration(
                          isCollapsed: true,
                          border: InputBorder.none,
                          hintText: 'Busca el celular o contacto',
                          hintStyle: appFont(
                            fontSize: 14.5,
                            color: ContactsColors.hint,
                          ),
                        ),
                      ),
                    ),
                    if (_query.isNotEmpty)
                      GestureDetector(
                        onTap: () {
                          _searchCtrl.clear();
                          setState(() => _query = '');
                        },
                        child: const Icon(
                          Icons.close_rounded,
                          color: ContactsColors.hint,
                          size: 22,
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 10),
              InkWell(
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
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildContactsHeader(bool searching) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 22, 16, 14),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(36)),
      ),
      child: Text(
        searching ? 'Resultados' : 'Todos tus contactos',
        style: appFont(
          fontSize: 16.5,
          fontWeight: FontWeight.w700,
          color: ContactsColors.textDark,
        ),
      ),
    );
  }
}
