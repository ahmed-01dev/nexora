import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/app_error.dart';
import '../moderation/report_dialog.dart';

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
  bool _hasMore = true;
  bool _loadingMore = false;
  int _nextOffset = 0;
  int _requestGeneration = 0;
  static const int _pageSize = 100;

  SupabaseClient get _db => Supabase.instance.client;

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

  Future<List<Map<String, dynamic>>> _load({int offset = 0}) async {
    final generation = ++_requestGeneration;
    final rows = await _db
        .from('comments')
        .select('id,post_id,user_id,content,parent_id,created_at,edited_at,deleted_at,profiles!comments_user_id_fkey(id,username,display_name,avatar_url)')
        .eq('post_id', widget.postId)
        .order('created_at', ascending: false)
        .order('id', ascending: false)
        .range(offset, offset + _pageSize - 1);
    if (mounted && generation == _requestGeneration) {
      setState(() {
        _hasMore = rows.length == _pageSize;
        _nextOffset = offset + rows.length;
      });
    }
    return List<Map<String, dynamic>>.from(rows);
  }

  Future<void> _loadMore(List<Map<String, dynamic>> current) async {
    if (_loadingMore || !_hasMore) return;
    final generation = _requestGeneration;
    setState(() => _loadingMore = true);
    try {
      final rows = await _db
          .from('comments')
          .select('id,post_id,user_id,content,parent_id,created_at,edited_at,deleted_at,profiles!comments_user_id_fkey(id,username,display_name,avatar_url)')
          .eq('post_id', widget.postId)
          .order('created_at', ascending: false)
          .order('id', ascending: false)
          .range(_nextOffset, _nextOffset + _pageSize - 1);
      if (!mounted || generation != _requestGeneration) return;
      final knownIds = current.map((comment) => comment['id']).toSet();
      final additions = List<Map<String, dynamic>>.from(rows)
          .where((comment) => !knownIds.contains(comment['id']))
          .toList();
      setState(() {
        _future = Future.value([...current, ...additions]);
        _nextOffset += rows.length;
        _hasMore = rows.length == _pageSize;
        _loadingMore = false;
      });
    } catch (error, stack) {
      AppErrorService.report(error, stack, source: 'load_more_comments');
      if (mounted && generation == _requestGeneration) {
        setState(() => _loadingMore = false);
        _notice(AppErrorService.message(error));
      }
    } finally {
      if (mounted && generation == _requestGeneration && _loadingMore) {
        setState(() => _loadingMore = false);
      }
    }
  }

  Future<void> _refresh() async {
    final next = _load();
    setState(() {
      _nextOffset = 0;
      _loadingMore = false;
      _future = next;
    });
    try {
      await next;
    } catch (error, stack) {
      AppErrorService.report(error, stack, source: 'comments_refresh');
      // FutureBuilder owns the visible error state; resolve pull-to-refresh.
    }
  }

  Future<void> _send() async {
    final content = _composer.text.trim();
    if (_sending || content.isEmpty) return;
    if (content.length > 2000) {
      _notice('التعليق لازم يكون أقل من 2000 حرف.');
      return;
    }
    final userId = _db.auth.currentUser?.id;
    if (userId == null) {
      _notice('انتهت جلسة الدخول. سجّل الدخول مرة تانية.');
      return;
    }
    setState(() => _sending = true);
    try {
      await _db.from('comments').insert({
        'post_id': widget.postId,
        'user_id': userId,
        'content': content,
        'parent_id': _replyTo,
      });
      _composer.clear();
      setState(() {
        _replyTo = null;
        _replyName = null;
        _future = _load();
      });
    } catch (error, stack) {
      AppErrorService.report(error, stack, source: 'create_comment');
      _notice(AppErrorService.message(error));
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  Future<void> _edit(Map<String, dynamic> comment) async {
    final controller = TextEditingController(
      text: (comment['content'] ?? '').toString(),
    );
    final edited = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('تعديل التعليق'),
        content: TextField(
          controller: controller,
          autofocus: true,
          minLines: 2,
          maxLines: 6,
          maxLength: 2000,
          decoration: const InputDecoration(hintText: 'اكتب التعليق بعد التعديل'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('إلغاء'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, controller.text),
            child: const Text('حفظ'),
          ),
        ],
      ),
    );
    controller.dispose();
    if (edited == null) return;
    final content = edited.trim();
    if (content.isEmpty || content.length > 2000) {
      _notice('التعليق لازم يكون من حرف إلى 2000 حرف.');
      return;
    }
    final userId = _db.auth.currentUser?.id;
    if (userId == null) {
      _notice('انتهت جلسة الدخول. سجّل الدخول مرة تانية.');
      return;
    }
    try {
      await _db
          .from('comments')
          .update({
            'content': content,
            'edited_at': DateTime.now().toUtc().toIso8601String(),
          })
          .eq('id', comment['id'] as String)
          .eq('user_id', userId);
      await _refresh();
    } catch (error, stack) {
      AppErrorService.report(error, stack, source: 'edit_comment');
      _notice(AppErrorService.message(error));
    }
  }

  Future<void> _report(Map<String, dynamic> comment) async {
    final submitted = await ReportDialog.show(
      context,
      targetType: 'comment',
      targetId: comment['id'] as String,
    );
    if (submitted && mounted) _notice('تم إرسال البلاغ للمراجعة');
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
    if (confirmed != true || !mounted) return;
    final userId = _db.auth.currentUser?.id;
    if (userId == null) {
      _notice('انتهت جلسة الدخول. سجّل الدخول مرة تانية.');
      return;
    }
    try {
      await _db.from('comments').update({'deleted_at': DateTime.now().toUtc().toIso8601String()}).eq('id', comment['id'] as String).eq('user_id', userId);
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
      padding: EdgeInsetsDirectional.only(start: (depth.clamp(0, 4) * 18.0).toDouble()),
      child: Column(
        children: [
          _CommentTile(
            key: ValueKey(comment['id']),
            comment: comment,
            mine: comment['user_id'] == _db.auth.currentUser?.id,
            onReply: () => setState(() {
              _replyTo = comment['id'] as String;
              _replyName = name;
            }),
            onEdit: () => _edit(comment),
            onDelete: () => _delete(comment),
            onReport: () => _report(comment),
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
                final loadedIds = comments.map((c) => c['id']).toSet();
                // If a reply is newer than its parent and the parent is on an older
                // page, keep it visible at the top level until that parent is loaded.
                final roots = comments
                    .where((c) => c['parent_id'] == null || !loadedIds.contains(c['parent_id']))
                    .toList();
                final replies = <String, List<Map<String, dynamic>>>{};
                for (final comment in comments) {
                  final parent = comment['parent_id'] as String?;
                  if (parent != null && loadedIds.contains(parent)) {
                    (replies[parent] ??= []).add(comment);
                  }
                }
                return RefreshIndicator(
                  onRefresh: _refresh,
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(12, 12, 12, 20),
                    children: [
                      for (final root in roots) _buildCommentThread(root, replies),
                      if (_hasMore || _loadingMore)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          child: Center(
                            child: _loadingMore
                                ? const CircularProgressIndicator()
                                : OutlinedButton(
                                    onPressed: () => _loadMore(comments),
                                    child: const Text('تحميل تعليقات أقدم'),
                                  ),
                          ),
                        ),
                    ],
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
    super.key,
    required this.comment,
    required this.mine,
    required this.onReply,
    required this.onEdit,
    required this.onDelete,
    required this.onReport,
  });

  final Map<String, dynamic> comment;
  final bool mine;
  final VoidCallback onReply;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onReport;

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
      final userId = _db.auth.currentUser?.id;
      if (userId == null) return;
      final row = await _db
          .from('comment_likes')
          .select('comment_id')
          .eq('user_id', userId)
          .eq('comment_id', widget.comment['id'] as String)
          .maybeSingle();
      if (mounted) setState(() => _liked = row != null);
    } catch (error, stack) {
      AppErrorService.report(error, stack, source: 'load_comment_like');
    }
  }

  Future<void> _toggleLike() async {
    if (_likeBusy || widget.comment['deleted_at'] != null) return;
    final userId = _db.auth.currentUser?.id;
    if (userId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('انتهت جلسة الدخول. سجّل الدخول مرة تانية.')),
      );
      return;
    }
    setState(() => _likeBusy = true);
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
    final stamp = date == null
        ? ''
        : '${date.day}/${date.month} • ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}${comment['edited_at'] != null ? ' • معدّل' : ''}';
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
                if (!widget.mine && !deleted)
                  IconButton(
                    tooltip: 'الإبلاغ عن التعليق',
                    visualDensity: VisualDensity.compact,
                    onPressed: widget.onReport,
                    icon: const Icon(Icons.flag_outlined, size: 18),
                  ),
                if (widget.mine && !deleted) ...[
                  IconButton(
                    tooltip: 'تعديل التعليق',
                    visualDensity: VisualDensity.compact,
                    onPressed: widget.onEdit,
                    icon: const Icon(Icons.edit_outlined, size: 18),
                  ),
                  IconButton(
                    tooltip: 'حذف التعليق',
                    visualDensity: VisualDensity.compact,
                    onPressed: widget.onDelete,
                    icon: const Icon(Icons.delete_outline, size: 18),
                  ),
                ],
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
