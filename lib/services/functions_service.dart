import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/foundation.dart' show kDebugMode;

class FunctionsService {
  final FirebaseFunctions _functions =
      FirebaseFunctions.instanceFor(region: 'southamerica-east1');

  late final HttpsCallable _grantAdminFn;

  // ====== POIs (LEGADO: ya no usamos comentarios por POI en la app) ======
  late final HttpsCallable _approveCommentFn;
  late final HttpsCallable _rejectCommentFn;

  // ====== Categorías (vigente) ======
  late final HttpsCallable _approveCategoryCommentFn;
  late final HttpsCallable _rejectCategoryCommentFn;

  FunctionsService({bool useEmulator = false}) {
    if (kDebugMode && useEmulator) {
      try {
        _functions.useFunctionsEmulator('localhost', 5001);
      } catch (_) {}
    }
    final opts = HttpsCallableOptions(timeout: const Duration(seconds: 20));

    _grantAdminFn             = _functions.httpsCallable('grantAdmin', options: opts);

    // POI (legado)
    _approveCommentFn         = _functions.httpsCallable('approveComment', options: opts);
    _rejectCommentFn          = _functions.httpsCallable('rejectComment', options: opts);

    // Categorías (actual)
    _approveCategoryCommentFn = _functions.httpsCallable('approveCategoryComment', options: opts);
    _rejectCategoryCommentFn  = _functions.httpsCallable('rejectCategoryComment', options: opts);
  }

  Future<void> grantAdmin(String uid) async {
    try {
      await _grantAdminFn.call({'uid': uid});
    } on FirebaseFunctionsException catch (e) {
      throw Exception('[grantAdmin/${e.code}] ${e.message ?? e.details ?? 'error'}');
    }
  }

  // ====== POIs (LEGADO) ======
  Future<void> approveComment({required String poiId, required String commentId}) async {
    try {
      await _approveCommentFn.call({'poiId': poiId, 'commentId': commentId});
    } on FirebaseFunctionsException catch (e) {
      throw Exception('[approveComment/${e.code}] ${e.message ?? e.details ?? 'error'}');
    }
  }

  Future<void> rejectComment({required String poiId, required String commentId}) async {
    try {
      await _rejectCommentFn.call({'poiId': poiId, 'commentId': commentId});
    } on FirebaseFunctionsException catch (e) {
      throw Exception('[rejectComment/${e.code}] ${e.message ?? e.details ?? 'error'}');
    }
  }

  // ====== Categorías (VIGENTE) ======
  Future<void> approveCategoryComment({required String categoryId, required String commentId}) async {
    try {
      await _approveCategoryCommentFn.call({'categoryId': categoryId, 'commentId': commentId});
    } on FirebaseFunctionsException catch (e) {
      throw Exception('[approveCategoryComment/${e.code}] ${e.message ?? e.details ?? 'error'}');
    }
  }

  Future<void> rejectCategoryComment({required String categoryId, required String commentId}) async {
    try {
      await _rejectCategoryCommentFn.call({'categoryId': categoryId, 'commentId': commentId});
    } on FirebaseFunctionsException catch (e) {
      throw Exception('[rejectCategoryComment/${e.code}] ${e.message ?? e.details ?? 'error'}');
    }
  }
}
