import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/app_error.dart';

class ModerationAppealsScreen extends StatefulWidget {
  const ModerationAppealsScreen({super.key});

  @override
  State<ModerationAppealsScreen> createState() =>
      _ModerationAppealsScreenState();
}

class _ModerationAppealsScreenState extends State<ModerationAppealsScreen> {
  static const int _pageSize = 30;
  final List<Map<String, dynamic>> _appeals = [];
  final Map<String, Map<String, dynamic>> _profiles = {};
  final Set<String> _busyIds = {};
  bool _loading = true;
  bool _loadingMore = false;
  bool _hasMore = true;
  bool _allStatuses = false;
  String? _error;
  String? _loadedReviewerId;

  @override
  void initState() {
    super.initState();
    _loadFirstPage();
  }

  Future<List<Map<String, dynamic>>> _fetchPage(int offset) async {
    final client = Supabase.instance.client;
    final reviewerId = client.auth.currentUser?.id;
    if (reviewerId == null) throw StateError('انتهت جلسة المراجعة.');
    var query = client
        .from('moderation_appeals')
        .select(
          'id,action_id,user_id,message,status,created_at,resolved_at,moderation_actions!moderation_appeals_action_id_fkey(action,reason,target_type,target_id)',
        );
    if (!_allStatuses) query = query.eq('status', 'open');
    final rows = await query
        .order('created_at', ascending: false)
        .order('id', ascending: false)
        .range(offset, offset + _pageSize - 1);
    if (client.auth.currentUser?.id != reviewerId) {
      throw StateError('تغير حساب المراجع أثناء تحميل الاستئنافات.');
    }
    final page = List<Map<String, dynamic>>.from(rows);

    final userIds = page
        .map((row) => row['user_id'] as String)
        .toSet()
        .toList();
    if (userIds.isNotEmpty) {
      final profiles = await client
          .from('profiles')
          .select('id,username,display_name')
          .inFilter('id', userIds);
      if (client.auth.currentUser?.id != reviewerId) {
        throw StateError('تغير حساب المراجع أثناء تحميل ملفات المستخدمين.');
      }
      for (final profile in profiles) {
        _profiles[profile['id'] as String] =
            Map<String, dynamic>.from(profile);
      }
    }
    if (client.auth.currentUser?.id != reviewerId) {
      throw StateError('تغير حساب المراجع أثناء تحميل الاستئنافات.');
    }
    _loadedReviewerId = reviewerId;
    return page;
  }

  Future<void> _loadFirstPage() async {
    setState(() {
      _loading = true;
      _loadingMore = false;
      _hasMore = true;
      _error = null;
      _appeals.clear();
      _profiles.clear();
    });
    try {
      final page = await _fetchPage(0);
      if (!mounted) return;
      setState(() {
        _appeals.addAll(page);
        _hasMore = page.length == _pageSize;
        _loading = false;
      });
    } catch (error, stack) {
      AppErrorService.report(error, stack, source: 'moderation_appeals_load');
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
      final page = await _fetchPage(_appeals.length);
      if (!mounted) return;
      setState(() {
        _appeals.addAll(page);
        _hasMore = page.length == _pageSize;
        _loadingMore = false;
      });
    } catch (error, stack) {
      AppErrorService.report(error, stack, source: 'moderation_appeals_more');
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

  Future<void> _decide(Map<String, dynamic> appeal, String decision) async {
    final id = appeal['id'] as String;
    final client = Supabase.instance.client;
    final reviewerId = client.auth.currentUser?.id;
    if (reviewerId == null || reviewerId != _loadedReviewerId ||
        _busyIds.contains(id)) return;
    final isOverturn = decision == 'overturned';
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(isOverturn ? 'قبول الاستئناف' : 'تأييد الإجراء'),
        content: Text(
          isOverturn
              ? 'سيتم تسجيل قبول الاستئناف في سجل المراجعة. هذا القرار لا يغيّر قيود الحساب تلقائيًا.'
              : 'سيتم تسجيل تأييد الإجراء الأصلي في سجل المراجعة.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('رجوع'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('تأكيد القرار'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted ||
        client.auth.currentUser?.id != reviewerId) return;

    setState(() => _busyIds.add(id));
    try {
      await client
          .from('moderation_appeals')
          .update({
            'status': decision,
            'reviewer_id': reviewerId,
            'resolved_at': DateTime.now().toUtc().toIso8601String(),
          })
          .eq('id', id);
      if (client.auth.currentUser?.id == reviewerId) {
        await _loadFirstPage();
      }
    } catch (error, stack) {
      AppErrorService.report(error, stack, source: 'moderation_appeal_decision');
      _showError(error);
    } finally {
      if (mounted) setState(() => _busyIds.remove(id));
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentUserId = Supabase.instance.client.auth.currentUser?.id;
    final reviewerChanged = currentUserId == null ||
        (_loadedReviewerId != null && currentUserId != _loadedReviewerId);
    return Scaffold(
        appBar: AppBar(
          title: const Text('مراجعة الاستئنافات'),
          actions: [
            IconButton(
              tooltip: 'تحديث',
              onPressed: _loading ? null : _loadFirstPage,
              icon: const Icon(Icons.refresh),
            ),
          ],
        ),
        body: reviewerChanged
            ? Center(child: TextButton(onPressed: _loadFirstPage, child: const Text('تغير حساب المراجع. أعد تحميل الاستئنافات.')))
            : Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
              child: Row(
                children: [
                  ChoiceChip(
                    label: const Text('المفتوحة'),
                    selected: !_allStatuses,
                    onSelected: (_) {
                      if (!_allStatuses) return;
                      setState(() => _allStatuses = false);
                      _loadFirstPage();
                    },
                  ),
                  const SizedBox(width: 8),
                  ChoiceChip(
                    label: const Text('الكل'),
                    selected: _allStatuses,
                    onSelected: (_) {
                      if (_allStatuses) return;
                      setState(() => _allStatuses = true);
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
                              const Text('تعذر تحميل الاستئنافات'),
                              TextButton(
                                onPressed: _loadFirstPage,
                                child: const Text('إعادة المحاولة'),
                              ),
                            ],
                          ),
                        )
                      : RefreshIndicator(
                          onRefresh: _loadFirstPage,
                          child: _appeals.isEmpty
                              ? ListView(
                                  physics: const AlwaysScrollableScrollPhysics(),
                                  children: const [
                                    SizedBox(height: 120),
                                    Icon(Icons.gavel_outlined, size: 52),
                                    SizedBox(height: 12),
                                    Center(child: Text('لا توجد استئنافات في هذا العرض')),
                                  ],
                                )
                              : ListView.separated(
                                  padding: const EdgeInsets.all(16),
                                  itemCount: _appeals.length +
                                      (_hasMore || _loadingMore ? 1 : 0),
                                  separatorBuilder: (_, __) =>
                                      const SizedBox(height: 10),
                                  itemBuilder: (context, index) {
                                    if (index == _appeals.length) {
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

                                    final appeal = _appeals[index];
                                    final id = appeal['id'] as String;
                                    final action = appeal['moderation_actions'] is Map
                                        ? Map<String, dynamic>.from(
                                            appeal['moderation_actions'] as Map,
                                          )
                                        : <String, dynamic>{};
                                    final profile =
                                        _profiles[appeal['user_id']] ?? {};
                                    final status =
                                        (appeal['status'] ?? 'open').toString();
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
                                                    (profile['display_name'] ??
                                                            profile['username'] ??
                                                            appeal['user_id'])
                                                        .toString(),
                                                    style: const TextStyle(
                                                      fontWeight:
                                                          FontWeight.w800,
                                                    ),
                                                  ),
                                                ),
                                                Chip(
                                                  label: Text(
                                                    status == 'open'
                                                        ? 'مفتوح'
                                                        : status == 'upheld'
                                                            ? 'مؤيد'
                                                            : status == 'overturned'
                                                                ? 'مقبول'
                                                                : status,
                                                  ),
                                                ),
                                              ],
                                            ),
                                            Text(
                                              'الإجراء: ${action['action'] ?? 'غير معروف'} · ${action['reason'] ?? ''}',
                                              style: const TextStyle(
                                                color: Colors.white70,
                                                fontSize: 12,
                                              ),
                                            ),
                                            const SizedBox(height: 8),
                                            Text(appeal['message'].toString()),
                                            if (status == 'open') ...[
                                              const SizedBox(height: 12),
                                              Wrap(
                                                spacing: 8,
                                                alignment:
                                                    WrapAlignment.end,
                                                children: [
                                                  OutlinedButton(
                                                    onPressed: busy
                                                        ? null
                                                        : () => _decide(
                                                              appeal,
                                                              'upheld',
                                                            ),
                                                    child: const Text(
                                                      'تأييد الإجراء',
                                                    ),
                                                  ),
                                                  FilledButton(
                                                    onPressed: busy
                                                        ? null
                                                        : () => _decide(
                                                              appeal,
                                                              'overturned',
                                                            ),
                                                    child: const Text(
                                                      'قبول الاستئناف',
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ],
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

