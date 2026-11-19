import 'package:shared_preferences/shared_preferences.dart';

/// Guarda en el celular la opción "Recuérdame", el último usuario y,
/// si está activo "Recuérdame", su contraseña para precargarla al volver.
class SessionService {
  SessionService._();

  static const _kRemember = 'remember_me';
  static const _kLastUser = 'last_username';
  static const _kLastPass = 'last_password';

  static Future<void> saveLogin({
    required bool remember,
    required String username,
    String? password,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kRemember, remember);
    if (remember) {
      await prefs.setString(_kLastUser, username.trim().toUpperCase());
      if (password != null) {
        await prefs.setString(_kLastPass, password);
      }
    } else {
      await prefs.remove(_kLastUser);
      await prefs.remove(_kLastPass);
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

  static Future<String?> lastPassword() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_kLastPass);
  }
}