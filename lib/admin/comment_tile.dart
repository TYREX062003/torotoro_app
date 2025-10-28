import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/comments_model.dart';

class CommentTile extends StatelessWidget {
  final Comment c;
  final VoidCallback? onApprove;
  final VoidCallback? onReject;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  final String? subtitleExtra;

  const CommentTile({
    super.key,
    required this.c,
    this.onApprove,
    this.onReject,
    this.onEdit,
    this.onDelete,
    this.subtitleExtra,
  });

  @override
  Widget build(BuildContext context) {
    final entityLabel = c.parentType == 'categories' ? 'Categoría' : 'POI';
    
    // Mostrar userName si existe, sino email, sino "Usuario"
    final displayName = c.userName.isNotEmpty ? c.userName : 'Usuario';

    return StreamBuilder<DocumentSnapshot>(
      // Cargar datos de la categoría para obtener la imagen
      stream: c.parentType == 'categories'
          ? FirebaseFirestore.instance
              .collection('categories')
              .doc(c.parentId)
              .snapshots()
          : null,
      builder: (context, categorySnap) {
        String? categoryImageUrl;
        String categoryName = c.parentId;

        if (categorySnap.hasData && categorySnap.data != null) {
          final data = categorySnap.data!.data() as Map<String, dynamic>?;
          if (data != null) {
            categoryImageUrl = data['coverUrl']?.toString() ?? data['imageUrl']?.toString();
            categoryName = data['name']?.toString() ?? c.parentId;
          }
        }

        return ListTile(
          // Reemplazar CircleAvatar con número por imagen de categoría
          leading: SizedBox(
            width: 56,
            height: 56,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: categoryImageUrl != null && categoryImageUrl.isNotEmpty
                  ? Image.network(
                      categoryImageUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => _buildPlaceholder(),
                    )
                  : _buildPlaceholder(),
            ),
          ),
          title: Text(
            c.text.isEmpty ? '(Sin texto)' : c.text,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Quitar el "• PENDIENTE" y solo mostrar la categoría
              Text(
                '$entityLabel: $categoryName',
                style: const TextStyle(fontSize: 12, color: Colors.black87),
              ),
              const SizedBox(height: 2),
              // Mostrar userName en lugar de email
              Text(
                'Por: $displayName',
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
              if (subtitleExtra != null && subtitleExtra!.isNotEmpty) const SizedBox(height: 2),
              if (subtitleExtra != null && subtitleExtra!.isNotEmpty)
                Text(
                  subtitleExtra!,
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
            ],
          ),
          trailing: Wrap(
            spacing: 6,
            children: [
              if (onEdit != null)
                IconButton(
                  icon: const Icon(Icons.edit_outlined),
                  onPressed: onEdit,
                  tooltip: 'Editar',
                ),
              if (onDelete != null)
                IconButton(
                  icon: const Icon(Icons.delete_outline),
                  onPressed: onDelete,
                  tooltip: 'Eliminar',
                ),
              if (onReject != null)
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: onReject,
                  tooltip: 'Rechazar',
                ),
              if (onApprove != null)
                IconButton(
                  icon: const Icon(Icons.check),
                  onPressed: onApprove,
                  tooltip: 'Aprobar',
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildPlaceholder() {
    return Container(
      color: const Color(0xFFE0E0E0),
      child: const Center(
        child: Icon(
          Icons.category_outlined,
          size: 28,
          color: Colors.black38,
        ),
      ),
    );
  }
}