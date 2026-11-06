/// Client-side validation mirrored from the live public.reports constraints.
class ReportSubmissionValidation {
  static const Set<String> targetTypes = {
    'user',
    'post',
    'comment',
    'message',
    'story',
    'community',
  };

  static const Set<String> reasons = {
    'harassment',
    'threats',
    'spam',
    'scam',
    'impersonation',
    'sexual_content',
    'child_safety',
    'dangerous_content',
    'illegal_content',
    'copyright',
    'other',
  };

  static final RegExp _uuidPattern = RegExp(
    r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$',
  );

  static bool isValidTarget({required String type, required String id}) {
    return targetTypes.contains(type) && _uuidPattern.hasMatch(id.trim());
  }

  static bool isValidReason(String reason) => reasons.contains(reason);
}
