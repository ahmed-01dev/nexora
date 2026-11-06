import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/app_error.dart';

class FriendRequestsScreen extends StatefulWidget {
  const FriendRequestsScreen({super.key});

  @override
  State<FriendRequestsScreen> createState() => _FriendRequestsScreenState();
}

class _FriendRequestsScreenState extends State<FriendRequestsScreen> {
  late Future<Map<String, List<Map<String, dynamic>>>> _future;
  final Set<String> _busyIds = {};

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<Map<String, List<Map<String, dynamic>>>> _load() async {
    final client = Supabase.instance.client;
    final me = client.auth.currentUser?.id;
    if (me == null) throw StateError('انتهت جلسة الدخول.');
    final incoming = await client
        .from('friendships')
        .select('id,requester_id,profiles!friendships_requester_id_fkey(id,username,display_name)')
        .eq('addressee_id', me)
        .eq('status', 'pending')
        .order('created_at', ascending: false);
    final outgoing = await client
        .from('friendships')
        .select('id,addressee_id,profiles!friendships_addressee_id_fkey(id,username,display_name)')
        .eq('requester_id', me)
        .eq('status', 'pending')
        .order('created_at', ascending: false);
    return {
      'incoming': List<Map<String, dynamic>>.from(incoming),
      'outgoing': List<Map<String, dynamic>>.from(outgoing),
    };
  }

  Future<void> _act(String function, String id) async {
    if (_busyIds.contains(id)) return;
    setState(() => _busyIds.add(id));
    try {
      await Supabase.instance.client.rpc(function, params: {'p_request_id': id});
      if (mounted) setState(() => _future = _load());
    } catch (error, stack) {
      AppErrorService.report(error, stack, source: 'friend_request_action');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppErrorService.message(error))),
        );
      }
    } finally {
      if (mounted) setState(() => _busyIds.remove(id));
    }
  }

  Future<void> _refresh() async {
    final next = _load();
    setState(() => _future = next);
    try {
      await next;
    } catch (error, stack) {
      AppErrorService.report(error, stack, source: 'friend_requests_refresh');
      // FutureBuilder renders the error state; keep RefreshIndicator from
      // leaking an unhandled refresh exception.
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('طلبات الصداقة')),
      body: FutureBuilder<Map<String, List<Map<String, dynamic>>>>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return AppErrorView(title: 'تعذر تحميل الطلبات', error: snapshot.error, onRetry: _refresh);
          }
          final incoming = snapshot.data?['incoming'] ?? [];
          final outgoing = snapshot.data?['outgoing'] ?? [];
          if (incoming.isEmpty && outgoing.isEmpty) {
            return RefreshIndicator(
              onRefresh: _refresh,
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                children: const [
                  SizedBox(height: 140),
                  Center(child: Text('مفيش طلبات صداقة حاليًا.')),
                ],
              ),
            );
          }
          return RefreshIndicator(
            onRefresh: _refresh,
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                if (incoming.isNotEmpty) ...[
                  const Text('طلبات واردة', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w900)),
                  const SizedBox(height: 8),
                  for (final row in incoming)
                    _FriendRequestTile(
                      row: row,
                      incoming: true,
                      busy: _busyIds.contains(row['id']),
                      onAccept: () => _act('accept_friend_request', row['id'] as String),
                      onDecline: () => _act('decline_friend_request', row['id'] as String),
                    ),
                  const SizedBox(height: 20),
                ],
                if (outgoing.isNotEmpty) ...[
                  const Text('طلبات أرسلتها', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w900)),
                  const SizedBox(height: 8),
                  for (final row in outgoing)
                    _FriendRequestTile(
                      row: row,
                      incoming: false,
                      busy: _busyIds.contains(row['id']),
                      onDecline: () => _act('cancel_friend_request', row['id'] as String),
                    ),
                ],
              ],
            ),
          );
        },
      ),
    );
  }
}

class _FriendRequestTile extends StatelessWidget {
  const _FriendRequestTile({
    required this.row,
    required this.incoming,
    required this.onDecline,
    this.onAccept,
    this.busy = false,
  });

  final Map<String, dynamic> row;
  final bool incoming;
  final VoidCallback onDecline;
  final VoidCallback? onAccept;
  final bool busy;

  @override
  Widget build(BuildContext context) {
    final profile = row['profiles'] is Map
        ? Map<String, dynamic>.from(row['profiles'] as Map)
        : <String, dynamic>{};
    final profileHidden = profile.isEmpty;
    final name = profileHidden
        ? 'حساب خاص'
        : (profile['display_name'] ?? profile['username'] ?? 'مستخدم').toString();
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            const CircleAvatar(child: Icon(Icons.person_outline)),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(name, style: const TextStyle(fontWeight: FontWeight.w800)),
                  Text(profileHidden ? 'الملف الشخصي غير متاح' : '@${profile['username'] ?? 'user'}', style: const TextStyle(color: Colors.grey, fontSize: 12)),
                ],
              ),
            ),
            if (busy)
              const SizedBox.square(
                dimension: 22,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            else ...[
              if (incoming)
                IconButton(
                  tooltip: 'قبول',
                  onPressed: onAccept,
                  icon: const Icon(Icons.check_circle_outline),
                ),
              IconButton(
                tooltip: incoming ? 'رفض' : 'إلغاء الطلب',
                onPressed: onDecline,
                icon: Icon(incoming ? Icons.close : Icons.cancel_outlined),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class FriendRequestAction extends StatefulWidget {
  const FriendRequestAction({super.key, required this.otherUserId});
  final String otherUserId;

  @override
  State<FriendRequestAction> createState() => _FriendRequestActionState();
}

class _FriendRequestActionState extends State<FriendRequestAction> {
  Map<String, dynamic>? _request;
  bool _loading = true;
  bool _busy = false;
  String? _myId;
  int _loadGeneration = 0;
  int _actionGeneration = 0;

  @override
  void initState() {
    super.initState();
    _myId = Supabase.instance.client.auth.currentUser?.id;
    _load();
  }

  @override
  void didUpdateWidget(covariant FriendRequestAction oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.otherUserId != widget.otherUserId) {
      _actionGeneration++;
      _request = null;
      _busy = false;
      _load();
    }
  }

  Future<void> _load() async {
    final generation = ++_loadGeneration;
    final targetId = widget.otherUserId;
    final myId = _myId;
    if (myId == null) {
      if (mounted) setState(() => _loading = false);
      return;
    }
    if (mounted) setState(() => _loading = true);
    try {
      final client = Supabase.instance.client;
      final outgoing = await client
          .from('friendships')
          .select('id,requester_id,addressee_id,status')
          .eq('requester_id', myId)
          .eq('addressee_id', targetId)
          .maybeSingle();
      final incoming = outgoing == null
          ? await client
              .from('friendships')
              .select('id,requester_id,addressee_id,status')
              .eq('requester_id', targetId)
              .eq('addressee_id', myId)
              .maybeSingle()
          : null;
      if (mounted && generation == _loadGeneration) {
        setState(() { _request = outgoing ?? incoming; _loading = false; });
      }
    } catch (error, stack) {
      AppErrorService.report(error, stack, source: 'load_friendship');
      if (mounted && generation == _loadGeneration) {
        setState(() => _loading = false);
      }
    }
  }

  Future<void> _perform() async {
    if (_busy) return;
    final generation = ++_actionGeneration;
    final targetId = widget.otherUserId;
    setState(() => _busy = true);
    try {
      final request = _request;
      if (request == null ||
          request['status'] == 'declined' ||
          request['status'] == 'cancelled') {
        await Supabase.instance.client.rpc(
          'request_friend',
          params: {'p_addressee_id': targetId},
        );
      } else if (request['status'] == 'accepted') {
        await Supabase.instance.client.rpc(
          'remove_friend',
          params: {'p_other_user_id': targetId},
        );
      } else if (request['requester_id'] == _myId) {
        await Supabase.instance.client.rpc(
          'cancel_friend_request',
          params: {'p_request_id': request['id']},
        );
      } else {
        await Supabase.instance.client.rpc(
          'accept_friend_request',
          params: {'p_request_id': request['id']},
        );
      }
      if (mounted &&
          generation == _actionGeneration &&
          widget.otherUserId == targetId) {
        await _load();
      }
    } catch (error, stack) {
      AppErrorService.report(error, stack, source: 'friendship_action');
      if (mounted &&
          generation == _actionGeneration &&
          widget.otherUserId == targetId) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppErrorService.message(error))),
        );
      }
    } finally {
      if (mounted && generation == _actionGeneration) {
        setState(() => _busy = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final status = _request?['status'] as String?;
    final incoming = status == 'pending' && _request?['requester_id'] != _myId;
    final tooltip = _loading
        ? 'تحميل حالة الصداقة'
        : status == 'accepted'
            ? 'إزالة الصديق'
            : incoming
                ? 'قبول طلب الصداقة'
                : status == 'pending'
                    ? 'إلغاء طلب الصداقة'
                    : 'إضافة صديق';
    return IconButton(
      tooltip: tooltip,
      onPressed: _loading || _busy ? null : _perform,
      icon: _loading || _busy
          ? const SizedBox.square(dimension: 18, child: CircularProgressIndicator(strokeWidth: 2))
          : Icon(status == 'accepted'
              ? Icons.person
              : incoming
                  ? Icons.person_add_alt_1
                  : status == 'pending'
                      ? Icons.person_add_disabled
                      : Icons.person_add_alt),
    );
  }
}
