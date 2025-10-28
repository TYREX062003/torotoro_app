import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LocaleService extends ChangeNotifier {
  static final LocaleService _instance = LocaleService._internal();
  factory LocaleService() => _instance;
  LocaleService._internal();

  Locale _locale = const Locale('es'); // Por defecto español
  Locale get locale => _locale;

  Future<void> loadSavedLocale() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final langCode = prefs.getString('app_language') ?? 'es';
      _locale = Locale(langCode);
      notifyListeners();
    } catch (e) {
      // Opcional: logs
    }
  }

  Future<void> changeLocale(String langCode) async {
    try {
      _locale = Locale(langCode);
      notifyListeners();

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('app_language', langCode);
    } catch (e) {
      // Opcional: logs
    }
  }

  String get simpleLanguageCode => _locale.languageCode;
}
