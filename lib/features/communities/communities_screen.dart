import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/app_error.dart';
import 'community_channels_screen.dart';
import 'community_members_screen.dart';
import '../moderation/report_dialog.dart';

class CommunitiesScreen extends StatefulWidget {
  const CommunitiesScreen({super.key});

  @override
  State<CommunitiesScreen> createState() => _CommunitiesScreenState();
}

class _CommunitiesScreenState extends State<CommunitiesScreen> {
  static const int _pageSize = 30;

  final List<Map<String, dynamic>> _communities = [];
  final Set<String> _joined = {};
  final Map<String, String> _roles = {};
  final Set<String> _busyIds = {};

  bool _loading = true;
  bool _loadingMore = false;
  bool _hasMore = true;
  int _nextOffset = 0;
  int _requestGeneration = 0;
  String? _error;
  String? _loadedUserId;

  @override
  void initState() {
    super.initState();
    _loadFirstPage();
  }

  Future<List<Map<String, dynamic>>> _fetchPage(
    int offset, {
    required int generation,
  }) async {
    final db = Supabase.instance.client;
    final uid = db.auth.currentUser?.id;
    if (uid == null) throw StateError('يجب تسجيل الدخول لعرض المجتمعات.');
    final rows = await db
        .from('communities')
        .select('id,owner_id,name,slug,description,visibility,created_at')
        .order('created_at', ascending: false)
        .order('id', ascending: false)
        .range(offset, offset + _pageSize - 1);

    if (db.auth.currentUser?.id != uid) {
      throw StateError('تغير الحساب أثناء تحميل المجتمعات.');
    }
    final page = List<Map<String, dynamic>>.from(rows);
    if (page.isEmpty) {
      _loadedUserId = uid;
      return page;
    }

    final ids = page.map((row) => row['id'] as String).toList();
    final memberships = await db
        .from('community_members')
        .select('community_id,role')
        .eq('user_id', uid)
        .inFilter('community_id', ids);

    if (!mounted || generation != _requestGeneration) return page;
    if (db.auth.currentUser?.id != uid) {
      throw StateError('تغير الحساب أثناء تحميل عضويات المجتمعات.');
    }
    _loadedUserId = uid;

    for (final membership in memberships) {
      final id = membership['community_id'] as String;
      _joined.add(id);
      _roles[id] = membership['role'] as String;
    }

    for (final community in page) {
      if (community['owner_id'] == uid) {
        final id = community['id'] as String;
        _joined.add(id);
        _roles[id] = 'owner';
      }
    }
    return page;
  }

  Future<void> _loadFirstPage() async {
    final generation = ++_requestGeneration;
    setState(() {
      _loading = true;
      _loadingMore = false;
      _hasMore = true;
      _nextOffset = 0;
      _error = null;
      _communities.clear();
      _joined.clear();
      _roles.clear();
    });

    try {
      final page = await _fetchPage(0, generation: generation);
      if (!mounted || generation != _requestGeneration) return;
      setState(() {
        _communities.addAll(page);
        _nextOffset = page.length;
        _hasMore = page.length == _pageSize;
        _loading = false;
      });
    } catch (error, stack) {
      AppErrorService.report(error, stack, source: 'communities_load');
      if (mounted && generation == _requestGeneration) {
        setState(() {
          _error = AppErrorService.message(error);
          _loading = false;
        });
      }
    }
  }

  Future<void> _loadMore() async {
    if (_loading || _loadingMore || !_hasMore) return;
    final generation = _requestGeneration;
    setState(() => _loadingMore = true);
    try {
      final page = await _fetchPage(_nextOffset, generation: generation);
      if (!mounted || generation != _requestGeneration) return;
      final knownIds = _communities.map((row) => row['id']).toSet();
      final additions = page.where((row) => !knownIds.contains(row['id']));
      setState(() {
        _communities.addAll(additions);
        _nextOffset += page.length;
        _hasMore = page.length == _pageSize;
        _loadingMore = false;
      });
    } catch (error, stack) {
      AppErrorService.report(error, stack, source: 'communities_load_more');
      if (mounted && generation == _requestGeneration) {
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
    final db = Supabase.instance.client;
    final uid = db.auth.currentUser?.id;
    if (uid == null || uid != _loadedUserId ||
        _busyIds.contains(id) || community['owner_id'] == uid) return;

    setState(() => _busyIds.add(id));
    try {
      if (_joined.contains(id)) {
        await db
            .from('community_members')
            .delete()
            .eq('community_id', id)
            .eq('user_id', uid);
        if (mounted && db.auth.currentUser?.id == uid) {
          setState(() {
            _joined.remove(id);
            _roles.remove(id);
          });
        }
      } else {
        await db.from('community_members').insert({
          'community_id': id,
          'user_id': uid,
          'role': 'member',
        });
        if (mounted && db.auth.currentUser?.id == uid) {
          setState(() {
            _joined.add(id);
            _roles[id] = 'member';
          });
        }
      }
    } catch (error, stack) {
      AppErrorService.report(error, stack, source: 'community_membership');
      if (db.auth.currentUser?.id == uid) _showError(error);
    } finally {
      if (mounted) setState(() => _busyIds.remove(id));
    }
  }

  Future<void> _acceptInvite() async {
    final controller = TextEditingController();
    final code = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('الانضمام برمز دعوة'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(
            labelText: 'رمز الدعوة',
            hintText: 'UUID',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('إلغاء'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, controller.text.trim()),
            child: const Text('انضمام'),
          ),
        ],
      ),
    );
    controller.dispose();
    if (code == null || !mounted) return;
    final db = Supabase.instance.client;
    final actorId = db.auth.currentUser?.id;
    if (actorId == null || actorId != _loadedUserId) return;

    final validUuid = RegExp(
      r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$',
    ).hasMatch(code);
    if (!validUuid) {
      _showError(const FormatException('رمز الدعوة غير صحيح.'));
      return;
    }

    try {
      final response = await db.rpc(
        'accept_community_invite',
        params: {'p_invite_code': code},
      );
      if (db.auth.currentUser?.id != actorId) return;
      final rows = List<Map<String, dynamic>>.from(response as List);
      await _loadFirstPage();
      if (!mounted || db.auth.currentUser?.id != actorId) return;
      final name = rows.isNotEmpty
          ? (rows.first['community_name'] ?? 'المجتمع').toString()
          : 'المجتمع';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('تم الانضمام إلى $name')),
      );
    } catch (error, stack) {
      AppErrorService.report(error, stack, source: 'community_invite_accept');
      _showError(error);
    }
  }

  Future<void> _createInvite(Map<String, dynamic> community) async {
    final db = Supabase.instance.client;
    final actorId = db.auth.currentUser?.id;
    if (actorId == null || actorId != _loadedUserId) return;
    try {
      final response = await db.rpc(
        'create_community_invite',
        params: {
          'p_community_id': community['id'],
          'p_expires_in_hours': 168,
          'p_max_uses': 10,
        },
      );
      if (db.auth.currentUser?.id != actorId) return;
      final rows = List<Map<String, dynamic>>.from(response as List);
      if (rows.isEmpty) throw StateError('لم يتم إنشاء رمز الدعوة.');
      final code = rows.first['invite_code'].toString();
      if (!mounted || db.auth.currentUser?.id != actorId) return;

      await showDialog<void>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: const Text('رمز دعوة المجتمع'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'الرمز صالح لمدة 7 أيام، ويمكن استخدامه 10 مرات. شاركه مع الأشخاص المطلوب دعوتهم فقط.',
              ),
              const SizedBox(height: 12),
              SelectableText(
                code,
                textAlign: TextAlign.center,
                style: const TextStyle(fontWeight: FontWeight.w800),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('إغلاق'),
            ),
            FilledButton.icon(
              onPressed: () {
                Clipboard.setData(ClipboardData(text: code));
                Navigator.pop(dialogContext);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('تم نسخ رمز الدعوة')),
                );
              },
              icon: const Icon(Icons.copy),
              label: const Text('نسخ الرمز'),
            ),
          ],
        ),
      );
    } catch (error, stack) {
      AppErrorService.report(error, stack, source: 'community_invite_create');
      if (db.auth.currentUser?.id == actorId) _showError(error);
    }
  }

  Future<void> _revokeInvites(Map<String, dynamic> community) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('إلغاء رموز الدعوة'),
        content: const Text(
          'سيتم إبطال كل رموز الدعوة النشطة لهذا المجتمع. لن يستطيع أي شخص استخدامها بعد الآن.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('رجوع'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('إلغاء الدعوات'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    final db = Supabase.instance.client;
    final actorId = db.auth.currentUser?.id;
    if (actorId == null || actorId != _loadedUserId) return;

    try {
      final count = await db.rpc(
        'revoke_community_invites',
        params: {'p_community_id': community['id']},
      );
      if (!mounted || db.auth.currentUser?.id != actorId) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('تم إلغاء ${count ?? 0} رمز دعوة')),
      );
    } catch (error, stack) {
      AppErrorService.report(error, stack, source: 'community_invite_revoke');
      _showError(error);
    }
  }

  Future<void> _createCommunity() async {
    final result = await showDialog<Map<String, String>>(
      context: context,
      builder: (dialogContext) {
        final name = TextEditingController();
        final slug = TextEditingController();
        final description = TextEditingController();
        String visibility = 'public';
        String? validation;

        return StatefulBuilder(
          builder: (context, refresh) => AlertDialog(
            title: const Text('إنشاء مجتمع'),
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
                  DropdownButtonFormField<String>(
                    value: visibility,
                    decoration: const InputDecoration(labelText: 'خصوصية المجتمع'),
                    items: const [
                      DropdownMenuItem(value: 'public', child: Text('عام — يظهر للجميع')),
                      DropdownMenuItem(value: 'private', child: Text('خاص — بالدعوة فقط')),
                      DropdownMenuItem(value: 'invite_only', child: Text('غير مدرج — بالدعوة فقط')),
                    ],
                    onChanged: (value) => refresh(() => visibility = value ?? 'public'),
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
                      child: Text(
                        validation!,
                        style: const TextStyle(color: Colors.redAccent),
                      ),
                    ),
                  const SizedBox(height: 8),
                  const Text(
                    'المجتمعات الخاصة وغير المدرجة لا تظهر في الاستكشاف، ويمكن للمالك دعوة الأعضاء برمز محدود الاستخدام.',
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
                  final communityName = name.text.trim();
                  final communitySlug = slug.text.trim().toLowerCase();
                  if (communityName.length < 2 || communityName.length > 80) {
                    refresh(() => validation = 'اسم المجتمع لازم يكون من 2 إلى 80 حرفًا.');
                    return;
                  }
                  if (!RegExp(r'^[a-z0-9-]{3,60}$').hasMatch(communitySlug)) {
                    refresh(() => validation = 'الرابط لازم يكون 3–60 حرفًا إنجليزيًا أو رقمًا أو شرطة.');
                    return;
                  }
                  Navigator.pop(dialogContext, {
                    'name': communityName,
                    'slug': communitySlug,
                    'description': description.text.trim(),
                    'visibility': visibility,
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
      final uid = db.auth.currentUser?.id;
      if (uid == null || uid != _loadedUserId) {
        _showError(StateError('تغير الحساب. أعد فتح المجتمعات قبل الإنشاء.'));
        return;
      }
      if (uid == null) {
        _showError(StateError('انتهت جلسة الدخول. سجّل الدخول مرة تانية.'));
        return;
      }
      final created = await db.from('communities').insert({
        'owner_id': uid,
        'name': result['name'],
        'slug': result['slug'],
        'description': result['description'],
        'visibility': result['visibility'],
      }).select('id').single();

      if (db.auth.currentUser?.id != uid) return;
      final id = created['id'] as String;
      try {
        await db.from('community_members').insert({
          'community_id': id,
          'user_id': uid,
          'role': 'owner',
        });
      } catch (_) {
        if (db.auth.currentUser?.id == uid) {
          await db.from('communities').delete().eq('id', id).eq('owner_id', uid);
        }
        rethrow;
      }

      if (db.auth.currentUser?.id != uid) return;
      await _loadFirstPage();
      if (mounted && db.auth.currentUser?.id == uid) {
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
  Widget build(BuildContext context) {
    final currentUserId = Supabase.instance.client.auth.currentUser?.id;
    final viewerChanged = currentUserId == null ||
        (_loadedUserId != null && currentUserId != _loadedUserId);
    return Scaffold(
        appBar: AppBar(
          title: const Text('المجتمعات'),
          actions: [
            IconButton(
              tooltip: 'قبول دعوة',
              onPressed: _acceptInvite,
              icon: const Icon(Icons.confirmation_number_outlined),
            ),
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
        body: viewerChanged
            ? Center(child: TextButton(onPressed: _loadFirstPage, child: const Text('تغير الحساب. أعد تحميل المجتمعات.')))
            : _loading
            ? const Center(child: CircularProgressIndicator())
            : _error != null
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.cloud_off, size: 42),
                        const SizedBox(height: 10),
                        const Text('تعذر تحميل المجتمعات'),
                        TextButton(
                          onPressed: _loadFirstPage,
                          child: const Text('إعادة المحاولة'),
                        ),
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
                              Center(child: Text('لا توجد مجتمعات متاحة حاليًا')),
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
                                  Supabase.instance.client.auth.currentUser?.id;
                              final joined = _joined.contains(id);
                              final role = _roles[id] ?? (isOwner ? 'owner' : 'member');
                              final canManageChannels = isOwner || role == 'moderator';
                              final isPrivate = community['visibility'] != 'public';
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
                                            Chip(label: Text(role == 'moderator' ? 'مشرف' : 'عضو')),
                                        ],
                                      ),
                                      if (isPrivate) ...[
                                        const SizedBox(height: 6),
                                        const Align(
                                          alignment: AlignmentDirectional.centerEnd,
                                          child: Chip(label: Text('خاص / بالدعوة')),
                                        ),
                                      ],
                                      if ((community['description'] ?? '').toString().isNotEmpty) ...[
                                        const SizedBox(height: 10),
                                        Text(community['description'].toString()),
                                      ],
                                      const SizedBox(height: 10),
                                      Wrap(
                                        spacing: 8,
                                        runSpacing: 6,
                                        alignment: WrapAlignment.end,
                                        children: [
                                          if (joined || isOwner)
                                            OutlinedButton.icon(
                                              onPressed: () => Navigator.of(context).push(
                                                MaterialPageRoute<void>(
                                                  builder: (_) => CommunityChannelsScreen(
                                                    communityId: id,
                                                    communityName: community['name'].toString(),
                                                    canManageChannels: canManageChannels,
                                                  ),
                                                ),
                                              ),
                                              icon: const Icon(Icons.forum_outlined),
                                              label: const Text('القنوات'),
                                            ),
                                          if (isOwner && isPrivate) ...[
                                            OutlinedButton.icon(
                                              onPressed: () => _createInvite(community),
                                              icon: const Icon(Icons.key_outlined),
                                              label: const Text('إنشاء دعوة'),
                                            ),
                                            OutlinedButton.icon(
                                              onPressed: () => _revokeInvites(community),
                                              icon: const Icon(Icons.link_off_outlined),
                                              label: const Text('إلغاء الدعوات'),
                                            ),
                                          ],
                                          if (isOwner)
                                            OutlinedButton.icon(
                                              onPressed: () => Navigator.of(context).push(
                                                MaterialPageRoute<void>(
                                                  builder: (_) => CommunityMembersScreen(
                                                    communityId: id,
                                                    communityName: community['name'].toString(),
                                                  ),
                                                ),
                                              ),
                                              icon: const Icon(Icons.manage_accounts_outlined),
                                              label: const Text('إدارة الأعضاء'),
                                            ),
                                          if (!isOwner)
                                            OutlinedButton.icon(
                                              onPressed: () async {
                                                final submitted = await ReportDialog.show(
                                                  context,
                                                  targetType: 'community',
                                                  targetId: id,
                                                );
                                                if (submitted && mounted) {
                                                  ScaffoldMessenger.of(context).showSnackBar(
                                                    const SnackBar(content: Text('تم إرسال البلاغ للمراجعة')),
                                                  );
                                                }
                                              },
                                              icon: const Icon(Icons.flag_outlined, size: 18),
                                              label: const Text('إبلاغ'),
                                            ),
                                          if (!isOwner)
                                            OutlinedButton(
                                              onPressed: busy ? null : () => _toggleMembership(community),
                                              child: busy
                                                  ? const SizedBox.square(
                                                      dimension: 16,
                                                      child: CircularProgressIndicator(strokeWidth: 2),
                                                    )
                                                  : Text(joined ? 'مغادرة المجتمع' : 'انضمام'),
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
};
}
