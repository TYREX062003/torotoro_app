import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class UserProfileService {
  static final _db = FirebaseFirestore.instance;

  /// Crea/actualiza el documento del usuario en `users/{uid}`
  static Future<void> upsertCurrentUser() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final ref = _db.collection('users').doc(user.uid);
    final now = FieldValue.serverTimestamp();

    await ref.set({
      'uid': user.uid,
      'email': user.email,
      'displayName': user.displayName,
      'photoURL': user.photoURL,
      'providerIds': user.providerData.map((p) => p.providerId).toList(),
      'updatedAt': now,
      'createdAt': now, // si ya existe, merge no pisa el valor previo
    }, SetOptions(merge: true));
  }
}
