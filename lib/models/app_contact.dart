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

  /// "Rosa Fabián" → "Rosa Fab*"
  String get maskedName {
    if (_nameIsNumber) return maskedPhone;
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.length < 2) return parts.first;
    final last = parts[1];
    final cut = last.length > 3 ? last.substring(0, 3) : last;
    return '${parts.first} $cut*';
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
