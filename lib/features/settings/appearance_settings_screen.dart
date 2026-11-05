import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/app_error.dart';
import '../../core/theme/nexora_theme.dart';

final ValueNotifier<String> nexoraThemeNotifier = ValueNotifier<String>('amoled');
final ValueNotifier<Color> nexoraAccentNotifier =
    ValueNotifier<Color>(NexoraColors.violet);

String nexoraColorToHex(Color color) =>
    '#${color.toARGB32().toRadixString(16).padLeft(8, '0').substring(2).toUpperCase()}';

Color? parseNexoraAccent(String? value) {
  if (value == null) return null;
  final normalized = value.trim().replaceFirst('#', '');
  if (!RegExp(r'^[0-9a-fA-F]{6}$').hasMatch(normalized)) return null;
  return Color(int.parse('FF$normalized', radix: 16));
}

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
    'custom': 'لون مخصص',
  };

  static const List<Color> _accents = [
    NexoraColors.violet,
    NexoraColors.cyan,
    NexoraColors.pink,
    NexoraColors.amber,
    Color(0xFF38E8A5),
    Color(0xFF4F8CFF),
    Color(0xFFFF7043),
    Color(0xFFB388FF),
  ];

  Future<void> _save({required String theme, required Color accent}) async {
    if (_saving) return;
    setState(() => _saving = true);
    try {
      final uid = Supabase.instance.client.auth.currentUser!.id;
      await Supabase.instance.client.from('user_preferences').upsert({
        'user_id': uid,
        'theme': theme,
        'accent_color': nexoraColorToHex(accent),
        'updated_at': DateTime.now().toUtc().toIso8601String(),
      }, onConflict: 'user_id');
      nexoraAccentNotifier.value = accent;
      nexoraThemeNotifier.value = theme;
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تم حفظ المظهر واللون')),
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

  Future<void> _selectTheme(String value) {
    final accent = switch (value) {
      'pink_amoled' => NexoraColors.pink,
      'custom' => nexoraAccentNotifier.value,
      _ => NexoraColors.violet,
    };
    return _save(theme: value, accent: accent);
  }

  Future<void> _selectAccent(Color value) =>
      _save(theme: 'custom', accent: value);

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('المظهر')),
        body: ValueListenableBuilder<String>(
          valueListenable: nexoraThemeNotifier,
          builder: (context, selected, _) => ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Text(
                'اختر شكل NEXORA. سيتم حفظ اختيارك على حسابك ومزامنته عند تسجيل الدخول.',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.72),
                ),
              ),
              const SizedBox(height: 16),
              for (final entry in _labels.entries)
                Card(
                  child: RadioListTile<String>(
                    value: entry.key,
                    groupValue: selected,
                    onChanged: _saving ? null : (value) {
                      if (value != null) _selectTheme(value);
                    },
                    title: Text(entry.value),
                    subtitle: Text(switch (entry.key) {
                      'amoled' => 'أسود عميق لتقليل إضاءة الشاشة',
                      'light' => 'واجهة فاتحة وواضحة',
                      'pink_amoled' => 'أسود عميق مع لون وردي مميز',
                      _ => 'اختر لون التمييز من لوحة الألوان بالأسفل',
                    }),
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
                              : entry.key == 'custom'
                                  ? nexoraAccentNotifier.value
                                  : entry.key == 'light'
                                      ? const Color(0xFFBBBBBB)
                                      : const Color(0xFF555555),
                          width: 3,
                        ),
                      ),
                      child: entry.key == 'pink_amoled'
                          ? const Icon(Icons.circle, color: NexoraColors.pink, size: 15)
                          : entry.key == 'custom'
                              ? Icon(Icons.circle, color: nexoraAccentNotifier.value, size: 15)
                              : null,
                    ),
                  ),
                ),
              const SizedBox(height: 18),
              Text('لون التمييز المخصص', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 6),
              Text(
                'اختيار أي لون يحول المظهر إلى وضع مخصص ويحفظ اللون في حسابك.',
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 14,
                runSpacing: 14,
                children: [
                  for (final color in _accents)
                    Semantics(
                      button: true,
                      label: 'اختيار اللون ${nexoraColorToHex(color)}',
                      child: InkWell(
                        onTap: _saving ? null : () => _selectAccent(color),
                        borderRadius: BorderRadius.circular(30),
                        child: ValueListenableBuilder<Color>(
                          valueListenable: nexoraAccentNotifier,
                          builder: (context, accent, _) => Container(
                            width: 42,
                            height: 42,
                            decoration: BoxDecoration(
                              color: color,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: accent.toARGB32() == color.toARGB32()
                                    ? Theme.of(context).colorScheme.onSurface
                                    : Colors.transparent,
                                width: 3,
                              ),
                            ),
                            child: accent.toARGB32() == color.toARGB32()
                                ? const Icon(Icons.check, color: Colors.white)
                                : null,
                          ),
                        ),
                      ),
                    ),
                ],
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
