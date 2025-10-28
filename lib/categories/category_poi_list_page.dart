import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:torotoro_app/models/poi_model.dart';
import 'package:torotoro_app/poi/poi_page.dart';

class CategoryPoiListPage extends StatelessWidget {
  final String categoryId;   // doc id de la categoría (slug)
  final String categoryName; // título visible

  const CategoryPoiListPage({
    super.key,
    required this.categoryId,
    required this.categoryName,
  });

  String _norm(String? s) {
    final raw = (s ?? '').toLowerCase().trim();
    const from = 'áàäâãåéèëêíìïîóòöôõúùüûñç';
    const to   = 'aaaaaaeeeeiiiiooooouuuunc';
    var out = StringBuffer();
    for (final ch in raw.runes) {
      final c = String.fromCharCode(ch);
      final idx = from.indexOf(c);
      out.write(idx >= 0 ? to[idx] : c);
    }
    final noSymbols = out.toString().replaceAll(RegExp(r'[^a-z0-9]+'), '');
    return noSymbols;
  }

  bool _matchesCategory(String slug, Map<String, dynamic> m) {
    final nslug = _norm(slug);
    final cat1 = _norm(m['category']?.toString());
    final cat2 = _norm(m['categoryId']?.toString());
    final list = (m['categories'] is List ? (m['categories'] as List) : const [])
        .map((e) => _norm(e?.toString()))
        .toList();
    return cat1 == nslug || cat2 == nslug || list.contains(nslug);
  }

  @override
  Widget build(BuildContext context) {
    final q = FirebaseFirestore.instance.collection('pois').orderBy('name');
    return Scaffold(
      backgroundColor: const Color(0xFFF2E8D5),
      appBar: AppBar(
        title: Text('POIs - $categoryName'),
        backgroundColor: const Color(0xFFF2E8D5),
        foregroundColor: const Color(0xFF5B4636),
        elevation: 0,
        centerTitle: true,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: q.snapshots(),
        builder: (context, snap) {
          if (snap.hasError) {
            return Center(child: Padding(
              padding: const EdgeInsets.all(16),
              child: Text('Error: ${snap.error}'),
            ));
          }
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final all = snap.data?.docs ?? [];
          final filtered = all.where((d) {
            final m = d.data() as Map<String, dynamic>;
            return _matchesCategory(categoryId, m);
          }).toList();

          if (filtered.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: const [
                    Text('No hay POIs en esta categoría.'),
                    SizedBox(height: 12),
                    Text(
                      'Tip: verifica que los POIs tengan\n'
                      '• category / categoryId = "<slug>"\n'
                      '• o categories[] contenga ese slug',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 12, color: Colors.black54),
                    ),
                  ],
                ),
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 16),
            itemCount: filtered.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (context, i) {
              final d = filtered[i];
              final m = d.data() as Map<String, dynamic>;
              final name = (m['name'] ?? d.id).toString();
              final desc = (m['desc'] ?? '').toString();
              final imageUrl = (m['coverUrl'] ?? m['imageUrl'] ?? '').toString();

              return Material(
                color: Colors.white,
                elevation: 0,
                borderRadius: BorderRadius.circular(12),
                child: InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: () {
                    final poi = Poi.fromMap(d.id, m);
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => PoiPage(poi: poi)),
                    );
                  },
                  child: Padding(
                    padding: const EdgeInsets.all(10),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: imageUrl.isNotEmpty
                              ? Image.network(
                                  imageUrl,
                                  width: 96, height: 96, fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) => const ColoredBox(
                                    color: Color(0xFFE0E0E0),
                                    child: SizedBox(width: 96, height: 96),
                                  ),
                                )
                              : const ColoredBox(
                                  color: Color(0xFFE0E0E0),
                                  child: SizedBox(width: 96, height: 96),
                                ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(name,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                      fontWeight: FontWeight.w800,
                                      fontSize: 16,
                                      color: Color(0xFF5B4636))),
                              const SizedBox(height: 6),
                              Text(
                                desc.isEmpty ? '—' : desc,
                                maxLines: 3,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(fontSize: 13, height: 1.3),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
