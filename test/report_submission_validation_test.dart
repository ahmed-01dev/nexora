import 'package:flutter_test/flutter_test.dart';
import 'package:nexora/features/moderation/report_submission_validation.dart';

void main() {
  group('ReportSubmissionValidation', () {
    test('accepts each live target type with a UUID target', () {
      const id = '550e8400-e29b-41d4-a716-446655440000';
      for (final type in ReportSubmissionValidation.targetTypes) {
        expect(
          ReportSubmissionValidation.isValidTarget(type: type, id: id),
          isTrue,
          reason: 'Expected $type to be a supported report target',
        );
      }
    });

    test('rejects unknown target types and malformed UUIDs', () {
      expect(
        ReportSubmissionValidation.isValidTarget(
          type: 'profile',
          id: '550e8400-e29b-41d4-a716-446655440000',
        ),
        isFalse,
      );
      expect(
        ReportSubmissionValidation.isValidTarget(
          type: 'user',
          id: 'not-a-uuid',
        ),
        isFalse,
      );
      expect(
        ReportSubmissionValidation.isValidTarget(type: 'user', id: ' '),
        isFalse,
      );
    });

    test('accepts only report reasons allowed by the live check constraint', () {
      for (final reason in ReportSubmissionValidation.reasons) {
        expect(ReportSubmissionValidation.isValidReason(reason), isTrue);
      }
      expect(ReportSubmissionValidation.isValidReason('invalid'), isFalse);
    });
  });
}
