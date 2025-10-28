import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/functions_service.dart';
import '../services/auth_service.dart';

class MakeMeAdminButton extends StatefulWidget {
  const MakeMeAdminButton({super.key});

  @override
  State<MakeMeAdminButton> createState() => _MakeMeAdminButtonState();
}

class _MakeMeAdminButtonState extends State<MakeMeAdminButton> {
  final _funcs = FunctionsService();
  final _auth = AuthService();
  bool _loading = false;
  String? _msg;

  Future<void> _makeMeAdmin() async {
    if (!mounted) return;
    setState(() {
      _loading = true;
      _msg = null;
    });

    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _msg = 'No hay usuario logueado';
      });
      return;
    }

    try {
      await _funcs.grantAdmin(uid);
      await FirebaseAuth.instance.currentUser?.getIdToken(true);
      final role = await _auth.refreshAndGetRole();
      if (!mounted) return;
      setState(() => _msg = 'Hecho ✅. Rol actual: $role');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Rol ADMIN concedido')),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _msg = 'Error: $e');
    } finally {
      if (!mounted) return;
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        ElevatedButton.icon(
          onPressed: _loading ? null : _makeMeAdmin,
          icon: _loading
              ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
              : const Icon(Icons.verified_user),
          label: Text(_loading ? 'Concediendo...' : 'Concederme rol ADMIN'),
        ),
        if (_msg != null)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(_msg!, textAlign: TextAlign.center),
          ),
      ],
    );
  }
}
