import 'package:supabase_flutter/supabase_flutter.dart';

/// Extracts unique, normalized hashtags from Arabic and Latin post text.
class HashtagService {
  static final RegExp _pattern = RegExp(
    r'#([A-Za-z0-9_\u0600-\u06FF\u0750-\u077F\u08A0-\u08FF]{1,64})',
  );

  static List<String> extract(String content) {
    final tags = <String>{};
    for (final match in _pattern.allMatches(content)) {
      final tag = match.group(1)?.toLowerCase().trim();
      if (tag != null && tag.isNotEmpty) tags.add(tag);
    }
    return tags.toList(growable: false);
  }

  /// Stores post/tag relations using the existing normalized hashtag tables.
  static Future<void> indexPost({
    required SupabaseClient client,
    required String postId,
    required String content,
  }) async {
    final tags = extract(content);
    for (final tag in tags) {
      final hashtag = await client
          .from('hashtags')
          .upsert({'tag': tag}, onConflict: 'tag')
          .select('id')
          .single();
      await client.from('post_hashtags').upsert({
        'post_id': postId,
        'hashtag_id': hashtag['id'],
      }, onConflict: 'post_id,hashtag_id');
    }
  }
}
