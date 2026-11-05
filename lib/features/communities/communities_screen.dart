import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/app_error.dart';
import 'community_channels_screen.dart';

class CommunitiesScreen extends StatefulWidget {
  const CommunitiesScreen({super.key});

  @override
  State<CommunitiesScreen> createState() => _CommunitiesScreenState();
}

class _CommunitiesScreenState extends State<CommunitiesScreen> {
  static const int _pageSize = 30;
  final List<Map<String, dynamic>> _communities = [];
  final Set<String> _joined = {};
  final Set<String> _busyIds = {};
  bool _loading = true;
  bool _loadingMore = false;
  bool _hasMore = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadFirstPage();
  }

  Future<void> _loadFirstPage() async {
    setState(() {
      _loading = true;
      _loadingMore = false;
      _hasMore = true;
      _error = null;
      _communities.clear();
      _joined.clear();
    });
    try {
      final page = await _fetchPage(0);
      if (!mounted) return;
      setState(() {
        _communities.addAll(page);
        _hasMore = page.length == _pageSize;
        _loading = false;
      });
    } catch (error, stack) {
      AppErrorService.report(error, stack, source: 'communities_load');
      if (mounted) setState(() {
        _error = AppErrorService.message(error);
        _loading = false;
      });
    }
  }

  Future<List<Map<String, dynamic>>> _fetchPage(int offset) async {
    final db = Supabase.instance.client;
    final uid = db.auth.currentUser!.id;
    final rows = await db
        .from('communities')
        .select('id,owner_id,name,slug,description,visibility,created_at')
        .eq('visibility', 'public')
        .order('created_at', ascending: false)
        .order('id', ascending: false)
        .range(offset, offset + _pageSize - 1);
    final page = List<Map<String, dynamic>>.from(rows);
    if (page.isNotEmpty) {
      final ids = page.map((row) => row['id'] as String).toList();
      final memberships = await db
          .from('community_members')
          .select('community_id')
          .eq('user_id', uid)
          .inFilter('community_id', ids);
      final joined = memberships
          .map((row) => row['community_id'] as String)
          .toSet();
      for (final row in page) {
        if (row['owner_id'] == uid) joined.add(row['id'] as String);
      }
      _joined.addAll(joined);
    }
    return page;
  }

  Future<void> _loadMore() async {
    if (_loadingMore || !_hasMore) return;
    setState(() => _loadingMore = true);
    try {
      final page = await _fetchPage(_communities.length);
      if (!mounted) return;
      setState(() {
        _communities.addAll(page);
        _hasMore = page.length == _pageSize;
        _loadingMore = false;
      });
    } catch (error, stack) {
      AppErrorService.report(error, stack, source: 'communities_load_more');
      if (mounted) {
        setState(() => _loadingMore = false);
        _showError(error);
      }
    }
  }

  void _showError(Object error) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(AppErrorService.message(error))),
    );
  }

  Future<void> _toggleMembership(Map<String, dynamic> community) async {
    final id = community['id'] as String;
    final uid = Supabase.instance.client.auth.currentUser!.id;
    if (_busyIds.contains(id) || community['owner_id'] == uid) return;
    setState(() => _busyIds.add(id));
    try {
      if (_joined.contains(id)) {
        await Supabase.instance.client
            .from('community_members')
            .delete()
            .eq('community_id', id)
            .eq('user_id', uid);
        if (mounted) setState(() => _joined.remove(id));
      } else {
        await Supabase.instance.client.from('community_members').insert({
          'community_id': id,
          'user_id': uid,
          'role': 'member',
        });
        if (mounted) setState(() => _joined.add(id));
      }
    } catch (error, stack) {
      AppErrorService.report(error, stack, source: 'community_membership');
      _showError(error);
    } finally {
      if (mounted) setState(() => _busyIds.remove(id));
    }
  }

  Future<void> _createCommunity() async {
    final result = await showDialog<Map<String, String>>(
      context: context,
      builder: (dialogContext) {
        final name = TextEditingController();
        final slug = TextEditingController();
        final description = TextEditingController();
        String? validation;
        return StatefulBuilder(
          builder: (context, refresh) => AlertDialog(
            title: const Text('إنشاء مجتمع عام'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: name,
                    maxLength: 80,
                    decoration: const InputDecoration(labelText: 'اسم المجتمع'),
                    onChanged: (value) {
                      if (slug.text.isEmpty || slug.text.startsWith('community-')) {
                        final generated = value
                            .toLowerCase()
                            .replaceAll(RegExp(r'[^a-z0-9]+'), '-')
                            .replaceAll(RegExp(r'^-+|-+$'), '');
                        slug.text = generated.length >= 3
                            ? generated.substring(0, generated.length > 60 ? 60 : generated.length)
                            : 'community-${DateTime.now().millisecondsSinceEpoch}';
                      }
                    },
                  ),
                  TextField(
                    controller: slug,
                    maxLength: 60,
                    decoration: const InputDecoration(labelText: 'رابط المجتمع (بالإنجليزية)'),
                  ),
                  TextField(
                    controller: description,
                    maxLength: 500,
                    maxLines: 3,
                    decoration: const InputDecoration(labelText: 'وصف المجتمع'),
                  ),
                  if (validation != null)
                    Align(
                      alignment: AlignmentDirectional.centerStart,
                      child: Text(validation!, style: const TextStyle(color: Colors.redAccent)),
                    ),
                  const SizedBox(height: 8),
                  const Text(
                    'المجتمعات الخاصة والدعوات غير مفعّلة في الواجهة حاليًا؛ الإنشاء متاح للمجتمعات العامة فقط.',
                    style: TextStyle(fontSize: 12, color: Colors.white70),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext),
                child: const Text('إلغاء'),
              ),
              FilledButton(
                onPressed: () {
                  final n = name.text.trim();
                  final s = slug.text.trim().toLowerCase();
                  if (n.length < 2 || n.length > 80) {
                    refresh(() => validation = 'اسم المجتمع لازم يكون من 2 إلى 80 حرفًا.');
                    return;
                  }
                  if (!RegExp(r'^[a-z0-9-]{3,60}$').hasMatch(s)) {
                    refresh(() => validation = 'الرابط لازم يكون 3–60 حرفًا إنجليزيًا أو رقمًا أو شرطة.');
                    return;
                  }
                  Navigator.pop(dialogContext, {
                    'name': n,
                    'slug': s,
                    'description': description.text.trim(),
                  });
                },
                child: const Text('إنشاء'),
              ),
            ],
          ),
        );
      },
    );
    if (result == null || !mounted) return;
    try {
      final db = Supabase.instance.client;
      final uid = db.auth.currentUser!.id;
      final created = await db.from('communities').insert({
        'owner_id': uid,
        'name': result['name'],
        'slug': result['slug'],
        'description': result['description'],
        'visibility': 'public',
      }).select('id').single();
      final id = created['id'] as String;
      try {
        await db.from('community_members').insert({
          'community_id': id,
          'user_id': uid,
          'role': 'owner',
        });
      } catch (_) {
        await db.from('communities').delete().eq('id', id);
        rethrow;
      }
      await _loadFirstPage();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تم إنشاء المجتمع')),
        );
      }
    } catch (error, stack) {
      AppErrorService.report(error, stack, source: 'community_create');
      _showError(error);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(
          title: const Text('المجتمعات'),
          actions: [
            IconButton(
              tooltip: 'تحديث',
              onPressed: _loading ? null : _loadFirstPage,
              icon: const Icon(Icons.refresh),
            ),
            IconButton(
              tooltip: 'إنشاء مجتمع',
              onPressed: _createCommunity,
              icon: const Icon(Icons.add),
            ),
          ],
        ),
        body: _loading
            ? const Center(child: CircularProgressIndicator())
            : _error != null
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.cloud_off, size: 42),
                        const SizedBox(height: 10),
                        const Text('تعذر تحميل المجتمعات'),
                        TextButton(onPressed: _loadFirstPage, child: const Text('إعادة المحاولة')),
                      ],
                    ),
                  )
                : RefreshIndicator(
                    onRefresh: _loadFirstPage,
                    child: _communities.isEmpty
                        ? ListView(
                            physics: const AlwaysScrollableScrollPhysics(),
                            children: const [
                              SizedBox(height: 120),
                              Icon(Icons.groups_outlined, size: 56),
                              SizedBox(height: 12),
                              Center(child: Text('لسه مفيش مجتمعات عامة')),
                            ],
                          )
                        : ListView.separated(
                            padding: const EdgeInsets.all(16),
                            itemCount: _communities.length + (_hasMore || _loadingMore ? 1 : 0),
                            separatorBuilder: (_, __) => const SizedBox(height: 12),
                            itemBuilder: (context, index) {
                              if (index == _communities.length) {
                                return Center(
                                  child: TextButton(
                                    onPressed: _loadingMore ? null : _loadMore,
                                    child: _loadingMore
                                        ? const SizedBox.square(
                                            dimension: 18,
                                            child: CircularProgressIndicator(strokeWidth: 2),
                                          )
                                        : const Text('تحميل المزيد'),
                                  ),
                                );
                              }
                              final community = _communities[index];
                              final id = community['id'] as String;
                              final isOwner = community['owner_id'] ==
                                  Supabase.instance.client.auth.currentUser!.id;
                              final joined = _joined.contains(id);
                              final busy = _busyIds.contains(id);
                              return Card(
                                child: Padding(
                                  padding: const EdgeInsets.all(16),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.stretch,
                                    children: [
                                      Row(
                                        children: [
                                          const CircleAvatar(child: Icon(Icons.groups_2_outlined)),
                                          const SizedBox(width: 12),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  (community['name'] ?? '').toString(),
                                                  style: const TextStyle(fontWeight: FontWeight.w800),
                                                ),
                                                Text(
                                                  '/${community['slug']}',
                                                  style: const TextStyle(color: Colors.white54, fontSize: 12),
                                                ),
                                              ],
                                            ),
                                          ),
                                          if (isOwner)
                                            const Chip(label: Text('المالك'))
                                          else if (joined)
                                            const Chip(label: Text('عضو')),
                                        ],
                                      ),
                                      if ((community['description'] ?? '').toString().isNotEmpty) ...[
                                        const SizedBox(height: 10),
                                        Text(community['description'].toString()),
                                      ],
                                      const SizedBox(height: 10),
                                      Row(
                                        children: [
                                          if (joined || isOwner)
                                            Expanded(
                                              child: OutlinedButton.icon(
                                                onPressed: () => Navigator.of(context).push(
                                                  MaterialPageRoute<void>(
                                                    builder: (_) => CommunityChannelsScreen(
                                                      communityId: id,
                                                      communityName: community['name'].toString(),
                                                      isOwner: isOwner,
                                                    ),
                                                  ),
                                                ),
                                                icon: const Icon(Icons.forum_outlined),
                                                label: const Text('القنوات'),
                                              ),
                                            ),
                                          if (joined && !isOwner) const SizedBox(width: 8),
                                          if (isOwner)
                                            const Expanded(child: Text('أنت تدير هذا المجتمع'))
                                          else
                                            Expanded(
                                              child: OutlinedButton(
                                                onPressed: busy ? null : () => _toggleMembership(community),
                                                child: busy
                                                    ? const SizedBox.square(
                                                        dimension: 16,
                                                        child: CircularProgressIndicator(strokeWidth: 2),
                                                      )
                                                    : Text(joined ? 'مغادرة المجتمع' : 'انضمام'),
                                              ),
                                            ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                  ),
      );
}
