import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/poi_model.dart';
import '../models/comments_model.dart';

class PoiRepository {
  PoiRepository();

  final FirebaseFirestore _db = FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _col => _db.collection('pois');
  CollectionReference<Map<String, dynamic>> _poiComments(String poiId) =>
      _col.doc(poiId).collection('comments');

  // ================== POIs ==================

  Future<void> updatePoi(String poiId, Map<String, dynamic> data) async {
    final payload = <String, dynamic>{
      ...data,
      'updatedAt': FieldValue.serverTimestamp(),
    };
    await _col.doc(poiId).set(payload, SetOptions(merge: true));
  }

  Future<void> updatePoiCoverUrl(String poiId, String url) async {
    await updatePoi(poiId, {
      'coverUrl': url,
      'imageUrl': url, // compat temporal
    });
  }

  Future<void> createPoi(String poiId, Poi poi) async {
    await _col.doc(poiId).set({
      ...poi.toMap(),
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> deletePoi(String poiId) async {
    await _col.doc(poiId).delete();
  }

  Future<bool> exists(String poiId) async {
    final d = await _col.doc(poiId).get();
    return d.exists;
  }

  Future<Poi?> getPoi(String poiId) async {
    final d = await _col.doc(poiId).get();
    if (!d.exists) return null;
    return Poi.fromMap(d.id, d.data()!);
  }

  Stream<List<Poi>> streamPois({String orderField = 'name', bool descending = false}) {
    return _col
        .orderBy(orderField, descending: descending)
        .snapshots()
        .map((s) => s.docs.map((d) => Poi.fromMap(d.id, d.data())).toList());
  }

  Future<List<Poi>> fetchPoisOnce({String orderField = 'name', bool descending = false}) async {
    final s = await _col.orderBy(orderField, descending: descending).get();
    return s.docs.map((d) => Poi.fromMap(d.id, d.data())).toList();
  }

  Stream<List<Poi>> searchByName(String query, {int limit = 20}) {
    if (query.isEmpty) return streamPois();
    final end = '$query\uf8ff';
    return _col
        .orderBy('name')
        .startAt([query])
        .endAt([end])
        .limit(limit)
        .snapshots()
        .map((s) => s.docs.map((d) => Poi.fromMap(d.id, d.data())).toList());
  }

  // ================== Comentarios (LEGADO, no usados) ==================
  Stream<List<Comment>> streamApprovedComments(String poiId) {
    return _poiComments(poiId)
        .where('status', isEqualTo: 'APROBADO')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((s) => s.docs.map((d) => Comment.fromSnapshot(d)).toList());
  }

  Future<Comment?> getUserComment({
    required String poiId,
    required String uid,
  }) async {
    final d = await _poiComments(poiId).doc(uid).get();
    if (!d.exists) return null;
    return Comment.fromSnapshot(d);
  }

  Future<void> upsertUserComment({
    required String poiId,
    required String uid,
    required String userName,
    required String userPhotoUrl,
    required String text,
    required double rating,
  }) async {
    final ref = _poiComments(poiId).doc(uid);
    await ref.set({
      'id': uid,
      'parentType': 'pois',
      'parentId': poiId,
      'userId': uid,
      'userName': userName,
      'userPhotoUrl': userPhotoUrl,
      'text': text,
      'rating': rating,
      'status': 'PENDIENTE',
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<void> deleteComment({
    required String poiId,
    required String commentId,
  }) async {
    await _poiComments(poiId).doc(commentId).delete();
  }
}
