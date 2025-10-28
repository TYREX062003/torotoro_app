import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../categories/category_poi_list_page.dart';

class DiscoverPage extends StatelessWidget {
  const DiscoverPage({super.key});

  // Sanea URL sin RegExp: quita comillas, espacios y chars invisibles
  String _sanitizeUrl(String? raw) {
    var s = (raw ?? '').trim();
    if (s.length >= 2 && s.startsWith('"') && s.endsWith('"')) {
      s = s.substring(1, s.length - 1).trim();
    }
    if (s.length >= 2 && s.startsWith("'") && s.endsWith("'")) {
      s = s.substring(1, s.length - 1).trim();
    }
    const junk = ['\u200B', '\u200E', '\u200F']; // zero-width/RTL marks
    for (final j in junk) {
      s = s.replaceAll(j, '');
    }
    return s;
  }

  bool _isLikelyValidUrl(String s) {
    final u = Uri.tryParse(s);
    return u != null && (u.scheme == 'https' || u.scheme == 'http') && u.host.isNotEmpty;
  }

  @override
  Widget build(BuildContext context) {
    final col = FirebaseFirestore.instance.collection('categories').orderBy('order');

    return Scaffold(
      appBar: AppBar(title: const Text('Discover')),
      body: StreamBuilder<QuerySnapshot>(
        stream: col.snapshots(),
        builder: (context, snap) {
          if (snap.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  'Error cargando categorías:\n${snap.error}',
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }

          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final docs = snap.data?.docs ?? [];
          if (docs.isEmpty) {
            return const Center(child: Text('No hay categorías.'));
          }

          return GridView.builder(
            padding: const EdgeInsets.all(16),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 1.1,
            ),
            itemCount: docs.length,
            itemBuilder: (context, i) {
              final d = docs[i];
              final m = d.data() as Map<String, dynamic>;
              final name = (m['name'] ?? d.id).toString();

              final rawUrl = (m['coverUrl'] ?? '').toString();
              final coverUrl = _sanitizeUrl(rawUrl);
              final validUrl = _isLikelyValidUrl(coverUrl);

              return GestureDetector(
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => CategoryPoiListPage(
                        categoryId: d.id,
                        categoryName: name,
                      ),
                    ),
                  );
                },
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      if (validUrl)
                        Image.network(
                          coverUrl,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Container(
                            color: Colors.grey[300],
                            alignment: Alignment.center,
                            child: const Icon(Icons.image_not_supported, size: 48),
                          ),
                        )
                      else
                        Container(
                          color: Colors.grey[300],
                          alignment: Alignment.center,
                          child: const Icon(Icons.image_outlined, size: 48),
                        ),
                      Container(
                        decoration: const BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Color.fromRGBO(0, 0, 0, 0.6),
                              Color.fromRGBO(0, 0, 0, 0.0),
                            ],
                            begin: Alignment.bottomCenter,
                            end: Alignment.topCenter,
                          ),
                        ),
                      ),
                      Align(
                        alignment: Alignment.bottomCenter,
                        child: Padding(
                          padding: const EdgeInsets.all(8),
                          child: Text(
                            name,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                    ],  
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
