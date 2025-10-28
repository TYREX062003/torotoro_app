// lib/admin/seed_categories.dart (versión segura)
import 'package:cloud_firestore/cloud_firestore.dart';

Future<void> seedCategoriesOnce() async {
  final col = FirebaseFirestore.instance.collection('categories');

  final items = <Map<String, dynamic>>[
    {'id':'historia','name':'Historia','order':1},
    {'id':'flora','name':'Flora','order':2},
    {'id':'fauna','name':'Fauna','order':3},
    {'id':'turismo','name':'Turismo','order':4},
    {'id':'fosiles','name':'Fósiles','order':5},
    {'id':'geografia','name':'Geografía','order':6},
    {'id':'arquitectura','name':'Arquitectura','order':7},
    {'id':'departamento-de-potosi','name':'Departamento de Potosí','order':8},
  ];

  for (final c in items) {
    final id = c['id'] as String;
    final ref = col.doc(id);
    final snap = await ref.get();

    if (!snap.exists) {
      // Solo crea si NO existe
      await ref.set({
        'name': c['name'],
        'order': c['order'],
        'desc': '',
        'body': '',
        'coverUrl': '',
        'coverPath': '',
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } else {
      // Si existe, solo rellena campos faltantes SIN pisar lo ya guardado
      final m = snap.data() as Map<String, dynamic>? ?? {};
      final patch = <String, dynamic>{};
      void putIfMissing(String k, dynamic v) {
        if (!m.containsKey(k)) patch[k] = v;
      }

      putIfMissing('name', c['name']);
      putIfMissing('order', c['order']);
      putIfMissing('desc', '');
      putIfMissing('body', '');
      putIfMissing('coverUrl', '');
      putIfMissing('coverPath', '');

      if (patch.isNotEmpty) {
        patch['updatedAt'] = FieldValue.serverTimestamp();
        await ref.set(patch, SetOptions(merge: true));
      }
    }
  }
}
