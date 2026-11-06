import 'package:flutter/material.dart';
import '../../core/theme/nexora_theme.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/app_error.dart';
import '../moderation/report_dialog.dart';
import 'message_attachment_service.dart';

class MessagesScreen extends StatefulWidget {
  const MessagesScreen({super.key});

  @override
  State<MessagesScreen> createState() => _MessagesScreenState();
}

class _MessagesScreenState extends State<MessagesScreen> {
  late Future<List<Map<String, dynamic>>> _future;
  String? _loadedUserId;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<List<Map<String, dynamic>>> _load() async {
    final client = Supabase.instance.client;
    final userId = client.auth.currentUser?.id;
    if (userId == null) {
      throw StateError('انتهت جلسة الدخول. سجّل الدخول مرة تانية.');
    }
    final rows = await client.rpc('get_my_conversation_previews');
    if (client.auth.currentUser?.id != userId) {
      throw StateError('تغير الحساب أثناء تحميل المحادثات.');
    }
    _loadedUserId = userId;
    return List<Map<String, dynamic>>.from(
      (rows as List).map((raw) {
        final row = Map<String, dynamic>.from(raw as Map);
        return {
          'id': row['conversation_id'],
          'conversation': {
            'id': row['conversation_id'],
            'conversation_type': row['conversation_type'],
            'title': row['conversation_title'],
            'created_at': row['conversation_created_at'],
            'last_message_at': row['last_message_at'],
          },
          'peer': {
            'id': row['peer_id'],
            'username': row['peer_username'],
            'display_name': row['peer_display_name'],
            'avatar_url': row['peer_avatar_url'],
          },
          'latest': row['latest_message_id'] == null
              ? null
              : {
                  'id': row['latest_message_id'],
                  'body': row['latest_body'],
                  'message_type': row['latest_message_type'],
                  'created_at': row['latest_created_at'],
                  'sender_id': row['latest_sender_id'],
                  'deleted_at': row['latest_deleted_at'],
                },
        };
      }),
    );
  }

  Future<void> _refresh() async {
    if (!mounted) return;
    final next = _load();
    setState(() => _future = next);
    try {
      await next;
    } catch (error, stack) {
      AppErrorService.report(error, stack, source: 'messages_refresh');
      // FutureBuilder owns the error state; do not leak a failed refresh future.
    }
  }

  Future<void> _newMessage() async {
    final client = Supabase.instance.client;
    final userId = client.auth.currentUser?.id;
    if (userId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('انتهت جلسة الدخول. سجّل الدخول مرة تانية.')),
      );
      return;
    }
    final profile = await showModalBottomSheet<Map<String, dynamic>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      builder: (_) => const _NewConversationSheet(),
    );
    if (!mounted || profile == null || client.auth.currentUser?.id != userId) return;

    try {
      final conversationId = await client.rpc(
        'create_direct_conversation',
        params: {'p_other_user_id': profile['id']},
      );
      if (!mounted || client.auth.currentUser?.id != userId) return;
      await _refresh();
      if (!mounted || client.auth.currentUser?.id != userId) return;
      Navigator.of(context).push(MaterialPageRoute<void>(
        builder: (_) => ChatScreen(
          conversationId: conversationId.toString(),
          title: (profile['display_name'] ?? profile['username'] ?? 'محادثة')
              .toString(),
        ),
      ));
    } catch (error, stack) {
      AppErrorService.report(error, stack, source: 'create_conversation');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppErrorService.message(error))),
        );
      }
    }
  }

  void _open(Map<String, dynamic> item) {
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) return;
    if (_loadedUserId != userId) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تغير الحساب. حدّث قائمة المحادثات أولًا.')),
      );
      return;
    }
    final peer = item['peer'] as Map<String, dynamic>;
    final conversation = item['conversation'] as Map<String, dynamic>;
    final title = conversation['conversation_type'] == 'group'
        ? (conversation['title'] ?? 'مجموعة').toString()
        : (peer['display_name'] ?? peer['username'] ?? 'محادثة').toString();
    Navigator.of(context).push(MaterialPageRoute<void>(
      builder: (_) => ChatScreen(
        conversationId: item['id'] as String,
        title: title,
      ),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('الرسائل', style: TextStyle(fontWeight: FontWeight.w900)),
        actions: [
          IconButton(
            tooltip: 'رسالة جديدة',
            onPressed: _newMessage,
            icon: const Icon(Icons.edit_square),
          ),
          IconButton(
            tooltip: 'تحديث',
            onPressed: _refresh,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _future,
        builder: (context, snapshot) {
          final currentUserId = Supabase.instance.client.auth.currentUser?.id;
          if (currentUserId == null ||
              (_loadedUserId != null && _loadedUserId != currentUserId)) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('تغير الحساب. حدّث قائمة المحادثات.'),
                  TextButton(onPressed: _refresh, child: const Text('تحديث')),
                ],
              ),
            );
          }
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return AppErrorView(
              title: 'تعذر تحميل المحادثات',
              error: snapshot.error,
              onRetry: _refresh,
            );
          }
          final items = snapshot.data ?? [];
          if (items.isEmpty) {
            return RefreshIndicator(
              onRefresh: _refresh,
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                children: [
                  const SizedBox(height: 100),
                  Padding(
                    padding: const EdgeInsets.all(28),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.forum_outlined, size: 54),
                        const SizedBox(height: 16),
                        const Text('مساحتك الخاصة للكلام',
                            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
                        const SizedBox(height: 8),
                        const Text(
                          'ابدأ محادثة مع شخص تسمح إعدادات الخصوصية عنده باستقبال رسائلك.',
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 18),
                        FilledButton.icon(
                          onPressed: _newMessage,
                          icon: const Icon(Icons.add_comment_outlined),
                          label: const Text('رسالة جديدة'),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          }
          return RefreshIndicator(
            onRefresh: _refresh,
            child: ListView.separated(
              itemCount: items.length,
              padding: const EdgeInsets.symmetric(vertical: 8),
              separatorBuilder: (_, __) => const Divider(height: 1, indent: 76),
              itemBuilder: (context, index) {
                final item = items[index];
                final peer = item['peer'] as Map<String, dynamic>;
                final latest = item['latest'] as Map<String, dynamic>?;
                final conversation = item['conversation'] as Map<String, dynamic>;
                final isGroup = conversation['conversation_type'] == 'group' ||
                    conversation['conversation_type'] == 'community';
                final name = (isGroup
                        ? conversation['title']
                        : (peer['display_name'] ?? peer['username']))
                    ?.toString();
                final displayName = (name == null || name.isEmpty)
                    ? (isGroup ? 'مجموعة NEXORA' : 'مستخدم NEXORA')
                    : name;
                final preview = latest == null
                    ? 'ابدأ المحادثة'
                    : (latest['deleted_at'] != null
                        ? 'تم حذف الرسالة'
                        : (latest['message_type'] == 'text'
                            ? (latest['body'] ?? '').toString()
                            : 'مرفق'));
                return ListTile(
                  onTap: () => _open(item),
                  leading: CircleAvatar(
                    backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
                    child: const Icon(Icons.person_outline),
                  ),
                  title: Text(displayName, maxLines: 1, overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontWeight: FontWeight.w700)),
                  subtitle: Text(preview, maxLines: 1, overflow: TextOverflow.ellipsis),
                  trailing: const Icon(Icons.chevron_left),
                );
              },
            ),
          );
        },
      ),
    );
  }
}

class ChatScreen extends StatefulWidget {
  const ChatScreen({
    super.key,
    required this.conversationId,
    required this.title,
  });

  final String conversationId;
  final String title;

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _controller = TextEditingController();
  final _scrollController = ScrollController();
  final _attachmentService = MessageAttachmentService();
  final Map<String, Future<String?>> _attachmentUrls = {};
  late final Stream<List<Map<String, dynamic>>> _messages;
  bool _sending = false;
  bool _sendingAttachment = false;
  bool _nearBottom = true;
  int _lastMessageCount = -1;
  String? _sendError;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_trackScrollPosition);
    final client = Supabase.instance.client;
    _messages = client
        .from('messages')
        .stream(primaryKey: ['id'])
        .eq('conversation_id', widget.conversationId)
        .order('created_at');
    WidgetsBinding.instance.addPostFrameCallback((_) => _markRead());
  }

  void _trackScrollPosition() {
    if (!_scrollController.hasClients) return;
    final position = _scrollController.position;
    _nearBottom = position.maxScrollExtent - position.pixels < 160;
  }

  void _scrollToLatest({bool animate = true}) {
    if (!_scrollController.hasClients) return;
    final target = _scrollController.position.maxScrollExtent;
    if (animate) {
      _scrollController.animateTo(
        target,
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOut,
      );
    } else {
      _scrollController.jumpTo(target);
    }
  }

  Future<void> _markRead() async {
    try {
      await Supabase.instance.client
          .from('conversation_members')
          .update({'last_read_at': DateTime.now().toUtc().toIso8601String()})
          .eq('conversation_id', widget.conversationId)
          .eq('user_id', Supabase.instance.client.auth.currentUser!.id);
    } catch (error, stack) {
      AppErrorService.report(error, stack, source: 'message_read_receipt');
    }
  }

  Future<void> _editMessage(Map<String, dynamic> message) async {
    final controller = TextEditingController(
      text: (message['body'] ?? '').toString(),
    );
    final edited = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('تعديل الرسالة'),
        content: TextField(
          controller: controller,
          autofocus: true,
          minLines: 1,
          maxLines: 5,
          maxLength: 5000,
          decoration: const InputDecoration(hintText: 'اكتب الرسالة بعد التعديل'),
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
    final body = edited.trim();
    if (body.isEmpty || body.length > 5000) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('الرسالة لازم تكون من حرف إلى 5000 حرف.')),
        );
      }
      return;
    }
    try {
      await Supabase.instance.client
          .from('messages')
          .update({
            'body': body,
            'edited_at': DateTime.now().toUtc().toIso8601String(),
          })
          .eq('id', message['id'] as String)
          .eq('sender_id', Supabase.instance.client.auth.currentUser!.id);
    } catch (error, stack) {
      AppErrorService.report(error, stack, source: 'edit_message');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppErrorService.message(error))),
        );
      }
    }
  }

  Future<void> _deleteMessage(Map<String, dynamic> message) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('حذف الرسالة؟'),
        content: const Text('سيظهر مكانها إشعار بأن الرسالة حُذفت.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('إلغاء'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('حذف'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await _attachmentService.deleteOwnAttachment(message['id'] as String);
      await Supabase.instance.client
          .from('messages')
          .update({'deleted_at': DateTime.now().toUtc().toIso8601String()})
          .eq('id', message['id'] as String)
          .eq('sender_id', Supabase.instance.client.auth.currentUser!.id);
      _attachmentUrls.remove(message['id']);
    } catch (error, stack) {
      AppErrorService.report(error, stack, source: 'delete_message');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppErrorService.message(error))),
        );
      }
    }
  }

  Future<void> _send() async {
    final text = _controller.text.trim();
    if (text.isEmpty || _sending) return;
    if (text.length > 5000) {
      setState(() => _sendError = 'الرسالة أطول من الحد المسموح (5000 حرف).');
      return;
    }
    setState(() {
      _sending = true;
      _sendError = null;
    });
    try {
      await Supabase.instance.client.from('messages').insert({
        'conversation_id': widget.conversationId,
        'sender_id': Supabase.instance.client.auth.currentUser!.id,
        'message_type': 'text',
        'body': text,
        'encryption_mode': 'server_readable',
      });
      _controller.clear();
      await _markRead();
    } catch (error, stack) {
      AppErrorService.report(error, stack, source: 'send_message');
      if (mounted) setState(() => _sendError = AppErrorService.message(error));
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  Future<void> _sendImage() async {
    if (_sending || _sendingAttachment) return;
    setState(() { _sendingAttachment = true; _sendError = null; });
    try {
      final file = await _attachmentService.pickImage();
      if (file == null) return;
      final messageId = await _attachmentService.sendImage(widget.conversationId, file);
      _attachmentUrls.remove(messageId);
      await _markRead();
    } catch (error, stack) {
      AppErrorService.report(error, stack, source: 'send_message_image');
      if (mounted) setState(() => _sendError = AppErrorService.message(error));
    } finally {
      if (mounted) setState(() => _sendingAttachment = false);
    }
  }

  Future<String?> _imageUrl(String messageId) =>
      _attachmentUrls.putIfAbsent(messageId, () => _attachmentService.signedImageUrl(messageId));

  @override
  void dispose() {
    _scrollController.removeListener(_trackScrollPosition);
    _scrollController.dispose();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final myId = Supabase.instance.client.auth.currentUser?.id;
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title, maxLines: 1, overflow: TextOverflow.ellipsis),
      ),
      body: Column(
        children: [
          Material(
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
            child: const Padding(
              padding: EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              child: Row(
                children: [
                  Icon(Icons.lock_outline, size: 16),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'المراسلة متاحة الآن كنص عادي عبر اتصال آمن؛ التشفير من الطرف للطرف لم يُفعّل بعد.',
                      style: TextStyle(fontSize: 11),
                    ),
                  ),
                ],
              ),
            ),
          ),
          Expanded(
            child: StreamBuilder<List<Map<String, dynamic>>>(
              stream: _messages,
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return AppErrorView(
                    title: 'تعذر تحديث الرسائل',
                    error: snapshot.error,
                    onRetry: () => setState(() {}),
                  );
                }
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }
                final messages = snapshot.data!;
                if (_lastMessageCount != messages.length) {
                  final firstLoad = _lastMessageCount == -1;
                  _lastMessageCount = messages.length;
                  if (firstLoad || _nearBottom) {
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      if (mounted) _scrollToLatest(animate: !firstLoad);
                    });
                  }
                }
                if (messages.isEmpty) {
                  return const Center(child: Text('ابدأ أول رسالة في المحادثة.'));
                }
                return ListView.builder(
                  controller: _scrollController,
                  reverse: false,
                  padding: const EdgeInsets.all(16),
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final message = messages[index];
                    final mine = message['sender_id'] == myId;
                    final deleted = message['deleted_at'] != null;
                    return Align(
                      alignment: mine ? Alignment.centerRight : Alignment.centerLeft,
                      child: Container(
                        constraints: BoxConstraints(
                          maxWidth: MediaQuery.sizeOf(context).width * .78,
                        ),
                        margin: const EdgeInsets.only(bottom: 9),
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        decoration: BoxDecoration(
                          color: mine
                              ? Theme.of(context).colorScheme.primary
                              : Theme.of(context).colorScheme.surfaceContainerHighest,
                          borderRadius: BorderRadius.circular(18),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (!deleted)
                              PopupMenuButton<String>(
                                tooltip: 'خيارات الرسالة',
                                padding: EdgeInsets.zero,
                                iconSize: 18,
                                onSelected: (value) async {
                                  if (value == 'edit') _editMessage(message);
                                  if (value == 'delete') _deleteMessage(message);
                                  if (value == 'report') {
                                    final submitted = await ReportDialog.show(
                                      context,
                                      targetType: 'message',
                                      targetId: message['id'] as String,
                                    );
                                    if (submitted && context.mounted) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(content: Text('تم إرسال البلاغ للمراجعة')),
                                      );
                                    }
                                  }
                                },
                                itemBuilder: (_) => [
                                  if (mine) ...[
                                    if (message['message_type'] == 'text')
                                      const PopupMenuItem(
                                        value: 'edit',
                                        child: Text('تعديل الرسالة'),
                                      ),
                                    const PopupMenuItem(
                                      value: 'delete',
                                      child: Text('حذف الرسالة'),
                                    ),
                                  ] else
                                    const PopupMenuItem(
                                      value: 'report',
                                      child: Row(
                                        children: [
                                          Icon(Icons.flag_outlined, size: 18),
                                          SizedBox(width: 8),
                                          Text('الإبلاغ عن الرسالة'),
                                        ],
                                      ),
                                    ),
                                ],
                              ),
                            if (deleted)
                              const Text('تم حذف الرسالة')
                            else if (message['message_type'] == 'image')
                              FutureBuilder<String?>(
                                future: _imageUrl(message['id'] as String),
                                builder: (context, imageSnapshot) {
                                  final url = imageSnapshot.data;
                                  if (url == null) {
                                    return Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        const Text('الصورة غير جاهزة'),
                                        IconButton(
                                          tooltip: 'إعادة تحميل الصورة',
                                          onPressed: () => setState(() => _attachmentUrls.remove(message['id'])),
                                          icon: const Icon(Icons.refresh),
                                        ),
                                      ],
                                    );
                                  }
                                  return ClipRRect(
                                    borderRadius: BorderRadius.circular(12),
                                    child: Image.network(
                                      url,
                                      width: MediaQuery.sizeOf(context).width * .62,
                                      fit: BoxFit.cover,
                                      errorBuilder: (_, __, ___) => const Text('تعذر عرض الصورة'),
                                    ),
                                  );
                                },
                              )
                            else
                              Text(
                                (message['body'] ?? '').toString(),
                                style: TextStyle(
                                  color: mine
                                      ? Theme.of(context).colorScheme.onPrimary
                                      : Theme.of(context).colorScheme.onSurface,
                                ),
                              ),
                            if (message['edited_at'] != null && !deleted)
                              const Padding(
                                padding: EdgeInsets.only(top: 4),
                                child: Text('معدّلة', style: TextStyle(fontSize: 10)),
                              ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
          if (_sendError != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Text(_sendError!, style: const TextStyle(color: NexoraColors.danger)),
            ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 10),
              child: Row(
                children: [
                  IconButton(
                    tooltip: 'إرسال صورة',
                    onPressed: _sending || _sendingAttachment ? null : _sendImage,
                    icon: _sendingAttachment
                        ? const SizedBox.square(dimension: 18, child: CircularProgressIndicator(strokeWidth: 2))
                        : const Icon(Icons.image_outlined),
                  ),
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      minLines: 1,
                      maxLines: 5,
                      maxLength: 5000,
                      decoration: const InputDecoration(
                        hintText: 'اكتب رسالة...',
                        counterText: '',
                      ),
                      onSubmitted: (_) => _send(),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton.filled(
                    onPressed: _sending ? null : _send,
                    icon: _sending
                        ? const SizedBox.square(
                            dimension: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.send),
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

class _NewConversationSheet extends StatefulWidget {
  const _NewConversationSheet();

  @override
  State<_NewConversationSheet> createState() => _NewConversationSheetState();
}

class _NewConversationSheetState extends State<_NewConversationSheet> {
  final _search = TextEditingController();
  bool _loading = false;
  String? _error;
  List<Map<String, dynamic>> _results = [];

  Future<void> _find() async {
    final term = _search.text.trim().replaceAll(RegExp(r'[^a-zA-Z0-9_ء-ي ]'), '');
    if (term.length < 2) {
      setState(() => _error = 'اكتب حرفين على الأقل للبحث باسم المستخدم.');
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final rows = await Supabase.instance.client
          .from('profiles')
          .select('id,username,display_name,avatar_url')
          .neq('id', Supabase.instance.client.auth.currentUser!.id)
          .ilike('username', '%$term%')
          .limit(20);
      if (mounted) {
        setState(() => _results = List<Map<String, dynamic>>.from(rows));
      }
    } catch (error, stack) {
      AppErrorService.report(error, stack, source: 'search_message_recipient');
      if (mounted) setState(() => _error = AppErrorService.message(error));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(
          left: 18,
          right: 18,
          top: 20,
          bottom: MediaQuery.viewInsetsOf(context).bottom + 20,
        ),
        child: SizedBox(
          height: MediaQuery.sizeOf(context).height * .72,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text('محادثة جديدة',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900)),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _search,
                      decoration: const InputDecoration(
                        hintText: 'ابحث باسم المستخدم',
                        prefixIcon: Icon(Icons.search),
                      ),
                      onSubmitted: (_) => _find(),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton.filled(onPressed: _loading ? null : _find, icon: const Icon(Icons.search)),
                ],
              ),
              if (_error != null)
                Padding(
                  padding: const EdgeInsets.all(8),
                  child: Text(_error!, style: const TextStyle(color: NexoraColors.danger)),
                ),
              if (_loading) const LinearProgressIndicator(),
              const SizedBox(height: 8),
              Expanded(
                child: _results.isEmpty
                    ? const Center(child: Text('ابحث عن حساب لبدء المحادثة.'))
                    : ListView.separated(
                        itemCount: _results.length,
                        separatorBuilder: (_, __) => const Divider(height: 1),
                        itemBuilder: (context, index) {
                          final profile = _results[index];
                          return ListTile(
                            leading: const CircleAvatar(child: Icon(Icons.person_outline)),
                            title: Text((profile['display_name'] ?? 'مستخدم').toString()),
                            subtitle: Text('@${profile['username'] ?? 'user'}'),
                            onTap: () => Navigator.of(context).pop(profile),
                          );
                        },
                      ),
              ),
              const Text(
                'إمكانية بدء المحادثة تخضع لخصوصية الطرف الآخر والحظر المتبادل.',
                style: TextStyle(fontSize: 11, color: NexoraColors.textMuted),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
