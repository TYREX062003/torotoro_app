class Poi {
  final String id;
  final String name;
  final String description;
  final double lat;
  final double lng;
  final String category;

  /// Campos añadidos para compatibilidad con la UI
  final String imageUrl;
  final double ratingAvg;
  final int ratingCount;

  Poi({
    required this.id,
    required this.name,
    required this.description,
    required this.lat,
    required this.lng,
    required this.category,
    required this.imageUrl,
    required this.ratingAvg,
    required this.ratingCount,
  });

  factory Poi.fromMap(String id, Map<String, dynamic> data) {
    double _toDouble(dynamic v) => v is num ? v.toDouble() : double.tryParse('${v ?? ''}') ?? 0;
    int _toInt(dynamic v) => v is int ? v : int.tryParse('${v ?? ''}') ?? 0;

    return Poi(
      id: id,
      name: (data['name'] ?? '').toString(),
      description: (data['description'] ?? data['desc'] ?? '').toString(),
      lat: _toDouble(data['lat']),
      lng: _toDouble(data['lng']),
      category: (data['category'] ?? 'general').toString(),
      imageUrl: (data['imageUrl'] ?? data['coverUrl'] ?? '').toString(),
      ratingAvg: _toDouble(data['ratingAvg']),
      ratingCount: _toInt(data['ratingCount']),
    );
  }

  Map<String, dynamic> toMap() => {
        'name': name,
        'description': description,
        'lat': lat,
        'lng': lng,
        'category': category,
        'imageUrl': imageUrl,
        'ratingAvg': ratingAvg,
        'ratingCount': ratingCount,
      };
}
