import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import '../services/storage_service.dart';

class PoiAdminEditPage extends StatefulWidget {
  final String poiId;
  final Map<String, dynamic>? initialData;
  
  const PoiAdminEditPage({
    super.key,
    required this.poiId,
    this.initialData,
  });

  @override
  State<PoiAdminEditPage> createState() => _PoiAdminEditPageState();
}

class _PoiAdminEditPageState extends State<PoiAdminEditPage> {
  final _form = GlobalKey<FormState>();
  late final TextEditingController _name;
  late final TextEditingController _desc;
  late final TextEditingController _lat;
  late final TextEditingController _lng;

  String _imageUrl = '';
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final m = widget.initialData ?? {};
    _name = TextEditingController(text: (m['name'] ?? '').toString());
    _desc = TextEditingController(text: (m['description'] ?? m['desc'] ?? '').toString());
    
    final latVal = m['lat'] is num ? (m['lat'] as num).toDouble() : 0.0;
    final lngVal = m['lng'] is num ? (m['lng'] as num).toDouble() : 0.0;
    
    _lat = TextEditingController(text: latVal.toString());
    _lng = TextEditingController(text: lngVal.toString());
    _imageUrl = (m['imageUrl'] ?? m['coverUrl'] ?? '').toString();
  }

  @override
  void dispose() {
    _name.dispose();
    _desc.dispose();
    _lat.dispose();
    _lng.dispose();
    super.dispose();
  }

  Future<void> _pickAndUploadImage() async {
    final l10n = AppLocalizations.of(context)!;
    final isSpanish = Localizations.localeOf(context).languageCode == 'es';
    
    final res = await FilePicker.platform.pickFiles(
      withData: true,
      type: FileType.image,
    );
    
    if (res == null || res.files.isEmpty) return;

    setState(() => _saving = true);
    
    try {
      final url = await StorageService().uploadPoiImage(
        widget.poiId,
        res.files.first,
      );
      
      setState(() => _imageUrl = url);
      
      await FirebaseFirestore.instance.collection('pois').doc(widget.poiId).update({
        'imageUrl': url,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(isSpanish ? 'Imagen actualizada ✅' : 'Image updated ✅')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${l10n.error}: $e')),
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
      final lat = double.tryParse(_lat.text.trim()) ?? 0.0;
      final lng = double.tryParse(_lng.text.trim()) ?? 0.0;
      
      await FirebaseFirestore.instance.collection('pois').doc(widget.poiId).set({
        'name': _name.text.trim(),
        'description': _desc.text.trim(),
        'lat': lat,
        'lng': lng,
        'imageUrl': _imageUrl,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
      
      if (!mounted) return;
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(isSpanish ? 'POI guardado ✅' : 'POI saved ✅')),
      );
      
      Navigator.pop(context, true);
      
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${l10n.error}: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isSpanish = Localizations.localeOf(context).languageCode == 'es';
    final img = _imageUrl;
    
    return Scaffold(
      backgroundColor: const Color(0xFFF2E8D5),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF2E8D5),
        elevation: 0,
        title: Text('${l10n.edit} POI — ${widget.poiId}'),
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
                          ? Image.network(
                              img,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => _buildPlaceholder(isSpanish),
                            )
                          : _buildPlaceholder(isSpanish),
                    ),
                  ),
                  Positioned(
                    right: 8,
                    bottom: 8,
                    child: FloatingActionButton.small(
                      heroTag: 'uploadImage',
                      onPressed: _saving ? null : _pickAndUploadImage,
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
                  const Icon(Icons.location_on, size: 18, color: Colors.black54),
                  const SizedBox(width: 8),
                  const Text(
                    'ID: ',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: Colors.black54,
                    ),
                  ),
                  Text(
                    widget.poiId,
                    style: const TextStyle(
                      fontFamily: 'monospace',
                      color: Colors.black87,
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 20),
            
            Form(
              key: _form,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextFormField(
                    controller: _name,
                    decoration: InputDecoration(
                      labelText: isSpanish ? 'Nombre del lugar *' : 'Place name *',
                      hintText: isSpanish ? 'Ej: Cañón de Torotoro' : 'Ex: Torotoro Canyon',
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
                      labelText: isSpanish ? 'Descripción' : 'Description',
                      hintText: isSpanish
                          ? 'Descripción del punto de interés...'
                          : 'Point of interest description...',
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      alignLabelWithHint: true,
                    ),
                    maxLines: 5,
                    minLines: 3,
                  ),
                  
                  const SizedBox(height: 16),
                  
                  Text(
                    isSpanish
                        ? 'Ubicación (Coordenadas)'
                        : 'Location (Coordinates)',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF5B4636),
                    ),
                  ),
                  const SizedBox(height: 8),
                  
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _lat,
                          decoration: InputDecoration(
                            labelText: isSpanish ? 'Latitud *' : 'Latitude *',
                            hintText: '-18.108883',
                            filled: true,
                            fillColor: Colors.white,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide.none,
                            ),
                          ),
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                            signed: true,
                          ),
                          validator: (v) {
                            if (v == null || v.trim().isEmpty) {
                              return isSpanish ? 'Requerido' : 'Required';
                            }
                            if (double.tryParse(v.trim()) == null) {
                              return isSpanish ? 'Número inválido' : 'Invalid number';
                            }
                            return null;
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextFormField(
                          controller: _lng,
                          decoration: InputDecoration(
                            labelText: isSpanish ? 'Longitud *' : 'Longitude *',
                            hintText: '-65.771849',
                            filled: true,
                            fillColor: Colors.white,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide.none,
                            ),
                          ),
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                            signed: true,
                          ),
                          validator: (v) {
                            if (v == null || v.trim().isEmpty) {
                              return isSpanish ? 'Requerido' : 'Required';
                            }
                            if (double.tryParse(v.trim()) == null) {
                              return isSpanish ? 'Número inválido' : 'Invalid number';
                            }
                            return null;
                          },
                        ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 8),
                  Text(
                    isSpanish
                        ? 'Tip: Puedes obtener coordenadas desde Google Maps haciendo clic derecho en el mapa'
                        : 'Tip: You can get coordinates from Google Maps by right-clicking on the map',
                    style: const TextStyle(fontSize: 12, color: Colors.black54),
                  ),
                  
                  const SizedBox(height: 28),
                  
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: FilledButton.icon(
                      onPressed: _saving ? null : _save,
                      style: FilledButton.styleFrom(
                        backgroundColor: const Color(0xFF6B7C3F),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      icon: _saving
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(Icons.save_outlined),
                      label: Text(
                        _saving
                            ? l10n.saving
                            : (isSpanish ? 'Guardar cambios' : 'Save changes'),
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlaceholder(bool isSpanish) {
    return ColoredBox(
      color: const Color(0xFFE0E0E0),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.photo_outlined, size: 48, color: Colors.black38),
            const SizedBox(height: 8),
            Text(
              isSpanish ? 'Sin imagen' : 'No image',
              style: const TextStyle(color: Colors.black54, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }
}