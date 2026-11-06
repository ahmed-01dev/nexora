import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/app_error.dart';

class CommunityMembersScreen extends StatefulWidget {
  const CommunityMembersScreen({
    super.key,
    required this.communityId,
    required this.communityName,
  });

  final String communityId;
  final String communityName;

  @override
  State<CommunityMembersScreen> createState() => _CommunityMembersScreenState();
}

class _CommunityMembersScreenState extends State<CommunityMembersScreen> {
  bool _loading = true;
  String? _error;
  final Set<String> _busy = {};
  List<Map<String, dynamic>> _members = [];
  String? _loadedUserId;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final client = Supabase.instance.client;
      final userId = client.auth.currentUser?.id;
      if (userId == null) {
        throw StateError('انتهت جلسة الدخول. سجّل الدخول مرة تانية.');
      }
      final rows = await client
          .from('community_members')
          .select('user_id,role,joined_at,profiles!community_members_user_id_fkey(id,username,display_name,avatar_url)')
          .eq('community_id', widget.communityId)
          .order('joined_at');
      if (!mounted) return;
      if (client.auth.currentUser?.id != userId) {
        setState(() {
          _members = [];
          _error = 'تغير الحساب أثناء تحميل الأعضاء.';
          _loading = false;
        });
        return;
      }
      setState(() {
        _loadedUserId = userId;
        _members = List<Map<String, dynamic>>.from(rows);
        _loading = false;
      });
    } catch (error, stack) {
      AppErrorService.report(error, stack, source: 'community_members_load');
      if (mounted) setState(() {
        _error = AppErrorService.message(error);
        _loading = false;
      });
    }
  }

  Future<void> _setRole(String userId, String role) async {
    final client = Supabase.instance.client;
    final actorId = client.auth.currentUser?.id;
    if (actorId == null || actorId != _loadedUserId || _busy.contains(userId)) {
      _showError(StateError('انتهت الجلسة أو تغير الحساب. حدّث القائمة.'));
      return;
    }
    setState(() => _busy.add(userId));
    try {
      await client
          .from('community_members')
          .update({'role': role})
          .eq('community_id', widget.communityId)
          .eq('user_id', userId);
      if (client.auth.currentUser?.id != actorId) return;
      await _load();
    } catch (error, stack) {
      AppErrorService.report(error, stack, source: 'community_member_role');
      _showError(error);
    } finally {
      if (mounted) setState(() => _busy.remove(userId));
    }
  }

  Future<void> _removeMember(String userId, String label) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('إزالة العضو؟'),
        content: Text('هل تريد إزالة $label من المجتمع؟ سيتم سحب وصوله إلى القنوات أيضًا.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('إلغاء'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('إزالة'),
          ),
        ],
      ),
    );
    final client = Supabase.instance.client;
    final actorId = client.auth.currentUser?.id;
    if (confirmed != true || !mounted || actorId == null ||
        actorId != _loadedUserId || _busy.contains(userId)) return;
    setState(() => _busy.add(userId));
    try {
      await client
          .from('community_members')
          .delete()
          .eq('community_id', widget.communityId)
          .eq('user_id', userId);
      if (mounted && client.auth.currentUser?.id == actorId) {
        setState(() => _members.removeWhere((row) => row['user_id'] == userId));
      }
    } catch (error, stack) {
      AppErrorService.report(error, stack, source: 'community_member_remove');
      _showError(error);
    } finally {
      if (mounted) setState(() => _busy.remove(userId));
    }
  }

  void _showError(Object error) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(AppErrorService.message(error))),
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentUserId = Supabase.instance.client.auth.currentUser?.id;
    final viewerChanged = currentUserId == null || currentUserId != _loadedUserId;
    return Scaffold(
      appBar: AppBar(
        title: Text('أعضاء ${widget.communityName}'),
        actions: [
          IconButton(
            tooltip: 'تحديث',
            onPressed: _loading ? null : _load,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : viewerChanged
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text('تغير الحساب. حدّث قائمة الأعضاء.'),
                      TextButton(onPressed: _load, child: const Text('تحديث')),
                    ],
                  ),
                )
              : _error != null
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text('تعذر تحميل الأعضاء'),
                      TextButton(onPressed: _load, child: const Text('إعادة المحاولة')),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _load,
                  child: _members.isEmpty
                      ? ListView(
                          physics: const AlwaysScrollableScrollPhysics(),
                          children: const [
                            SizedBox(height: 120),
                            Center(child: Text('لا يوجد أعضاء مسجلون')),
                          ],
                        )
                      : ListView.separated(
                          padding: const EdgeInsets.all(12),
                          itemCount: _members.length,
                          separatorBuilder: (_, __) => const Divider(height: 1),
                          itemBuilder: (context, index) {
                            final member = _members[index];
                            final userId = member['user_id'] as String;
                            final profile = member['profiles'] is Map
                                ? Map<String, dynamic>.from(member['profiles'] as Map)
                                : <String, dynamic>{};
                            final role = (member['role'] ?? 'member').toString();
                            final isSelf = userId == currentUserId;
                            final isOwner = role == 'owner';
                            final label = (profile['display_name'] ??
                                    profile['username'] ??
                                    'عضو')
                                .toString();
                            return ListTile(
                              leading: CircleAvatar(
                                child: Text(label.isNotEmpty ? label.substring(0, 1) : '?'),
                              ),
                              title: Text(label),
                              subtitle: Text('@${profile['username'] ?? 'user'} · ${role == 'owner' ? 'مالك' : role == 'moderator' ? 'مشرف' : 'عضو'}'),
                              trailing: isOwner || isSelf
                                  ? null
                                  : PopupMenuButton<String>(
                                      enabled: !_busy.contains(userId),
                                      onSelected: (value) {
                                        if (value == 'remove') {
                                          _removeMember(userId, label);
                                        } else {
                                          _setRole(userId, value);
                                        }
                                      },
                                      itemBuilder: (_) => [
                                        if (role != 'moderator')
                                          const PopupMenuItem(
                                            value: 'moderator',
                                            child: Text('ترقية إلى مشرف'),
                                          ),
                                        if (role == 'moderator')
                                          const PopupMenuItem(
                                            value: 'member',
                                            child: Text('إلغاء الإشراف'),
                                          ),
                                        const PopupMenuDivider(),
                                        const PopupMenuItem(
                                          value: 'remove',
                                          child: Text('إزالة من المجتمع'),
                                        ),
                                      ],
                                    ),
                            );
                          },
                        ),
                ),
    );
  }
}
