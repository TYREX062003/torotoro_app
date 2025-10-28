import 'package:cloud_firestore/cloud_firestore.dart';

class ReportsService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  /// Obtiene el total de usuarios activos
  Future<int> getActiveUsersCount() async {
    try {
      final snapshot = await _db.collection('users').get();
      return snapshot.size;
    } catch (e) {
      print('Error obteniendo usuarios: $e');
      return 0;
    }
  }

  /// Obtiene el total de calificaciones (comentarios)
  Future<int> getTotalRatingsCount() async {
    try {
      // Usar collection group para contar todos los comentarios
      final snapshot = await _db.collectionGroup('comments').get();
      return snapshot.size;
    } catch (e) {
      print('Error obteniendo calificaciones: $e');
      return 0;
    }
  }

  /// Obtiene el POI más visto (basado en cantidad de comentarios)
  Future<Map<String, dynamic>> getMostViewedPlace() async {
    try {
      final pois = await _db.collection('pois').get();
      
      String mostViewedId = '';
      String mostViewedName = 'N/A';
      int maxComments = 0;

      for (var poiDoc in pois.docs) {
        final commentsCount = await _db
            .collection('pois')
            .doc(poiDoc.id)
            .collection('comments')
            .get()
            .then((snap) => snap.size);

        if (commentsCount > maxComments) {
          maxComments = commentsCount;
          mostViewedId = poiDoc.id;
          mostViewedName = poiDoc.data()['name']?.toString() ?? poiDoc.id;
        }
      }

      return {
        'id': mostViewedId,
        'name': mostViewedName,
        'count': maxComments,
      };
    } catch (e) {
      print('Error obteniendo lugar más visto: $e');
      return {'id': '', 'name': 'N/A', 'count': 0};
    }
  }

  /// Obtiene el crecimiento de usuarios por mes
  Future<List<Map<String, dynamic>>> getUserGrowth() async {
    try {
      final users = await _db.collection('users').get();
      
      // Agrupar por mes
      final Map<String, int> monthCounts = {};
      
      for (var user in users.docs) {
        final data = user.data();
        final createdAt = data['createdAt'] as Timestamp?;
        
        if (createdAt != null) {
          final date = createdAt.toDate();
          final monthKey = '${date.year}-${date.month.toString().padLeft(2, '0')}';
          monthCounts[monthKey] = (monthCounts[monthKey] ?? 0) + 1;
        }
      }

      // Convertir a lista ordenada
      final sortedMonths = monthCounts.keys.toList()..sort();
      
      return sortedMonths.map((month) {
        return {
          'month': month,
          'count': monthCounts[month] ?? 0,
        };
      }).toList();
    } catch (e) {
      print('Error obteniendo crecimiento: $e');
      return [];
    }
  }

  /// Obtiene distribución por categorías
  Future<Map<String, int>> getCategoryDistribution() async {
    try {
      final categories = await _db.collection('categories').get();
      final Map<String, int> distribution = {};

      for (var category in categories.docs) {
        final name = category.data()['name']?.toString() ?? category.id;
        final commentsCount = await _db
            .collection('categories')
            .doc(category.id)
            .collection('comments')
            .get()
            .then((snap) => snap.size);

        distribution[name] = commentsCount;
      }

      return distribution;
    } catch (e) {
      print('Error obteniendo distribución: $e');
      return {};
    }
  }

  /// Obtiene los lugares con más calificaciones
  Future<List<Map<String, dynamic>>> getTopRatedPlaces({int limit = 5}) async {
    try {
      final pois = await _db.collection('pois').get();
      final List<Map<String, dynamic>> places = [];

      for (var poi in pois.docs) {
        final data = poi.data();
        final name = data['name']?.toString() ?? poi.id;
        final commentsCount = await _db
            .collection('pois')
            .doc(poi.id)
            .collection('comments')
            .get()
            .then((snap) => snap.size);

        places.add({
          'id': poi.id,
          'name': name,
          'count': commentsCount,
        });
      }

      // Ordenar por cantidad de comentarios
      places.sort((a, b) => (b['count'] as int).compareTo(a['count'] as int));

      return places.take(limit).toList();
    } catch (e) {
      print('Error obteniendo lugares top: $e');
      return [];
    }
  }

  /// Obtiene estadísticas filtradas por fecha
  Future<Map<String, dynamic>> getFilteredStats({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      Query<Map<String, dynamic>> usersQuery = _db.collection('users');
      
      if (startDate != null) {
        usersQuery = usersQuery.where('createdAt', 
            isGreaterThanOrEqualTo: Timestamp.fromDate(startDate));
      }
      
      if (endDate != null) {
        usersQuery = usersQuery.where('createdAt', 
            isLessThanOrEqualTo: Timestamp.fromDate(endDate));
      }

      final users = await usersQuery.get();

      return {
        'users': users.size,
        'startDate': startDate,
        'endDate': endDate,
      };
    } catch (e) {
      print('Error obteniendo estadísticas filtradas: $e');
      return {'users': 0};
    }
  }
}