import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/theme/nexora_theme.dart';

import '../../core/app_error.dart';
import '../messaging/messages_screen.dart';
import 'nearby_distance_band.dart';

class NearbyDiscoveryScreen extends StatefulWidget {
  const NearbyDiscoveryScreen({super.key});

  @override
  State<NearbyDiscoveryScreen> createState() => _NearbyDiscoveryScreenState();
}

class _NearbyDiscoveryScreenState extends State<NearbyDiscoveryScreen> {
  bool _loading = true;
  bool _busy = false;
  bool _enabled = false;
  String? _error;
  String? _loadedUserId;
  List<Map<String, dynamic>> _people = const [];

  @override
  void initState() {
    super.initState();
    _loadStatus();
  }

  Future<void> _loadStatus() async {
    setState(() { _loading = true; _error = null; });
    try {
      final client = Supabase.instance.client;
      final userId = client.auth.currentUser?.id;
      if (userId == null) throw StateError('انتهت جلسة الدخول.');
      final result = await client.rpc('my_nearby_presence_enabled');
      if (client.auth.currentUser?.id != userId) {
        if (mounted) setState(() { _loading = false; _error = 'تغير الحساب. أعد تحميل اكتشاف الأشخاص القريبين.'; });
        return;
      }
      final enabled = result == true;
      if (!mounted) return;
      _loadedUserId = userId;
      setState(() { _enabled = enabled; _loading = false; });
      if (enabled) await _loadPeople();
    } catch (error, stack) {
      AppErrorService.report(error, stack, source: 'nearby_status');
      if (mounted) setState(() { _error = AppErrorService.message(error); _loading = false; });
    }
  }

  Future<void> _loadPeople() async {
    try {
      final client = Supabase.instance.client;
      final userId = client.auth.currentUser?.id;
      if (userId == null || userId != _loadedUserId) {
        throw StateError('تغير الحساب. حدّث اكتشاف الأشخاص القريبين.');
      }
      final rows = await client.rpc(
        'find_nearby_people',
        params: {'p_limit': 50},
      );
      if (!mounted || client.auth.currentUser?.id != userId) return;
      setState(() => _people = List<Map<String, dynamic>>.from(rows as List));
    } catch (error, stack) {
      AppErrorService.report(error, stack, source: 'nearby_people');
      if (mounted) setState(() => _error = AppErrorService.message(error));
    }
  }

  String _nearbyErrorMessage(Object error) {
    final detail = error.toString();
    if (detail.contains('فعّل خدمة الموقع')) {
      return 'خدمة الموقع مقفولة. فعّلها من إعدادات الجهاز وحاول تاني.';
    }
    if (detail.contains('لازم تسمح بإذن الموقع')) {
      return 'لازم تسمح بإذن الموقع أثناء استخدام التطبيق لتشغيل اكتشاف الأشخاص القريبين.';
    }
    if (detail.contains('إذن الموقع مرفوض نهائيًا')) {
      return 'إذن الموقع مرفوض نهائيًا. افتح إعدادات التطبيق واسمح بالموقع، ثم ارجع وحاول تاني.';
    }
    if (detail.contains('Location service') ||
        detail.contains('location permissions')) {
      return 'تعذر الوصول للموقع. راجع خدمة الموقع والأذونات وحاول تاني.';
    }
    return AppErrorService.message(error);
  }

  Future<void> _setEnabled(bool value) async {
    if (_busy) return;
    final client = Supabase.instance.client;
    final userId = client.auth.currentUser?.id;
    if (userId == null || userId != _loadedUserId) {
      setState(() => _error = 'تغير الحساب. أعد تحميل اكتشاف الأشخاص القريبين.');
      return;
    }
    setState(() { _busy = true; _error = null; });
    try {
      if (!value) {
        await client.rpc('update_my_nearby_presence', params: {
          'p_latitude': null, 'p_longitude': null, 'p_enabled': false,
        });
        if (!mounted || client.auth.currentUser?.id != userId) return;
        setState(() { _enabled = false; _people = const []; });
        return;
      }
      if (!await Geolocator.isLocationServiceEnabled()) {
        throw Exception('فعّل خدمة الموقع في جهازك ثم حاول مرة تانية.');
      }
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied) {
        throw Exception('لازم تسمح بإذن الموقع عشان تقدر تستخدم اكتشاف الأشخاص القريبين.');
      }
      if (permission == LocationPermission.deniedForever) {
        if (!kIsWeb) await Geolocator.openAppSettings();
        throw Exception('إذن الموقع مرفوض نهائيًا. افتح إعدادات التطبيق واسمح بالموقع.');
      }
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.medium,
          timeLimit: Duration(seconds: 20),
        ),
      );
      if (client.auth.currentUser?.id != userId) return;
      await client.rpc('update_my_nearby_presence', params: {
        'p_latitude': position.latitude,
        'p_longitude': position.longitude,
        'p_enabled': true,
      });
      if (!mounted || client.auth.currentUser?.id != userId) return;
      setState(() => _enabled = true);
      await _loadPeople();
    } catch (error, stack) {
      AppErrorService.report(error, stack, source: 'nearby_toggle');
      if (mounted) setState(() => _error = _nearbyErrorMessage(error));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  String _displayName(Map<String, dynamic> person) {
    final name = (person['display_name'] as String?)?.trim();
    if (name != null && name.isNotEmpty) return name;
    return '@${person['username'] ?? 'user'}';
  }

  Future<void> _messagePerson(Map<String, dynamic> person) async {
    final client = Supabase.instance.client;
    final userId = client.auth.currentUser?.id;
    if (userId == null || userId != _loadedUserId) return;
    try {
      final conversationId = await client.rpc(
        'create_direct_conversation',
        params: {'p_other_user_id': person['id']},
      );
      if (!mounted || client.auth.currentUser?.id != userId) return;
      await Navigator.of(context).push(MaterialPageRoute<void>(
        builder: (_) => ChatScreen(
          conversationId: conversationId.toString(),
          title: _displayName(person),
        ),
      ));
    } catch (error, stack) {
      AppErrorService.report(error, stack, source: 'nearby_start_conversation');
      if (!mounted || client.auth.currentUser?.id != userId) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppErrorService.message(error))),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentUserId = Supabase.instance.client.auth.currentUser?.id;
    final viewerChanged = currentUserId == null ||
        (_loadedUserId != null && currentUserId != _loadedUserId);
    return Scaffold(
    appBar: AppBar(
      title: const Text('الأشخاص القريبون'),
      actions: [
        IconButton(
          tooltip: 'تحديث الموقع والنتائج',
          onPressed: _busy || !_enabled ? null : () => _setEnabled(true),
          icon: const Icon(Icons.refresh),
        ),
      ],
    ),
    body: viewerChanged
      ? Center(child: TextButton(onPressed: _loadStatus, child: const Text('تغير الحساب. أعد تحميل اكتشاف الأشخاص القريبين.')))
      : _loading
      ? const Center(child: CircularProgressIndicator())
      : ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Card(child: SwitchListTile(
              value: _enabled,
              onChanged: _busy ? null : _setEnabled,
              title: const Text('السماح باكتشاف حسابي بالقرب'),
              subtitle: const Text('اختياري تمامًا. تقدر توقفه في أي وقت.'),
            )),
            const SizedBox(height: 10),
            const Card(child: Padding(
              padding: EdgeInsets.all(16),
              child: Text(
                'حماية موقعك: بنقرب الموقع قبل تخزينه (بدقة تقريبية حوالي كيلومتر)، ومش بنعرض إحداثيات أو مسافة دقيقة. النتائج بتظهر للحسابات العامة اللي فعّلت الميزة فقط، مع استبعاد الحسابات الخاصة والمحظورة. بيانات الموقع بتنتهي بعد 24 ساعة.',
                style: TextStyle(height: 1.5),
              ),
            )),
            if (_busy) const Padding(
              padding: EdgeInsets.all(18),
              child: Center(child: CircularProgressIndicator()),
            ),
            if (_error != null) ...[
              const SizedBox(height: 12),
              Text(_error!, style: const TextStyle(color: NexoraColors.danger)),
              TextButton(onPressed: _loadStatus, child: const Text('إعادة المحاولة')),
            ],
            if (_enabled && !_busy) ...[
              const SizedBox(height: 16),
              Text('حسابات قريبة منك', style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 8),
              if (_people.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 28),
                  child: Center(child: Text('مفيش حسابات قريبة مفعّلة الميزة حاليًا.')),
                )
              else
                for (final person in _people)
                  Card(child: ListTile(
                    leading: CircleAvatar(child: Text(_displayName(person).characters.first.toUpperCase())),
                    title: Text(_displayName(person)),
                    trailing: IconButton(
                      tooltip: 'مراسلة',
                      onPressed: () => _messagePerson(person),
                      icon: const Icon(Icons.chat_bubble_outline),
                    ),
                    dense: false,
                    subtitle: Text(
                      '@${person['username'] ?? ''} • ${nearbyDistanceLabel(person['distance_band']?.toString() ?? '')}',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  )),
            ],
          ],
        ),
  );
  }
}
