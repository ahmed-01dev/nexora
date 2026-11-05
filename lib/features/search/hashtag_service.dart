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
      if (tags.length >= 30) break;
    }
    return tags.toList(growable: false);
  }

  /// Inserts rows only; avoids requiring UPDATE RLS policies for upserts.
  static Future<void> indexPost({
    required SupabaseClient client,
    required String postId,
    required String content,
  }) async {
    for (final tag in extract(content)) {
      var hashtag = await client
          .from('hashtags')
          .select('id')
          .eq('tag', tag)
          .maybeSingle();

      if (hashtag == null) {
        try {
          hashtag = await client
              .from('hashtags')
              .insert({'tag': tag})
              .select('id')
              .single();
        } on PostgrestException catch (error) {
          if (error.code != '23505') rethrow;
          hashtag = await client
              .from('hashtags')
              .select('id')
              .eq('tag', tag)
              .single();
        }
      }

      final hashtagId = hashtag['id'];
      final relation = await client
          .from('post_hashtags')
          .select('post_id')
          .eq('post_id', postId)
          .eq('hashtag_id', hashtagId)
          .maybeSingle();
      if (relation == null) {
        try {
          await client.from('post_hashtags').insert({
            'post_id': postId,
            'hashtag_id': hashtagId,
          });
        } on PostgrestException catch (error) {
          if (error.code != '23505') rethrow;
        }
      }
    }
  }
}
