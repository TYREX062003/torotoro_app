import 'dart:collection';

/// Servicio de traducción/localización CORREGIDO
/// - Prioriza campos bilingües: name_es/name_en, body_es/body_en, desc_es/desc_en, tags_es/tags_en
/// - Fallback: name/body/desc/tags (genéricos)
/// - Diccionario para categorías/POIs (normalizado sin tildes)
class ContentTranslationService {
  static final ContentTranslationService _instance = ContentTranslationService._internal();
  factory ContentTranslationService() => _instance;
  ContentTranslationService._internal();

  // ===== Normalización simple de tildes =====
  static const Map<String, String> _accentMap = {
    'á': 'a', 'à': 'a', 'ä': 'a', 'â': 'a',
    'Á': 'a', 'À': 'a', 'Ä': 'a', 'Â': 'a',
    'é': 'e', 'è': 'e', 'ë': 'e', 'ê': 'e',
    'É': 'e', 'È': 'e', 'Ë': 'e', 'Ê': 'e',
    'í': 'i', 'ì': 'i', 'ï': 'i', 'î': 'i',
    'Í': 'i', 'Ì': 'i', 'Ï': 'i', 'Î': 'i',
    'ó': 'o', 'ò': 'o', 'ö': 'o', 'ô': 'o',
    'Ó': 'o', 'Ò': 'o', 'Ö': 'o', 'Ô': 'o',
    'ú': 'u', 'ù': 'u', 'ü': 'u', 'û': 'u',
    'Ú': 'u', 'Ù': 'u', 'Ü': 'u', 'Û': 'u',
    'ñ': 'n', 'Ñ': 'n',
  };

  String _normalizeKey(String s) {
    final buf = StringBuffer();
    for (final ch in s.trim().toLowerCase().runes) {
      final c = String.fromCharCode(ch);
      buf.write(_accentMap[c] ?? c);
    }
    return buf.toString();
  }

  // ===== Diccionarios (normalizados) =====
  final Map<String, Map<String, String>> _categoryDict = {
    'arquitectura': {'es': 'Arquitectura', 'en': 'Architecture'},
    'departamento de potosi': {'es': 'Departamento de Potosí', 'en': 'Department of Potosí'},
    'fauna': {'es': 'Fauna', 'en': 'Wildlife'},
    'flora': {'es': 'Flora', 'en': 'Flora'},
    'fosiles': {'es': 'Fósiles', 'en': 'Fossils'},
    'geografia': {'es': 'Geografía', 'en': 'Geography'},
    'geologia': {'es': 'Geología', 'en': 'Geology'},
    'historia': {'es': 'Historia', 'en': 'History'},
    'introduccion': {'es': 'Introducción', 'en': 'Introduction'},
  };

  final Map<String, Map<String, String>> _poiDict = {
    'canon de torotoro': {'es': 'Cañón de Torotoro', 'en': 'Torotoro Canyon'},
    'carreras pampa': {'es': 'Carreras Pampa', 'en': 'Carreras Pampa'},
    'el vergel': {'es': 'El Vergel', 'en': 'El Vergel'},
    'caverna de umajalanta': {'es': 'Caverna de Umajalanta', 'en': 'Umajalanta Cave'},
    'cementerio de tortugas': {'es': 'Cementerio de Tortugas', 'en': 'Turtle Cemetery'},
    'turu rumi': {'es': 'Turu Rumi', 'en': 'Turu Rumi'},
  };

  // ===== Helpers =====

  String? _stringOrNull(dynamic v) {
    if (v == null) return null;
    final str = v.toString().trim();
    return str.isEmpty ? null : str;
  }

  List<String> _listOfStrings(dynamic v) {
    if (v == null) return const <String>[];
    if (v is List) {
      return v
          .map((e) => e?.toString().trim() ?? '')
          .where((e) => e.isNotEmpty)
          .toList();
    }
    if (v is String && v.trim().isNotEmpty) {
      return v.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList();
    }
    return const <String>[];
  }

  List<String> _cleanTags(List<String> tags) {
    final seen = HashSet<String>(
      equals: (a, b) => a.toLowerCase() == b.toLowerCase(),
      hashCode: (a) => a.toLowerCase().hashCode,
    );
    final out = <String>[];
    for (final t in tags) {
      if (seen.add(t)) out.add(t);
    }
    return out;
  }

  /// ✅ MÉTODO PRINCIPAL: Obtiene texto localizado desde Firestore
  /// Prioridad: baseKey_langCode > baseKey > diccionario > original
  String pickLocalizedText(
    Map<String, dynamic> doc,
    String baseKey,
    String langCode,
  ) {
    // 1. Intentar campo bilingüe específico (name_es, name_en, etc.)
    final localizedKey = '${baseKey}_$langCode';
    final localized = _stringOrNull(doc[localizedKey]);
    if (localized != null) return localized;

    // 2. Intentar campo genérico (name, body, desc)
    final generic = _stringOrNull(doc[baseKey]);
    if (generic != null) {
      // Si es nombre de categoría o POI, intentar traducir desde diccionario
      if (baseKey == 'name') {
        final fromDict = _translateFromDict(generic, langCode);
        if (fromDict != null) return fromDict;
      }
      return generic;
    }

    return '';
  }

  /// ✅ Intenta traducir desde los diccionarios internos
  String? _translateFromDict(String text, String langCode) {
    final normalized = _normalizeKey(text);
    
    // Intentar diccionario de categorías
    final catTranslation = _categoryDict[normalized];
    if (catTranslation != null) {
      return catTranslation[langCode] ?? text;
    }

    // Intentar diccionario de POIs
    final poiTranslation = _poiDict[normalized];
    if (poiTranslation != null) {
      return poiTranslation[langCode] ?? text;
    }

    return null;
  }

  /// ✅ Obtiene lista localizada desde Firestore
  List<String> pickLocalizedList(
    Map<String, dynamic> doc,
    String baseKey,
    String langCode,
  ) {
    // 1. Intentar campo bilingüe (tags_es, tags_en)
    final localizedKey = '${baseKey}_$langCode';
    final localized = _listOfStrings(doc[localizedKey]);
    if (localized.isNotEmpty) return _cleanTags(localized);

    // 2. Intentar campo genérico (tags)
    final generic = _listOfStrings(doc[baseKey]);
    if (generic.isNotEmpty) return _cleanTags(generic);

    return const <String>[];
  }

  // ===== API CATEGORÍAS =====

  /// ✅ Obtiene nombre de categoría traducido
  String categoryNameFromDoc(Map<String, dynamic> doc, String langCode) {
    return pickLocalizedText(doc, 'name', langCode);
  }

  /// ✅ Obtiene body de categoría traducido
  String categoryBodyFromDoc(Map<String, dynamic> doc, String langCode) {
    final body = pickLocalizedText(doc, 'body', langCode);
    if (body.isNotEmpty) return body;
    
    // Fallback según idioma
    return langCode == 'es' 
        ? 'Contenido próximamente.' 
        : 'Content coming soon.';
  }

  /// ✅ Obtiene tags de categoría traducidos
  List<String> categoryTagsFromDoc(Map<String, dynamic> doc, String langCode) {
    return pickLocalizedList(doc, 'tags', langCode);
  }

  /// Traducción manual de nombre de categoría (para uso directo)
  String translateCategoryName(String originalName, String langCode) {
    final fromDict = _translateFromDict(originalName, langCode);
    return fromDict ?? originalName;
  }

  // ===== API POIs =====

  /// ✅ Obtiene nombre de POI traducido
  String poiNameFromDoc(Map<String, dynamic> doc, String langCode) {
    return pickLocalizedText(doc, 'name', langCode);
  }

  /// ✅ Obtiene descripción de POI traducida
  String poiDescFromDoc(Map<String, dynamic> doc, String langCode) {
    // Intentar desc primero, luego description como fallback
    final desc = pickLocalizedText(doc, 'desc', langCode);
    if (desc.isNotEmpty) return desc;

    final description = pickLocalizedText(doc, 'description', langCode);
    if (description.isNotEmpty) return description;

    // Fallback según idioma
    return langCode == 'es'
        ? 'Sin descripción disponible.'
        : 'No description available.';
  }

  /// ✅ Obtiene tags de POI traducidos
  List<String> poiTagsFromDoc(Map<String, dynamic> doc, String langCode) {
    return pickLocalizedList(doc, 'tags', langCode);
  }

  /// Traducción manual de nombre de POI (para uso directo)
  String translatePoiName(String originalName, String langCode) {
    final fromDict = _translateFromDict(originalName, langCode);
    return fromDict ?? originalName;
  }

  // ===== Frases comunes (para textos ya extraídos) =====
  String translateCommonPhrases(String text, String langCode) {
    if (langCode == 'es') return text;

    final replacements = <Pattern, String>{
      RegExp(r'\bPunto de interés\b', caseSensitive: false): 'Point of interest',
      RegExp(r'\bSin descripción disponible\.?\b', caseSensitive: false): 'No description available',
      RegExp(r'\bFormación rocosa\b', caseSensitive: false): 'Rock formation',
      RegExp(r'\bParque Nacional\b', caseSensitive: false): 'National Park',
      RegExp(r'\bCaverna\b', caseSensitive: false): 'Cave',
      RegExp(r'\bCañón\b', caseSensitive: false): 'Canyon',
      RegExp(r'\bCanon\b', caseSensitive: false): 'Canyon',
      RegExp(r'\bContenido próximamente\.?\b', caseSensitive: false): 'Content coming soon',
    };

    var out = text;
    replacements.forEach((pat, repl) {
      out = out.replaceAll(pat, repl);
    });
    return out;
  }

  /// Helper para textos inline
  String localizeInline({
    required String es,
    required String en,
    required String langCode,
  }) {
    return langCode == 'es' ? es : en;
  }
}