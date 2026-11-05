import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/app_error.dart';

class BlockedAccountsScreen extends StatefulWidget {
  const BlockedAccountsScreen({super.key});

  @override
  State<BlockedAccountsScreen> createState() => _BlockedAccountsScreenState();
}

class _BlockedAccountsScreenState extends State<BlockedAccountsScreen> {
  late Future<List<Map<String, dynamic>>> _future;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<List<Map<String, dynamic>>> _load() async {
    final client = Supabase.instance.client;
    final uid = client.auth.currentUser!.id;
    final rows = await client
        .from('blocks')
        .select(
          'blocked_id,created_at,profiles!blocks_blocked_id_fkey(id,username,display_name,avatar_url)',
        )
        .eq('blocker_id', uid)
        .order('created_at', ascending: false);
    return List<Map<String, dynamic>>.from(rows);
  }

  Future<void> _unblock(Map<String, dynamic> row) async {
    final profile = row['profiles'] is Map
        ? Map<String, dynamic>.from(row['profiles'] as Map)
        : <String, dynamic>{};
    final name = (profile['display_name'] ?? profile['username'] ?? 'هذا الحساب')
        .toString();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('إلغاء الحظر؟'),
        content: Text('هل تريد السماح لـ $name بالتفاعل معك مرة أخرى؟'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('إلغاء'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('إلغاء الحظر'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    try {
      await Supabase.instance.client
          .from('blocks')
          .delete()
          .eq('blocker_id', Supabase.instance.client.auth.currentUser!.id)
          .eq('blocked_id', row['blocked_id'] as String);
      if (!mounted) return;
      setState(() => _future = _load());
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تم إلغاء الحظر')),
      );
    } catch (error, stack) {
      AppErrorService.report(error, stack, source: 'unblock_account');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppErrorService.message(error))),
        );
      }
    }
  }

  Future<void> _refresh() async {
    setState(() => _future = _load());
    await _future;
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('الحسابات المحظورة')),
        body: FutureBuilder<List<Map<String, dynamic>>>(
          future: _future,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return AppErrorView(
                title: 'تعذر تحميل قائمة الحظر',
                error: snapshot.error,
                onRetry: _refresh,
              );
            }
            final rows = snapshot.data ?? const [];
            if (rows.isEmpty) {
              return const Center(
                child: Padding(
                  padding: EdgeInsets.all(28),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.shield_outlined, size: 46),
                      SizedBox(height: 12),
                      Text(
                        'قائمة الحظر فارغة',
                        style: TextStyle(fontWeight: FontWeight.w800),
                      ),
                      SizedBox(height: 6),
                      Text(
                        'الحسابات التي تحظرها ستظهر هنا، ويمكنك إلغاء حظرها في أي وقت.',
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              );
            }
            return RefreshIndicator(
              onRefresh: _refresh,
              child: ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: rows.length,
                separatorBuilder: (_, __) => const SizedBox(height: 8),
                itemBuilder: (context, index) {
                  final row = rows[index];
                  final profile = row['profiles'] is Map
                      ? Map<String, dynamic>.from(row['profiles'] as Map)
                      : <String, dynamic>{};
                  final username = (profile['username'] ?? 'unknown').toString();
                  final name =
                      (profile['display_name'] ?? 'مستخدم محظور').toString();
                  return Card(
                    child: ListTile(
                      leading: CircleAvatar(
                        child: Text(
                          name.isNotEmpty ? name.substring(0, 1) : '?',
                        ),
                      ),
                      title: Text(
                        name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      subtitle: Text('@$username'),
                      trailing: TextButton(
                        onPressed: () => _unblock(row),
                        child: const Text('إلغاء الحظر'),
                      ),
                    ),
                  );
                },
              ),
            );
          },
        ),
      );
}
