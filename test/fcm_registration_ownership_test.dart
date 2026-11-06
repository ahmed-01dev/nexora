import 'package:flutter_test/flutter_test.dart';
import 'package:nexora/features/notifications/fcm_registration_ownership.dart';

void main() {
  group('FcmRegistrationOwnership', () {
    test('uses queued previous owner before the current account fallback', () {
      final ownership = FcmRegistrationOwnership();
      ownership.queueUnregistration('fid-1', 'user-a');

      expect(
        ownership.takeUnregistrationOwner('fid-1', 'user-b'),
        'user-a',
      );
      expect(
        ownership.takeUnregistrationOwner('fid-1', 'user-b'),
        'user-b',
      );
    });

    test('preserves FIFO ownership for repeated unregister events', () {
      final ownership = FcmRegistrationOwnership();
      ownership.queueUnregistration('fid-1', 'user-a');
      ownership.queueUnregistration('fid-1', 'user-b');

      expect(ownership.takeUnregistrationOwner('fid-1', null), 'user-a');
      expect(ownership.takeUnregistrationOwner('fid-1', null), 'user-b');
    });

    test('does not clear a newer account registration for the same FID', () {
      final ownership = FcmRegistrationOwnership();

      expect(
        ownership.shouldClearTrackedRegistration(
          trackedFid: 'fid-1',
          trackedOwnerId: 'user-b',
          callbackFid: 'fid-1',
          callbackOwnerId: 'user-a',
        ),
        isFalse,
      );
    });

    test('clears the tracked registration when callback owner matches', () {
      final ownership = FcmRegistrationOwnership();

      expect(
        ownership.shouldClearTrackedRegistration(
          trackedFid: 'fid-1',
          trackedOwnerId: 'user-a',
          callbackFid: 'fid-1',
          callbackOwnerId: 'user-a',
        ),
        isTrue,
      );
    });

    test('removes queued ownership when Firebase unregister fails', () {
      final ownership = FcmRegistrationOwnership();
      ownership.queueUnregistration('fid-1', 'user-a');
      ownership.removeQueuedUnregistration('fid-1', 'user-a');

      expect(
        ownership.takeUnregistrationOwner('fid-1', 'user-b'),
        'user-b',
      );
    });
  });
}
