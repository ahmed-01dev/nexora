import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'fcm_registration_ownership.dart';

/// Android FCM registration lifecycle using Firebase Installation IDs (FIDs).
class NexoraPushService {
  NexoraPushService._();
  static final instance = NexoraPushService._();

  bool _started = false;
  String? _lastInstallationId;
  String? _installationOwnerUserId;
  final _registrationOwnership = FcmRegistrationOwnership();
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
      final currentUserId =
          Supabase.instance.client.auth.currentUser?.id;
      // A late Firebase registration callback can arrive after sign-out.
      // Do not overwrite the previous FID/owner until a live session exists.
      if (currentUserId == null || _registrationSuspended) return;
      _lastInstallationId = fid;
      _installationOwnerUserId = currentUserId;
      saveInstallationId(fid);
    }, onError: (Object error) {
      debugPrint('NEXORA FCM registration failed: ${error.runtimeType}');
    });
    _unregistrationSubscription = messaging.onUnregistered.listen((fid) {
      final ownerId = _registrationOwnership.takeUnregistrationOwner(
        fid,
        _installationOwnerUserId ??
            Supabase.instance.client.auth.currentUser?.id,
      );

      // An old account's delayed unregister event must not clear a newer
      // account's registration, even when Firebase reuses the same FID.
      if (_registrationOwnership.shouldClearTrackedRegistration(
        trackedFid: _lastInstallationId,
        trackedOwnerId: _installationOwnerUserId,
        callbackFid: fid,
        callbackOwnerId: ownerId,
      )) {
        _lastInstallationId = null;
        _installationOwnerUserId = null;
      }
      _deleteInstallationId(fid, ownerId: ownerId);
    });
    await registerIfAllowed();
  }

  Future<AuthorizationStatus?> status() async {
    if (!supported) return null;
    return (await FirebaseMessaging.instance.getNotificationSettings())
        .authorizationStatus;
  }

  Future<bool> requestPermission() async {
    if (!supported ||
        _registrationSuspended ||
        Supabase.instance.client.auth.currentUser == null) {
      return false;
    }
    final settings = await FirebaseMessaging.instance.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );
    if (settings.authorizationStatus != AuthorizationStatus.authorized ||
        _registrationSuspended ||
        Supabase.instance.client.auth.currentUser == null) {
      return false;
    }
    await FirebaseMessaging.instance.register();
    return true;
  }

  Future<void> registerIfAllowed({bool resumeAfterSignIn = false}) async {
    if (!supported) return;
    final currentUserId = Supabase.instance.client.auth.currentUser?.id;
    if (currentUserId == null) return;

    if (resumeAfterSignIn) {
      final previousOwnerId = _installationOwnerUserId;
      final previousFid = _lastInstallationId;
      if (previousOwnerId != null &&
          previousOwnerId != currentUserId &&
          previousFid != null) {
        // Supabase can replace a session without an account-screen logout.
        // Remove the old owner's row and queue its callback before the new
        // account registers the same device installation.
        _registrationGeneration++;
        _registrationOwnership.queueUnregistration(
          previousFid,
          previousOwnerId,
        );
        _lastInstallationId = null;
        try {
          await _deleteInstallationId(previousFid, ownerId: previousOwnerId);
          await FirebaseMessaging.instance.unregister();
        } catch (error) {
          _registrationOwnership.removeQueuedUnregistration(
            previousFid,
            previousOwnerId,
          );
          debugPrint('NEXORA FCM account-switch cleanup failed: ${error.runtimeType}');
        }
      }
      _installationOwnerUserId = currentUserId;
      _registrationSuspended = false;
    }
    if (_registrationSuspended) return;
    if (await status() != AuthorizationStatus.authorized) return;
    if (_registrationSuspended ||
        Supabase.instance.client.auth.currentUser?.id != currentUserId) {
      return;
    }
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
      debugPrint('NEXORA FCM installation registration failed: ${error.runtimeType}');
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
      debugPrint('NEXORA FCM installation cleanup failed: ${error.runtimeType}');
    }
  }

  /// Remove this account's installation before signing out.
  Future<void> unregisterCurrentDevice() async {
    if (!supported) return;
    // The account-screen path unregisters before sign-out; the auth listener
    // also observes signedOut. Avoid issuing a duplicate Firebase unregister.
    if (_registrationSuspended && _lastInstallationId == null) return;
    // Invalidate registrations already in flight before deleting the row.
    _registrationSuspended = true;
    _registrationGeneration++;
    final ownerId = Supabase.instance.client.auth.currentUser?.id ??
        _installationOwnerUserId;
    final fid = _lastInstallationId;
    // Preserve the account being cleaned until its asynchronous callback is
    // resolved; a newer signed-in account may register the same FID meanwhile.
    _installationOwnerUserId = ownerId;
    _lastInstallationId = null;
    if (fid != null && ownerId != null) {
      _registrationOwnership.queueUnregistration(fid, ownerId);
      await _deleteInstallationId(fid, ownerId: ownerId);
    }
    try {
      await FirebaseMessaging.instance.unregister();
    } catch (error) {
      // If Firebase did not accept unregister, remove the queued owner unless
      // the asynchronous callback already consumed it.
      if (fid != null && ownerId != null) {
        _registrationOwnership.removeQueuedUnregistration(fid, ownerId);
      }
      debugPrint('NEXORA FCM unregister failed: ${error.runtimeType}');
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
