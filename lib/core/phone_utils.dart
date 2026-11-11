/// Ayudas para números de celular de Perú.
class PhoneUtils {
  PhoneUtils._();

  /// Deja solo los números: "+51 982-493 975" → "51982493975"
  static String digitsOnly(String input) =>
      input.replaceAll(RegExp(r'\D'), '');

  /// Quita el código de país si está: "51982493975" → "982493975"
  static String stripCountryCode(String digits) {
    if (digits.length == 13 && digits.startsWith('0051')) {
      return digits.substring(4);
    }
    if (digits.length == 11 && digits.startsWith('51')) {
      return digits.substring(2);
    }
    return digits;
  }

  /// Si el texto contiene un celular peruano (9 dígitos que empiezan con 9),
  /// lo devuelve limpio. Ignora letras, espacios, símbolos y el +51.
  ///   "985708969"         → "985708969"
  ///   "+51 982 493 975"   → "982493975"
  ///   "A985708299sssck&"  → "985708299"
  ///   "985708akjj988"     → "985708988"
  static String? extractMobile(String input) {
    final d = stripCountryCode(digitsOnly(input));
    if (d.length == 9 && d.startsWith('9')) return d;
    return null;
  }
}
