import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'firebase_options.dart';

// Servicios
import 'services/locale_service.dart';

// Páginas
import 'home/home_page.dart';
import 'auth/login_page.dart';
import 'auth/register_page.dart';
import 'auth/reset_password_page.dart';
import 'admin/admin_gate.dart';

// L10n
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

// 🎨 Paleta
const kBeige = Color(0xFFF2E8D5);
const kOlive = Color(0xFF6B7C3F);
const kBrown = Color(0xFF5B4636);

// Navigator global
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  if (kIsWeb) {
    await FirebaseAuth.instance.setPersistence(Persistence.LOCAL);
  }
  // Alinear idioma por defecto del backend de auth con la app
  try {
    await FirebaseAuth.instance.setLanguageCode('es');
  } catch (_) {}

  // Cargar idioma guardado
  await LocaleService().loadSavedLocale();

  runApp(const TorotoroApp());
}

class TorotoroApp extends StatefulWidget {
  const TorotoroApp({super.key});

  @override
  State<TorotoroApp> createState() => _TorotoroAppState();
}

class _TorotoroAppState extends State<TorotoroApp> {
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
    final baseScheme = ColorScheme.fromSeed(seedColor: kOlive, brightness: Brightness.light);
    final scheme = baseScheme.copyWith(
      surface: kBeige,
      background: kBeige,
      primary: kOlive,
      onPrimary: Colors.white,
      onSurface: kBrown,
    );

    return MaterialApp(
      title: 'Torotoro',
      debugShowCheckedModeBanner: false,
      navigatorKey: navigatorKey,

      // ✅ i18n: usar los locales soportados del gen
      locale: _localeService.locale,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,

      theme: ThemeData(
        useMaterial3: true,
        colorScheme: scheme,
        scaffoldBackgroundColor: kBeige,
        appBarTheme: const AppBarTheme(
          backgroundColor: kBeige,
          elevation: 0,
          foregroundColor: kBrown,
          centerTitle: true,
        ),
        filledButtonTheme: FilledButtonThemeData(
          style: FilledButton.styleFrom(
            backgroundColor: kOlive,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 18),
          ),
        ),
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            foregroundColor: kOlive,
            side: const BorderSide(color: kOlive, width: 1.2),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 18),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.white,
          hintStyle: const TextStyle(color: Colors.black54),
          labelStyle: const TextStyle(color: kBrown),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
          contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 14),
        ),
        dividerTheme: const DividerThemeData(color: Color(0xFFDDD3BE), thickness: 1),
      ),
      home: const AuthGate(),
      routes: {
        '/login': (_) => const LoginPage(),
        '/register': (_) => const RegisterPage(),
        '/reset': (_) => const ResetPasswordPage(),
        '/home': (_) => const HomePage(),
        '/admin': (_) => const AdminGate(),
      },
    );
  }
}

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }
        if (snap.hasData) return const HomePage();
        return const LoginPage();
      },
    );
  }
}
