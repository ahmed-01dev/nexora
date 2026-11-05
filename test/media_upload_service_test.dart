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

  group('MediaUploadService.hasValidMediaSignature', () {
    test('accepts GIF87a and GIF89a image signatures', () {
      expect(
        MediaUploadService.hasValidMediaSignature(
          'gif',
          'GIF89a'.codeUnits,
        ),
        isTrue,
      );
      expect(
        MediaUploadService.hasValidMediaSignature(
          'gif',
          'GIF87a'.codeUnits,
        ),
        isTrue,
      );
    });

    test('accepts MP4 ftyp and WebM EBML signatures', () {
      expect(
        MediaUploadService.hasValidMediaSignature(
          'mp4',
          [0, 0, 0, 24, 0x66, 0x74, 0x79, 0x70, 0, 0, 0, 0],
        ),
        isTrue,
      );
      expect(
        MediaUploadService.hasValidMediaSignature(
          'webm',
          [0x1A, 0x45, 0xDF, 0xA3, 0x93],
        ),
        isTrue,
      );
    });

    test('rejects extension/content mismatches and truncated video files', () {
      expect(
        MediaUploadService.hasValidMediaSignature(
          'mp4',
          [0x1A, 0x45, 0xDF, 0xA3],
        ),
        isFalse,
      );
      expect(
        MediaUploadService.hasValidMediaSignature(
          'webm',
          [0, 0, 0, 24, 0x66, 0x74, 0x79, 0x70],
        ),
        isFalse,
      );
      expect(
        MediaUploadService.hasValidMediaSignature('gif', [0x47, 0x49]),
        isFalse,
      );
    });
  });
}
