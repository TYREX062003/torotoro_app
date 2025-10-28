import 'package:cloud_firestore/cloud_firestore.dart';

class Comment {
  final String id;
  /// 'pois' | 'categories'
  final String parentType;
  final String parentId;

  final String userId;
  final String userName;
  final String userPhotoUrl;
  final String text;
  final double rating;
  /// 'PENDIENTE' | 'APROBADO' | 'RECHAZADO'
  final String status;
  final Timestamp createdAt;
  final Timestamp? updatedAt;

  Comment({
    required this.id,
    required this.parentType,
    required this.parentId,
    required this.userId,
    required this.userName,
    required this.userPhotoUrl,
    required this.text,
    required this.rating,
    required this.status,
    required this.createdAt,
    this.updatedAt,
  });

  static String _normStatus(dynamic v) {
    final raw = (v ?? 'PENDIENTE').toString().toUpperCase();
    switch (raw) {
      case 'APROBADO':
      case 'RECHAZADO':
      case 'PENDIENTE':
        return raw;
      // compat con minúsculas antiguas
      case 'APPROVED':
      case 'APPROVE':
      case 'APPROVADO':
      case 'APPROVEDD':
      case 'APPROV':
        return 'APROBADO';
      case 'REJECTED':
      case 'REJECT':
        return 'RECHAZADO';
      case 'PENDING':
      default:
        return 'PENDIENTE';
    }
  }

  static double _toDouble(dynamic v) {
    if (v == null) return 0;
    if (v is num) return v.toDouble();
    if (v is String) return double.tryParse(v) ?? 0;
    return 0;
  }

  /// Construye desde cualquier subcolección '.../{parent}/comments/{id}'
  factory Comment.fromSnapshot(DocumentSnapshot snap) {
    final data = (snap.data() ?? const {}) as Map<String, dynamic>;
    final seg = snap.reference.path.split('/');
    final parentType = seg.isNotEmpty ? seg.first : '';
    final parentId = seg.length >= 2 ? seg[1] : '';

    return Comment(
      id: snap.id,
      parentType: parentType,
      parentId: parentId,
      userId: (data['userId'] ?? '').toString(),
      userName: (data['userName'] ?? '').toString(),
      userPhotoUrl: (data['userPhotoUrl'] ?? '').toString(),
      text: (data['text'] ?? '').toString(),
      rating: _toDouble(data['rating']),
      status: _normStatus(data['status']),
      createdAt: data['createdAt'] is Timestamp 
          ? data['createdAt'] as Timestamp 
          : Timestamp.now(),
      updatedAt: data['updatedAt'] is Timestamp 
          ? data['updatedAt'] as Timestamp 
          : null,
    );
  }

  /// Útil cuando ya conoces el padre
  factory Comment.fromMap({
    required String id,
    required String parentType,
    required String parentId,
    required Map<String, dynamic> data,
  }) {
    return Comment(
      id: id,
      parentType: parentType,
      parentId: parentId,
      userId: (data['userId'] ?? '').toString(),
      userName: (data['userName'] ?? '').toString(),
      userPhotoUrl: (data['userPhotoUrl'] ?? '').toString(),
      text: (data['text'] ?? '').toString(),
      rating: _toDouble(data['rating']),
      status: _normStatus(data['status']),
      createdAt: data['createdAt'] is Timestamp 
          ? data['createdAt'] as Timestamp 
          : Timestamp.now(),
      updatedAt: data['updatedAt'] is Timestamp 
          ? data['updatedAt'] as Timestamp 
          : null,
    );
  }

  Map<String, dynamic> toMap() => {
        'userId': userId,
        'userName': userName,
        'userPhotoUrl': userPhotoUrl,
        'text': text,
        'rating': rating,
        'status': status,
        'createdAt': createdAt,
        if (updatedAt != null) 'updatedAt': updatedAt,
      };
}