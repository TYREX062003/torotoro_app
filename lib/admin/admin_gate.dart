import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import '../services/auth_service.dart';

// Botón para pedir rol admin (si no lo tienes)
import './make_me_admin_button.dart';

// Tabs de administración
import './pending_comments_page.dart';
import './reports_page.dart';

// Usa alias para evitar conflictos de nombres entre archivos
import './poi_admin_list_page.dart' as poi_admin;
import './categories_admin_list_page.dart' as cat_admin;

class AdminGate extends StatefulWidget {
  const AdminGate({super.key});

  @override
  State<AdminGate> createState() => _AdminGateState();
}

class _AdminGateState extends State<AdminGate> {
  final _auth = AuthService();
  bool _loading = true;
  AppRole _role = AppRole.none;
  String? _error;

  @override
  void initState() {
    super.initState();
    _refreshRole();
  }

  Future<void> _refreshRole() async {
    if (!mounted) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final r = await _auth.refreshAndGetRole();
      if (!mounted) return;
      setState(() {
        _role = r;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = e.toString();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    
    final baseAppBar = AppBar(
      title: Text(l10n.administration),
      actions: [
        IconButton(
          tooltip: l10n.refreshRole,
          onPressed: _loading ? null : _refreshRole,
          icon: const Icon(Icons.refresh),
        ),
      ],
    );

    if (_loading) {
      return Scaffold(
        appBar: baseAppBar,
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_error != null) {
      return Scaffold(
        appBar: baseAppBar,
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.error_outline, size: 32),
                const SizedBox(height: 12),
                Text(
                  '${l10n.couldNotVerifyRole}\n$_error',
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                ElevatedButton(
                  onPressed: _refreshRole,
                  child: Text(l10n.retry),
                ),
              ],
            ),
          ),
        ),
      );
    }

    if (_role == AppRole.admin) {
      return DefaultTabController(
        length: 4,
        child: Scaffold(
          appBar: _TabbedAdminAppBar(),
          body: TabBarView(
            children: [
              const PendingCommentsPage(),
              poi_admin.PoiAdminListPage(),
              cat_admin.CategoriesAdminListPage(),
              const ReportsPage(),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: baseAppBar,
      body: const Center(child: MakeMeAdminButton()),
    );
  }
}

class _TabbedAdminAppBar extends StatelessWidget implements PreferredSizeWidget {
  const _TabbedAdminAppBar();

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight + kTextTabBarHeight);

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    
    return AppBar(
      title: Text(l10n.administration),
      bottom: TabBar(
        isScrollable: true, // ✅ Permite scroll horizontal en móvil
        tabAlignment: TabAlignment.start, // ✅ Alineación mejorada
        tabs: [
          Tab(icon: const Icon(Icons.rate_review_outlined), text: l10n.comments),
          Tab(icon: const Icon(Icons.place_outlined), text: l10n.pois),
          Tab(icon: const Icon(Icons.category_outlined), text: l10n.categories),
          Tab(icon: const Icon(Icons.bar_chart), text: l10n.reports),
        ],
      ),
    );
  }
}