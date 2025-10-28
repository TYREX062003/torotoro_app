class Category {
  final String key;      // ID del documento
  final String name;
  final String desc;
  final String body;     // Contenido largo (que usas en category_detail_page)
  final int order;
  final String coverUrl;
  final String coverPath; // Ruta en Storage

  Category({
    required this.key,
    required this.name,
    required this.desc,
    required this.body,
    required this.order,
    required this.coverUrl,
    required this.coverPath,
  });

  factory Category.fromMap(String id, Map<String, dynamic> m) {
    int _toInt(dynamic v) => v is int ? v : int.tryParse(v?.toString() ?? '0') ?? 0;
    
    return Category(
      key: id,
      name: (m['name'] ?? '').toString(),
      desc: (m['desc'] ?? '').toString(),
      body: (m['body'] ?? '').toString(),
      order: _toInt(m['order']),
      coverUrl: (m['coverUrl'] ?? '').toString(),
      coverPath: (m['coverPath'] ?? '').toString(),
    );
  }

  Map<String, dynamic> toMap() => {
    'key': key,
    'name': name,
    'desc': desc,
    'body': body,
    'order': order,
    'coverUrl': coverUrl,
    'coverPath': coverPath,
  };

  // Método de conveniencia para crear una categoría vacía
  factory Category.empty(String key) {
    return Category(
      key: key,
      name: '',
      desc: '',
      body: '',
      order: 0,
      coverUrl: '',
      coverPath: '',
    );
  }

  // Método para copiar con cambios
  Category copyWith({
    String? key,
    String? name,
    String? desc,
    String? body,
    int? order,
    String? coverUrl,
    String? coverPath,
  }) {
    return Category(
      key: key ?? this.key,
      name: name ?? this.name,
      desc: desc ?? this.desc,
      body: body ?? this.body,
      order: order ?? this.order,
      coverUrl: coverUrl ?? this.coverUrl,
      coverPath: coverPath ?? this.coverPath,
    );
  }
}