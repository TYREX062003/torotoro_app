import 'package:flutter/material.dart';

/// Limpia SOLO espacios y comillas al inicio/fin.
/// No re-encodea la URL para no romper tokens de Firebase.
String cleanUrl(String? raw) {
  if (raw == null) return '';
  var s = raw.trim();

  // Quita comillas simples/dobles/backticks al inicio/fin
  if (s.length >= 2) {
    final start = s[0];
    final end = s[s.length - 1];
    if ((start == '"' && end == '"') ||
        (start == "'" && end == "'") ||
        (start == '`' && end == '`')) {
      s = s.substring(1, s.length - 1).trim();
    }
  }

  // Colapsa espacios accidentales (no debería haber en URLs válidas)
  s = s.replaceAll(RegExp(r'\s+'), ' ');

  return s;
}

Widget networkImageSafe(
  String? url, {
  BoxFit fit = BoxFit.cover,
  Widget? fallback,
}) {
  final u = cleanUrl(url);
  if (u.isEmpty) {
    return fallback ??
        const ColoredBox(
          color: Color(0xFFE0E0E0),
          child: Center(child: Icon(Icons.image_outlined)),
        );
  }
  return Image.network(
    u,
    fit: fit,
    gaplessPlayback: true,
    errorBuilder: (_, __, ___) =>
        fallback ??
        const ColoredBox(
          color: Color(0xFFE0E0E0),
          child: Center(child: Icon(Icons.image_not_supported)),
        ),
  );
}
