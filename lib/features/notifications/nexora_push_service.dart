import 'dart:async';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class NexoraPushService {
  NexoraPushService._();
  static final instance = NexoraPushService._();
  bool _started = false;
  StreamSubscription<String>? _tokenSubscription;

  bool get supported => !kIsWeb &&
      defaultTargetPlatform == TargetPlatform.android &&
      Firebase.apps.isNotEmpty;

  Future<void> initialize() async {
    if (!supported || _started) return;
    _started = true;
    _tokenSubscription = FirebaseMessaging.instance.onTokenRefresh.listen((token) {
      saveToken(token);
    });
    await registerIfAllowed();
  }

  Future<AuthorizationStatus?> status() async {
    if (!supported) return null;
    return (await FirebaseMessaging.instance.getNotificationSettings())
        .authorizationStatus;
  }

  Future<bool> requestPermission() async {
    if (!supported) return false;
    final settings = await FirebaseMessaging.instance.requestPermission(
      alert: true, badge: true, sound: true,
    );
    if (settings.authorizationStatus != AuthorizationStatus.authorized) {
      return false;
    }
    final token = await FirebaseMessaging.instance.getToken();
    if (token == null || token.isEmpty) return false;
    await saveToken(token);
    return true;
  }

  Future<void> registerIfAllowed() async {
    if (!supported || Supabase.instance.client.auth.currentUser == null) return;
    if (await status() != AuthorizationStatus.authorized) return;
    final token = await FirebaseMessaging.instance.getToken();
    if (token != null && token.isNotEmpty) await saveToken(token);
  }

  Future<void> saveToken(String token) async {
    if (!supported) return;
    final client = Supabase.instance.client;
    final userId = client.auth.currentUser?.id;
    if (userId == null) return;
    try {
      await client.from('user_devices').upsert({
        'user_id': userId,
        'platform': 'android',
        'push_token': token,
        'device_label': 'Android device',
        'last_seen_at': DateTime.now().toUtc().toIso8601String(),
      }, onConflict: 'user_id,push_token');
    } catch (error) {
      debugPrint('NEXORA push token registration failed: $error');
    }
  }

  Future<void> unregisterCurrentDevice() async {
    if (!supported) return;
    final client = Supabase.instance.client;
    final userId = client.auth.currentUser?.id;
    if (userId == null) return;
    try {
      final token = await FirebaseMessaging.instance.getToken();
      if (token == null || token.isEmpty) return;
      await client.from('user_devices').delete()
          .eq('user_id', userId).eq('push_token', token);
    } catch (error) {
      debugPrint('NEXORA push token removal failed: $error');
    }
  }
  Future<void> dispose() async {
    await _tokenSubscription?.cancel();
    _tokenSubscription = null;
    _started = false;
  }
}
