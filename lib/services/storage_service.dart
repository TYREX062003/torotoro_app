import 'dart:typed_data';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:mime/mime.dart';

class StorageService {
  final FirebaseStorage _storage = FirebaseStorage.instance;

  /// Sube el cover de una categoría
  Future<String> uploadCategoryCover(String catId, PlatformFile file) async {
    final Uint8List? bytes = file.bytes;
    if (bytes == null) {
      throw 'El archivo no contiene bytes. Usa pickFiles(withData: true).';
    }

    final guessed = lookupMimeType(file.name, headerBytes: bytes) ?? 'image/jpeg';
    final ext = guessed.contains('png') ? 'png' : 'jpg';

    final ref = _storage.ref('categories/$catId/cover.$ext');
    final snap = await ref.putData(
      bytes,
      SettableMetadata(
        contentType: guessed,
        cacheControl: 'public, max-age=604800',
      ),
    );
    return await snap.ref.getDownloadURL();
  }

  /// Sube imagen principal de un POI
  Future<String> uploadPoiImage(String poiId, PlatformFile file) async {
    final Uint8List? bytes = file.bytes;
    if (bytes == null) {
      throw 'El archivo no contiene bytes. Usa pickFiles(withData: true).';
    }

    final guessed = lookupMimeType(file.name, headerBytes: bytes) ?? 'image/jpeg';
    final ext = guessed.contains('png') ? 'png' : 'jpg';

    final ref = _storage.ref('pois/$poiId/cover.$ext');
    final snap = await ref.putData(
      bytes,
      SettableMetadata(
        contentType: guessed,
        cacheControl: 'public, max-age=604800',
      ),
    );
    return await snap.ref.getDownloadURL();
  }
}
