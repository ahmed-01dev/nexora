import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/app_error.dart';
import '../../core/theme/nexora_theme.dart';

final ValueNotifier<String> nexoraThemeNotifier =
    ValueNotifier<String>('amoled');

class AppearanceSettingsScreen extends StatefulWidget {
  const AppearanceSettingsScreen({super.key});

  @override
  State<AppearanceSettingsScreen> createState() =>
      _AppearanceSettingsScreenState();
}

class _AppearanceSettingsScreenState extends State<AppearanceSettingsScreen> {
  bool _saving = false;

  static const Map<String, String> _labels = {
    'amoled': 'أسود AMOLED',
    'light': 'فاتح',
    'pink_amoled': 'AMOLED وردي',
  };

  Future<void> _select(String value) async {
    if (_saving || value == nexoraThemeNotifier.value) return;
    setState(() => _saving = true);
    try {
      final uid = Supabase.instance.client.auth.currentUser!.id;
      await Supabase.instance.client.from('user_preferences').upsert({
        'user_id': uid,
        'theme': value,
        'updated_at': DateTime.now().toUtc().toIso8601String(),
      }, onConflict: 'user_id');
      nexoraThemeNotifier.value = value;
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تم حفظ المظهر')),
        );
      }
    } catch (error, stack) {
      AppErrorService.report(error, stack, source: 'save_appearance');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppErrorService.message(error))),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('المظهر')),
        body: ValueListenableBuilder<String>(
          valueListenable: nexoraThemeNotifier,
          builder: (context, selected, _) => ListView(
            padding: const EdgeInsets.all(16),
            children: [
              const Text(
                'اختر شكل NEXORA. سيتم حفظ اختيارك على حسابك ومزامنته عند تسجيل الدخول.',
                style: TextStyle(color: Colors.white70),
              ),
              const SizedBox(height: 16),
              for (final entry in _labels.entries)
                Card(
                  child: RadioListTile<String>(
                    value: entry.key,
                    groupValue: selected,
                    onChanged:
                        _saving ? null : (value) { if (value != null) _select(value); },
                    title: Text(entry.value),
                    subtitle: Text(
                      entry.key == 'amoled'
                          ? 'أسود عميق لتقليل إضاءة الشاشة'
                          : entry.key == 'light'
                              ? 'واجهة فاتحة وواضحة'
                              : 'أسود عميق مع لون وردي مميز',
                    ),
                    secondary: Container(
                      width: 34,
                      height: 34,
                      decoration: BoxDecoration(
                        color: entry.key == 'light'
                            ? const Color(0xFFF7F7F8)
                            : const Color(0xFF000000),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: entry.key == 'pink_amoled'
                              ? NexoraColors.pink
                              : entry.key == 'light'
                                  ? const Color(0xFFBBBBBB)
                                  : const Color(0xFF555555),
                          width: 3,
                        ),
                      ),
                      child: entry.key == 'pink_amoled'
                          ? const Icon(Icons.circle, color: NexoraColors.pink, size: 15)
                          : null,
                    ),
                  ),
                ),
              if (_saving)
                const Padding(
                  padding: EdgeInsets.all(18),
                  child: Center(child: CircularProgressIndicator()),
                ),
            ],
          ),
        ),
      );
}
