import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '/categories/category_detail_page.dart';
import '../services/content_translation_service.dart';
import '../services/locale_service.dart';

class FavoritesPage extends StatefulWidget {
  const FavoritesPage({super.key});

  @override
  State<FavoritesPage> createState() => _FavoritesPageState();
}

class _FavoritesPageState extends State<FavoritesPage> {
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

  Stream<List<String>> _watchFavoriteCategoryIds(String uid) {
    final col = FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('favorites')
        .doc('categories')
        .collection('items')
        .orderBy('createdAt', descending: true);
    
    return col.snapshots().map((s) => s.docs.map((d) => d.id).toList());
  }

  Stream<List<Map<String, dynamic>>> _watchCategoriesByIds(
    List<String> ids,
  ) async* {
    if (ids.isEmpty) {
      yield <Map<String, dynamic>>[];
      return;
    }

    // Dividir en chunks de 10 (límite de whereIn)
    final chunks = <List<String>>[];
    for (var i = 0; i < ids.length; i += 10) {
      chunks.add(
        ids.sublist(i, (i + 10 > ids.length) ? ids.length : i + 10),
      );
    }

    final futures = chunks.map((c) => FirebaseFirestore.instance
        .collection('categories')
        .where(FieldPath.documentId, whereIn: c)
        .get());

    final snaps = await Future.wait(futures);
    final all = snaps
        .expand((s) => s.docs.map((d) => {'id': d.id, ...d.data()}))
        .toList();

    // Mantener el orden original
    all.sort((a, b) => ids.indexOf(a['id']).compareTo(ids.indexOf(b['id'])));
    yield all;
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final currentLang = _localeService.simpleLanguageCode;

    if (user == null) {
      return Scaffold(
        backgroundColor: const Color(0xFFF2E8D5),
        // ✅ CAMBIO: Sin AppBar - el mensaje ya indica el contexto
        body: Center(
          child: Text(
            currentLang == 'es'
                ? 'Inicia sesión para ver tus favoritos'
                : 'Log in to see your favorites',
            style: const TextStyle(fontSize: 16),
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF2E8D5),
      // ✅ CAMBIO: Sin AppBar - el título "Favoritos" ya está en el body
      body: StreamBuilder<List<String>>(
        stream: _watchFavoriteCategoryIds(user.uid),
        builder: (context, idsSnap) {
          if (!idsSnap.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final ids = idsSnap.data!;
          if (ids.isEmpty) {
            return Center(
              child: Text(
                currentLang == 'es'
                    ? 'Aquí aparecerán tus lugares favoritos ⭐'
                    : 'Your favorite places will appear here ⭐',
                style: const TextStyle(fontSize: 18),
                textAlign: TextAlign.center,
              ),
            );
          }

          return StreamBuilder<List<Map<String, dynamic>>>(
            stream: _watchCategoriesByIds(ids),
            builder: (context, catSnap) {
              if (!catSnap.hasData) {
                return const Center(child: CircularProgressIndicator());
              }

              final cats = catSnap.data!;

              return ListView.separated(
                itemCount: cats.length,
                separatorBuilder: (_, __) => const Divider(height: 1),
                itemBuilder: (_, i) {
                  final m = cats[i];
                  final id = m['id'] as String;

                  // ✅ TRADUCCIÓN CORRECTA: Usar servicio de traducción
                  final translatedName = _translationService
                      .categoryNameFromDoc(m, currentLang);
                  
                  final displayName = translatedName.isEmpty 
                      ? id 
                      : translatedName;

                  final cover = (m['coverUrl'] ?? '').toString().trim();

                  return ListTile(
                    leading: SizedBox(
                      width: 56,
                      height: 56,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: cover.isNotEmpty
                            ? Image.network(
                                cover,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => const ColoredBox(
                                  color: Color(0xFFE0E0E0),
                                  child: Center(
                                    child: Icon(
                                      Icons.image_not_supported,
                                      size: 28,
                                    ),
                                  ),
                                ),
                              )
                            : const ColoredBox(
                                color: Color(0xFFE0E0E0),
                                child: Center(
                                  child: Icon(
                                    Icons.image_outlined,
                                    size: 28,
                                  ),
                                ),
                              ),
                      ),
                    ),
                    title: Text(displayName),
                    subtitle: Text(
                      currentLang == 'es' ? 'Categoría' : 'Category',
                    ),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => CategoryDetailPage(
                            catId: id,
                            catName: displayName,
                          ),
                        ),
                      );
                    },
                    onLongPress: () async {
                      await FirebaseFirestore.instance
                          .collection('users')
                          .doc(user.uid)
                          .collection('favorites')
                          .doc('categories')
                          .collection('items')
                          .doc(id)
                          .delete();

                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              currentLang == 'es'
                                  ? 'Quitado de favoritos: $displayName'
                                  : 'Removed from favorites: $displayName',
                            ),
                          ),
                        );
                      }
                    },
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}