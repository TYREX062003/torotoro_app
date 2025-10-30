import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

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
  final _db = FirebaseFirestore.instance;

  User? get currentUser => _auth.currentUser;

  Stream<User?> authStateChanges() => _auth.authStateChanges();

  /// Fuerza refresh del token y devuelve el rol leído del custom claim "role".
  /// Si no hay custom claim, intenta leer de Firestore como fallback.
  Future<AppRole> refreshAndGetRole() async {
    final user = _auth.currentUser;
    if (user == null) return AppRole.none;

    try {
      // 🔥 CRÍTICO: Asegurar que el documento del usuario exista
      await _ensureUserDocumentExists(user);

      // Intentar obtener el rol desde custom claims
      final token = await user.getIdTokenResult(true);
      final claimRole = token.claims?['role'] as String?;
      
      if (claimRole != null) {
        return roleFromString(claimRole);
      }

      // 🔥 FALLBACK: Si no hay custom claim, leer de Firestore
      final userDoc = await _db.collection('users').doc(user.uid).get();
      
      if (userDoc.exists) {
        final firestoreRole = userDoc.data()?['role'] as String?;
        return roleFromString(firestoreRole);
      }

      // Si no existe el documento, es un usuario nuevo → tourist por defecto
      return AppRole.tourist;
    } catch (e) {
      print('⚠️ Error en refreshAndGetRole: $e');
      // En caso de error, asumir tourist para no bloquear la app
      return AppRole.tourist;
    }
  }

  /// 🔥 NUEVO: Asegura que el documento del usuario exista en Firestore
  Future<void> _ensureUserDocumentExists(User user) async {
    try {
      final userRef = _db.collection('users').doc(user.uid);
      final doc = await userRef.get();

      if (!doc.exists) {
        print('📝 Creando documento de usuario para ${user.email}');
        
        await userRef.set({
          'uid': user.uid,
          'email': user.email,
          'displayName': user.displayName ?? '',
          'photoURL': user.photoURL ?? '',
          'role': 'tourist', // Rol por defecto
          'providerIds': user.providerData.map((p) => p.providerId).toList(),
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        });
        
        print('✅ Documento de usuario creado exitosamente');
      }
    } catch (e) {
      print('❌ Error al crear documento de usuario: $e');
      // No lanzar error para no bloquear el login
    }
  }

  Future<void> signOut() => _auth.signOut();
}