class AppContact {
  final String name;
  final String phone; // solo dígitos, ej. "987654321"

  const AppContact(this.name, this.phone);

  /// Contacto sin nombre (número nuevo): se muestra el número como nombre.
  factory AppContact.number(String phone) {
    final c = AppContact('', phone);
    return AppContact(c.formattedPhone, phone);
  }

  bool get _nameIsNumber => RegExp(r'^[\d ]+$').hasMatch(name.trim());

  /// "Rosa Fabián" → "RF"
  String get initials {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty || parts.first.isEmpty) return '?';
    final first = parts.first[0];
    final second = parts.length > 1 ? parts[1][0] : '';
    return (first + second).toUpperCase();
  }

  /// "Rosa Maria Luz Fabian QUISPE" → "Rosa Fab*"
  /// "Rosa Luz Fabian Quispe" → "Rosa Fab*"
  /// "Rosa Fabian Quispe" → "Rosa Fab*"
  String get maskedName {
    if (_nameIsNumber) return maskedPhone;
    final parts = name
        .trim()
        .split(RegExp(r'\s+'))
        .where((p) => p.isNotEmpty)
        .toList();
    if (parts.isEmpty) return maskedPhone;
    if (parts.length == 1) return _capitalizar(parts.first);

    final firstName = _capitalizar(parts.first);
    final firstSurnameRaw =
        parts.length >= 3 ? parts[parts.length - 2] : parts[1];
    final firstSurname = _capitalizar(firstSurnameRaw);
    final cut = firstSurname.length > 3
        ? firstSurname.substring(0, 3)
        : firstSurname;

    return '$firstName $cut*';
  }

  String _capitalizar(String text) {
    if (text.isEmpty) return text;
    return text[0].toUpperCase() + text.substring(1).toLowerCase();
  }

  /// "987654321" → "*** *** 321"
  String get maskedPhone {
    final end = phone.length >= 3 ? phone.substring(phone.length - 3) : phone;
    return '*** *** $end';
  }

  /// "987654321" → "987 654 321"
  String get formattedPhone {
    if (phone.length != 9) return phone;
    return '${phone.substring(0, 3)} ${phone.substring(3, 6)} ${phone.substring(6)}';
  }
}