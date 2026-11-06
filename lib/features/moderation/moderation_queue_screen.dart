import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/app_error.dart';
import 'moderation_appeals_screen.dart';

class ModerationQueueScreen extends StatefulWidget {
  const ModerationQueueScreen({super.key, required this.role});

  final String role;

  @override
  State<ModerationQueueScreen> createState() => _ModerationQueueScreenState();
}

class _ModerationQueueScreenState extends State<ModerationQueueScreen> {
  static const int _pageSize = 30;
  final List<Map<String, dynamic>> _reports = [];
  bool _loading = true;
  bool _loadingMore = false;
  bool _hasMore = true;
  String? _error;
  String _filter = 'active';
  final Set<String> _busyIds = {};

  bool get _canReview =>
      const {'super_admin', 'admin', 'moderator'}.contains(widget.role);

  static const Map<String, String> _reasonLabels = {
    'harassment': 'مضايقة أو تنمر',
    'threats': 'تهديدات',
    'spam': 'سبام',
    'scam': 'احتيال',
    'impersonation': 'انتحال شخصية',
    'sexual_content': 'محتوى جنسي',
    'child_safety': 'سلامة طفل',
    'dangerous_content': 'محتوى خطير',
    'illegal_content': 'محتوى غير قانوني',
    'copyright': 'حقوق ملكية',
    'other': 'أخرى',
  };

  @override
  void initState() {
    super.initState();
    _loadFirstPage();
  }

  Future<List<Map<String, dynamic>>> _fetchPage(int offset) async {
    var query = Supabase.instance.client
        .from('reports')
        .select(
          'id,reporter_id,target_type,target_id,reason,details,status,created_at,assigned_to,profiles!reports_reporter_id_fkey(username,display_name)',
        );
    if (_filter == 'active') {
      query = query.inFilter('status', ['open', 'reviewing']);
    }
    final rows = await query
        .order('created_at', ascending: false)
        .order('id', ascending: false)
        .range(offset, offset + _pageSize - 1);
    return List<Map<String, dynamic>>.from(rows);
  }

  Future<void> _loadFirstPage() async {
    setState(() {
      _loading = true;
      _loadingMore = false;
      _hasMore = true;
      _error = null;
      _reports.clear();
    });
    try {
      final page = await _fetchPage(0);
      if (!mounted) return;
      setState(() {
        _reports.addAll(page);
        _hasMore = page.length == _pageSize;
        _loading = false;
      });
    } catch (error, stack) {
      AppErrorService.report(error, stack, source: 'moderation_queue_load');
      if (mounted) {
        setState(() {
          _error = AppErrorService.message(error);
          _loading = false;
        });
      }
    }
  }

  Future<void> _loadMore() async {
    if (_loadingMore || !_hasMore) return;
    setState(() => _loadingMore = true);
    try {
      final page = await _fetchPage(_reports.length);
      if (!mounted) return;
      setState(() {
        _reports.addAll(page);
        _hasMore = page.length == _pageSize;
        _loadingMore = false;
      });
    } catch (error, stack) {
      AppErrorService.report(error, stack, source: 'moderation_queue_more');
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

  Future<void> _viewTarget(Map<String, dynamic> report) async {
    final type = (report['target_type'] ?? '').toString();
    final id = (report['target_id'] ?? '').toString();
    if (id.isEmpty) return;

    String table;
    String columns;
    switch (type) {
      case 'user':
        table = 'profiles';
        columns = 'id,username,display_name,bio,is_verified,is_private';
        break;
      case 'post':
        table = 'posts';
        columns = 'id,user_id,content,visibility,created_at,deleted_at';
        break;
      case 'comment':
        table = 'comments';
        columns = 'id,user_id,content,created_at,deleted_at,post_id';
        break;
      case 'story':
        table = 'stories';
        columns = 'id,user_id,text_content,story_type,visibility,created_at,expires_at,archived_at';
        break;
      case 'message':
        table = 'messages';
        columns = 'id,sender_id,body,message_type,encryption_mode,created_at,deleted_at';
        break;
      case 'community':
        table = 'communities';
        columns = 'id,owner_id,name,description,visibility,created_at';
        break;
      default:
        return;
    }

    try {
      final row = await Supabase.instance.client
          .from(table)
          .select(columns)
          .eq('id', id)
          .maybeSingle();
      if (!mounted) return;
      if (row == null) {
        await showDialog<void>(
          context: context,
          builder: (dialogContext) => AlertDialog(
            title: const Text('المحتوى غير متاح'),
            content: const Text(
              'لا يمكن عرض هذا الهدف من حساب المراجع الحالي. لم يتم تجاوز إعدادات الخصوصية أو صلاحيات قاعدة البيانات.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext),
                child: const Text('إغلاق'),
              ),
            ],
          ),
        );
        return;
      }

      final data = Map<String, dynamic>.from(row);
      String title;
      String body;
      switch (type) {
        case 'user':
          title = 'الحساب المُبلّغ عنه';
          body = [
            'الاسم: ${data['display_name'] ?? '—'}',
            'المعرّف: @${data['username'] ?? '—'}',
            'نبذة: ${data['bio'] ?? '—'}',
            'الحساب: ${data['is_private'] == true ? 'خاص' : 'عام'}',
            'التوثيق: ${data['is_verified'] == true ? 'موثق' : 'غير موثق'}',
          ].join('\n');
          break;
        case 'post':
          title = 'المنشور المُبلّغ عنه';
          body = [
            'المحتوى: ${data['content'] ?? '—'}',
            'الظهور: ${data['visibility'] ?? '—'}',
            'الحالة: ${data['deleted_at'] == null ? 'متاح' : 'محذوف'}',
          ].join('\n');
          break;
        case 'comment':
          title = 'التعليق المُبلّغ عنه';
          body = [
            'المحتوى: ${data['content'] ?? '—'}',
            'الحالة: ${data['deleted_at'] == null ? 'متاح' : 'محذوف'}',
            'المنشور: ${data['post_id']}',
          ].join('\n');
          break;
        case 'story':
          title = 'القصة المُبلّغ عنها';
          body = [
            'النص: ${data['text_content'] ?? 'قصة وسائط'}',
            'النوع: ${data['story_type'] ?? '—'}',
            'الظهور: ${data['visibility'] ?? '—'}',
            'تنتهي: ${data['expires_at'] ?? '—'}',
          ].join('\n');
          break;
        case 'message':
          title = 'الرسالة المُبلّغ عنها';
          final encrypted = data['encryption_mode']?.toString() != 'none' &&
              data['encryption_mode']?.toString() != 'plaintext';
          body = encrypted
              ? 'هذه الرسالة مشفرة أو لا يمكن عرض نصها في مركز الإشراف.'
              : 'المحتوى: ${data['body'] ?? '—'}';
          break;
        case 'community':
          title = 'المجتمع المُبلّغ عنه';
          body = [
            'الاسم: ${data['name'] ?? '—'}',
            'الوصف: ${data['description'] ?? '—'}',
            'الظهور: ${data['visibility'] ?? '—'}',
          ].join('\n');
          break;
        default:
          title = 'تفاصيل الهدف';
          body = 'لا توجد تفاصيل قابلة للعرض.';
      }

      await showDialog<void>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: Text(title),
          content: SingleChildScrollView(child: SelectableText(body)),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('إغلاق'),
            ),
          ],
        ),
      );
    } catch (error, stack) {
      AppErrorService.report(error, stack, source: 'moderation_target_preview');
      _showError(error);
    }
  }

  Future<void> _assignToMe(Map<String, dynamic> report) async {
    final id = report['id'] as String;
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (!_canReview || userId == null || _busyIds.contains(id)) return;
    setState(() => _busyIds.add(id));
    try {
      await Supabase.instance.client
          .from('reports')
          .update({
            'assigned_to': userId,
            'status': 'reviewing',
          })
          .eq('id', id);
      await _loadFirstPage();
    } catch (error, stack) {
      AppErrorService.report(error, stack, source: 'moderation_assign');
      _showError(error);
    } finally {
      if (mounted) setState(() => _busyIds.remove(id));
    }
  }

  Future<void> _dismiss(Map<String, dynamic> report) async {
    final note = TextEditingController();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('إغلاق البلاغ دون إجراء'),
        content: TextField(
          controller: note,
          maxLength: 1000,
          maxLines: 3,
          decoration: const InputDecoration(
            labelText: 'ملاحظة القرار (اختياري)',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('رجوع'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('إغلاق البلاغ'),
          ),
        ],
      ),
    );
    final resolution = note.text.trim();
    note.dispose();
    if (confirmed != true || !mounted) return;
    if (!_canReview || Supabase.instance.client.auth.currentUser == null) {
      _showError(StateError('انتهت جلسة الدخول أو لم تعد تملك صلاحية المراجعة.'));
      return;
    }

    final id = report['id'] as String;
    if (_busyIds.contains(id)) return;
    setState(() => _busyIds.add(id));
    try {
      await Supabase.instance.client
          .from('reports')
          .update({
            'status': 'dismissed',
            'resolved_at': DateTime.now().toUtc().toIso8601String(),
            'resolution_note': resolution,
          })
          .eq('id', id);
      await _loadFirstPage();
    } catch (error, stack) {
      AppErrorService.report(error, stack, source: 'moderation_dismiss');
      _showError(error);
    } finally {
      if (mounted) setState(() => _busyIds.remove(id));
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(
          title: const Text('مركز مراجعة البلاغات'),
          actions: [
            if (_canReview)
              IconButton(
                tooltip: 'مراجعة الاستئنافات',
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => const ModerationAppealsScreen(),
                  ),
                ),
                icon: const Icon(Icons.gavel_outlined),
              ),
            IconButton(
              tooltip: 'تحديث',
              onPressed: _loading ? null : _loadFirstPage,
              icon: const Icon(Icons.refresh),
            ),
          ],
        ),
        body: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
              child: Row(
                children: [
                  ChoiceChip(
                    label: const Text('النشطة'),
                    selected: _filter == 'active',
                    onSelected: (_) {
                      if (_filter == 'active') return;
                      setState(() => _filter = 'active');
                      _loadFirstPage();
                    },
                  ),
                  const SizedBox(width: 8),
                  ChoiceChip(
                    label: const Text('كل البلاغات'),
                    selected: _filter == 'all',
                    onSelected: (_) {
                      if (_filter == 'all') return;
                      setState(() => _filter = 'all');
                      _loadFirstPage();
                    },
                  ),
                ],
              ),
            ),
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator())
                  : _error != null
                      ? Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Text('تعذر تحميل البلاغات'),
                              TextButton(
                                onPressed: _loadFirstPage,
                                child: const Text('إعادة المحاولة'),
                              ),
                            ],
                          ),
                        )
                      : RefreshIndicator(
                          onRefresh: _loadFirstPage,
                          child: _reports.isEmpty
                              ? ListView(
                                  physics: const AlwaysScrollableScrollPhysics(),
                                  children: const [
                                    SizedBox(height: 120),
                                    Icon(Icons.verified_outlined, size: 52),
                                    SizedBox(height: 12),
                                    Center(child: Text('لا توجد بلاغات في هذا العرض')),
                                  ],
                                )
                              : ListView.separated(
                                  padding: const EdgeInsets.all(16),
                                  itemCount: _reports.length +
                                      (_hasMore || _loadingMore ? 1 : 0),
                                  separatorBuilder: (_, __) =>
                                      const SizedBox(height: 10),
                                  itemBuilder: (context, index) {
                                    if (index == _reports.length) {
                                      return Center(
                                        child: TextButton(
                                          onPressed:
                                              _loadingMore ? null : _loadMore,
                                          child: _loadingMore
                                              ? const SizedBox.square(
                                                  dimension: 18,
                                                  child:
                                                      CircularProgressIndicator(
                                                    strokeWidth: 2,
                                                  ),
                                                )
                                              : const Text('تحميل المزيد'),
                                        ),
                                      );
                                    }
                                    final report = _reports[index];
                                    final reporter = report['profiles'] is Map
                                        ? Map<String, dynamic>.from(
                                            report['profiles'] as Map,
                                          )
                                        : <String, dynamic>{};
                                    final id = report['id'] as String;
                                    final status =
                                        (report['status'] ?? 'open').toString();
                                    final assigned =
                                        report['assigned_to'] == Supabase
                                            .instance.client.auth.currentUser?.id;
                                    final busy = _busyIds.contains(id);
                                    return Card(
                                      child: Padding(
                                        padding: const EdgeInsets.all(14),
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.stretch,
                                          children: [
                                            Row(
                                              children: [
                                                Expanded(
                                                  child: Text(
                                                    '${report['target_type']} · ${_reasonLabels[report['reason']] ?? report['reason']}',
                                                    style: const TextStyle(
                                                      fontWeight:
                                                          FontWeight.w800,
                                                    ),
                                                  ),
                                                ),
                                                Chip(
                                                  label: Text(
                                                    status == 'open'
                                                        ? 'جديد'
                                                        : status == 'reviewing'
                                                            ? 'قيد المراجعة'
                                                            : status == 'dismissed'
                                                                ? 'مغلق'
                                                                : status,
                                                  ),
                                                ),
                                              ],
                                            ),
                                            Text(
                                              'المبلّغ: ${reporter['display_name'] ?? reporter['username'] ?? 'مستخدم'}',
                                              style: const TextStyle(
                                                color: Colors.white70,
                                                fontSize: 12,
                                              ),
                                            ),
                                            const SizedBox(height: 6),
                                            Align(
                                              alignment: AlignmentDirectional.centerStart,
                                              child: TextButton.icon(
                                                onPressed: () => _viewTarget(report),
                                                icon: const Icon(Icons.visibility_outlined, size: 18),
                                                label: const Text('عرض الهدف المُبلّغ عنه'),
                                              ),
                                            ),
                                            if ((report['details'] ?? '')
                                                .toString()
                                                .isNotEmpty) ...[
                                              const SizedBox(height: 8),
                                              Text(report['details'].toString()),
                                            ],
                                            const SizedBox(height: 10),
                                            if (_canReview &&
                                                (status == 'open' ||
                                                    status == 'reviewing'))
                                              Wrap(
                                                spacing: 8,
                                                alignment:
                                                    WrapAlignment.end,
                                                children: [
                                                  OutlinedButton(
                                                    onPressed: busy
                                                        ? null
                                                        : () =>
                                                            _assignToMe(report),
                                                    child: Text(
                                                      assigned
                                                          ? 'مُسند إليك'
                                                          : 'تولي البلاغ',
                                                    ),
                                                  ),
                                                  FilledButton.tonal(
                                                    onPressed: busy
                                                        ? null
                                                        : () =>
                                                            _dismiss(report),
                                                    child: const Text(
                                                      'إغلاق دون إجراء',
                                                    ),
                                                  ),
                                                ],
                                              )
                                            else if (status == 'reviewing')
                                              const Align(
                                                alignment: AlignmentDirectional
                                                    .centerEnd,
                                                child: Text('قيد المراجعة'),
                                              ),
                                          ],
                                        ),
                                      ),
                                    );
                                  },
                                ),
                        ),
            ),
          ],
        ),
      );
}
