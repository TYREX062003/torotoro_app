import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

import '../map/map_page.dart';
import '../favorites/favorites_page.dart';
import '../menu/menu_page.dart';
import '../categories/categories_page.dart';

const kBeige = Color(0xFFF2E8D5);
const kBrown = Color(0xFF5B4636);

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _currentIndex = 0;
  late final List<Widget> _pages;

  @override
  void initState() {
    super.initState();
    _pages = const [
      MapPage(),        // 0
      FavoritesPage(),  // 1
      CategoriesPage(), // 2
      MenuPage(),       // 3
    ];
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    // 🔥 Cambio 1: Usar l10n.map para traducción automática
    final titles = [l10n.map, l10n.favorites, l10n.categories, l10n.menu];

    // 🔥 Cambio 2: Ocultar AppBar tanto en Mapa (0) como en Categorías (2)
    final hideAppBar = _currentIndex == 0 || _currentIndex == 2;

    return Scaffold(
      appBar: hideAppBar
          ? null
          : AppBar(
              title: Text(titles[_currentIndex]),
              backgroundColor: kBeige,
              foregroundColor: kBrown,
              elevation: 0,
              centerTitle: true,
            ),
      body: IndexedStack(index: _currentIndex, children: _pages),
      bottomNavigationBar: NavigationBar(
        backgroundColor: kBeige,
        indicatorColor: kBrown.withOpacity(0.15),
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        selectedIndex: _currentIndex,
        onDestinationSelected: (index) => setState(() => _currentIndex = index),
        destinations: [
          NavigationDestination(
            icon: const Icon(Icons.map_outlined),
            selectedIcon: const Icon(Icons.map),
            label: l10n.map, // 🔥 Cambio 3: Usar l10n.map también en el navbar
          ),
          NavigationDestination(
            icon: const Icon(Icons.favorite_border),
            selectedIcon: const Icon(Icons.favorite),
            label: l10n.favorites,
          ),
          NavigationDestination(
            icon: const Icon(Icons.category_outlined),
            selectedIcon: const Icon(Icons.category),
            label: l10n.categories,
          ),
          NavigationDestination(
            icon: const Icon(Icons.menu),
            label: l10n.menu,
          ),
        ],
      ),
    );
  }
}