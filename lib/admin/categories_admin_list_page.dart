import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'categories_admin_edit_page.dart';
import '../categories/category_repository.dart';
import '../models/category_model.dart';
import '../utils/net.dart';

class CategoriesAdminListPage extends StatelessWidget {
  const CategoriesAdminListPage({super.key});

  Future<void> _confirmDelete(BuildContext context, String catId, String catName) async {
    final l10n = AppLocalizations.of(context)!;
    final isSpanish = Localizations.localeOf(context).languageCode == 'es';
    
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(isSpanish ? 'Eliminar categoría' : 'Delete category'),
        content: Text(
          isSpanish
            ? '¿Estás seguro de eliminar "${catName.isEmpty ? catId : catName}"?\n\nEsta acción NO se puede deshacer.\n\nADVERTENCIA: Los comentarios asociados a esta categoría NO serán eliminados automáticamente.'
            : 'Are you sure you want to delete "${catName.isEmpty ? catId : catName}"?\n\nThis action CANNOT be undone.\n\nWARNING: Comments associated with this category will NOT be automatically deleted.',
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
      await FirebaseFirestore.instance.collection('categories').doc(catId).delete();
      
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(isSpanish ? 'Categoría "$catId" eliminada ✅' : 'Category "$catId" deleted ✅'),
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

  Future<void> _createNewCategory(BuildContext context) async {
    final l10n = AppLocalizations.of(context)!;
    final isSpanish = Localizations.localeOf(context).languageCode == 'es';
    
    final key = await showDialog<String>(
      context: context,
      builder: (ctx) {
        final controller = TextEditingController();
        return AlertDialog(
          title: Text(isSpanish ? 'Nueva categoría' : 'New category'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                isSpanish
                  ? 'Ingresa un identificador único (slug) para la categoría.'
                  : 'Enter a unique identifier (slug) for the category.',
                style: const TextStyle(fontSize: 13, color: Colors.black87),
              ),
              const SizedBox(height: 8),
              Text(
                isSpanish
                  ? 'Ejemplos: "cuevas", "lagunas", "museos"'
                  : 'Examples: "caves", "lakes", "museums"',
                style: const TextStyle(fontSize: 12, color: Colors.black54),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: controller,
                decoration: InputDecoration(
                  labelText: 'Key (slug)',
                  hintText: isSpanish ? 'ej: cuevas' : 'ex: caves',
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
      final doc = await FirebaseFirestore.instance.collection('categories').doc(key).get();

      if (doc.exists) {
        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(isSpanish
              ? 'La categoría "$key" ya existe. Usa otro identificador.'
              : 'Category "$key" already exists. Use another identifier.'),
            backgroundColor: Colors.orange,
          ),
        );
        return;
      }

      final repo = CategoryRepository();
      final newCategory = Category.empty(key);
      await repo.createCategory(key, newCategory);

      if (!context.mounted) return;

      final saved = await Navigator.of(context).push<bool>(
        MaterialPageRoute(
          builder: (_) => CategoriesAdminEditPage(
            catId: key,
            initialData: newCategory.toMap(),
          ),
        ),
      );

      if (context.mounted && saved == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(isSpanish
            ? 'Categoría creada exitosamente ✅'
            : 'Category created successfully ✅')),
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
    final col = FirebaseFirestore.instance.collection('categories').orderBy('order');

    return Scaffold(
      appBar: AppBar(title: Text('${l10n.categories} — Admin')),
      
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _createNewCategory(context),
        icon: const Icon(Icons.add),
        label: Text(isSpanish ? 'Nueva categoría' : 'New category'),
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
                  const Icon(Icons.category_outlined, size: 64, color: Colors.black26),
                  const SizedBox(height: 16),
                  Text(
                    isSpanish ? 'No hay categorías.' : 'No categories.',
                    style: const TextStyle(fontSize: 16, color: Colors.black54),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    isSpanish ? 'Usa el botón "+" para crear una nueva.' : 'Use the "+" button to create a new one.',
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
              final coverUrl = m['coverUrl']?.toString();
              final order = m['order'] is int
                  ? (m['order'] as int)
                  : int.tryParse(m['order']?.toString() ?? '0') ?? 0;

              return ListTile(
                onTap: () {
                  Navigator.of(context).push<bool>(
                    MaterialPageRoute(
                      builder: (_) => CategoriesAdminEditPage(
                        catId: d.id,
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
                    child: networkImageSafe(coverUrl, fit: BoxFit.cover),
                  ),
                ),
                title: Text(
                  name.isEmpty ? d.id : name,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                subtitle: Text('${isSpanish ? 'Orden' : 'Order'}: $order • ID: ${d.id}'),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      tooltip: l10n.edit,
                      icon: const Icon(Icons.edit_outlined),
                      onPressed: () {
                        Navigator.of(context).push<bool>(
                          MaterialPageRoute(
                            builder: (_) => CategoriesAdminEditPage(
                              catId: d.id,
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