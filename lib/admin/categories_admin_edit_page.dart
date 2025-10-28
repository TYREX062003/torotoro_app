import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import '../categories/category_repository.dart';
import '../services/storage_service.dart';

class CategoriesAdminEditPage extends StatefulWidget {
  final String catId;
  final Map<String, dynamic>? initialData;
  const CategoriesAdminEditPage({super.key, required this.catId, this.initialData});

  @override
  State<CategoriesAdminEditPage> createState() => _CategoriesAdminEditPageState();
}

class _CategoriesAdminEditPageState extends State<CategoriesAdminEditPage> {
  final _form = GlobalKey<FormState>();
  late final TextEditingController _name;
  late final TextEditingController _desc;
  late final TextEditingController _body;
  late final TextEditingController _order;

  String _coverUrl = '';
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final m = widget.initialData ?? {};
    _name = TextEditingController(text: (m['name'] ?? '').toString());
    _desc = TextEditingController(text: (m['desc'] ?? '').toString());
    _body = TextEditingController(text: (m['body'] ?? '').toString());
    _order = TextEditingController(text: (m['order'] ?? 0).toString());
    _coverUrl = (m['coverUrl'] ?? '').toString();
  }

  @override
  void dispose() {
    _name.dispose();
    _desc.dispose();
    _body.dispose();
    _order.dispose();
    super.dispose();
  }

  Future<void> _pickAndUploadCover() async {
    final l10n = AppLocalizations.of(context)!;
    final isSpanish = Localizations.localeOf(context).languageCode == 'es';
    
    final res = await FilePicker.platform.pickFiles(withData: true, type: FileType.image);
    if (res == null || res.files.isEmpty) return;

    setState(() => _saving = true);
    try {
      final url = await StorageService().uploadCategoryCover(widget.catId, res.files.first);
      setState(() => _coverUrl = url);
      await CategoryRepository().updateCategory(widget.catId, {
        'coverUrl': url,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(isSpanish ? 'Portada actualizada ✅' : 'Cover updated ✅'))
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${l10n.error}: $e'))
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _save() async {
    final l10n = AppLocalizations.of(context)!;
    final isSpanish = Localizations.localeOf(context).languageCode == 'es';
    
    if (!_form.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      final order = int.tryParse(_order.text.trim()) ?? 0;
      await CategoryRepository().updateCategory(widget.catId, {
        'key': widget.catId,
        'name': _name.text.trim(),
        'desc': _desc.text.trim(),
        'body': _body.text.trim(),
        'order': order,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(isSpanish ? 'Categoría guardada ✅' : 'Category saved ✅'))
      );
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${l10n.error}: $e'))
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isSpanish = Localizations.localeOf(context).languageCode == 'es';
    final img = _coverUrl;
    
    return Scaffold(
      backgroundColor: const Color(0xFFF2E8D5),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF2E8D5),
        elevation: 0,
        title: Text(isSpanish ? 'Editar categoría — ${widget.catId}' : 'Edit category — ${widget.catId}'),
        centerTitle: true,
      ),
      body: AbsorbPointer(
        absorbing: _saving,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Center(
              child: Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: SizedBox(
                      width: 220,
                      height: 220,
                      child: img.isNotEmpty
                          ? Image.network(img, fit: BoxFit.cover)
                          : ColoredBox(
                              color: const Color(0xFFE0E0E0),
                              child: Center(
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(Icons.photo_outlined, size: 48, color: Colors.black38),
                                    const SizedBox(height: 8),
                                    Text(isSpanish ? 'Sin portada' : 'No cover', 
                                      style: const TextStyle(color: Colors.black54, fontSize: 12)),
                                  ],
                                ),
                              ),
                            ),
                    ),
                  ),
                  Positioned(
                    right: 8, bottom: 8,
                    child: FloatingActionButton.small(
                      onPressed: _saving ? null : _pickAndUploadCover,
                      backgroundColor: const Color(0xFF6B7C3F),
                      child: const Icon(Icons.camera_alt_outlined, size: 20),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.black12,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const Icon(Icons.key, size: 18, color: Colors.black54),
                  const SizedBox(width: 8),
                  const Text('ID: ', style: TextStyle(fontWeight: FontWeight.w600, color: Colors.black54)),
                  Text(widget.catId, style: const TextStyle(fontFamily: 'monospace', color: Colors.black87)),
                ],
              ),
            ),
            
            const SizedBox(height: 20),
            
            Form(
              key: _form,
              child: Column(children: [
                TextFormField(
                  controller: _name,
                  decoration: InputDecoration(
                    labelText: isSpanish ? 'Nombre *' : 'Name *',
                    hintText: isSpanish ? 'Ej: Introducción' : 'Ex: Introduction',
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  validator: (v) => (v == null || v.trim().isEmpty) 
                    ? (isSpanish ? 'El nombre es requerido' : 'Name is required') 
                    : null,
                ),
                const SizedBox(height: 16),
                
                TextFormField(
                  controller: _desc,
                  decoration: InputDecoration(
                    labelText: isSpanish ? 'Descripción corta' : 'Short description',
                    hintText: isSpanish ? 'Resumen breve (opcional)' : 'Brief summary (optional)',
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  maxLines: 2,
                ),
                const SizedBox(height: 16),
                
                TextFormField(
                  controller: _body,
                  decoration: InputDecoration(
                    labelText: isSpanish ? 'Contenido completo' : 'Full content',
                    hintText: isSpanish 
                      ? 'Escribe el contenido detallado de esta categoría...' 
                      : 'Write the detailed content of this category...',
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    alignLabelWithHint: true,
                  ),
                  maxLines: 8,
                  minLines: 5,
                ),
                const SizedBox(height: 16),
                
                TextFormField(
                  controller: _order,
                  decoration: InputDecoration(
                    labelText: isSpanish ? 'Orden' : 'Order',
                    hintText: isSpanish ? 'Número para ordenar (0, 1, 2...)' : 'Sort number (0, 1, 2...)',
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    helperText: isSpanish 
                      ? 'Define el orden de aparición en la lista' 
                      : 'Defines the display order in the list',
                  ),
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 28),
                
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: FilledButton.icon(
                    onPressed: _saving ? null : _save,
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFF6B7C3F),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    icon: _saving
                        ? const SizedBox(
                            width: 20, height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                          )
                        : const Icon(Icons.save_outlined),
                    label: Text(
                      _saving ? l10n.saving : (isSpanish ? 'Guardar cambios' : 'Save changes'),
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
              ]),
            ),
          ],
        ),
      ),
    );
  }
}