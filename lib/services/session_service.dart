import 'package:shared_preferences/shared_preferences.dart';

/// Guarda en el celular la opción "Recuérdame" y el último usuario.
class SessionService {
  SessionService._();

  static const _kRemember = 'remember_me';
  static const _kLastUser = 'last_username';

  static Future<void> saveLogin({
    required bool remember,
    required String username,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kRemember, remember);
    if (remember) {
      await prefs.setString(_kLastUser, username);
    } else {
      await prefs.remove(_kLastUser);
    }
  }

  /// Si es false, al abrir la app se cierra la sesión y va al login.
  static Future<bool> shouldRemember() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_kRemember) ?? true;
  }

  static Future<String?> lastUsername() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_kLastUser);
  }
}
