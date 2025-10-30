import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class UserProfileService {
  static final _db = FirebaseFirestore.instance;

  /// Crea/actualiza el documento del usuario en `users/{uid}`
  static Future<void> upsertCurrentUser() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      print('⚠️ No hay usuario autenticado');
      return;
    }

    try {
      final ref = _db.collection('users').doc(user.uid);
      final now = FieldValue.serverTimestamp();

      // 🔥 MEJORADO: Verificar si el documento ya existe
      final doc = await ref.get();
      
      if (doc.exists) {
        // Si existe, solo actualizar campos básicos
        await ref.update({
          'email': user.email,
          'displayName': user.displayName ?? '',
          'photoURL': user.photoURL ?? '',
          'providerIds': user.providerData.map((p) => p.providerId).toList(),
          'updatedAt': now,
        });
        print('✅ Usuario actualizado: ${user.email}');
      } else {
        // Si no existe, crear con rol por defecto
        await ref.set({
          'uid': user.uid,
          'email': user.email,
          'displayName': user.displayName ?? '',
          'photoURL': user.photoURL ?? '',
          'role': 'tourist', // 🔥 Rol por defecto para nuevos usuarios
          'providerIds': user.providerData.map((p) => p.providerId).toList(),
          'createdAt': now,
          'updatedAt': now,
        });
        print('✅ Usuario creado: ${user.email}');
      }
    } catch (e) {
      print('❌ Error en upsertCurrentUser: $e');
      // No lanzar error para no bloquear el flujo de login
    }
  }

  /// 🔥 NUEVO: Verifica si el usuario tiene un documento en Firestore
  static Future<bool> userDocumentExists(String uid) async {
    try {
      final doc = await _db.collection('users').doc(uid).get();
      return doc.exists;
    } catch (e) {
      print('❌ Error verificando documento: $e');
      return false;
    }
  }
}