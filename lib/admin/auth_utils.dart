import 'package:firebase_auth/firebase_auth.dart';

Future<void> refreshAdminClaims() async {
  final u = FirebaseAuth.instance.currentUser;
  if (u != null) {
    await u.getIdToken(true); // fuerza refresco de custom claims (role=admin)
  }
}
