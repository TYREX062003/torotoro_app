import 'package:firebase_auth/firebase_auth.dart';

class RoleGuard {
  /// Devuelve true si el usuario tiene rol admin en sus custom claims.
  /// Refresca el ID token para asegurar que las claims estén actualizadas.
  static Future<bool> isAdmin() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return false;
    final token = await user.getIdTokenResult(true); // refresca claims
    return token.claims?['role'] == 'admin';
  }
}
