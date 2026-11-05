import 'package:flutter_test/flutter_test.dart';
import 'package:nexora/features/media/media_upload_service.dart';

void main() {
  group('MediaUploadService.hasValidImageSignature', () {
    test('accepts JPEG signatures for jpg and jpeg extensions', () {
      const bytes = [0xFF, 0xD8, 0xFF, 0xE0, 0x00];
      expect(MediaUploadService.hasValidImageSignature('jpg', bytes), isTrue);
      expect(MediaUploadService.hasValidImageSignature('jpeg', bytes), isTrue);
    });

    test('accepts a complete PNG signature', () {
      const bytes = [0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A];
      expect(MediaUploadService.hasValidImageSignature('png', bytes), isTrue);
    });

    test('accepts RIFF WEBP signature', () {
      const bytes = [
        0x52, 0x49, 0x46, 0x46, 0x10, 0x00, 0x00, 0x00,
        0x57, 0x45, 0x42, 0x50,
      ];
      expect(MediaUploadService.hasValidImageSignature('webp', bytes), isTrue);
    });

    test('rejects mismatched, malformed, and unsupported files', () {
      const png = [0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A];
      expect(MediaUploadService.hasValidImageSignature('jpg', png), isFalse);
      expect(MediaUploadService.hasValidImageSignature('png', [0x89, 0x50]), isFalse);
      expect(MediaUploadService.hasValidImageSignature('svg', [0x3C, 0x73]), isFalse);
    });
  });
}
