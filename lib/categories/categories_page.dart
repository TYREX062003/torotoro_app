import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'category_detail_page.dart';
import '../utils/net.dart';
import '../services/content_translation_service.dart';
import '../services/locale_service.dart';

class CategoriesPage extends StatefulWidget {
  const CategoriesPage({super.key});

  @override
  State<CategoriesPage> createState() => _CategoriesPageState();
}

class _CategoriesPageState extends State<CategoriesPage> {
  final _translationService = ContentTranslationService();
  final _localeService = LocaleService();

  @override
  void initState() {
    super.initState();
    _localeService.addListener(_onLocaleChanged);
  }

  @override
  void dispose() {
    _localeService.removeListener(_onLocaleChanged);
    super.dispose();
  }

  void _onLocaleChanged() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final col = FirebaseFirestore.instance
        .collection('categories')
        .orderBy('order', descending: false);
    final currentLang = _localeService.simpleLanguageCode;

    return Scaffold(
      backgroundColor: const Color(0xFFF2E8D5),
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 16),
            const Text(
              'Toro Toro',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.w800,
                color: Color(0xFF5B4636),
              ),
            ),
            const SizedBox(height: 4),
            // ✅ CAMBIO: "Potosí" → "Categorías" (traducido)
            Text(
              currentLang == 'es' ? 'Categorías' : 'Categories',
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Color(0xFF6B7C3F),
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: col.snapshots(),
                builder: (context, snap) {
                  if (snap.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  final docs = snap.data?.docs ?? [];
                  if (docs.isEmpty) {
                    return Center(
                      child: Text(
                        currentLang == 'es' 
                            ? 'No hay categorías disponibles.' 
                            : 'No categories available.',
                        style: const TextStyle(fontSize: 16),
                      ),
                    );
                  }

                  return Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 900),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 12,
                        ),
                        child: GridView.builder(
                          itemCount: docs.length,
                          gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                            maxCrossAxisExtent: 220,
                            mainAxisSpacing: 20,
                            crossAxisSpacing: 20,
                            childAspectRatio: 1,
                          ),
                          itemBuilder: (context, i) {
                            final doc = docs[i];
                            final data = (doc.data() as Map<String, dynamic>?) ?? {};
                            
                            // ✅ TRADUCCIÓN CORRECTA: Usar servicio con documento completo
                            final translatedName = _translationService
                                .categoryNameFromDoc(data, currentLang);
                            
                            final coverUrl = (data['coverUrl'] ?? '').toString().trim();

                            // Fallback al ID si no hay nombre
                            final displayName = translatedName.isEmpty 
                                ? doc.id 
                                : translatedName;

                            return GestureDetector(
                              onTap: () {
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (_) => CategoryDetailPage(
                                      catId: doc.id,
                                      catName: displayName,
                                    ),
                                  ),
                                );
                              },
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(28),
                                child: Stack(
                                  fit: StackFit.expand,
                                  children: [
                                    networkImageSafe(
                                      coverUrl.isEmpty ? null : coverUrl,
                                      fit: BoxFit.cover,
                                      fallback: Container(
                                        color: Colors.grey[300],
                                        alignment: Alignment.center,
                                        child: const Icon(
                                          Icons.image_outlined,
                                          size: 48,
                                        ),
                                      ),
                                    ),
                                    Container(
                                      color: Colors.black.withOpacity(0.28),
                                    ),
                                    Center(
                                      child: Padding(
                                        padding: const EdgeInsets.all(8.0),
                                        child: Text(
                                          displayName,
                                          textAlign: TextAlign.center,
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 16,
                                            fontWeight: FontWeight.w800,
                                            shadows: [
                                              Shadow(
                                                offset: Offset(1, 1),
                                                blurRadius: 2,
                                                color: Colors.black54,
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}