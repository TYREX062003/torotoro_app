import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

// 🎨 Colores
const kBeige = Color(0xFFF2E8D5);
const kOlive = Color(0xFF6B7C3F);
const kBrown = Color(0xFF5B4636);

class WebLoginPage extends StatefulWidget {
  const WebLoginPage({super.key});

  @override
  State<WebLoginPage> createState() => _WebLoginPageState();
}

class _WebLoginPageState extends State<WebLoginPage> {
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  String _mapAuthError(FirebaseAuthException e) {
    switch (e.code) {
      case 'user-not-found':
        return 'Usuario no encontrado';
      case 'wrong-password':
        return 'Contraseña incorrecta';
      case 'invalid-credential':
        return 'Credenciales inválidas';
      case 'invalid-email':
        return 'Email no válido';
      case 'user-disabled':
        return 'Usuario deshabilitado';
      case 'too-many-requests':
        return 'Demasiados intentos. Intenta más tarde';
      default:
        return e.message ?? 'Error de autenticación (${e.code})';
    }
  }

  Future<void> _loginEmail() async {
    if (!mounted) return;
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: _emailCtrl.text.trim(),
        password: _passCtrl.text,
      );

      // Verificar si es admin
      if (!mounted) return;
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final token = await user.getIdTokenResult(true);
        final isAdmin = token.claims?['role'] == 'admin';

        if (!mounted) return;
        
        if (isAdmin) {
          // Es admin: ir al panel admin
          Navigator.of(context).pushReplacementNamed('/admin');
        } else {
          // No es admin: mostrar mensaje y volver a landing
          setState(() {
            _error = 'Esta cuenta no tiene permisos de administrador';
          });
          await FirebaseAuth.instance.signOut();
        }
      }
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      setState(() => _error = _mapAuthError(e));
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = 'Error inesperado: $e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _loginGoogle() async {
    if (!mounted) return;
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      if (kIsWeb) {
        final provider = GoogleAuthProvider()..addScope('email');
        await FirebaseAuth.instance.signInWithPopup(provider);
      } else {
        final googleSignIn = GoogleSignIn(scopes: const ['email']);
        final googleUser = await googleSignIn.signIn();
        if (googleUser == null) {
          if (mounted) setState(() => _loading = false);
          return;
        }
        final googleAuth = await googleUser.authentication;
        final cred = GoogleAuthProvider.credential(
          accessToken: googleAuth.accessToken,
          idToken: googleAuth.idToken,
        );
        await FirebaseAuth.instance.signInWithCredential(cred);
      }

      // Verificar si es admin
      if (!mounted) return;
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final token = await user.getIdTokenResult(true);
        final isAdmin = token.claims?['role'] == 'admin';

        if (!mounted) return;
        
        if (isAdmin) {
          Navigator.of(context).pushReplacementNamed('/admin');
        } else {
          setState(() {
            _error = 'Esta cuenta no tiene permisos de administrador';
          });
          await FirebaseAuth.instance.signOut();
        }
      }
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      setState(() => _error = _mapAuthError(e));
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = 'Error con Google: $e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBeige,
      body: Stack(
        children: [
          // Botón volver
          Positioned(
            top: 40,
            left: 40,
            child: IconButton(
              icon: const Icon(Icons.arrow_back, color: kBrown),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ),

          // Contenido centrado
          Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 450),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Logo
                      Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.1),
                              blurRadius: 20,
                              offset: const Offset(0, 10),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.admin_panel_settings,
                          size: 80,
                          color: kOlive,
                        ),
                      ),

                      const SizedBox(height: 32),

                      // Título
                      const Text(
                        'Panel de Administración',
                        style: TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          color: kBrown,
                        ),
                        textAlign: TextAlign.center,
                      ),

                      const SizedBox(height: 12),

                      Text(
                        'Solo para administradores',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.black.withValues(alpha: 0.6),
                        ),
                      ),

                      const SizedBox(height: 40),

                      // Formulario
                      Container(
                        padding: const EdgeInsets.all(32),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.08),
                              blurRadius: 20,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Column(
                          children: [
                            // Email
                            TextField(
                              controller: _emailCtrl,
                              keyboardType: TextInputType.emailAddress,
                              decoration: InputDecoration(
                                labelText: 'Email',
                                prefixIcon: const Icon(Icons.email_outlined),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                filled: true,
                                fillColor: const Color(0xFFF5F5F5),
                              ),
                            ),

                            const SizedBox(height: 20),

                            // Password
                            TextField(
                              controller: _passCtrl,
                              obscureText: true,
                              decoration: InputDecoration(
                                labelText: 'Contraseña',
                                prefixIcon: const Icon(Icons.lock_outlined),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                filled: true,
                                fillColor: const Color(0xFFF5F5F5),
                              ),
                              onSubmitted: (_) => _loginEmail(),
                            ),

                            const SizedBox(height: 24),

                            // Error message
                            if (_error != null)
                              Container(
                                padding: const EdgeInsets.all(12),
                                margin: const EdgeInsets.only(bottom: 20),
                                decoration: BoxDecoration(
                                  color: Colors.red.shade50,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: Colors.red.shade200),
                                ),
                                child: Row(
                                  children: [
                                    Icon(Icons.error_outline,
                                        color: Colors.red.shade700, size: 20),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        _error!,
                                        style: TextStyle(
                                          color: Colors.red.shade700,
                                          fontSize: 13,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                            // Botón login
                            SizedBox(
                              width: double.infinity,
                              height: 54,
                              child: FilledButton(
                                onPressed: _loading ? null : _loginEmail,
                                style: FilledButton.styleFrom(
                                  backgroundColor: kOlive,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                child: _loading
                                    ? const SizedBox(
                                        width: 24,
                                        height: 24,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: Colors.white,
                                        ),
                                      )
                                    : const Text(
                                        'Iniciar sesión',
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                              ),
                            ),

                            const SizedBox(height: 24),

                            // Divider
                            Row(
                              children: [
                                const Expanded(child: Divider()),
                                Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 16),
                                  child: Text(
                                    'o',
                                    style: TextStyle(
                                      color: Colors.black.withValues(alpha: 0.5),
                                    ),
                                  ),
                                ),
                                const Expanded(child: Divider()),
                              ],
                            ),

                            const SizedBox(height: 24),

                            // Google button
                            SizedBox(
                              width: double.infinity,
                              height: 54,
                              child: OutlinedButton.icon(
                                onPressed: _loading ? null : _loginGoogle,
                                style: OutlinedButton.styleFrom(
                                  side: BorderSide(color: kOlive.withValues(alpha: 0.5)),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                icon: const Icon(Icons.g_mobiledata, size: 28),
                                label: const Text(
                                  'Continuar con Google',
                                  style: TextStyle(fontSize: 16),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}