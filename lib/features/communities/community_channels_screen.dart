import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/app_error.dart';
import '../messaging/messages_screen.dart';

class CommunityChannelsScreen extends StatefulWidget {
  const CommunityChannelsScreen({
    super.key,
    required this.communityId,
    required this.communityName,
    required this.canManageChannels,
  });

  final String communityId;
  final String communityName;
  final bool canManageChannels;

  @override
  State<CommunityChannelsScreen> createState() => _CommunityChannelsScreenState();
}

class _CommunityChannelsScreenState extends State<CommunityChannelsScreen> {
  bool _loading = true;
  bool _creating = false;
  String? _error;
  List<Map<String, dynamic>> _channels = [];

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
      final rows = await Supabase.instance.client
          .from('community_channels')
          .select('id,conversation_id,name,slug,created_at')
          .eq('community_id', widget.communityId)
          .order('created_at')
          .order('id');
      if (!mounted) return;
      setState(() {
        _channels = List<Map<String, dynamic>>.from(rows);
        _loading = false;
      });
    } catch (error, stack) {
      AppErrorService.report(error, stack, source: 'community_channels_load');
      if (mounted) setState(() {
        _error = AppErrorService.message(error);
        _loading = false;
      });
    }
  }

  Future<void> _createChannel() async {
    final result = await showDialog<Map<String, String>>(
      context: context,
      builder: (dialogContext) {
        final name = TextEditingController();
        final slug = TextEditingController();
        String? validation;
        return StatefulBuilder(
          builder: (context, refresh) => AlertDialog(
            title: const Text('إنشاء قناة'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: name,
                  maxLength: 60,
                  decoration: const InputDecoration(labelText: 'اسم القناة'),
                  onChanged: (value) {
                    if (slug.text.isEmpty || slug.text.startsWith('channel-')) {
                      final normalized = value.toLowerCase()
                          .replaceAll(RegExp(r'[^a-z0-9]+'), '-')
                          .replaceAll(RegExp(r'^-+|-+$'), '');
                      slug.text = normalized.length >= 2
                          ? normalized.substring(0, normalized.length > 60 ? 60 : normalized.length)
                          : 'channel-${DateTime.now().millisecondsSinceEpoch}';
                    }
                  },
                ),
                TextField(
                  controller: slug,
                  maxLength: 60,
                  decoration: const InputDecoration(labelText: 'معرّف القناة بالإنجليزية'),
                ),
                if (validation != null)
                  Text(validation!, style: const TextStyle(color: Colors.redAccent)),
              ],
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
                  if (n.length < 2 || n.length > 60) {
                    refresh(() => validation = 'اسم القناة لازم يكون من 2 إلى 60 حرفًا.');
                    return;
                  }
                  if (!RegExp(r'^[a-z0-9-]{2,60}$').hasMatch(s)) {
                    refresh(() => validation = 'المعرّف لازم يكون إنجليزيًا من 2 إلى 60 حرفًا.');
                    return;
                  }
                  Navigator.pop(dialogContext, {'name': n, 'slug': s});
                },
                child: const Text('إنشاء'),
              ),
            ],
          ),
        );
      },
    );
    if (result == null || !mounted || _creating) return;
    setState(() => _creating = true);
    final db = Supabase.instance.client;
    final uid = db.auth.currentUser!.id;
    String? conversationId;
    try {
      final conversation = await db.from('conversations').insert({
        'created_by': uid,
        'conversation_type': 'community',
        'title': '${widget.communityName} · ${result['name']}',
      }).select('id').single();
      conversationId = conversation['id'] as String;
      await db.from('conversation_members').insert({
        'conversation_id': conversationId,
        'user_id': uid,
        'role': 'owner',
      });
      await db.from('community_channels').insert({
        'community_id': widget.communityId,
        'conversation_id': conversationId,
        'name': result['name'],
        'slug': result['slug'],
        'created_by': uid,
      });
      await _load();
    } catch (error, stack) {
      AppErrorService.report(error, stack, source: 'community_channel_create');
      if (conversationId != null) {
        try {
          await db.from('conversations').delete().eq('id', conversationId);
        } catch (cleanupError, cleanupStack) {
          AppErrorService.report(cleanupError, cleanupStack, source: 'community_channel_cleanup');
        }
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppErrorService.message(error))),
        );
      }
    } finally {
      if (mounted) setState(() => _creating = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(
          title: Text(widget.communityName, maxLines: 1, overflow: TextOverflow.ellipsis),
          actions: [
            IconButton(
              tooltip: 'تحديث',
              onPressed: _loading ? null : _load,
              icon: const Icon(Icons.refresh),
            ),
            if (widget.canManageChannels)
              IconButton(
                tooltip: 'إنشاء قناة',
                onPressed: _creating ? null : _createChannel,
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
                        const Text('تعذر تحميل القنوات'),
                        TextButton(onPressed: _load, child: const Text('إعادة المحاولة')),
                      ],
                    ),
                  )
                : RefreshIndicator(
                    onRefresh: _load,
                    child: _channels.isEmpty
                        ? ListView(
                            physics: const AlwaysScrollableScrollPhysics(),
                            children: const [
                              SizedBox(height: 120),
                              Icon(Icons.forum_outlined, size: 52),
                              SizedBox(height: 12),
                              Center(child: Text('لا توجد قنوات في المجتمع بعد')),
                            ],
                          )
                        : ListView.separated(
                            padding: const EdgeInsets.all(16),
                            itemCount: _channels.length,
                            separatorBuilder: (_, __) => const Divider(height: 1),
                            itemBuilder: (context, index) {
                              final channel = _channels[index];
                              return ListTile(
                                leading: const CircleAvatar(child: Icon(Icons.tag)),
                                title: Text(channel['name'].toString()),
                                subtitle: Text('#${channel['slug']}'),
                                trailing: const Icon(Icons.chevron_left),
                                onTap: () => Navigator.of(context).push(
                                  MaterialPageRoute<void>(
                                    builder: (_) => ChatScreen(
                                      conversationId: channel['conversation_id'] as String,
                                      title: '${widget.communityName} · ${channel['name']}',
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                  ),
      );
}
