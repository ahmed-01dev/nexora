import 'package:flutter/material.dart';
import '../../core/theme/nexora_theme.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/app_error.dart';

class PrivacySettingsScreen extends StatefulWidget {
  const PrivacySettingsScreen({super.key});

  @override
  State<PrivacySettingsScreen> createState() => _PrivacySettingsScreenState();
}

class _PrivacySettingsScreenState extends State<PrivacySettingsScreen> {
  bool _loading = true;
  bool _saving = false;
  bool _isPrivate = false;
  bool _allowFriendRequests = true;
  String _messagesFrom = 'followers';
  String? _error;
  String? _loadedUserId;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    try {
      final client = Supabase.instance.client;
      final userId = client.auth.currentUser?.id;
      if (userId == null) throw StateError('انتهت جلسة الدخول.');
      final profile = await client
          .from('profiles')
          .select('is_private')
          .eq('id', userId)
          .maybeSingle();
      if (client.auth.currentUser?.id != userId) {
        throw StateError('تغير الحساب أثناء تحميل إعدادات الخصوصية.');
      }
      final settings = await client
          .from('user_private_settings')
          .select('allow_messages_from,allow_friend_requests')
          .eq('user_id', userId)
          .maybeSingle();
      if (!mounted) return;
      if (client.auth.currentUser?.id != userId) {
        setState(() {
          _error = 'تغير الحساب أثناء تحميل إعدادات الخصوصية.';
          _loading = false;
        });
        return;
      }
      setState(() {
        _loadedUserId = userId;
        _isPrivate = profile?['is_private'] as bool? ?? false;
        _messagesFrom = settings?['allow_messages_from'] as String? ?? 'followers';
        _allowFriendRequests = settings?['allow_friend_requests'] as bool? ?? true;
        _loading = false;
      });
    } catch (error, stack) {
      AppErrorService.report(error, stack, source: 'load_privacy_settings');
      if (mounted) setState(() { _error = AppErrorService.message(error); _loading = false; });
    }
  }

  Future<void> _save() async {
    final client = Supabase.instance.client;
    final userId = client.auth.currentUser?.id;
    if (userId == null || userId != _loadedUserId) {
      setState(() => _error = 'تغير الحساب. أعد تحميل إعدادات الخصوصية قبل الحفظ.');
      return;
    }
    setState(() { _saving = true; _error = null; });
    try {
      await client.rpc(
        'update_privacy_settings',
        params: {
          'p_is_private': _isPrivate,
          'p_allow_messages_from': _messagesFrom,
          'p_allow_friend_requests': _allowFriendRequests,
        },
      );
      if (!mounted || client.auth.currentUser?.id != userId) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تم حفظ إعدادات الخصوصية')),
      );
    } catch (error, stack) {
      AppErrorService.report(error, stack, source: 'save_privacy_settings');
      if (mounted) setState(() => _error = AppErrorService.message(error));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentUserId = Supabase.instance.client.auth.currentUser?.id;
    final viewerChanged = currentUserId == null ||
        (_loadedUserId != null && currentUserId != _loadedUserId);
    return Scaffold(
      appBar: AppBar(title: const Text('مركز الخصوصية')),
      body: viewerChanged
          ? Center(
              child: TextButton(
                onPressed: _load,
                child: const Text('تغير الحساب. أعد تحميل إعدادات الخصوصية.'),
              ),
            )
          : _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(18),
              children: [
                const Text(
                  'إنت المتحكم في مين يقدر يشوفك ويتواصل معاك.',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 18),
                Card(
                  child: SwitchListTile(
                    value: _isPrivate,
                    onChanged: _saving ? null : (value) => setState(() => _isPrivate = value),
                    title: const Text('حساب خاص'),
                    subtitle: const Text(
                      'عند تفعيل الخصوصية، منشوراتك ومعلومات ملفك تخضع لسياسات الحساب الخاص.',
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Card(
                  child: SwitchListTile(
                    value: _allowFriendRequests,
                    onChanged: _saving ? null : (value) => setState(() => _allowFriendRequests = value),
                    title: const Text('السماح بطلبات الصداقة'),
                    subtitle: const Text('لو أوقفتها، مش هيقدر أي حساب يرسل لك طلب صداقة جديد.'),
                  ),
                ),
                const SizedBox(height: 12),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const Text('مين يقدر يبعتلك رسالة؟',
                            style: TextStyle(fontWeight: FontWeight.w800)),
                        const SizedBox(height: 10),
                        DropdownButtonFormField<String>(
                          value: _messagesFrom,
                          items: const [
                            DropdownMenuItem(value: 'everyone', child: Text('أي شخص')),
                            DropdownMenuItem(value: 'followers', child: Text('الأشخاص اللي بتتابعهم')),
                            DropdownMenuItem(value: 'friends', child: Text('الأصدقاء فقط')),
                            DropdownMenuItem(value: 'nobody', child: Text('لا أحد')),
                          ],
                          onChanged: _saving
                              ? null
                              : (value) => setState(() => _messagesFrom = value ?? 'followers'),
                        ),
                        const SizedBox(height: 10),
                        const Text(
                          'الاختيار ده بيتطبق على إنشاء المحادثات الجديدة. الحظر المتبادل يمنع بدء محادثة في كل الحالات.',
                          style: TextStyle(fontSize: 12, color: NexoraColors.textMuted, height: 1.5),
                        ),
                      ],
                    ),
                  ),
                ),
                if (_error != null) ...[
                  const SizedBox(height: 12),
                  Text(_error!, style: const TextStyle(color: NexoraColors.danger)),
                ],
                const SizedBox(height: 20),
                FilledButton(
                  onPressed: _saving ? null : _save,
                  child: _saving
                      ? const SizedBox.square(dimension: 18, child: CircularProgressIndicator(strokeWidth: 2))
                      : const Text('حفظ التغييرات'),
                ),
              ],
            ),
    );
  }
}
