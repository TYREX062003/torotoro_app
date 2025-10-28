import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/comments_model.dart';

class CommentsRepository {
  // Singleton para mantener streams vivos
  static final CommentsRepository _instance = CommentsRepository._internal();
  factory CommentsRepository() => _instance;
  CommentsRepository._internal();

  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // StreamControllers broadcast
  StreamController<List<Comment>>? _pendingController;
  StreamController<List<Comment>>? _approvedController;
  StreamController<List<Comment>>? _rejectedController;
  StreamController<List<Comment>>? _allController;

  // Cache del último valor emitido
  List<Comment>? _lastPendingValue;
  List<Comment>? _lastApprovedValue;
  List<Comment>? _lastRejectedValue;
  List<Comment>? _lastAllValue;

  // Subscripciones
  StreamSubscription? _pendingSub;
  StreamSubscription? _approvedSub;
  StreamSubscription? _rejectedSub;
  StreamSubscription? _allSub;

  // ---------- STREAMS PÚBLICOS ----------
  
  Stream<List<Comment>> streamPendingCategories() {
    _pendingController ??= StreamController<List<Comment>>.broadcast(
      onListen: () {
        if (_lastPendingValue != null) {
          _pendingController?.add(_lastPendingValue!);
        }
      },
    );
    
    _pendingSub ??= _queryByStatus('PENDIENTE').listen(
      (data) {
        _lastPendingValue = data;
        _pendingController?.add(data);
      },
      onError: (e) => _pendingController?.addError(e),
    );
    
    return _pendingController!.stream;
  }

  Stream<List<Comment>> streamApprovedCategories() {
    _approvedController ??= StreamController<List<Comment>>.broadcast(
      onListen: () {
        if (_lastApprovedValue != null) {
          _approvedController?.add(_lastApprovedValue!);
        }
      },
    );
    
    _approvedSub ??= _queryByStatus('APROBADO').listen(
      (data) {
        _lastApprovedValue = data;
        _approvedController?.add(data);
      },
      onError: (e) => _approvedController?.addError(e),
    );
    
    return _approvedController!.stream;
  }

  Stream<List<Comment>> streamRejectedCategories() {
    _rejectedController ??= StreamController<List<Comment>>.broadcast(
      onListen: () {
        if (_lastRejectedValue != null) {
          _rejectedController?.add(_lastRejectedValue!);
        }
      },
    );
    
    _rejectedSub ??= _queryByStatus('RECHAZADO').listen(
      (data) {
        _lastRejectedValue = data;
        _rejectedController?.add(data);
      },
      onError: (e) => _rejectedController?.addError(e),
    );
    
    return _rejectedController!.stream;
  }

  Stream<List<Comment>> streamAllCategories() {
    _allController ??= StreamController<List<Comment>>.broadcast(
      onListen: () {
        if (_lastAllValue != null) {
          _allController?.add(_lastAllValue!);
        }
      },
    );
    
    _allSub ??= _db
        .collectionGroup('comments')
        .where('parentType', isEqualTo: 'categories')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(_toCommentsSafe)
        .listen(
          (data) {
            _lastAllValue = data;
            _allController?.add(data);
          },
          onError: (e) => _allController?.addError(e),
        );
    
    return _allController!.stream;
  }

  // ---------- ACCIONES ----------
  
  Future<void> approveComment({
    required String categoryId,
    required String commentId
  }) async {
    await _db.collection('categories').doc(categoryId)
        .collection('comments').doc(commentId).update({
      'status': 'APROBADO',
      'moderatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> rejectComment({
    required String categoryId,
    required String commentId
  }) async {
    await _db.collection('categories').doc(categoryId)
        .collection('comments').doc(commentId).update({
      'status': 'RECHAZADO',
      'moderatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> deleteCategoryComment({
    required String categoryId,
    required String commentId
  }) async {
    await _db.collection('categories').doc(categoryId)
        .collection('comments').doc(commentId).delete();
  }

  Future<void> updateComment({
    required String categoryId,
    required String commentId,
    required Map<String, dynamic> data,
  }) async {
    await _db.collection('categories').doc(categoryId)
        .collection('comments').doc(commentId).update({
      ...data,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  // ---------- CLEANUP ----------
  
  void dispose() {
    _pendingSub?.cancel();
    _approvedSub?.cancel();
    _rejectedSub?.cancel();
    _allSub?.cancel();

    _pendingController?.close();
    _approvedController?.close();
    _rejectedController?.close();
    _allController?.close();
    
    _lastPendingValue = null;
    _lastApprovedValue = null;
    _lastRejectedValue = null;
    _lastAllValue = null;
  }

  // ---------- PRIVADOS ----------
  
  Stream<List<Comment>> _queryByStatus(String status) {
    return _db
        .collectionGroup('comments')
        .where('parentType', isEqualTo: 'categories')
        .where('status', isEqualTo: status)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(_toCommentsSafe);
  }

  DateTime _asDateTime(dynamic v) {
    if (v == null) return DateTime.fromMillisecondsSinceEpoch(0);
    if (v is DateTime) return v;
    if (v is Timestamp) return v.toDate();
    return DateTime.fromMillisecondsSinceEpoch(0);
  }

  List<Comment> _toCommentsSafe(QuerySnapshot<Map<String, dynamic>> snap) {
    final items = <Comment>[];
    
    for (final doc in snap.docs) {
      try {
        final c = Comment.fromSnapshot(doc);
        if (c.parentType != 'categories') continue;
        _asDateTime(c.createdAt);
        items.add(c);
      } catch (e) {
        // Silenciosamente salta comentarios con errores
      }
    }
    
    items.sort((a, b) {
      final da = _asDateTime(a.createdAt);
      final db = _asDateTime(b.createdAt);
      return db.compareTo(da);
    });
    
    return items;
  }
}