# NEXORA — Live PostgreSQL Constraint Inventory

> Read-only catalog snapshot from Supabase project `wwdeexgkwpftyavbhiff`, captured 2026-11-06. This is descriptive evidence, not migration source.

- Total constraints: 166
- CHECK: 51
- FOREIGN KEY: 67
- PRIMARY KEY: 39
- UNIQUE: 9

| Schema | Table | Constraint | Type | Live definition |
|---|---|---|---|---|
| `private` | `profile_discovery_locations` | `profile_discovery_locations_latitude_approx_check` | CHECK | `CHECK (latitude_approx >= '-90'::integer::numeric AND latitude_approx <= 90::numeric)` |
| `private` | `profile_discovery_locations` | `profile_discovery_locations_longitude_approx_check` | CHECK | `CHECK (longitude_approx >= '-180'::integer::numeric AND longitude_approx <= 180::numeric)` |
| `private` | `profile_discovery_locations` | `profile_discovery_locations_user_id_fkey` | FOREIGN KEY | `FOREIGN KEY (user_id) REFERENCES profiles(id) ON DELETE CASCADE` |
| `private` | `profile_discovery_locations` | `profile_discovery_locations_pkey` | PRIMARY KEY | `PRIMARY KEY (user_id)` |
| `public` | `audit_logs` | `audit_logs_pkey` | PRIMARY KEY | `PRIMARY KEY (id)` |
| `public` | `blocks` | `blocks_no_self` | CHECK | `CHECK (blocker_id <> blocked_id)` |
| `public` | `blocks` | `blocks_blocked_id_fkey` | FOREIGN KEY | `FOREIGN KEY (blocked_id) REFERENCES profiles(id) ON DELETE CASCADE` |
| `public` | `blocks` | `blocks_blocker_id_fkey` | FOREIGN KEY | `FOREIGN KEY (blocker_id) REFERENCES profiles(id) ON DELETE CASCADE` |
| `public` | `blocks` | `blocks_pkey` | PRIMARY KEY | `PRIMARY KEY (blocker_id, blocked_id)` |
| `public` | `call_participants` | `call_participants_call_id_fkey` | FOREIGN KEY | `FOREIGN KEY (call_id) REFERENCES call_sessions(id) ON DELETE CASCADE` |
| `public` | `call_participants` | `call_participants_user_id_fkey` | FOREIGN KEY | `FOREIGN KEY (user_id) REFERENCES profiles(id) ON DELETE CASCADE` |
| `public` | `call_participants` | `call_participants_pkey` | PRIMARY KEY | `PRIMARY KEY (call_id, user_id)` |
| `public` | `call_sessions` | `call_sessions_call_type_check` | CHECK | `CHECK (call_type = ANY (ARRAY['voice'::text, 'video'::text, 'group_voice'::text, 'group_video'::text]))` |
| `public` | `call_sessions` | `call_sessions_status_check` | CHECK | `CHECK (status = ANY (ARRAY['ringing'::text, 'active'::text, 'ended'::text, 'missed'::text, 'rejected'::text, 'failed'::text]))` |
| `public` | `call_sessions` | `call_sessions_conversation_id_fkey` | FOREIGN KEY | `FOREIGN KEY (conversation_id) REFERENCES conversations(id) ON DELETE CASCADE` |
| `public` | `call_sessions` | `call_sessions_initiated_by_fkey` | FOREIGN KEY | `FOREIGN KEY (initiated_by) REFERENCES profiles(id) ON DELETE RESTRICT` |
| `public` | `call_sessions` | `call_sessions_pkey` | PRIMARY KEY | `PRIMARY KEY (id)` |
| `public` | `collection_items` | `collection_items_collection_id_fkey` | FOREIGN KEY | `FOREIGN KEY (collection_id) REFERENCES collections(id) ON DELETE CASCADE` |
| `public` | `collection_items` | `collection_items_post_id_fkey` | FOREIGN KEY | `FOREIGN KEY (post_id) REFERENCES posts(id) ON DELETE CASCADE` |
| `public` | `collection_items` | `collection_items_pkey` | PRIMARY KEY | `PRIMARY KEY (collection_id, post_id)` |
| `public` | `collections` | `collections_name_check` | CHECK | `CHECK (char_length(name) >= 1 AND char_length(name) <= 60)` |
| `public` | `collections` | `collections_user_id_fkey` | FOREIGN KEY | `FOREIGN KEY (user_id) REFERENCES profiles(id) ON DELETE CASCADE` |
| `public` | `collections` | `collections_pkey` | PRIMARY KEY | `PRIMARY KEY (id)` |
| `public` | `comment_likes` | `comment_likes_comment_id_fkey` | FOREIGN KEY | `FOREIGN KEY (comment_id) REFERENCES comments(id) ON DELETE CASCADE` |
| `public` | `comment_likes` | `comment_likes_user_id_fkey` | FOREIGN KEY | `FOREIGN KEY (user_id) REFERENCES profiles(id) ON DELETE CASCADE` |
| `public` | `comment_likes` | `comment_likes_pkey` | PRIMARY KEY | `PRIMARY KEY (user_id, comment_id)` |
| `public` | `comments` | `comments_content_check` | CHECK | `CHECK (char_length(content) >= 1 AND char_length(content) <= 2000)` |
| `public` | `comments` | `comments_parent_id_fkey` | FOREIGN KEY | `FOREIGN KEY (parent_id) REFERENCES comments(id) ON DELETE CASCADE` |
| `public` | `comments` | `comments_post_id_fkey` | FOREIGN KEY | `FOREIGN KEY (post_id) REFERENCES posts(id) ON DELETE CASCADE` |
| `public` | `comments` | `comments_user_id_fkey` | FOREIGN KEY | `FOREIGN KEY (user_id) REFERENCES profiles(id) ON DELETE CASCADE` |
| `public` | `comments` | `comments_pkey` | PRIMARY KEY | `PRIMARY KEY (id)` |
| `public` | `communities` | `communities_name_check` | CHECK | `CHECK (char_length(name) >= 2 AND char_length(name) <= 80)` |
| `public` | `communities` | `communities_slug_check` | CHECK | `CHECK (slug ~ '^[a-z0-9-]{3,60}$'::text)` |
| `public` | `communities` | `communities_visibility_check` | CHECK | `CHECK (visibility = ANY (ARRAY['public'::text, 'private'::text, 'invite_only'::text]))` |
| `public` | `communities` | `communities_owner_id_fkey` | FOREIGN KEY | `FOREIGN KEY (owner_id) REFERENCES profiles(id) ON DELETE RESTRICT` |
| `public` | `communities` | `communities_pkey` | PRIMARY KEY | `PRIMARY KEY (id)` |
| `public` | `communities` | `communities_slug_key` | UNIQUE | `UNIQUE (slug)` |
| `public` | `community_channels` | `community_channels_name_check` | CHECK | `CHECK (char_length(btrim(name)) >= 2 AND char_length(btrim(name)) <= 60)` |
| `public` | `community_channels` | `community_channels_slug_check` | CHECK | `CHECK (slug ~ '^[a-z0-9-]{2,60}$'::text)` |
| `public` | `community_channels` | `community_channels_community_id_fkey` | FOREIGN KEY | `FOREIGN KEY (community_id) REFERENCES communities(id) ON DELETE CASCADE` |
| `public` | `community_channels` | `community_channels_conversation_id_fkey` | FOREIGN KEY | `FOREIGN KEY (conversation_id) REFERENCES conversations(id) ON DELETE CASCADE` |
| `public` | `community_channels` | `community_channels_created_by_fkey` | FOREIGN KEY | `FOREIGN KEY (created_by) REFERENCES auth.users(id) ON DELETE RESTRICT` |
| `public` | `community_channels` | `community_channels_pkey` | PRIMARY KEY | `PRIMARY KEY (id)` |
| `public` | `community_channels` | `community_channels_community_id_slug_key` | UNIQUE | `UNIQUE (community_id, slug)` |
| `public` | `community_channels` | `community_channels_conversation_id_key` | UNIQUE | `UNIQUE (conversation_id)` |
| `public` | `community_invites` | `community_invites_check` | CHECK | `CHECK (use_count >= 0 AND use_count <= max_uses)` |
| `public` | `community_invites` | `community_invites_max_uses_check` | CHECK | `CHECK (max_uses >= 1 AND max_uses <= 500)` |
| `public` | `community_invites` | `community_invites_community_id_fkey` | FOREIGN KEY | `FOREIGN KEY (community_id) REFERENCES communities(id) ON DELETE CASCADE` |
| `public` | `community_invites` | `community_invites_created_by_fkey` | FOREIGN KEY | `FOREIGN KEY (created_by) REFERENCES profiles(id) ON DELETE RESTRICT` |
| `public` | `community_invites` | `community_invites_pkey` | PRIMARY KEY | `PRIMARY KEY (id)` |
| `public` | `community_invites` | `community_invites_invite_code_key` | UNIQUE | `UNIQUE (invite_code)` |
| `public` | `community_members` | `community_members_role_check` | CHECK | `CHECK (role = ANY (ARRAY['owner'::text, 'moderator'::text, 'member'::text]))` |
| `public` | `community_members` | `community_members_community_id_fkey` | FOREIGN KEY | `FOREIGN KEY (community_id) REFERENCES communities(id) ON DELETE CASCADE` |
| `public` | `community_members` | `community_members_user_id_fkey` | FOREIGN KEY | `FOREIGN KEY (user_id) REFERENCES profiles(id) ON DELETE CASCADE` |
| `public` | `community_members` | `community_members_pkey` | PRIMARY KEY | `PRIMARY KEY (community_id, user_id)` |
| `public` | `conversation_members` | `conversation_members_role_check` | CHECK | `CHECK (role = ANY (ARRAY['owner'::text, 'admin'::text, 'member'::text]))` |
| `public` | `conversation_members` | `conversation_members_conversation_id_fkey` | FOREIGN KEY | `FOREIGN KEY (conversation_id) REFERENCES conversations(id) ON DELETE CASCADE` |
| `public` | `conversation_members` | `conversation_members_user_id_fkey` | FOREIGN KEY | `FOREIGN KEY (user_id) REFERENCES profiles(id) ON DELETE CASCADE` |
| `public` | `conversation_members` | `conversation_members_pkey` | PRIMARY KEY | `PRIMARY KEY (conversation_id, user_id)` |
| `public` | `conversations` | `conversations_conversation_type_check` | CHECK | `CHECK (conversation_type = ANY (ARRAY['direct'::text, 'group'::text, 'community'::text]))` |
| `public` | `conversations` | `conversations_created_by_fkey` | FOREIGN KEY | `FOREIGN KEY (created_by) REFERENCES profiles(id) ON DELETE RESTRICT` |
| `public` | `conversations` | `conversations_pkey` | PRIMARY KEY | `PRIMARY KEY (id)` |
| `public` | `follows` | `follows_check` | CHECK | `CHECK (follower_id <> following_id)` |
| `public` | `follows` | `follows_no_self_follow` | CHECK | `CHECK (follower_id <> following_id)` |
| `public` | `follows` | `follows_status_check` | CHECK | `CHECK (status = ANY (ARRAY['pending'::text, 'accepted'::text]))` |
| `public` | `follows` | `follows_follower_id_fkey` | FOREIGN KEY | `FOREIGN KEY (follower_id) REFERENCES profiles(id) ON DELETE CASCADE` |
| `public` | `follows` | `follows_following_id_fkey` | FOREIGN KEY | `FOREIGN KEY (following_id) REFERENCES profiles(id) ON DELETE CASCADE` |
| `public` | `follows` | `follows_pkey` | PRIMARY KEY | `PRIMARY KEY (follower_id, following_id)` |
| `public` | `friendships` | `friendships_no_self` | CHECK | `CHECK (requester_id <> addressee_id)` |
| `public` | `friendships` | `friendships_status_check` | CHECK | `CHECK (status = ANY (ARRAY['pending'::text, 'accepted'::text, 'declined'::text, 'cancelled'::text]))` |
| `public` | `friendships` | `friendships_addressee_id_fkey` | FOREIGN KEY | `FOREIGN KEY (addressee_id) REFERENCES profiles(id) ON DELETE CASCADE` |
| `public` | `friendships` | `friendships_requester_id_fkey` | FOREIGN KEY | `FOREIGN KEY (requester_id) REFERENCES profiles(id) ON DELETE CASCADE` |
| `public` | `friendships` | `friendships_pkey` | PRIMARY KEY | `PRIMARY KEY (id)` |
| `public` | `friendships` | `friendships_unique_pair` | UNIQUE | `UNIQUE (requester_id, addressee_id)` |
| `public` | `hashtags` | `hashtags_tag_check` | CHECK | `CHECK (char_length(tag) >= 1 AND char_length(tag) <= 64 AND tag = lower(tag) AND tag !~ '\s'::text)` |
| `public` | `hashtags` | `hashtags_pkey` | PRIMARY KEY | `PRIMARY KEY (id)` |
| `public` | `hashtags` | `hashtags_tag_key` | UNIQUE | `UNIQUE (tag)` |
| `public` | `likes` | `likes_post_id_fkey` | FOREIGN KEY | `FOREIGN KEY (post_id) REFERENCES posts(id) ON DELETE CASCADE` |
| `public` | `likes` | `likes_user_id_fkey` | FOREIGN KEY | `FOREIGN KEY (user_id) REFERENCES profiles(id) ON DELETE CASCADE` |
| `public` | `likes` | `likes_pkey` | PRIMARY KEY | `PRIMARY KEY (user_id, post_id)` |
| `public` | `media` | `media_media_type_check` | CHECK | `CHECK (media_type = ANY (ARRAY['image'::text, 'video'::text]))` |
| `public` | `media` | `media_post_id_fkey` | FOREIGN KEY | `FOREIGN KEY (post_id) REFERENCES posts(id) ON DELETE CASCADE` |
| `public` | `media` | `media_user_id_fkey` | FOREIGN KEY | `FOREIGN KEY (user_id) REFERENCES profiles(id) ON DELETE CASCADE` |
| `public` | `media` | `media_pkey` | PRIMARY KEY | `PRIMARY KEY (id)` |
| `public` | `message_attachments` | `message_attachments_size_bytes_check` | CHECK | `CHECK (size_bytes > 0)` |
| `public` | `message_attachments` | `message_attachments_message_id_fkey` | FOREIGN KEY | `FOREIGN KEY (message_id) REFERENCES messages(id) ON DELETE CASCADE` |
| `public` | `message_attachments` | `message_attachments_uploader_id_fkey` | FOREIGN KEY | `FOREIGN KEY (uploader_id) REFERENCES profiles(id) ON DELETE CASCADE` |
| `public` | `message_attachments` | `message_attachments_pkey` | PRIMARY KEY | `PRIMARY KEY (id)` |
| `public` | `message_reactions` | `message_reactions_reaction_check` | CHECK | `CHECK (char_length(reaction) >= 1 AND char_length(reaction) <= 32)` |
| `public` | `message_reactions` | `message_reactions_message_id_fkey` | FOREIGN KEY | `FOREIGN KEY (message_id) REFERENCES messages(id) ON DELETE CASCADE` |
| `public` | `message_reactions` | `message_reactions_user_id_fkey` | FOREIGN KEY | `FOREIGN KEY (user_id) REFERENCES profiles(id) ON DELETE CASCADE` |
| `public` | `message_reactions` | `message_reactions_pkey` | PRIMARY KEY | `PRIMARY KEY (message_id, user_id, reaction)` |
| `public` | `messages` | `messages_body_or_cipher` | CHECK | `CHECK (body IS NOT NULL OR ciphertext IS NOT NULL OR message_type <> 'text'::text)` |
| `public` | `messages` | `messages_encryption_mode_check` | CHECK | `CHECK (encryption_mode = 'server_readable'::text)` |
| `public` | `messages` | `messages_message_type_check` | CHECK | `CHECK (message_type = ANY (ARRAY['text'::text, 'image'::text, 'video'::text, 'audio'::text, 'file'::text, 'post'::text, 'profile'::text, 'location'::text, 'system'::text]))` |
| `public` | `messages` | `messages_conversation_id_fkey` | FOREIGN KEY | `FOREIGN KEY (conversation_id) REFERENCES conversations(id) ON DELETE CASCADE` |
| `public` | `messages` | `messages_reply_to_fkey` | FOREIGN KEY | `FOREIGN KEY (reply_to) REFERENCES messages(id) ON DELETE SET NULL` |
| `public` | `messages` | `messages_sender_id_fkey` | FOREIGN KEY | `FOREIGN KEY (sender_id) REFERENCES profiles(id) ON DELETE RESTRICT` |
| `public` | `messages` | `messages_pkey` | PRIMARY KEY | `PRIMARY KEY (id)` |
| `public` | `moderation_actions` | `moderation_actions_action_check` | CHECK | `CHECK (action = ANY (ARRAY['dismiss'::text, 'warn'::text, 'remove_content'::text, 'restrict'::text, 'suspend'::text, 'ban'::text]))` |
| `public` | `moderation_actions` | `moderation_actions_reason_check` | CHECK | `CHECK (char_length(reason) <= 2000)` |
| `public` | `moderation_actions` | `moderation_actions_target_type_check` | CHECK | `CHECK (target_type = ANY (ARRAY['user'::text, 'post'::text, 'comment'::text, 'message'::text, 'story'::text, 'community'::text]))` |
| `public` | `moderation_actions` | `moderation_actions_moderator_id_fkey` | FOREIGN KEY | `FOREIGN KEY (moderator_id) REFERENCES auth.users(id)` |
| `public` | `moderation_actions` | `moderation_actions_report_id_fkey` | FOREIGN KEY | `FOREIGN KEY (report_id) REFERENCES reports(id) ON DELETE SET NULL` |
| `public` | `moderation_actions` | `moderation_actions_pkey` | PRIMARY KEY | `PRIMARY KEY (id)` |
| `public` | `moderation_appeals` | `moderation_appeals_message_check` | CHECK | `CHECK (char_length(message) >= 1 AND char_length(message) <= 2000)` |
| `public` | `moderation_appeals` | `moderation_appeals_status_check` | CHECK | `CHECK (status = ANY (ARRAY['open'::text, 'upheld'::text, 'overturned'::text]))` |
| `public` | `moderation_appeals` | `moderation_appeals_action_id_fkey` | FOREIGN KEY | `FOREIGN KEY (action_id) REFERENCES moderation_actions(id) ON DELETE CASCADE` |
| `public` | `moderation_appeals` | `moderation_appeals_reviewer_id_fkey` | FOREIGN KEY | `FOREIGN KEY (reviewer_id) REFERENCES auth.users(id) ON DELETE SET NULL` |
| `public` | `moderation_appeals` | `moderation_appeals_user_id_fkey` | FOREIGN KEY | `FOREIGN KEY (user_id) REFERENCES auth.users(id) ON DELETE CASCADE` |
| `public` | `moderation_appeals` | `moderation_appeals_pkey` | PRIMARY KEY | `PRIMARY KEY (id)` |
| `public` | `moderation_appeals` | `moderation_appeals_action_id_user_id_key` | UNIQUE | `UNIQUE (action_id, user_id)` |
| `public` | `notification_preferences` | `notification_preferences_category_check` | CHECK | `CHECK (category = ANY (ARRAY['like'::text, 'comment'::text, 'reply'::text, 'follow'::text, 'friend_request'::text, 'friend_accepted'::text, 'mention'::text, 'repost'::text, 'message'::text, 'call'::text, 'group_invite'::text, 'system'::text, 'security'::text]))` |
| `public` | `notification_preferences` | `notification_preferences_user_id_fkey` | FOREIGN KEY | `FOREIGN KEY (user_id) REFERENCES auth.users(id) ON DELETE CASCADE` |
| `public` | `notification_preferences` | `notification_preferences_pkey` | PRIMARY KEY | `PRIMARY KEY (user_id, category)` |
| `public` | `notifications` | `notifications_notification_type_check` | CHECK | `CHECK (notification_type = ANY (ARRAY['like'::text, 'comment'::text, 'reply'::text, 'follow'::text, 'friend_request'::text, 'friend_accepted'::text, 'mention'::text, 'repost'::text, 'message'::text, 'call'::text, 'group_invite'::text, 'system'::text, 'security'::text]))` |
| `public` | `notifications` | `notifications_actor_id_fkey` | FOREIGN KEY | `FOREIGN KEY (actor_id) REFERENCES profiles(id) ON DELETE SET NULL` |
| `public` | `notifications` | `notifications_recipient_id_fkey` | FOREIGN KEY | `FOREIGN KEY (recipient_id) REFERENCES profiles(id) ON DELETE CASCADE` |
| `public` | `notifications` | `notifications_pkey` | PRIMARY KEY | `PRIMARY KEY (id)` |
| `public` | `post_hashtags` | `post_hashtags_hashtag_id_fkey` | FOREIGN KEY | `FOREIGN KEY (hashtag_id) REFERENCES hashtags(id) ON DELETE CASCADE` |
| `public` | `post_hashtags` | `post_hashtags_post_id_fkey` | FOREIGN KEY | `FOREIGN KEY (post_id) REFERENCES posts(id) ON DELETE CASCADE` |
| `public` | `post_hashtags` | `post_hashtags_pkey` | PRIMARY KEY | `PRIMARY KEY (post_id, hashtag_id)` |
| `public` | `posts` | `posts_visibility_check` | CHECK | `CHECK (visibility = ANY (ARRAY['public'::text, 'followers'::text, 'friends'::text, 'private'::text]))` |
| `public` | `posts` | `posts_user_id_fkey` | FOREIGN KEY | `FOREIGN KEY (user_id) REFERENCES profiles(id) ON DELETE CASCADE` |
| `public` | `posts` | `posts_pkey` | PRIMARY KEY | `PRIMARY KEY (id)` |
| `public` | `profiles` | `profiles_id_fkey` | FOREIGN KEY | `FOREIGN KEY (id) REFERENCES auth.users(id) ON DELETE CASCADE` |
| `public` | `profiles` | `profiles_pkey` | PRIMARY KEY | `PRIMARY KEY (id)` |
| `public` | `profiles` | `profiles_username_key` | UNIQUE | `UNIQUE (username)` |
| `public` | `reports` | `reports_reason_check` | CHECK | `CHECK (reason = ANY (ARRAY['harassment'::text, 'threats'::text, 'spam'::text, 'scam'::text, 'impersonation'::text, 'sexual_content'::text, 'child_safety'::text, 'dangerous_content'::text, 'illegal_content'::text, 'copyright'::text, 'other'::text]))` |
| `public` | `reports` | `reports_status_check` | CHECK | `CHECK (status = ANY (ARRAY['open'::text, 'reviewing'::text, 'actioned'::text, 'dismissed'::text, 'appealed'::text]))` |
| `public` | `reports` | `reports_target_type_check` | CHECK | `CHECK (target_type = ANY (ARRAY['user'::text, 'post'::text, 'comment'::text, 'message'::text, 'story'::text, 'community'::text]))` |
| `public` | `reports` | `reports_assigned_to_fkey` | FOREIGN KEY | `FOREIGN KEY (assigned_to) REFERENCES auth.users(id) ON DELETE SET NULL` |
| `public` | `reports` | `reports_reporter_id_fkey` | FOREIGN KEY | `FOREIGN KEY (reporter_id) REFERENCES profiles(id) ON DELETE CASCADE` |
| `public` | `reports` | `reports_pkey` | PRIMARY KEY | `PRIMARY KEY (id)` |
| `public` | `reposts` | `reposts_quote_text_check` | CHECK | `CHECK (quote_text IS NULL OR char_length(quote_text) >= 1 AND char_length(quote_text) <= 500)` |
| `public` | `reposts` | `reposts_post_id_fkey` | FOREIGN KEY | `FOREIGN KEY (post_id) REFERENCES posts(id) ON DELETE CASCADE` |
| `public` | `reposts` | `reposts_user_id_fkey` | FOREIGN KEY | `FOREIGN KEY (user_id) REFERENCES profiles(id) ON DELETE CASCADE` |
| `public` | `reposts` | `reposts_pkey` | PRIMARY KEY | `PRIMARY KEY (id)` |
| `public` | `saves` | `saves_post_id_fkey` | FOREIGN KEY | `FOREIGN KEY (post_id) REFERENCES posts(id) ON DELETE CASCADE` |
| `public` | `saves` | `saves_user_id_fkey` | FOREIGN KEY | `FOREIGN KEY (user_id) REFERENCES profiles(id) ON DELETE CASCADE` |
| `public` | `saves` | `saves_pkey` | PRIMARY KEY | `PRIMARY KEY (user_id, post_id)` |
| `public` | `staff_members` | `staff_members_role_check` | CHECK | `CHECK (role = ANY (ARRAY['super_admin'::text, 'admin'::text, 'moderator'::text, 'support'::text, 'analyst'::text]))` |
| `public` | `staff_members` | `staff_members_created_by_fkey` | FOREIGN KEY | `FOREIGN KEY (created_by) REFERENCES auth.users(id) ON DELETE SET NULL` |
| `public` | `staff_members` | `staff_members_user_id_fkey` | FOREIGN KEY | `FOREIGN KEY (user_id) REFERENCES auth.users(id) ON DELETE CASCADE` |
| `public` | `staff_members` | `staff_members_pkey` | PRIMARY KEY | `PRIMARY KEY (user_id)` |
| `public` | `stories` | `stories_content_required` | CHECK | `CHECK (media_path IS NOT NULL OR NULLIF(text_content, ''::text) IS NOT NULL)` |
| `public` | `stories` | `stories_story_type_check` | CHECK | `CHECK (story_type = ANY (ARRAY['photo'::text, 'video'::text, 'text'::text]))` |
| `public` | `stories` | `stories_visibility_check` | CHECK | `CHECK (visibility = ANY (ARRAY['public'::text, 'followers'::text, 'close_friends'::text]))` |
| `public` | `stories` | `stories_user_id_fkey` | FOREIGN KEY | `FOREIGN KEY (user_id) REFERENCES profiles(id) ON DELETE CASCADE` |
| `public` | `stories` | `stories_pkey` | PRIMARY KEY | `PRIMARY KEY (id)` |
| `public` | `story_views` | `story_views_story_id_fkey` | FOREIGN KEY | `FOREIGN KEY (story_id) REFERENCES stories(id) ON DELETE CASCADE` |
| `public` | `story_views` | `story_views_viewer_id_fkey` | FOREIGN KEY | `FOREIGN KEY (viewer_id) REFERENCES profiles(id) ON DELETE CASCADE` |
| `public` | `story_views` | `story_views_pkey` | PRIMARY KEY | `PRIMARY KEY (story_id, viewer_id)` |
| `public` | `user_devices` | `user_devices_platform_check` | CHECK | `CHECK (platform = ANY (ARRAY['android'::text, 'ios'::text, 'web'::text]))` |
| `public` | `user_devices` | `user_devices_user_id_fkey` | FOREIGN KEY | `FOREIGN KEY (user_id) REFERENCES auth.users(id) ON DELETE CASCADE` |
| `public` | `user_devices` | `user_devices_pkey` | PRIMARY KEY | `PRIMARY KEY (id)` |
| `public` | `user_devices` | `user_devices_user_id_push_token_key` | UNIQUE | `UNIQUE (user_id, push_token)` |
| `public` | `user_preferences` | `user_preferences_theme_check` | CHECK | `CHECK (theme = ANY (ARRAY['amoled'::text, 'light'::text, 'pink_amoled'::text, 'custom'::text]))` |
| `public` | `user_preferences` | `user_preferences_user_id_fkey` | FOREIGN KEY | `FOREIGN KEY (user_id) REFERENCES profiles(id) ON DELETE CASCADE` |
| `public` | `user_preferences` | `user_preferences_pkey` | PRIMARY KEY | `PRIMARY KEY (user_id)` |
| `public` | `user_private_settings` | `user_private_settings_allow_mentions_from_check` | CHECK | `CHECK (allow_mentions_from = ANY (ARRAY['everyone'::text, 'followers'::text, 'friends'::text, 'nobody'::text]))` |
| `public` | `user_private_settings` | `user_private_settings_allow_messages_from_check` | CHECK | `CHECK (allow_messages_from = ANY (ARRAY['everyone'::text, 'followers'::text, 'friends'::text, 'nobody'::text]))` |
| `public` | `user_private_settings` | `user_private_settings_location_visibility_check` | CHECK | `CHECK (location_visibility = ANY (ARRAY['invisible'::text, 'friends'::text, 'selected'::text]))` |
| `public` | `user_private_settings` | `user_private_settings_profile_visibility_check` | CHECK | `CHECK (profile_visibility = ANY (ARRAY['public'::text, 'private'::text]))` |
| `public` | `user_private_settings` | `user_private_settings_user_id_fkey` | FOREIGN KEY | `FOREIGN KEY (user_id) REFERENCES profiles(id) ON DELETE CASCADE` |
| `public` | `user_private_settings` | `user_private_settings_pkey` | PRIMARY KEY | `PRIMARY KEY (user_id)` |

## Interpretation

- Definitions are read from PostgreSQL catalogs using `pg_get_constraintdef`.
- This inventory does not prove that all application workflows handle constraint violations correctly.
- Do not use this file to create/replay migrations. Remote/local migration-history reconciliation and a verified backup remain prerequisites for schema changes.
