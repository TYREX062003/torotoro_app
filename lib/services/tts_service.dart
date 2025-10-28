import 'package:flutter_tts/flutter_tts.dart';
import 'locale_service.dart';

class TtsService {
  static final TtsService _instance = TtsService._internal();
  factory TtsService() => _instance;
  TtsService._internal() {
    _localeService.addListener(_onLocaleChanged);
  }

  final FlutterTts _flutterTts = FlutterTts();
  final LocaleService _localeService = LocaleService();

  bool _isInitialized = false;
  bool _isSpeaking = false;

  bool get isSpeaking => _isSpeaking;

  /// Devuelve un código de idioma aceptado por los motores
  String get currentLanguage {
    final code = _localeService.simpleLanguageCode;
    // Preferimos variantes ampliamente disponibles
    if (code == 'es') return 'es-ES';
    return 'en-US';
  }

  void _onLocaleChanged() async {
    if (!_isInitialized) return;
    // Al cambiar el idioma, detener para evitar mezcla de acentos
    await stop();
    await _flutterTts.setLanguage(currentLanguage);
  }

  Future<void> _initialize() async {
    if (_isInitialized) return;

    try {
      await _flutterTts.setLanguage(currentLanguage);
      await _flutterTts.setSpeechRate(0.48); // ligeramente más lento y natural
      await _flutterTts.setVolume(1.0);
      await _flutterTts.setPitch(1.0);

      // Seleccionar una voz si está disponible para el idioma actual
      final voices = await _flutterTts.getVoices;
      if (voices is List) {
        final lang = currentLanguage;
        final match = voices.cast<Map>().firstWhere(
          (v) => (v['locale']?.toString() ?? '').startsWith(lang),
          orElse: () => const {},
        );
        if (match.isNotEmpty) {
          await _flutterTts.setVoice({
            'name': match['name'],
            'locale': match['locale'],
          });
        }
      }

      _flutterTts.setStartHandler(() => _isSpeaking = true);
      _flutterTts.setCompletionHandler(() => _isSpeaking = false);
      _flutterTts.setCancelHandler(() => _isSpeaking = false);
      _flutterTts.setErrorHandler((_) => _isSpeaking = false);

      _isInitialized = true;
    } catch (_) {}
  }

  Future<void> speak(String text) async {
    if (text.trim().isEmpty) return;
    await _initialize();
    try {
      if (_isSpeaking) {
        await stop();
      }
      await _flutterTts.setLanguage(currentLanguage);
      await _flutterTts.speak(text);
    } catch (_) {}
  }

  Future<void> stop() async {
    try {
      await _flutterTts.stop();
      _isSpeaking = false;
    } catch (_) {}
  }

  Future<void> pause() async {
    try {
      await _flutterTts.pause();
    } catch (_) {}
  }

  Future<void> dispose() async {
    _localeService.removeListener(_onLocaleChanged);
    await stop();
  }
}
