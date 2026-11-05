import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class BlockAccountService {
  static Future<bool> confirmAndBlock(
    BuildContext context, {
    required String targetUserId,
    required String displayName,
  }) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('حظر الحساب؟'),
        content: Text(
          'لن يتمكن $displayName من بدء محادثة معك أو التفاعل معك في المساحات التي تطبق الحظر. يمكنك إلغاء الحظر من مركز الخصوصية.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('إلغاء'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('حظر'),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return false;

    final client = Supabase.instance.client;
    final me = client.auth.currentUser!.id;
    final existing = await client
        .from('blocks')
        .select('blocked_id')
        .eq('blocker_id', me)
        .eq('blocked_id', targetUserId)
        .maybeSingle();
    if (existing == null) {
      await client.from('blocks').insert({
        'blocker_id': me,
        'blocked_id': targetUserId,
      });
    }
    return true;
  }
}
