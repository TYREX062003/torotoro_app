import 'package:cloud_firestore/cloud_firestore.dart';
import '/models/category_model.dart';

class CategoryRepository {
  final _col = FirebaseFirestore.instance.collection('categories');

  Future<void> updateCategory(String id, Map<String, dynamic> data) async {
    await _col.doc(id).set(
      {
        ...data,
        'updatedAt': FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );
  }

  Future<void> createCategory(String id, Category c) async {
    await _col.doc(id).set({
      ...c.toMap(),
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Stream<List<Category>> watchAll() {
    return _col.orderBy('order').snapshots().map(
          (s) => s.docs.map((d) => Category.fromMap(d.id, d.data())).toList(),
        );
  }
}
