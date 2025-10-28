import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import '../services/auth_service.dart';
import '../services/locale_service.dart';

class MenuPage extends StatefulWidget {
  const MenuPage({super.key});

  @override
  State<MenuPage> createState() => _MenuPageState();
}

class _MenuPageState extends State<MenuPage> {
  final _authSvc = AuthService();
  final _localeService = LocaleService();

  bool _loading = true;
  AppRole _role = AppRole.none;

  @override
  void initState() {
    super.initState();
    _loadRole();
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

  Future<void> _loadRole() async {
    try {
      final r = await _authSvc.refreshAndGetRole();
      if (!mounted) return;
      setState(() {
        _role = r;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loading = false);
    }
  }

  Future<void> _changeLanguage(String langCode) async {
    await _localeService.changeLocale(langCode);
    if (!mounted) return;
    final l10n = AppLocalizations.of(context)!;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          langCode == 'es' 
              ? l10n.languageChangedToSpanish 
              : l10n.languageChangedToEnglish,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final user = FirebaseAuth.instance.currentUser;
    final selectedLanguage = _localeService.simpleLanguageCode;

    if (_loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    // ✅ CAMBIO: Scaffold SIN AppBar - no hay botón de logout arriba
    return Scaffold(
      backgroundColor: const Color(0xFFF2E8D5),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            // Título del perfil
            Text(
              l10n.profile,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: const Color(0xFF5B4636),
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              '${l10n.user}: ${user?.email ?? l10n.guest}',
              style: const TextStyle(color: Colors.black87),
            ),
            const Divider(height: 30),

            // Opciones
            Text(
              l10n.options,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: const Color(0xFF5B4636),
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 10),

            // Panel de administrador (solo si es admin)
            if (_role == AppRole.admin) ...[
              ListTile(
                leading: const Icon(
                  Icons.admin_panel_settings,
                  color: Color(0xFF5B4636),
                ),
                title: Text(l10n.adminPanel),
                onTap: () => Navigator.of(context).pushNamed('/admin'),
              ),
              const Divider(),
            ],

            // Selector de idioma
            ExpansionTile(
              leading: const Icon(
                Icons.language,
                color: Color(0xFF5B4636),
              ),
              title: Text(l10n.language),
              subtitle: Text(
                selectedLanguage == 'es' ? l10n.spanish : l10n.english,
                style: const TextStyle(
                  fontSize: 13,
                  color: Colors.black54,
                ),
              ),
              children: [
                RadioListTile<String>(
                  title: Text(l10n.spanish),
                  value: 'es',
                  groupValue: selectedLanguage,
                  onChanged: (value) => value == null 
                      ? null 
                      : _changeLanguage(value),
                ),
                RadioListTile<String>(
                  title: Text(l10n.english),
                  value: 'en',
                  groupValue: selectedLanguage,
                  onChanged: (value) => value == null 
                      ? null 
                      : _changeLanguage(value),
                ),
              ],
            ),
            const Divider(),

            // ✅ Cerrar sesión - SOLO AQUÍ (no en AppBar)
            ListTile(
              leading: const Icon(
                Icons.logout,
                color: Color(0xFF5B4636),
              ),
              title: Text(l10n.logout),
              onTap: () async {
                await FirebaseAuth.instance.signOut();
                if (!mounted) return;
                Navigator.pushReplacementNamed(context, '/login');
              },
            ),
          ],
        ),
      ),
    );
  }
}