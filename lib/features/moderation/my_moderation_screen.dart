import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/app_error.dart';

class MyModerationScreen extends StatefulWidget {
  const MyModerationScreen({super.key});

  @override
  State<MyModerationScreen> createState() => _MyModerationScreenState();
}

class _MyModerationScreenState extends State<MyModerationScreen> {
  bool _loading = true;
  String? _error;
  List<Map<String, dynamic>> _actions = [];
  final Map<String, Map<String, dynamic>> _appealsByAction = {};
  final Set<String> _busyIds = {};
  String? _loadedUserId;

  static const Map<String, String> _actionLabels = {
    'warn': 'تحذير',
    'remove_content': 'إزالة محتوى',
    'restrict': 'تقييد الحساب',
    'suspend': 'إيقاف مؤقت',
    'ban': 'حظر الحساب',
    'dismiss': 'تم رفض البلاغ',
  };

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
      _actions = [];
      _appealsByAction.clear();
    });
    try {
      final db = Supabase.instance.client;
      final uid = db.auth.currentUser?.id;
      if (uid == null) throw StateError('انتهت جلسة الدخول.');
      final actions = await db
          .from('moderation_actions')
          .select('id,action,reason,created_at,expires_at')
          .eq('target_type', 'user')
          .eq('target_id', uid)
          .order('created_at', ascending: false)
          .limit(100);
      if (db.auth.currentUser?.id != uid) throw StateError('تغير الحساب أثناء تحميل الإجراءات.');
      final rows = List<Map<String, dynamic>>.from(actions);
      if (rows.isNotEmpty) {
        final ids = rows.map((row) => row['id'] as String).toList();
        final appeals = await db
            .from('moderation_appeals')
            .select('id,action_id,message,status,created_at,resolved_at')
            .eq('user_id', uid)
            .inFilter('action_id', ids);
        if (db.auth.currentUser?.id != uid) throw StateError('تغير الحساب أثناء تحميل الاستئنافات.');
        for (final appeal in appeals) {
          _appealsByAction[appeal['action_id'] as String] =
              Map<String, dynamic>.from(appeal);
        }
      }
      if (!mounted) return;
      if (db.auth.currentUser?.id != uid) return;
      _loadedUserId = uid;
      setState(() {
        _actions = rows;
        _loading = false;
      });
    } catch (error, stack) {
      AppErrorService.report(error, stack, source: 'my_moderation_load');
      if (mounted) {
        setState(() {
          _error = AppErrorService.message(error);
          _loading = false;
        });
      }
    }
  }

  Future<void> _appeal(Map<String, dynamic> action) async {
    final actionId = action['id'] as String;
    if (_busyIds.contains(actionId) ||
        action['action'] == 'dismiss' ||
        _appealsByAction.containsKey(actionId)) {
      return;
    }

    final client = Supabase.instance.client;
    final actorId = client.auth.currentUser?.id;
    if (actorId == null || actorId != _loadedUserId) return;
    final controller = TextEditingController();
    final message = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('تقديم استئناف'),
        content: TextField(
          controller: controller,
          autofocus: true,
          maxLength: 2000,
          maxLines: 5,
          decoration: const InputDecoration(
            labelText: 'اشرح سبب اعتراضك',
            alignLabelWithHint: true,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('إلغاء'),
          ),
          FilledButton(
            onPressed: () {
              final value = controller.text.trim();
              if (value.length < 10) return;
              Navigator.pop(dialogContext, value);
            },
            child: const Text('إرسال'),
          ),
        ],
      ),
    );
    controller.dispose();
    if (message == null || !mounted ||
        client.auth.currentUser?.id != actorId) return;

    setState(() => _busyIds.add(actionId));
    try {
      final inserted = await client
          .from('moderation_appeals')
          .insert({
            'action_id': actionId,
            'user_id': uid,
            'message': message,
          })
          .select('id,action_id,message,status,created_at,resolved_at')
          .single();
      if (mounted && client.auth.currentUser?.id == actorId) {
        setState(() {
          _appealsByAction[actionId] = Map<String, dynamic>.from(inserted);
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تم إرسال الاستئناف للمراجعة')),
        );
      }
    } catch (error, stack) {
      AppErrorService.report(error, stack, source: 'submit_moderation_appeal');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppErrorService.message(error))),
        );
      }
    } finally {
      if (mounted) setState(() => _busyIds.remove(actionId));
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentUserId = Supabase.instance.client.auth.currentUser?.id;
    final viewerChanged = currentUserId == null ||
        (_loadedUserId != null && currentUserId != _loadedUserId);
    return Scaffold(
        appBar: AppBar(
          title: const Text('إجراءاتي والاستئنافات'),
          actions: [
            IconButton(
              tooltip: 'تحديث',
              onPressed: _loading ? null : _load,
              icon: const Icon(Icons.refresh),
            ),
          ],
        ),
        body: viewerChanged
            ? Center(child: TextButton(onPressed: _load, child: const Text('تغير الحساب. أعد تحميل الإجراءات.')))
            : _loading
            ? const Center(child: CircularProgressIndicator())
            : _error != null
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text('تعذر تحميل الإجراءات'),
                        TextButton(onPressed: _load, child: const Text('إعادة المحاولة')),
                      ],
                    ),
                  )
                : RefreshIndicator(
                    onRefresh: _load,
                    child: _actions.isEmpty
                        ? ListView(
                            physics: const AlwaysScrollableScrollPhysics(),
                            children: const [
                              SizedBox(height: 120),
                              Icon(Icons.verified_user_outlined, size: 52),
                              SizedBox(height: 12),
                              Center(child: Text('لا توجد إجراءات إشرافية على حسابك')),
                            ],
                          )
                        : ListView.separated(
                            padding: const EdgeInsets.all(16),
                            itemCount: _actions.length,
                            separatorBuilder: (_, __) => const SizedBox(height: 10),
                            itemBuilder: (context, index) {
                              final action = _actions[index];
                              final id = action['id'] as String;
                              final actionType = action['action'].toString();
                              final appeal = _appealsByAction[id];
                              final appealStatus = appeal?['status']?.toString();
                              final busy = _busyIds.contains(id);
                              final canAppeal =
                                  actionType != 'dismiss' && appeal == null;
                              return Card(
                                child: Padding(
                                  padding: const EdgeInsets.all(16),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.stretch,
                                    children: [
                                      Row(
                                        children: [
                                          Expanded(
                                            child: Text(
                                              _actionLabels[actionType] ?? actionType,
                                              style: const TextStyle(
                                                fontWeight: FontWeight.w800,
                                              ),
                                            ),
                                          ),
                                          Chip(
                                            label: Text(
                                              appealStatus == 'open'
                                                  ? 'استئناف قيد المراجعة'
                                                  : appealStatus == 'upheld'
                                                      ? 'تم تأييد الإجراء'
                                                      : appealStatus == 'overturned'
                                                          ? 'تم إلغاء الإجراء'
                                                          : 'إجراء مسجل',
                                            ),
                                          ),
                                        ],
                                      ),
                                      if ((action['reason'] ?? '').toString().isNotEmpty)
                                        Text(action['reason'].toString()),
                                      const SizedBox(height: 6),
                                      Text(
                                        'تاريخ الإجراء: ${action['created_at']}',
                                        style: const TextStyle(
                                          color: Colors.white54,
                                          fontSize: 11,
                                        ),
                                      ),
                                      if (action['expires_at'] != null)
                                        Text(
                                          'ينتهي في: ${action['expires_at']}',
                                          style: const TextStyle(
                                            color: Colors.white54,
                                            fontSize: 11,
                                          ),
                                        ),
                                      if (appeal != null) ...[
                                        const SizedBox(height: 10),
                                        Text('استئنافك: ${appeal['message']}'),
                                      ],
                                      if (canAppeal) ...[
                                        const SizedBox(height: 12),
                                        Align(
                                          alignment: AlignmentDirectional.centerEnd,
                                          child: OutlinedButton.icon(
                                            onPressed: busy ? null : () => _appeal(action),
                                            icon: busy
                                                ? const SizedBox.square(
                                                    dimension: 16,
                                                    child: CircularProgressIndicator(
                                                      strokeWidth: 2,
                                                    ),
                                                  )
                                                : const Icon(Icons.gavel_outlined),
                                            label: const Text('اعترض على الإجراء'),
                                          ),
                                        ),
                                      ],
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
