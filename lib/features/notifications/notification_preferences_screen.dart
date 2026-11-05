import 'package:flutter/material.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/app_error.dart';
import 'nexora_push_service.dart';

class NotificationPreferencesScreen extends StatefulWidget {
  const NotificationPreferencesScreen({super.key});
  @override
  State<NotificationPreferencesScreen> createState() => _NotificationPreferencesScreenState();
}

class _NotificationPreferencesScreenState extends State<NotificationPreferencesScreen> {
  static const categories = <String, String>{
    'like': 'الإعجابات', 'comment': 'التعليقات', 'reply': 'الردود',
    'follow': 'المتابعات', 'friend_request': 'طلبات الصداقة',
    'friend_accepted': 'قبول طلب الصداقة', 'mention': 'الإشارات إليك',
    'repost': 'إعادة النشر', 'message': 'الرسائل', 'call': 'المكالمات',
    'group_invite': 'دعوات المجموعات', 'system': 'إشعارات النظام', 'security': 'التنبيهات الأمنية',
  };
  final Map<String, bool> values = {};
  final Map<String, Map<String, dynamic>> settings = {};
  bool loading = true;
  bool saving = false;
  String? error;

  @override
  void initState() { super.initState(); load(); }

  Future<void> load() async {
    try {
      final uid = Supabase.instance.client.auth.currentUser!.id;
      final rows = await Supabase.instance.client.from('notification_preferences').select('category,in_app,push,email').eq('user_id', uid);
      values.clear();
      settings.clear();
      for (final row in rows) {
        final category = row['category'] as String;
        values[category] = row['in_app'] as bool? ?? true;
        settings[category] = Map<String, dynamic>.from(row);
      }
      if (mounted) setState(() { loading = false; error = null; });
    } catch (e, stack) {
      AppErrorService.report(e, stack, source: 'notification_preferences_load');
      if (mounted) setState(() { loading = false; error = AppErrorService.message(e); });
    }
  }

  Future<void> save(String category, bool enabled) async {
    if (saving) return;
    setState(() { saving = true; error = null; });
    try {
      final uid = Supabase.instance.client.auth.currentUser!.id;
      final previous = settings[category] ?? <String, dynamic>{'push': true, 'email': false};
      final updated = <String, dynamic>{
        'user_id': uid, 'category': category, 'in_app': enabled,
        'push': previous['push'] as bool? ?? true,
        'email': previous['email'] as bool? ?? false,
      };
      await Supabase.instance.client.from('notification_preferences').upsert(
        updated, onConflict: 'user_id,category',
      );
      if (mounted) setState(() {
        values[category] = enabled;
        settings[category] = updated;
      });
    } catch (e, stack) {
      AppErrorService.report(e, stack, source: 'notification_preferences_save');
      if (mounted) setState(() => error = AppErrorService.message(e));
    }
    finally { if (mounted) setState(() => saving = false); }
  }


  Future<void> savePush(String category, bool enabled) async {
    if (saving) return;
    if (enabled) {
      final granted = await NexoraPushService.instance.requestPermission();
      if (!granted) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('اسمح بإشعارات NEXORA من إعدادات الهاتف أولاً.')),
          );
        }
        return;
      }
    }
    setState(() { saving = true; error = null; });
    try {
      final uid = Supabase.instance.client.auth.currentUser!.id;
      final previous = settings[category] ??
          <String, dynamic>{'in_app': true, 'email': false};
      final updated = <String, dynamic>{
        'user_id': uid,
        'category': category,
        'in_app': previous['in_app'] as bool? ?? true,
        'push': enabled,
        'email': previous['email'] as bool? ?? false,
      };
      await Supabase.instance.client.from('notification_preferences').upsert(
        updated, onConflict: 'user_id,category',
      );
      if (mounted) setState(() => settings[category] = updated);
    } catch (e, stack) {
      AppErrorService.report(e, stack, source: 'notification_push_preference_save');
      if (mounted) setState(() => error = AppErrorService.message(e));
    } finally {
      if (mounted) setState(() => saving = false);
    }
  }

  Future<void> enableDevicePush() async {
    final enabled = await NexoraPushService.instance.requestPermission();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(enabled
          ? 'تم تفعيل إذن إشعارات الهاتف لهذا الجهاز.'
          : 'لم يتم منح إذن الإشعارات. راجع إعدادات الهاتف.')),
    );
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('تفضيلات الإشعارات')),
    body: loading ? const Center(child: CircularProgressIndicator()) : ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('إشعارات الهاتف'),
                const SizedBox(height: 6),
                FutureBuilder<AuthorizationStatus?>(
                  future: NexoraPushService.instance.status(),
                  builder: (context, snapshot) {
                    final status = snapshot.data;
                    final label = status == AuthorizationStatus.authorized
                        ? 'الإذن مفعّل على هذا الجهاز'
                        : status == AuthorizationStatus.denied
                            ? 'الإذن مرفوض من إعدادات الهاتف'
                            : 'لم يتم تفعيل الإذن بعد';
                    return Text(label);
                  },
                ),
                const SizedBox(height: 10),
                OutlinedButton.icon(
                  onPressed: saving ? null : enableDevicePush,
                  icon: const Icon(Icons.notifications_active_outlined),
                  label: const Text('تفعيل إشعارات الهاتف'),
                ),
              ],
            ),
          ),
        ),
        const Card(child: Padding(
          padding: EdgeInsets.all(16),
          child: Text('تحكم في الإشعارات داخل التطبيق وإشعارات الهاتف لكل نوع.'),
        )),
        if (error != null) Text(error!, style: const TextStyle(color: Colors.redAccent)),
        for (final item in categories.entries) Card(
          child: Column(
            children: [
              SwitchListTile(
                value: values[item.key] ?? true,
                onChanged: saving ? null : (value) => save(item.key, value),
                title: Text(item.value),
                subtitle: const Text('داخل التطبيق'),
              ),
              SwitchListTile(
                value: settings[item.key]?['push'] as bool? ?? true,
                onChanged: saving ? null : (value) => savePush(item.key, value),
                title: const Text('إشعار الهاتف'),
                subtitle: const Text('Push notification'),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}
