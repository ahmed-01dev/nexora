import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/app_error.dart';
import '../friends/friend_requests_screen.dart';
import '../messaging/messages_screen.dart';
import 'notification_preferences_screen.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  late Future<List<Map<String, dynamic>>> _future;
  static const int _pageSize = 50;
  bool _hasMore = true;
  bool _loadingMore = false;
  int _nextOffset = 0;
  int _generation = 0;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<List<Map<String, dynamic>>> _load({int offset = 0, int? generation}) async {
    final requestGeneration = generation ?? _generation;
    final client = Supabase.instance.client;
    final userId = client.auth.currentUser?.id;
    if (userId == null) {
      throw StateError('انتهت جلسة الدخول. سجّل الدخول مرة تانية.');
    }
    final response = await client.rpc(
      'get_my_notification_page',
      params: {'p_offset': offset, 'p_limit': _pageSize},
    );
    if (client.auth.currentUser?.id != userId) {
      throw StateError('تغير الحساب أثناء تحميل الإشعارات.');
    }
    final rows = response as List;
    if (mounted && requestGeneration == _generation) {
      setState(() {
        _hasMore = rows.length == _pageSize;
        _nextOffset = (offset + rows.length).toInt();
      });
    }
    return List<Map<String, dynamic>>.from(rows);
  }

  Future<void> _loadMore(List<Map<String, dynamic>> current) async {
    if (_loadingMore || !_hasMore) return;
    final generation = _generation;
    setState(() => _loadingMore = true);
    try {
      final additions = await _load(offset: _nextOffset, generation: generation);
      if (!mounted || generation != _generation) return;
      final known = current.map((row) => row['id']).toSet();
      final unique = additions.where((row) => !known.contains(row['id']));
      setState(() {
        _future = Future.value([...current, ...unique]);
        _loadingMore = false;
      });
    } catch (error, stack) {
      AppErrorService.report(error, stack, source: 'load_more_notifications');
      if (mounted && generation == _generation) {
        setState(() => _loadingMore = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppErrorService.message(error))),
        );
      }
    }
  }

  Future<void> _markRead(String id, String userId) async {
    final client = Supabase.instance.client;
    if (client.auth.currentUser?.id != userId) {
      throw StateError('تغير الحساب قبل تحديث الإشعار.');
    }
    await client
        .from('notifications')
        .update({'read_at': DateTime.now().toUtc().toIso8601String()})
        .eq('id', id)
        .eq('recipient_id', userId);
    if (client.auth.currentUser?.id != userId) {
      throw StateError('تغير الحساب أثناء تحديث الإشعار.');
    }
  }

  Future<void> _markAllRead() async {
    final client = Supabase.instance.client;
    final userId = client.auth.currentUser?.id;
    if (userId == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('انتهت جلسة الدخول. سجّل الدخول مرة تانية.')),
        );
      }
      return;
    }
    try {
      await client
          .from('notifications')
          .update({'read_at': DateTime.now().toUtc().toIso8601String()})
          .eq('recipient_id', userId)
          .isFilter('read_at', null);
      if (mounted && client.auth.currentUser?.id == userId) await _refresh();
    } catch (error, stack) {
      AppErrorService.report(error, stack, source: 'mark_all_notifications_read');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(AppErrorService.message(error))));
      }
    }
  }

  Future<void> _open(Map<String, dynamic> row) async {
    final client = Supabase.instance.client;
    final userId = client.auth.currentUser?.id;
    if (userId == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('انتهت جلسة الدخول. سجّل الدخول مرة تانية.')),
        );
      }
      return;
    }
    try {
      await _markRead(row['id'] as String, userId);
      if (!mounted || client.auth.currentUser?.id != userId) return;
      await _refresh();
      if (!mounted || client.auth.currentUser?.id != userId) return;
      final type = row['notification_type'] as String? ?? '';
      final payload = row['payload'] is Map
          ? Map<String, dynamic>.from(row['payload'] as Map)
          : <String, dynamic>{};
      if (type == 'message' && payload['conversation_id'] != null) {
        final actor = row['profiles'] is Map
            ? Map<String, dynamic>.from(row['profiles'] as Map)
            : <String, dynamic>{};
        Navigator.of(context).push(MaterialPageRoute<void>(
          builder: (_) => ChatScreen(
            conversationId: payload['conversation_id'].toString(),
            title: (actor['display_name'] ?? actor['username'] ?? 'محادثة').toString(),
          ),
        ));
      } else if (type == 'friend_request') {
        Navigator.of(context).push(MaterialPageRoute<void>(
          builder: (_) => const FriendRequestsScreen(),
        ));
      }
    } catch (error, stack) {
      AppErrorService.report(error, stack, source: 'open_notification');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(AppErrorService.message(error))));
      }
    }
  }

  String _label(String type) => switch (type) {
    'message' => 'أرسل لك رسالة',
    'friend_request' => 'أرسل طلب صداقة',
    'friend_accepted' => 'قبل طلب الصداقة',
    'follow' => 'بدأ بمتابعتك',
    'like' => 'أعجب بمنشورك',
    'comment' => 'علّق على منشورك',
    'reply' => 'رد على تعليقك',
    'mention' => 'أشار إليك',
    'repost' => 'أعاد نشر محتواك',
    'security' => 'تنبيه أمني',
    _ => 'إشعار جديد',
  };

  Future<void> _refresh() async {
    if (!mounted) return;
    final generation = ++_generation;
    final next = _load(generation: generation);
    setState(() {
      _hasMore = true;
      _loadingMore = false;
      _nextOffset = 0;
      _future = next;
    });
    try {
      await next;
    } catch (error, stack) {
      AppErrorService.report(error, stack, source: 'notifications_refresh');
      // FutureBuilder owns the visible error state; resolve refresh safely.
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('الإشعارات'),
        actions: [
          IconButton(
            tooltip: 'تفضيلات الإشعارات',
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute<void>(builder: (_) => const NotificationPreferencesScreen()),
            ),
            icon: const Icon(Icons.tune),
          ),
          TextButton(onPressed: _markAllRead, child: const Text('قراءة الكل')),
          IconButton(onPressed: _refresh, icon: const Icon(Icons.refresh)),
        ],
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return AppErrorView(title: 'تعذر تحميل الإشعارات', error: snapshot.error, onRetry: _refresh);
          }
          final rows = snapshot.data ?? [];
          if (rows.isEmpty) {
            return const Center(child: Text('مفيش إشعارات لحد دلوقتي.'));
          }
          return RefreshIndicator(
            onRefresh: _refresh,
            child: ListView.separated(
              itemCount: rows.length + (_hasMore || _loadingMore ? 1 : 0),
              separatorBuilder: (_, __) => const Divider(height: 1, indent: 72),
              itemBuilder: (context, index) {
                if (index == rows.length) {
                  if (_loadingMore) {
                    return const Padding(
                      padding: EdgeInsets.all(16),
                      child: Center(child: CircularProgressIndicator()),
                    );
                  }
                  return Center(
                    child: TextButton.icon(
                      onPressed: () => _loadMore(rows),
                      icon: const Icon(Icons.expand_more),
                      label: const Text('تحميل إشعارات أقدم'),
                    ),
                  );
                }
                final row = rows[index];
                final actor = row['profiles'] is Map
                    ? Map<String, dynamic>.from(row['profiles'] as Map)
                    : <String, dynamic>{};
                final unread = row['read_at'] == null;
                final actorName = (actor['display_name'] ?? actor['username'] ?? 'NEXORA').toString();
                final type = row['notification_type'] as String? ?? '';
                return ListTile(
                  onTap: () => _open(row),
                  leading: CircleAvatar(
                    backgroundColor: unread
                        ? Theme.of(context).colorScheme.primaryContainer
                        : Theme.of(context).colorScheme.surfaceContainerHighest,
                    child: Icon(_icon(type)),
                  ),
                  title: Text(actorName, style: TextStyle(fontWeight: unread ? FontWeight.w900 : FontWeight.w600)),
                  subtitle: Text(_label(type)),
                  trailing: unread
                      ? Container(width: 8, height: 8, decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.primary,
                          shape: BoxShape.circle,
                        ))
                      : null,
                );
              },
            ),
          );
        },
      ),
    );
  }

  IconData _icon(String type) => switch (type) {
    'message' => Icons.chat_bubble_outline,
    'friend_request' || 'friend_accepted' => Icons.people_outline,
    'security' => Icons.shield_outlined,
    'like' => Icons.favorite_border,
    'comment' || 'reply' => Icons.mode_comment_outlined,
    _ => Icons.notifications_none,
  };
}
