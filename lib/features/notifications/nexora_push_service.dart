import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Registers real Firebase Cloud Messaging registration tokens for this account.
class NexoraPushService {
  NexoraPushService._();
  static final instance = NexoraPushService._();

  bool _started = false;
  String? _lastFcmToken;
  StreamSubscription<String>? _tokenRefreshSubscription;

  bool get supported => !kIsWeb &&
      defaultTargetPlatform == TargetPlatform.android &&
      Firebase.apps.isNotEmpty;

  Future<void> initialize() async {
    if (!supported || _started) return;
    _started = true;
    _tokenRefreshSubscription =
        FirebaseMessaging.instance.onTokenRefresh.listen(
      (token) {
        _lastFcmToken = token;
        saveFcmToken(token);
      },
      onError: (Object error) {
        debugPrint('NEXORA FCM token refresh failed: $error');
      },
    );
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
      alert: true,
      badge: true,
      sound: true,
    );
    final allowed =
        settings.authorizationStatus == AuthorizationStatus.authorized ||
        settings.authorizationStatus == AuthorizationStatus.provisional;
    if (!allowed) return false;
    await registerIfAllowed();
    return true;
  }

  Future<void> registerIfAllowed() async {
    if (!supported || Supabase.instance.client.auth.currentUser == null) return;
    final authorization = await status();
    if (authorization != AuthorizationStatus.authorized &&
        authorization != AuthorizationStatus.provisional) {
      return;
    }
    try {
      final token = await FirebaseMessaging.instance.getToken();
      if (token == null || token.isEmpty) return;
      _lastFcmToken = token;
      await saveFcmToken(token);
    } catch (error) {
      debugPrint('NEXORA FCM token registration failed: $error');
    }
  }

  Future<void> saveFcmToken(String token) async {
    if (!supported || token.isEmpty) return;
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
      debugPrint('NEXORA FCM token save failed: $error');
    }
  }

  Future<void> _deleteFcmToken(String token) async {
    final client = Supabase.instance.client;
    final userId = client.auth.currentUser?.id;
    if (userId == null || token.isEmpty) return;
    try {
      await client.from('user_devices').delete()
          .eq('user_id', userId)
          .eq('push_token', token);
    } catch (error) {
      debugPrint('NEXORA FCM token cleanup failed: $error');
    }
  }

  /// Remove this account's token before signing out; keep the FCM token on-device.
  Future<void> unregisterCurrentDevice() async {
    if (!supported) return;
    final token = _lastFcmToken ?? await FirebaseMessaging.instance.getToken();
    if (token != null) await _deleteFcmToken(token);
    _lastFcmToken = null;
  }

  Future<void> dispose() async {
    await _tokenRefreshSubscription?.cancel();
    _tokenRefreshSubscription = null;
    _started = false;
  }
}
