import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/app_error.dart';

class CommentsScreen extends StatefulWidget {
  const CommentsScreen({super.key, required this.postId});
  final String postId;

  @override
  State<CommentsScreen> createState() => _CommentsScreenState();
}

class _CommentsScreenState extends State<CommentsScreen> {
  final _composer = TextEditingController();
  late Future<List<Map<String, dynamic>>> _future;
  String? _replyTo;
  String? _replyName;
  bool _sending = false;

  SupabaseClient get _db => Supabase.instance.client;
  String get _myId => _db.auth.currentUser!.id;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  @override
  void dispose() {
    _composer.dispose();
    super.dispose();
  }

  Future<List<Map<String, dynamic>>> _load() async {
    final rows = await _db
        .from('comments')
        .select('id,post_id,user_id,content,parent_id,created_at,edited_at,deleted_at,profiles!comments_user_id_fkey(id,username,display_name,avatar_url)')
        .eq('post_id', widget.postId)
        .order('created_at', ascending: true)
        .limit(100);
    return List<Map<String, dynamic>>.from(rows);
  }

  Future<void> _refresh() async {
    setState(() => _future = _load());
    await _future;
  }

  Future<void> _send() async {
    final content = _composer.text.trim();
    if (_sending || content.isEmpty) return;
    if (content.length > 2000) {
      _notice('التعليق لازم يكون أقل من 2000 حرف.');
      return;
    }
    setState(() => _sending = true);
    try {
      await _db.from('comments').insert({
        'post_id': widget.postId,
        'user_id': _myId,
        'content': content,
        'parent_id': _replyTo,
      });
      _composer.clear();
      setState(() {
        _replyTo = null;
        _replyName = null;
        _future = _load();
      });
      await _future;
    } catch (error, stack) {
      AppErrorService.report(error, stack, source: 'create_comment');
      _notice(AppErrorService.message(error));
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  Future<void> _delete(Map<String, dynamic> comment) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('حذف التعليق؟'),
        content: const Text('سيظهر التعليق كمحذوف مع الاحتفاظ بسياق الردود.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('إلغاء')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('حذف')),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await _db.from('comments').update({'deleted_at': DateTime.now().toUtc().toIso8601String()}).eq('id', comment['id'] as String).eq('user_id', _myId);
      await _refresh();
    } catch (error, stack) {
      AppErrorService.report(error, stack, source: 'delete_comment');
      _notice(AppErrorService.message(error));
    }
  }

  void _notice(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  Widget _buildCommentThread(
    Map<String, dynamic> comment,
    Map<String, List<Map<String, dynamic>>> replies, {
    int depth = 0,
  }) {
    final profile = comment['profiles'];
    final name = profile is Map
        ? (profile['display_name'] ?? profile['username'] ?? 'مستخدم').toString()
        : 'مستخدم';
    final children = replies[comment['id']] ?? const <Map<String, dynamic>>[];
    return Padding(
      padding: EdgeInsetsDirectional.only(start: depth.clamp(0, 4) * 18.0),
      child: Column(
        children: [
          _CommentTile(
            comment: comment,
            mine: comment['user_id'] == _myId,
            onReply: () => setState(() {
              _replyTo = comment['id'] as String;
              _replyName = name;
            }),
            onDelete: () => _delete(comment),
          ),
          for (final child in children)
            _buildCommentThread(child, replies, depth: depth + 1),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('التعليقات')),
      body: Column(
        children: [
          Expanded(
            child: FutureBuilder<List<Map<String, dynamic>>>(
              future: _future,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return AppErrorView(
                    title: 'تعذر تحميل التعليقات',
                    error: snapshot.error,
                    onRetry: _refresh,
                  );
                }
                final comments = snapshot.data ?? [];
                if (comments.isEmpty) {
                  return RefreshIndicator(
                    onRefresh: _refresh,
                    child: ListView(
                      children: const [
                        SizedBox(height: 100),
                        Center(child: Text('لسه مفيش تعليقات. ابدأ الحوار.')),
                      ],
                    ),
                  );
                }
                final roots = comments.where((c) => c['parent_id'] == null).toList();
                final replies = <String, List<Map<String, dynamic>>>{};
                for (final comment in comments) {
                  final parent = comment['parent_id'] as String?;
                  if (parent != null) {
                    (replies[parent] ??= []).add(comment);
                  }
                }
                return RefreshIndicator(
                  onRefresh: _refresh,
                  child: ListView.builder(
                    padding: const EdgeInsets.fromLTRB(12, 12, 12, 20),
                    itemCount: roots.length,
                    itemBuilder: (context, index) =>
                        _buildCommentThread(roots[index], replies),
                  ),
                );
              },
            ),
          ),
          SafeArea(
            top: false,
            child: Container(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                border: Border(top: BorderSide(color: Theme.of(context).dividerColor)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (_replyTo != null)
                    Row(
                      children: [
                        Expanded(child: Text('الرد على $_replyName', style: const TextStyle(fontSize: 12, color: Colors.grey))),
                        IconButton(
                          tooltip: 'إلغاء الرد',
                          onPressed: () => setState(() { _replyTo = null; _replyName = null; }),
                          icon: const Icon(Icons.close, size: 18),
                        ),
                      ],
                    ),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _composer,
                          minLines: 1,
                          maxLines: 4,
                          maxLength: 2000,
                          textInputAction: TextInputAction.newline,
                          decoration: const InputDecoration(
                            hintText: 'اكتب تعليقك...',
                            counterText: '',
                            border: OutlineInputBorder(),
                            contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 11),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton.filled(
                        tooltip: 'إرسال التعليق',
                        onPressed: _sending ? null : _send,
                        icon: _sending
                            ? const SizedBox.square(dimension: 18, child: CircularProgressIndicator(strokeWidth: 2))
                            : const Icon(Icons.send),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CommentTile extends StatefulWidget {
  const _CommentTile({
    required this.comment,
    required this.mine,
    required this.onReply,
    required this.onDelete,
  });

  final Map<String, dynamic> comment;
  final bool mine;
  final VoidCallback onReply;
  final VoidCallback onDelete;

  @override
  State<_CommentTile> createState() => _CommentTileState();
}

class _CommentTileState extends State<_CommentTile> {
  bool _liked = false;
  bool _likeBusy = false;

  SupabaseClient get _db => Supabase.instance.client;

  @override
  void initState() {
    super.initState();
    if (widget.comment['deleted_at'] == null) _loadLike();
  }

  Future<void> _loadLike() async {
    try {
      final row = await _db
          .from('comment_likes')
          .select('comment_id')
          .eq('user_id', _db.auth.currentUser!.id)
          .eq('comment_id', widget.comment['id'] as String)
          .maybeSingle();
      if (mounted) setState(() => _liked = row != null);
    } catch (error, stack) {
      AppErrorService.report(error, stack, source: 'load_comment_like');
    }
  }

  Future<void> _toggleLike() async {
    if (_likeBusy || widget.comment['deleted_at'] != null) return;
    setState(() => _likeBusy = true);
    final userId = _db.auth.currentUser!.id;
    final commentId = widget.comment['id'] as String;
    try {
      if (_liked) {
        await _db.from('comment_likes')
            .delete()
            .eq('user_id', userId)
            .eq('comment_id', commentId);
        if (mounted) setState(() => _liked = false);
      } else {
        await _db.from('comment_likes').insert({
          'user_id': userId,
          'comment_id': commentId,
        });
        if (mounted) setState(() => _liked = true);
      }
    } catch (error, stack) {
      AppErrorService.report(error, stack, source: 'toggle_comment_like');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppErrorService.message(error))),
        );
      }
    } finally {
      if (mounted) setState(() => _likeBusy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final comment = widget.comment;
    final profile = comment['profiles'];
    final name = profile is Map
        ? (profile['display_name'] ?? profile['username'] ?? 'مستخدم NEXORA').toString()
        : 'مستخدم NEXORA';
    final deleted = comment['deleted_at'] != null;
    final date = DateTime.tryParse((comment['created_at'] ?? '').toString())?.toLocal();
    final stamp = date == null ? '' : '${date.day}/${date.month} • ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const CircleAvatar(radius: 15, child: Icon(Icons.person_outline, size: 17)),
                const SizedBox(width: 8),
                Expanded(child: Text(name, style: const TextStyle(fontWeight: FontWeight.w800))),
                Text(stamp, style: const TextStyle(fontSize: 10, color: Colors.grey)),
                if (widget.mine && !deleted)
                  IconButton(
                    tooltip: 'حذف التعليق',
                    visualDensity: VisualDensity.compact,
                    onPressed: widget.onDelete,
                    icon: const Icon(Icons.delete_outline, size: 18),
                  ),
              ],
            ),
            const SizedBox(height: 5),
            Text(
              deleted ? 'تم حذف هذا التعليق' : (comment['content'] ?? '').toString(),
              style: TextStyle(
                color: deleted ? Colors.grey : null,
                fontStyle: deleted ? FontStyle.italic : FontStyle.normal,
                height: 1.5,
              ),
            ),
            if (!deleted)
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton.icon(
                    onPressed: _likeBusy ? null : _toggleLike,
                    icon: _likeBusy
                        ? const SizedBox.square(dimension: 13, child: CircularProgressIndicator(strokeWidth: 2))
                        : Icon(_liked ? Icons.favorite : Icons.favorite_border, size: 17),
                    label: Text(_liked ? 'أعجبك' : 'إعجاب'),
                  ),
                  TextButton.icon(
                    onPressed: widget.onReply,
                    icon: const Icon(Icons.reply, size: 16),
                    label: const Text('رد'),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}
