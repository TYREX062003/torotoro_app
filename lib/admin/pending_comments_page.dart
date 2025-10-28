import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import '../models/comments_model.dart';
import '../admin/comments_repository.dart';
import '../admin/comment_tile.dart';

class PendingCommentsPage extends StatefulWidget {
  const PendingCommentsPage({super.key});

  @override
  State<PendingCommentsPage> createState() => _PendingCommentsPageState();
}

class _PendingCommentsPageState extends State<PendingCommentsPage>
    with TickerProviderStateMixin {
  final CommentsRepository _repo = CommentsRepository();
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this); // 🔥 Cambiado de 4 a 3
    _checkAuth();
  }

  Future<void> _checkAuth() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      print('❌ NO HAY USUARIO AUTENTICADO');
      return;
    }
    
    print('✅ Usuario: ${user.email}');
    
    try {
      final idTokenResult = await user.getIdTokenResult();
      final claims = idTokenResult.claims;
      print('📋 Claims: $claims');
      print('🔑 Es admin: ${claims?['role'] == 'admin'}');
      
      if (claims?['role'] != 'admin') {
        print('⚠️ USUARIO NO ES ADMIN');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('⚠️ Tu usuario no tiene permisos de administrador'),
              backgroundColor: Colors.orange,
              duration: Duration(seconds: 5),
            ),
          );
        }
      }
    } catch (e) {
      print('❌ Error obteniendo token: $e');
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  // ============================================
  // EDITAR COMENTARIO
  // ============================================
  Future<void> _editComment(String categoryId, Comment c) async {
    final l10n = AppLocalizations.of(context)!;
    final textCtrl = TextEditingController(text: c.text);
    int rating = c.rating.round();

    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text(l10n.editComment),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: textCtrl,
                    decoration: InputDecoration(
                      labelText: l10n.comments,
                      border: const OutlineInputBorder(),
                    ),
                    maxLines: 5,
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      const Text('⭐'),
                      const SizedBox(width: 8),
                      DropdownButton<int>(
                        value: rating,
                        items: [1, 2, 3, 4, 5]
                            .map((e) => DropdownMenuItem(
                                  value: e,
                                  child: Text('$e'),
                                ))
                            .toList(),
                        onChanged: (v) {
                          if (v != null) setDialogState(() => rating = v);
                        },
                      ),
                    ],
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx, false),
                  child: Text(l10n.cancel),
                ),
                FilledButton(
                  onPressed: () => Navigator.pop(ctx, true),
                  child: Text(l10n.save),
                ),
              ],
            );
          },
        );
      },
    );

    if (ok != true) return;

    try {
      await _repo.updateComment(
        categoryId: categoryId,
        commentId: c.id,
        data: {
          'text': textCtrl.text.trim(),
          'rating': rating,
        },
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.commentUpdated), 
          backgroundColor: Colors.green
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${l10n.error}: $e'), 
          backgroundColor: Colors.red
        ),
      );
    }
  }

  Future<void> _deleteComment(String categoryId, Comment c) async {
    final l10n = AppLocalizations.of(context)!;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.confirmDelete),
        content: Text(l10n.confirmDeleteMessage),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false), 
            child: Text(l10n.cancel)
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
      await _repo.deleteCategoryComment(
        categoryId: categoryId, 
        commentId: c.id
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.commentDeleted), 
          backgroundColor: Colors.green
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${l10n.error}: $e'), 
          backgroundColor: Colors.red
        ),
      );
    }
  }

  Future<void> _approveComment(String categoryId, Comment c) async {
    final l10n = AppLocalizations.of(context)!;
    try {
      await _repo.approveComment(categoryId: categoryId, commentId: c.id);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.commentApproved), 
          backgroundColor: Colors.green
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${l10n.error}: $e'), 
          backgroundColor: Colors.red
        ),
      );
    }
  }

  Future<void> _rejectComment(String categoryId, Comment c) async {
    final l10n = AppLocalizations.of(context)!;
    try {
      await _repo.rejectComment(categoryId: categoryId, commentId: c.id);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.commentRejected), 
          backgroundColor: Colors.orange
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${l10n.error}: $e'), 
          backgroundColor: Colors.red
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: const Color(0xFFF2E8D5),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF2E8D5),
        elevation: 0,
        title: Text('${l10n.comments} — ${l10n.categories}'),
        centerTitle: true,
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.black87,
          unselectedLabelColor: Colors.black45,
          indicatorColor: const Color(0xFF6B7C3F),
          isScrollable: true,
          tabs: [
            // 🔥 PENDIENTE COMENTADO TEMPORALMENTE
            // Tab(text: l10n.pending),
            Tab(text: l10n.approved),
            Tab(text: l10n.rejected),
            Tab(text: l10n.allComments),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // 🔥 PENDIENTE COMENTADO TEMPORALMENTE
          // _CommentsTab(
          //   stream: _repo.streamPendingCategories(),
          //   emptyMessage: l10n.noPendingComments,
          //   onApprove: _approveComment,
          //   onReject: _rejectComment,
          //   onEdit: _editComment,
          //   onDelete: _deleteComment,
          // ),
          _CommentsTab(
            stream: _repo.streamApprovedCategories(),
            emptyMessage: l10n.noApprovedComments,
            onApprove: _approveComment,
            onReject: _rejectComment,
            onEdit: _editComment,
            onDelete: _deleteComment,
          ),
          _CommentsTab(
            stream: _repo.streamRejectedCategories(),
            emptyMessage: l10n.noRejectedComments,
            onApprove: _approveComment,
            onReject: _rejectComment,
            onEdit: _editComment,
            onDelete: _deleteComment,
          ),
          _CommentsTab(
            stream: _repo.streamAllCategories(),
            emptyMessage: l10n.noComments,
            onApprove: _approveComment,
            onReject: _rejectComment,
            onEdit: _editComment,
            onDelete: _deleteComment,
          ),
        ],
      ),
    );
  }
}

// ============================================
// TAB CON KEEP ALIVE
// ============================================
class _CommentsTab extends StatefulWidget {
  final Stream<List<Comment>> stream;
  final String emptyMessage;
  final Future<void> Function(String categoryId, Comment c) onApprove;
  final Future<void> Function(String categoryId, Comment c) onReject;
  final Future<void> Function(String categoryId, Comment c) onEdit;
  final Future<void> Function(String categoryId, Comment c) onDelete;

  const _CommentsTab({
    required this.stream,
    required this.emptyMessage,
    required this.onApprove,
    required this.onReject,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  State<_CommentsTab> createState() => _CommentsTabState();
}

class _CommentsTabState extends State<_CommentsTab>
    with AutomaticKeepAliveClientMixin {
  
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    
    final l10n = AppLocalizations.of(context)!;

    return StreamBuilder<List<Comment>>(
      stream: widget.stream,
      builder: (context, snap) {
        // Error
        if (snap.hasError) {
          final error = snap.error.toString();
          
          if (error.contains('index') || error.contains('FAILED_PRECONDITION')) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.storage, size: 48, color: Colors.orange),
                    const SizedBox(height: 16),
                    const Text(
                      '🔍 Índice de Firestore faltante',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Revisa la consola de Flutter para el enlace del índice.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey[700]),
                    ),
                    const SizedBox(height: 16),
                    SelectableText(
                      error,
                      style: const TextStyle(fontSize: 10, color: Colors.red),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            );
          }

          return Center(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 48, color: Colors.red),
                  const SizedBox(height: 16),
                  Text(
                    '${l10n.error}:', 
                    style: const TextStyle(fontWeight: FontWeight.bold)
                  ),
                  const SizedBox(height: 8),
                  SelectableText(
                    error,
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.red),
                  ),
                ],
              ),
            ),
          );
        }

        // Loading
        if (snap.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final items = snap.data ?? const <Comment>[];

        // Empty
        if (items.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.comment_outlined, size: 64, color: Colors.black26),
                const SizedBox(height: 12),
                Text(
                  widget.emptyMessage,
                  style: const TextStyle(color: Colors.black54),
                ),
              ],
            ),
          );
        }

        // Lista
        return ListView.separated(
          itemCount: items.length,
          separatorBuilder: (_, __) => const SizedBox(height: 0),
          itemBuilder: (_, i) {
            final c = items[i];
            final categoryId = c.parentId;
            return CommentTile(
              c: c,
              onApprove: () => widget.onApprove(categoryId, c),
              onReject:  () => widget.onReject(categoryId, c),
              onEdit:    () => widget.onEdit(categoryId, c),
              onDelete:  () => widget.onDelete(categoryId, c),
            );
          },
        );
      },
    );
  }
}