import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AdminDiagnosticsPage extends StatefulWidget {
  const AdminDiagnosticsPage({super.key});

  @override
  State<AdminDiagnosticsPage> createState() => _AdminDiagnosticsPageState();
}

class _AdminDiagnosticsPageState extends State<AdminDiagnosticsPage> {
  String _authInfo = '…';
  String _claimsInfo = '…';
  String _cgNoOrder = '…';
  String _cgWithOrder = '…';
  String _categoriesRead = '…';

  @override
  void initState() {
    super.initState();
    _runDiagnostics();
  }

  Future<void> _runDiagnostics() async {
    if (!mounted) return;
    setState(() {
      _authInfo = 'probando…';
      _claimsInfo = 'probando…';
      _cgNoOrder = 'probando…';
      _cgWithOrder = 'probando…';
      _categoriesRead = 'probando…';
    });

    // 1) Auth + claims
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      if (!mounted) return;
      setState(() {
        _authInfo = 'NO LOGUEADO';
        _claimsInfo = '-';
      });
    } else {
      try {
        final result = await user.getIdTokenResult(true);
        final claims = result.claims ?? {};
        if (!mounted) return;
        setState(() {
          _authInfo = 'UID: ${user.uid}\nEmail: ${user.email ?? '-'}';
          _claimsInfo = 'Claims: ${claims.isEmpty ? '{}' : claims.toString()}';
        });
      } catch (e) {
        if (!mounted) return;
        setState(() {
          _authInfo = 'ERROR auth: $e';
          _claimsInfo = '-';
        });
      }
    }

    // 2) collectionGroup('comments') (categorías) sin y con orderBy
    try {
      final aSnap = await FirebaseFirestore.instance
          .collectionGroup('comments')
          .where('status', isEqualTo: 'PENDIENTE')
          .limit(3)
          .get();

      final bSnap = await FirebaseFirestore.instance
          .collectionGroup('comments')
          .where('status', isEqualTo: 'PENDIENTE')
          .orderBy('createdAt', descending: true)
          .limit(3)
          .get();

      final a = aSnap.docs.map((d) => d.reference.path).join('\n');
      final b = bSnap.docs.map((d) => d.reference.path).join('\n');

      if (!mounted) return;
      setState(() {
        _cgNoOrder = 'OK — ${aSnap.size} docs\n$a';
        _cgWithOrder = 'OK — ${bSnap.size} docs\n$b';
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _cgNoOrder = 'ERROR CG sin orderBy: $e';
        _cgWithOrder = 'ERROR CG con orderBy: $e';
      });
    }

    // 3) Lectura de categorías (pública)
    try {
      final s = await FirebaseFirestore.instance.collection('categories').limit(1).get();
      if (!mounted) return;
      setState(() {
        _categoriesRead = 'OK — docs: ${s.size}';
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _categoriesRead = 'ERROR categories: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final items = <_Row>[
      _Row('Auth', _authInfo),
      _Row('Claims', _claimsInfo),
      _Row('CG pending (sin orderBy)', _cgNoOrder),
      _Row('CG pending (con orderBy)', _cgWithOrder),
      _Row('Categories read', _categoriesRead),
    ];
    return Scaffold(
      appBar: AppBar(
        title: const Text('Diagnóstico Admin'),
        actions: [
          IconButton(onPressed: _runDiagnostics, icon: const Icon(Icons.refresh)),
        ],
      ),
      body: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: items.length,
        separatorBuilder: (_, __) => const Divider(),
        itemBuilder: (_, i) {
          final r = items[i];
          return ListTile(
            title: Text(r.title, style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text(r.value),
          );
        },
      ),
    );
  }
}

class _Row {
  final String title;
  final String value;
  _Row(this.title, this.value);
}
