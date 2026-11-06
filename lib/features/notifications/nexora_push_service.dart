import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Android FCM registration lifecycle using Firebase Installation IDs (FIDs).
class NexoraPushService {
  NexoraPushService._();
  static final instance = NexoraPushService._();

  bool _started = false;
  String? _lastInstallationId;
  int _registrationGeneration = 0;
  bool _registrationSuspended = false;
  StreamSubscription<String>? _registrationSubscription;
  StreamSubscription<String>? _unregistrationSubscription;

  bool get supported => !kIsWeb &&
      defaultTargetPlatform == TargetPlatform.android &&
      Firebase.apps.isNotEmpty;

  Future<void> initialize() async {
    if (!supported || _started) return;
    _started = true;
    final messaging = FirebaseMessaging.instance;
    _registrationSubscription = messaging.onRegistered.listen((fid) {
      _lastInstallationId = fid;
      saveInstallationId(fid);
    }, onError: (Object error) {
      debugPrint('NEXORA FCM registration failed: $error');
    });
    _unregistrationSubscription = messaging.onUnregistered.listen((fid) {
      _lastInstallationId = null;
      _deleteInstallationId(fid);
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
      alert: true,
      badge: true,
      sound: true,
    );
    if (settings.authorizationStatus != AuthorizationStatus.authorized) {
      return false;
    }
    await FirebaseMessaging.instance.register();
    return true;
  }

  Future<void> registerIfAllowed() async {
    if (!supported || Supabase.instance.client.auth.currentUser == null) return;
    _registrationSuspended = false;
    if (await status() != AuthorizationStatus.authorized) return;
    await FirebaseMessaging.instance.register();
  }

  Future<void> saveInstallationId(String fid) async {
    if (!supported || fid.isEmpty || _registrationSuspended) return;
    final client = Supabase.instance.client;
    final userId = client.auth.currentUser?.id;
    if (userId == null) return;
    final generation = _registrationGeneration;
    try {
      await client.from('user_devices').upsert({
        'user_id': userId,
        'platform': 'android',
        'push_token': fid,
        'device_label': 'Android device',
        'last_seen_at': DateTime.now().toUtc().toIso8601String(),
      }, onConflict: 'user_id,push_token');

      // A registration request can finish after sign-out/account switching.
      // Reconcile the old owner's row after the upsert to avoid stale devices.
      if (generation != _registrationGeneration ||
          client.auth.currentUser?.id != userId) {
        await _deleteInstallationId(fid, ownerId: userId);
      }
    } catch (error) {
      debugPrint('NEXORA FCM installation registration failed: $error');
    }
  }

  Future<void> _deleteInstallationId(
    String fid, {
    String? ownerId,
  }) async {
    final client = Supabase.instance.client;
    final userId = ownerId ?? client.auth.currentUser?.id;
    if (userId == null || fid.isEmpty) return;
    try {
      await client.from('user_devices').delete()
          .eq('user_id', userId)
          .eq('push_token', fid);
    } catch (error) {
      debugPrint('NEXORA FCM installation cleanup failed: $error');
    }
  }

  /// Remove this account's installation before signing out.
  Future<void> unregisterCurrentDevice() async {
    if (!supported) return;
    // Invalidate registrations already in flight before deleting the row.
    _registrationSuspended = true;
    _registrationGeneration++;
    final ownerId = Supabase.instance.client.auth.currentUser?.id;
    final fid = _lastInstallationId;
    _lastInstallationId = null;
    if (fid != null) {
      await _deleteInstallationId(fid, ownerId: ownerId);
    }
    try {
      await FirebaseMessaging.instance.unregister();
    } catch (error) {
      debugPrint('NEXORA FCM unregister failed: $error');
    }
  }

  Future<void> dispose() async {
    await _registrationSubscription?.cancel();
    await _unregistrationSubscription?.cancel();
    _registrationSubscription = null;
    _unregistrationSubscription = null;
    _started = false;
  }
}
