import 'package:flutter/material.dart';
import '../models/poi_model.dart';
import '../services/content_translation_service.dart';
import '../services/locale_service.dart';

class PoiPage extends StatelessWidget {
  final Poi poi;
  const PoiPage({super.key, required this.poi});

  @override
  Widget build(BuildContext context) {
    final lang = LocaleService().simpleLanguageCode;
    final tr = ContentTranslationService();

    final name = tr.translatePoiName(poi.name, lang);
    final desc = (poi.description).trim().isEmpty
        ? (lang == 'es' ? 'Sin descripción disponible.' : 'No description available.')
        : tr.translateCommonPhrases(poi.description, lang);
    final cat = tr.translateCategoryName(poi.category, lang);

    final labelCategory = lang == 'es' ? 'Categoría' : 'Category';
    final labelLocation = lang == 'es' ? 'Ubicación' : 'Location';
    final labelRatings  = lang == 'es' ? 'Valoraciones' : 'Ratings';
    final infoRatings   = lang == 'es'
        ? 'Las calificaciones y comentarios se realizan en la CATEGORÍA correspondiente.'
        : 'Ratings and comments are made in the corresponding CATEGORY.';

    return Scaffold(
      appBar: AppBar(title: Text(name)),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if ((poi.imageUrl).trim().isNotEmpty)
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: Image.network(
                  poi.imageUrl,
                  height: 200,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    height: 200,
                    width: double.infinity,
                    color: const Color(0xFFE0E0E0),
                    alignment: Alignment.center,
                    child: const Icon(Icons.image_not_supported),
                  ),
                ),
              ),
            const SizedBox(height: 16),

            Text(name, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text(desc, style: const TextStyle(fontSize: 16)),
            const SizedBox(height: 16),
            Text('$labelCategory: $cat'),
            Text('$labelLocation: (${poi.lat.toStringAsFixed(5)}, ${poi.lng.toStringAsFixed(5)})'),

            const SizedBox(height: 24),
            const Divider(),
            const SizedBox(height: 12),

            if (poi.ratingCount > 0)
              Text('$labelRatings: ${poi.ratingAvg.toStringAsFixed(1)} (${poi.ratingCount})'),
            if (poi.ratingCount == 0)
              Text(labelRatings, style: const TextStyle(fontWeight: FontWeight.w600)),

            const SizedBox(height: 8),
            Text(infoRatings, style: const TextStyle(fontStyle: FontStyle.italic)),
          ],
        ),
      ),
    );
  }
}
