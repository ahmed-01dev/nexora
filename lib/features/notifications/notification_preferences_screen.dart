import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

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
    } catch (e) { if (mounted) setState(() { loading = false; error = e.toString(); }); }
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
    } catch (e) { if (mounted) setState(() => error = e.toString()); }
    finally { if (mounted) setState(() => saving = false); }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('تفضيلات الإشعارات')),
    body: loading ? const Center(child: CircularProgressIndicator()) : ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Card(child: Padding(padding: EdgeInsets.all(16), child: Text('اختار أنواع الإشعارات اللي تظهر داخل NEXORA. Push والبريد الإلكتروني غير مفعّلين حتى ربط مزود الإرسال.'))),
        if (error != null) Text(error!, style: const TextStyle(color: Colors.redAccent)),
        for (final item in categories.entries) Card(child: SwitchListTile(
          value: values[item.key] ?? true,
          onChanged: saving ? null : (value) => save(item.key, value),
          title: Text(item.value), subtitle: const Text('إشعار داخل التطبيق'),
        )),
      ],
    ),
  );
}
