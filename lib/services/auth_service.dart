import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// Todo lo de Firebase Auth va aquí.
/// El usuario solo escribe su "usuario"; internamente se usa usuario@ypayone.com.
class AuthService {
  AuthService._();
  static final AuthService instance = AuthService._();

  static const String domain = 'ypayone.com';
  static final RegExp _validUser = RegExp(r'^[a-z0-9._-]{3,20}$');

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  User? get currentUser => _auth.currentUser;

  String normalize(String username) => username.trim().toLowerCase();

  String _emailFor(String username) => '${normalize(username)}@$domain';

  bool isValidUsername(String username) =>
      _validUser.hasMatch(normalize(username));

  /// "roger@ypayone.com" → "ROGER"
  String usernameOf(User user) =>
      (user.email ?? '').split('@').first.toUpperCase();

  Future<void> signIn(String username, String password) async {
    await _auth.signInWithEmailAndPassword(
      email: _emailFor(username),
      password: password,
    );
  }

  Future<void> register({
    required String vendorCode,
    required String username,
    required String password,
  }) async {
    final cred = await _auth.createUserWithEmailAndPassword(
      email: _emailFor(username),
      password: password,
    );
    await _db.collection('users').doc(cred.user!.uid).set({
      'username': username.trim().toUpperCase(),
      'vendorCode': vendorCode.trim(),
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  /// Cambia la contraseña verificando primero la actual.
  /// Al terminar cierra sesión para que entre con la nueva.
  Future<void> changePassword({
    required String username,
    required String currentPassword,
    required String newPassword,
  }) async {
    final cred = await _auth.signInWithEmailAndPassword(
      email: _emailFor(username),
      password: currentPassword,
    );
    await cred.user!.updatePassword(newPassword);
    await _auth.signOut();
  }

  Future<void> signOut() => _auth.signOut();

  /// Convierte errores de Firebase en mensajes entendibles.
  static String messageFor(Object error) {
    if (error is FirebaseAuthException) {
      switch (error.code) {
        case 'invalid-credential':
        case 'wrong-password':
        case 'user-not-found':
        case 'invalid-email':
          return 'Usuario o contraseña incorrectos.';
        case 'email-already-in-use':
          return 'Ese nombre de usuario ya está en uso.';
        case 'weak-password':
          return 'La contraseña debe tener al menos 6 dígitos.';
        case 'user-disabled':
          return 'Esta cuenta está deshabilitada.';
        case 'too-many-requests':
          return 'Demasiados intentos. Espera unos minutos.';
        case 'network-request-failed':
          return 'Sin conexión a internet.';
        default:
          return 'Ocurrió un error (${error.code}).';
      }
    }
    if (error is FirebaseException) {
      return 'No se pudieron guardar los datos (${error.code}).';
    }
    return 'Ocurrió un error inesperado.';
  }
}
