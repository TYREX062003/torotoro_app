import 'package:firebase_auth/firebase_auth.dart';

enum AppRole { admin, guide, tourist, none }

AppRole roleFromString(String? v) {
  switch (v) {
    case 'admin':
      return AppRole.admin;
    case 'guide':
      return AppRole.guide;
    case 'tourist':
      return AppRole.tourist;
    default:
      return AppRole.none;
  }
}

class AuthService {
  final _auth = FirebaseAuth.instance;

  User? get currentUser => _auth.currentUser;

  Stream<User?> authStateChanges() => _auth.authStateChanges();

  /// Fuerza refresh del token y devuelve el rol leído del custom claim "role".
  Future<AppRole> refreshAndGetRole() async {
    final user = _auth.currentUser;
    if (user == null) return AppRole.none;
    final token = await user.getIdTokenResult(true);
    return roleFromString(token.claims?['role'] as String?);
  }

  Future<void> signOut() => _auth.signOut();
}
