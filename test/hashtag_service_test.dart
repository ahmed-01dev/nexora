import 'package:flutter_test/flutter_test.dart';
import 'package:nexora/features/search/hashtag_service.dart';

void main() {
  group('HashtagService.extract', () {
    test('extracts unique Latin hashtags in lowercase', () {
      expect(
        HashtagService.extract('Hello #Flutter #NEXORA #flutter'),
        ['flutter', 'nexora'],
      );
    });

    test('supports Arabic hashtags', () {
      expect(
        HashtagService.extract('أهلاً #مصر #القاهرة'),
        ['مصر', 'القاهرة'],
      );
    });

    test('ignores a bare hash and tags longer than 64 characters', () {
      final longTag = 'a' * 65;
      expect(HashtagService.extract('# $longTag #ok'), ['ok']);
    });

    test('returns no tags for ordinary text', () {
      expect(HashtagService.extract('No tags here'), isEmpty);
    });
  });
}
