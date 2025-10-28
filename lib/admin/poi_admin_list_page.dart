import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'poi_admin_edit_page.dart';
import '../utils/net.dart';

class PoiAdminListPage extends StatelessWidget {
  const PoiAdminListPage({super.key});

  Future<void> _confirmDelete(BuildContext context, String poiId, String poiName) async {
    final l10n = AppLocalizations.of(context)!;
    final isSpanish = Localizations.localeOf(context).languageCode == 'es';
    
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(isSpanish ? 'Eliminar POI' : 'Delete POI'),
        content: Text(
          isSpanish
              ? '¿Estás seguro de eliminar "${poiName.isEmpty ? poiId : poiName}"?\n\nEsta acción NO se puede deshacer.'
              : 'Are you sure you want to delete "${poiName.isEmpty ? poiId : poiName}"?\n\nThis action CANNOT be undone.',
          style: const TextStyle(height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: Text(l10n.delete),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      await FirebaseFirestore.instance.collection('pois').doc(poiId).delete();
      
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(isSpanish ? 'POI "$poiId" eliminado ✅' : 'POI "$poiId" deleted ✅'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${l10n.error}: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _createNewPoi(BuildContext context) async {
    final l10n = AppLocalizations.of(context)!;
    final isSpanish = Localizations.localeOf(context).languageCode == 'es';
    
    final key = await showDialog<String>(
      context: context,
      builder: (ctx) {
        final controller = TextEditingController();
        return AlertDialog(
          title: Text(isSpanish ? 'Nuevo POI' : 'New POI'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                isSpanish
                    ? 'Ingresa un identificador único (slug) para el POI.'
                    : 'Enter a unique identifier (slug) for the POI.',
                style: const TextStyle(fontSize: 13, color: Colors.black87),
              ),
              const SizedBox(height: 8),
              Text(
                isSpanish
                    ? 'Ejemplos: "torotoro_canon", "cueva_umajalanta"'
                    : 'Examples: "torotoro_canyon", "umajalanta_cave"',
                style: const TextStyle(fontSize: 12, color: Colors.black54),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: controller,
                decoration: InputDecoration(
                  labelText: 'Key (slug)',
                  hintText: isSpanish ? 'ej: torotoro_canon' : 'ex: torotoro_canyon',
                  border: const OutlineInputBorder(),
                ),
                autofocus: true,
                onSubmitted: (v) => Navigator.pop(ctx, v.trim()),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(l10n.cancel),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, controller.text.trim()),
              child: Text(isSpanish ? 'Continuar' : 'Continue'),
            ),
          ],
        );
      },
    );

    if (key == null || key.isEmpty) return;

    try {
      final doc = await FirebaseFirestore.instance.collection('pois').doc(key).get();

      if (doc.exists) {
        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(isSpanish
                ? 'El POI "$key" ya existe. Usa otro identificador.'
                : 'POI "$key" already exists. Use another identifier.'),
            backgroundColor: Colors.orange,
          ),
        );
        return;
      }

      await FirebaseFirestore.instance.collection('pois').doc(key).set({
        'name': '',
        'description': '',
        'lat': -18.108883,
        'lng': -65.771849,
        'category': 'general',
        'imageUrl': '',
        'ratingAvg': 0,
        'ratingCount': 0,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      if (!context.mounted) return;

      final saved = await Navigator.of(context).push<bool>(
        MaterialPageRoute(
          builder: (_) => PoiAdminEditPage(poiId: key),
        ),
      );

      if (context.mounted && saved == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(isSpanish
              ? 'POI creado exitosamente ✅'
              : 'POI created successfully ✅')),
        );
      }
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${l10n.error}: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isSpanish = Localizations.localeOf(context).languageCode == 'es';
    final col = FirebaseFirestore.instance.collection('pois').orderBy('name');

    return Scaffold(
      appBar: AppBar(title: Text('${l10n.pois} — Admin')),
      
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _createNewPoi(context),
        icon: const Icon(Icons.add_location_alt_outlined),
        label: Text(isSpanish ? 'Nuevo POI' : 'New POI'),
      ),
      
      body: StreamBuilder<QuerySnapshot>(
        stream: col.snapshots(),
        builder: (context, snap) {
          if (snap.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  '${l10n.errorLoadingData}:\n${snap.error}',
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
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.location_off_outlined, size: 64, color: Colors.black26),
                  const SizedBox(height: 16),
                  Text(
                    isSpanish
                        ? 'No hay POIs registrados.'
                        : 'No POIs registered.',
                    style: const TextStyle(fontSize: 16, color: Colors.black54),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    isSpanish
                        ? 'Usa el botón "+" para crear uno nuevo.'
                        : 'Use the "+" button to create a new one.',
                    style: const TextStyle(fontSize: 13, color: Colors.black38),
                  ),
                ],
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.only(bottom: 80),
            itemCount: docs.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (context, i) {
              final d = docs[i];
              final m = d.data() as Map<String, dynamic>;
              final name = (m['name'] ?? '').toString();
              final imageUrl = m['imageUrl']?.toString() ?? m['coverUrl']?.toString();
              final lat = m['lat'] is num ? (m['lat'] as num).toDouble() : 0.0;
              final lng = m['lng'] is num ? (m['lng'] as num).toDouble() : 0.0;

              return ListTile(
                onTap: () {
                  Navigator.of(context).push<bool>(
                    MaterialPageRoute(
                      builder: (_) => PoiAdminEditPage(
                        poiId: d.id,
                        initialData: m,
                      ),
                    ),
                  );
                },
                leading: SizedBox(
                  width: 56,
                  height: 56,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: networkImageSafe(imageUrl, fit: BoxFit.cover),
                  ),
                ),
                title: Text(
                  name.isEmpty ? d.id : name,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                subtitle: Text(
                    'Coords: ${lat.toStringAsFixed(5)}, ${lng.toStringAsFixed(5)}'
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      tooltip: l10n.edit,
                      icon: const Icon(Icons.edit_outlined),
                      onPressed: () {
                        Navigator.of(context).push<bool>(
                          MaterialPageRoute(
                            builder: (_) => PoiAdminEditPage(
                              poiId: d.id,
                              initialData: m,
                            ),
                          ),
                        );
                      },
                    ),
                    IconButton(
                      tooltip: l10n.delete,
                      icon: const Icon(Icons.delete_outline, color: Colors.red),
                      onPressed: () => _confirmDelete(context, d.id, name),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}