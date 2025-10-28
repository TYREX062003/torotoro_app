import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import '../utils/net.dart';
import '../services/tts_service.dart';
import '../services/content_translation_service.dart';
import '../services/locale_service.dart';

class CategoryDetailPage extends StatefulWidget {
  final String catId;
  final String catName;

  const CategoryDetailPage({
    super.key,
    required this.catId,
    required this.catName,
  });

  @override
  State<CategoryDetailPage> createState() => _CategoryDetailPageState();
}

class _CategoryDetailPageState extends State<CategoryDetailPage> {
  final _commentCtrl = TextEditingController();
  final TtsService _ttsService = TtsService();
  final _translationService = ContentTranslationService();
  final _localeService = LocaleService();

  bool _saving = false;
  int _rating = 0;
  bool _fav = false;
  bool _isSpeaking = false;
  bool _loadedMyCommentOnce = false;

  DocumentReference<Map<String, dynamic>>? get _myCommentRef {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return null;
    return FirebaseFirestore.instance.doc(
      'categories/${widget.catId}/comments/$uid',
    );
  }

  @override
  void initState() {
    super.initState();
    _loadFavorite();
    _localeService.addListener(_onLocaleChanged);
  }

  @override
  void dispose() {
    _commentCtrl.dispose();
    _localeService.removeListener(_onLocaleChanged);
    _ttsService.dispose();
    super.dispose();
  }

  void _onLocaleChanged() {
    if (mounted) setState(() {});
  }

  Future<void> _loadFavorite() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    final favDoc = await FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('favorites')
        .doc('categories')
        .collection('items')
        .doc(widget.catId)
        .get();

    if (mounted) setState(() => _fav = favDoc.exists);
  }

  void _snack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg)),
    );
  }

  Future<void> _toggleFavorite() async {
    final currentLang = _localeService.simpleLanguageCode;
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      _snack(
        currentLang == 'es'
            ? 'Inicia sesión para usar favoritos'
            : 'Log in to use favorites',
      );
      return;
    }

    setState(() => _fav = !_fav);

    final ref = FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('favorites')
        .doc('categories')
        .collection('items')
        .doc(widget.catId);

    if (_fav) {
      await ref.set({'createdAt': FieldValue.serverTimestamp()});
      _snack(
        currentLang == 'es'
            ? 'Añadido a favoritos'
            : 'Added to favorites',
      );
    } else {
      await ref.delete();
      _snack(
        currentLang == 'es'
            ? 'Quitado de favoritos'
            : 'Removed from favorites',
      );
    }
  }

  Future<void> _toggleTts(String text) async {
    final currentLang = _localeService.simpleLanguageCode;
    final l10n = AppLocalizations.of(context)!;

    if (_isSpeaking) {
      await _ttsService.stop();
      if (mounted) setState(() => _isSpeaking = false);
      return;
    }

    final raw = text.trim();
    final noContentMsg = l10n.contentComingSoon;

    if (raw.isEmpty || raw == noContentMsg) {
      _snack(
        currentLang == 'es'
            ? 'No hay contenido para narrar'
            : 'No content to narrate',
      );
      return;
    }

    // Narrar el texto traducido correctamente
    await _ttsService.speak(raw);
    if (mounted) setState(() => _isSpeaking = true);

    // Desactivar ícono cuando termine
    Future.delayed(const Duration(milliseconds: 800), () {
      if (mounted && !_ttsService.isSpeaking) {
        setState(() => _isSpeaking = false);
      }
    });
  }

  Future<void> _submitMyComment() async {
    final currentLang = _localeService.simpleLanguageCode;
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      _snack(
        currentLang == 'es'
            ? 'Inicia sesión para comentar'
            : 'Log in to comment',
      );
      return;
    }

    if (_rating == 0) {
      _snack(
        currentLang == 'es'
            ? 'Selecciona una calificación'
            : 'Select a rating',
      );
      return;
    }

    final text = _commentCtrl.text.trim();
    if (text.isEmpty) {
      _snack(
        currentLang == 'es'
            ? 'Escribe tu comentario'
            : 'Write your comment',
      );
      return;
    }

    setState(() => _saving = true);

    try {
      final ref = _myCommentRef!;
      await FirebaseFirestore.instance.runTransaction((tx) async {
        final snap = await tx.get(ref);
        final base = <String, dynamic>{
          'id': user.uid,
          'parentType': 'categories',
          'parentId': widget.catId,
          'userId': user.uid,
          'userName': user.displayName?.trim().isNotEmpty == true
              ? user.displayName!.trim()
              : (user.email ?? 'Anónimo'),
          'userPhotoUrl': user.photoURL,
          'text': text,
          'rating': _rating.clamp(1, 5),
          'status': 'pending',
          'updatedAt': FieldValue.serverTimestamp(),
        };

        if (!snap.exists) {
          base['createdAt'] = FieldValue.serverTimestamp();
        }

        tx.set(ref, base, SetOptions(merge: true));
      });

      _snack(
        currentLang == 'es'
            ? 'Comentario enviado'
            : 'Comment submitted',
      );
    } catch (e) {
      _snack(
        '${currentLang == 'es' ? 'Error al guardar' : 'Save error'}: $e',
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final catDoc = FirebaseFirestore.instance
        .collection('categories')
        .doc(widget.catId);
    final currentLang = _localeService.simpleLanguageCode;

    return Scaffold(
      backgroundColor: const Color(0xFFF2E8D5),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF2E8D5),
        elevation: 0,
        centerTitle: true,
        title: Text(
          widget.catName,
          style: const TextStyle(color: Color(0xFF5B4636)),
        ),
        iconTheme: const IconThemeData(color: Color(0xFF5B4636)),
      ),
      body: AbsorbPointer(
        absorbing: _saving,
        child: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
          stream: catDoc.snapshots(),
          builder: (context, snap) {
            if (snap.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            final data = (snap.data?.data() ?? {})
              ..removeWhere((k, v) => v == null);

            // ✅ TRADUCCIÓN CORRECTA: Obtener nombre y body traducidos
            final translatedName = _translationService
                .categoryNameFromDoc(data, currentLang);
            final translatedBody = _translationService
                .categoryBodyFromDoc(data, currentLang);

            final displayName = translatedName.isEmpty
                ? widget.catName
                : translatedName;

            final coverUrl = (data['coverUrl'] ?? '').toString().trim();

            return ListView(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
              children: [
                // Imagen de portada
                ClipRRect(
                  borderRadius: BorderRadius.circular(28),
                  child: SizedBox(
                    height: 180,
                    child: networkImageSafe(
                      coverUrl.isEmpty ? null : coverUrl,
                      fit: BoxFit.cover,
                      fallback: const ColoredBox(
                        color: Color(0xFFE0E0E0),
                        child: Center(
                          child: Icon(Icons.photo_outlined),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Título y controles
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        displayName,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF5B4636),
                        ),
                      ),
                    ),
                    IconButton(
                      tooltip: _isSpeaking
                          ? (currentLang == 'es'
                              ? 'Detener narración'
                              : 'Stop narration')
                          : (currentLang == 'es'
                              ? 'Escuchar descripción'
                              : 'Listen description'),
                      onPressed: () => _toggleTts(translatedBody),
                      icon: Icon(
                        _isSpeaking ? Icons.volume_up : Icons.volume_up_outlined,
                        color: _isSpeaking
                            ? const Color(0xFF6B7C3F)
                            : const Color(0xFF5B4636),
                      ),
                    ),
                    IconButton(
                      tooltip: _fav
                          ? (currentLang == 'es'
                              ? 'Quitar de favoritos'
                              : 'Remove from favorites')
                          : (currentLang == 'es'
                              ? 'Añadir a favoritos'
                              : 'Add to favorites'),
                      onPressed: _toggleFavorite,
                      icon: Icon(
                        _fav ? Icons.favorite : Icons.favorite_border,
                        color: const Color(0xFF5B4636),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),

                // Descripción traducida
                Text(
                  translatedBody,
                  style: const TextStyle(
                    fontSize: 14,
                    height: 1.5,
                    color: Colors.black87,
                  ),
                ),

                const SizedBox(height: 24),
                const Divider(),
                const SizedBox(height: 12),

                // Sección de comentarios
                Text(
                  currentLang == 'es' ? 'Mi comentario' : 'My comment',
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                    color: Color(0xFF5B4636),
                  ),
                ),
                const SizedBox(height: 8),

                StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
                  stream: _myCommentRef?.snapshots(),
                  builder: (context, s) {
                    final m = s.data?.data();
                    if (m != null && !_loadedMyCommentOnce) {
                      _commentCtrl.text = (m['text'] ?? '').toString();
                      final r = m['rating'];
                      _rating = r is int
                          ? r
                          : int.tryParse(r?.toString() ?? '0') ?? 0;
                      _loadedMyCommentOnce = true;
                    }

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Rating stars
                        Row(
                          children: List.generate(5, (i) {
                            final idx = i + 1;
                            final filled = _rating >= idx;
                            return IconButton(
                              iconSize: 28,
                              onPressed: () => setState(() => _rating = idx),
                              icon: Icon(
                                filled ? Icons.star : Icons.star_border,
                              ),
                              color: Colors.amber,
                            );
                          }),
                        ),
                        const SizedBox(height: 8),

                        // Text field
                        TextField(
                          controller: _commentCtrl,
                          maxLines: 3,
                          decoration: InputDecoration(
                            hintText: currentLang == 'es'
                                ? 'Escribe tu comentario...'
                                : 'Write your comment...',
                            filled: true,
                            fillColor: Colors.white,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide.none,
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),

                        // Submit button
                        SizedBox(
                          width: double.infinity,
                          height: 44,
                          child: FilledButton(
                            onPressed: _saving ? null : _submitMyComment,
                            style: FilledButton.styleFrom(
                              backgroundColor: const Color(0xFF6B7C3F),
                            ),
                            child: Text(_saving ? l10n.saving : l10n.save),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}