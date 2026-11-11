import 'package:flutter/material.dart';

import '../../../core/app_text.dart';
import '../../../models/app_contact.dart';
import 'contacts_colors.dart';

/// Fila de un contacto: nombre y número, con línea separadora debajo.
class ContactTile extends StatelessWidget {
  final AppContact contact;
  final VoidCallback onTap;

  const ContactTile({super.key, required this.contact, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 13),
          decoration: const BoxDecoration(
            border: Border(
              bottom: BorderSide(color: ContactsColors.divider),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                contact.name,
                style: appFont(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: ContactsColors.textDark,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                contact.formattedPhone,
                style: appFont(fontSize: 15.5, color: ContactsColors.textGrey),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
