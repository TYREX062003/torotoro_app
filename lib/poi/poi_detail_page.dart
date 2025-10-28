import 'package:flutter/material.dart';
import '../services/content_translation_service.dart';
import '../services/locale_service.dart';
import '../services/tts_service.dart';

class PoiDetailPage extends StatefulWidget {
  final String poiId;
  final Map<String, dynamic> data;

  const PoiDetailPage({
    super.key,
    required this.poiId,
    required this.data,
  });

  @override
  State<PoiDetailPage> createState() => _PoiDetailPageState();
}

class _PoiDetailPageState extends State<PoiDetailPage> {
  final _translationService = ContentTranslationService();
  final _localeService = LocaleService();
  final _ttsService = TtsService();

  bool _isSpeaking = false;

  @override
  void initState() {
    super.initState();
    _localeService.addListener(_onLocaleChanged);
  }

  @override
  void dispose() {
    _localeService.removeListener(_onLocaleChanged);
    _ttsService.dispose();
    super.dispose();
  }

  void _onLocaleChanged() {
    if (mounted) setState(() {});
  }

  Future<void> _toggleTts(String text) async {
    final currentLang = _localeService.simpleLanguageCode;

    if (_isSpeaking) {
      await _ttsService.stop();
      if (mounted) setState(() => _isSpeaking = false);
      return;
    }

    final raw = text.trim();
    if (raw.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            currentLang == 'es'
                ? 'No hay contenido para narrar'
                : 'No content to narrate',
          ),
        ),
      );
      return;
    }

    await _ttsService.speak(raw);
    if (mounted) setState(() => _isSpeaking = true);

    Future.delayed(const Duration(milliseconds: 800), () {
      if (mounted && !_ttsService.isSpeaking) {
        setState(() => _isSpeaking = false);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final currentLang = _localeService.simpleLanguageCode;

    // ✅ TRADUCCIÓN CORRECTA: Usar servicio con documento completo
    final translatedName = _translationService.poiNameFromDoc(
      widget.data,
      currentLang,
    );
    final translatedDesc = _translationService.poiDescFromDoc(
      widget.data,
      currentLang,
    );
    final translatedTags = _translationService.poiTagsFromDoc(
      widget.data,
      currentLang,
    );

    // Fallback al ID si no hay nombre
    final displayName = translatedName.isEmpty ? widget.poiId : translatedName;

    final coverUrl = (widget.data['coverUrl'] ?? widget.data['imageUrl'] ?? '')
        .toString()
        .trim();

    return Scaffold(
      backgroundColor: const Color(0xFFF2E8D5),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF2E8D5),
        elevation: 0,
        centerTitle: true,
        title: Text(
          displayName,
          style: const TextStyle(color: Color(0xFF5B4636)),
        ),
        iconTheme: const IconThemeData(color: Color(0xFF5B4636)),
      ),
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            // Imagen de portada
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(28),
                  child: coverUrl.isNotEmpty
                      ? Image.network(
                          coverUrl,
                          height: 200,
                          width: double.infinity,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Container(
                            height: 200,
                            color: Colors.grey[300],
                            alignment: Alignment.center,
                            child: const Icon(
                              Icons.image_not_supported,
                              size: 48,
                            ),
                          ),
                        )
                      : Container(
                          height: 200,
                          color: Colors.grey[300],
                          alignment: Alignment.center,
                          child: const Icon(
                            Icons.image_outlined,
                            size: 64,
                          ),
                        ),
                ),
              ),
            ),

            // Título y control de audio
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        displayName, // ✅ Nombre traducido
                        style: const TextStyle(
                          fontSize: 20,
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
                      onPressed: () => _toggleTts(translatedDesc),
                      icon: Icon(
                        _isSpeaking ? Icons.volume_up : Icons.volume_up_outlined,
                        color: _isSpeaking
                            ? const Color(0xFF6B7C3F)
                            : const Color(0xFF5B4636),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SliverToBoxAdapter(child: SizedBox(height: 8)),

            // Subtítulo "Punto de interés"
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  currentLang == 'es' ? 'Punto de interés' : 'Point of interest',
                  style: const TextStyle(
                    fontSize: 14,
                    color: Color(0xFF6B7C3F),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),

            const SliverToBoxAdapter(child: SizedBox(height: 12)),

            // Descripción traducida
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  translatedDesc, // ✅ Descripción traducida
                  style: const TextStyle(
                    fontSize: 14,
                    height: 1.5,
                    color: Colors.black87,
                  ),
                ),
              ),
            ),

            const SliverToBoxAdapter(child: SizedBox(height: 16)),

            // Tags traducidos (si existen)
            if (translatedTags.isNotEmpty) ...[
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Text(
                    currentLang == 'es' ? 'Etiquetas' : 'Tags',
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 16,
                      color: Color(0xFF5B4636),
                    ),
                  ),
                ),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 8)),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: translatedTags.map((tag) {
                      return Chip(
                        label: Text(tag),
                        backgroundColor: const Color(0xFF6B7C3F).withOpacity(0.1),
                        labelStyle: const TextStyle(
                          color: Color(0xFF5B4636),
                          fontSize: 13,
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ),
            ],

            const SliverToBoxAdapter(child: SizedBox(height: 24)),
          ],
        ),
      ),
    );
  }
}