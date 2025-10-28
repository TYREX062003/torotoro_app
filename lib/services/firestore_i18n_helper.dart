/// Helper para obtener textos traducidos desde Firestore
class FirestoreI18nHelper {
  /// Obtiene el nombre traducido según el idioma actual
  static String getName(Map<String, dynamic> data, String languageCode) {
    final key = 'name_$languageCode';
    final translated = data[key]?.toString();
    
    if (translated != null && translated.isNotEmpty) {
      return translated;
    }
    
    // Fallback al campo legacy 'name'
    return data['name']?.toString() ?? '';
  }

  /// Obtiene la descripción traducida según el idioma actual
  static String getDescription(Map<String, dynamic> data, String languageCode) {
    final key = 'desc_$languageCode';
    final translated = data[key]?.toString();
    
    if (translated != null && translated.isNotEmpty) {
      return translated;
    }
    
    // Fallback a campos legacy
    return data['desc']?.toString() ?? 
           data['description']?.toString() ?? 
           '';
  }

  /// Obtiene el cuerpo/contenido traducido según el idioma actual
  static String getBody(Map<String, dynamic> data, String languageCode) {
    final key = 'body_$languageCode';
    final translated = data[key]?.toString();
    
    if (translated != null && translated.isNotEmpty) {
      return translated;
    }
    
    // Fallback al campo legacy 'body'
    return data['body']?.toString() ?? '';
  }

  /// Obtiene la categoría traducida según el idioma actual
  static String getCategory(Map<String, dynamic> data, String languageCode) {
    final key = 'category_$languageCode';
    final translated = data[key]?.toString();
    
    if (translated != null && translated.isNotEmpty) {
      return translated;
    }
    
    // Fallback al campo legacy 'category'
    return data['category']?.toString() ?? '';
  }

  /// Obtiene cualquier campo traducido genérico
  static String getField(
    Map<String, dynamic> data, 
    String fieldName, 
    String languageCode,
  ) {
    final key = '${fieldName}_$languageCode';
    final translated = data[key]?.toString();
    
    if (translated != null && translated.isNotEmpty) {
      return translated;
    }
    
    // Fallback al campo sin sufijo
    return data[fieldName]?.toString() ?? '';
  }
}