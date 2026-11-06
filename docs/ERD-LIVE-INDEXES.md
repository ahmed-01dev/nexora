# NEXORA — Live PostgreSQL Index Inventory

> Read-only catalog snapshot from Supabase project `wwdeexgkwpftyavbhiff`, captured 2026-11-06. This file records deployed index definitions and is not a migration script.

- Indexes: 106

| Schema | Table | Index | Definition |
|---|---|---|---|
| `private` | `profile_discovery_locations` | `profile_discovery_locations_pkey` | `CREATE UNIQUE INDEX profile_discovery_locations_pkey ON private.profile_discovery_locations USING btree (user_id)` |
| `private` | `profile_discovery_locations` | `profile_discovery_locations_updated_idx` | `CREATE INDEX profile_discovery_locations_updated_idx ON private.profile_discovery_locations USING btree (updated_at)` |
| `public` | `audit_logs` | `audit_logs_created_idx` | `CREATE INDEX audit_logs_created_idx ON public.audit_logs USING btree (created_at DESC)` |
| `public` | `audit_logs` | `audit_logs_entity_idx` | `CREATE INDEX audit_logs_entity_idx ON public.audit_logs USING btree (entity_type, entity_id)` |
| `public` | `audit_logs` | `audit_logs_pkey` | `CREATE UNIQUE INDEX audit_logs_pkey ON public.audit_logs USING btree (id)` |
| `public` | `blocks` | `blocks_blocked_idx` | `CREATE INDEX blocks_blocked_idx ON public.blocks USING btree (blocked_id)` |
| `public` | `blocks` | `blocks_pkey` | `CREATE UNIQUE INDEX blocks_pkey ON public.blocks USING btree (blocker_id, blocked_id)` |
| `public` | `call_participants` | `call_participants_pkey` | `CREATE UNIQUE INDEX call_participants_pkey ON public.call_participants USING btree (call_id, user_id)` |
| `public` | `call_participants` | `call_participants_user_idx` | `CREATE INDEX call_participants_user_idx ON public.call_participants USING btree (user_id)` |
| `public` | `call_sessions` | `call_sessions_conversation_created_idx` | `CREATE INDEX call_sessions_conversation_created_idx ON public.call_sessions USING btree (conversation_id, started_at DESC)` |
| `public` | `call_sessions` | `call_sessions_initiated_by_idx` | `CREATE INDEX call_sessions_initiated_by_idx ON public.call_sessions USING btree (initiated_by)` |
| `public` | `call_sessions` | `call_sessions_pkey` | `CREATE UNIQUE INDEX call_sessions_pkey ON public.call_sessions USING btree (id)` |
| `public` | `collection_items` | `collection_items_pkey` | `CREATE UNIQUE INDEX collection_items_pkey ON public.collection_items USING btree (collection_id, post_id)` |
| `public` | `collection_items` | `collection_items_post_idx` | `CREATE INDEX collection_items_post_idx ON public.collection_items USING btree (post_id)` |
| `public` | `collections` | `collections_pkey` | `CREATE UNIQUE INDEX collections_pkey ON public.collections USING btree (id)` |
| `public` | `collections` | `collections_user_name_unique` | `CREATE UNIQUE INDEX collections_user_name_unique ON public.collections USING btree (user_id, lower(name))` |
| `public` | `comment_likes` | `comment_likes_comment_idx` | `CREATE INDEX comment_likes_comment_idx ON public.comment_likes USING btree (comment_id)` |
| `public` | `comment_likes` | `comment_likes_pkey` | `CREATE UNIQUE INDEX comment_likes_pkey ON public.comment_likes USING btree (user_id, comment_id)` |
| `public` | `comments` | `comments_parent_idx` | `CREATE INDEX comments_parent_idx ON public.comments USING btree (parent_id)` |
| `public` | `comments` | `comments_pkey` | `CREATE UNIQUE INDEX comments_pkey ON public.comments USING btree (id)` |
| `public` | `comments` | `comments_post_created_idx` | `CREATE INDEX comments_post_created_idx ON public.comments USING btree (post_id, created_at DESC)` |
| `public` | `comments` | `comments_user_id_idx` | `CREATE INDEX comments_user_id_idx ON public.comments USING btree (user_id)` |
| `public` | `communities` | `communities_owner_idx` | `CREATE INDEX communities_owner_idx ON public.communities USING btree (owner_id)` |
| `public` | `communities` | `communities_pkey` | `CREATE UNIQUE INDEX communities_pkey ON public.communities USING btree (id)` |
| `public` | `communities` | `communities_slug_key` | `CREATE UNIQUE INDEX communities_slug_key ON public.communities USING btree (slug)` |
| `public` | `communities` | `communities_visibility_created_idx` | `CREATE INDEX communities_visibility_created_idx ON public.communities USING btree (visibility, created_at DESC)` |
| `public` | `community_channels` | `community_channels_community_id_slug_key` | `CREATE UNIQUE INDEX community_channels_community_id_slug_key ON public.community_channels USING btree (community_id, slug)` |
| `public` | `community_channels` | `community_channels_conversation_id_key` | `CREATE UNIQUE INDEX community_channels_conversation_id_key ON public.community_channels USING btree (conversation_id)` |
| `public` | `community_channels` | `community_channels_created_by_idx` | `CREATE INDEX community_channels_created_by_idx ON public.community_channels USING btree (created_by)` |
| `public` | `community_channels` | `community_channels_pkey` | `CREATE UNIQUE INDEX community_channels_pkey ON public.community_channels USING btree (id)` |
| `public` | `community_invites` | `community_invites_community_created_idx` | `CREATE INDEX community_invites_community_created_idx ON public.community_invites USING btree (community_id, created_at DESC)` |
| `public` | `community_invites` | `community_invites_created_by_idx` | `CREATE INDEX community_invites_created_by_idx ON public.community_invites USING btree (created_by)` |
| `public` | `community_invites` | `community_invites_invite_code_key` | `CREATE UNIQUE INDEX community_invites_invite_code_key ON public.community_invites USING btree (invite_code)` |
| `public` | `community_invites` | `community_invites_pkey` | `CREATE UNIQUE INDEX community_invites_pkey ON public.community_invites USING btree (id)` |
| `public` | `community_members` | `community_members_pkey` | `CREATE UNIQUE INDEX community_members_pkey ON public.community_members USING btree (community_id, user_id)` |
| `public` | `community_members` | `community_members_user_idx` | `CREATE INDEX community_members_user_idx ON public.community_members USING btree (user_id, community_id)` |
| `public` | `conversation_members` | `conversation_members_pkey` | `CREATE UNIQUE INDEX conversation_members_pkey ON public.conversation_members USING btree (conversation_id, user_id)` |
| `public` | `conversation_members` | `conversation_members_user_idx` | `CREATE INDEX conversation_members_user_idx ON public.conversation_members USING btree (user_id, conversation_id)` |
| `public` | `conversations` | `conversations_created_by_idx` | `CREATE INDEX conversations_created_by_idx ON public.conversations USING btree (created_by)` |
| `public` | `conversations` | `conversations_pkey` | `CREATE UNIQUE INDEX conversations_pkey ON public.conversations USING btree (id)` |
| `public` | `follows` | `follows_follower_status_idx` | `CREATE INDEX follows_follower_status_idx ON public.follows USING btree (follower_id, status)` |
| `public` | `follows` | `follows_following_idx` | `CREATE INDEX follows_following_idx ON public.follows USING btree (following_id)` |
| `public` | `follows` | `follows_following_status_idx` | `CREATE INDEX follows_following_status_idx ON public.follows USING btree (following_id, status)` |
| `public` | `follows` | `follows_pkey` | `CREATE UNIQUE INDEX follows_pkey ON public.follows USING btree (follower_id, following_id)` |
| `public` | `friendships` | `friendships_addressee_status_idx` | `CREATE INDEX friendships_addressee_status_idx ON public.friendships USING btree (addressee_id, status, created_at DESC)` |
| `public` | `friendships` | `friendships_pkey` | `CREATE UNIQUE INDEX friendships_pkey ON public.friendships USING btree (id)` |
| `public` | `friendships` | `friendships_unique_pair` | `CREATE UNIQUE INDEX friendships_unique_pair ON public.friendships USING btree (requester_id, addressee_id)` |
| `public` | `hashtags` | `hashtags_pkey` | `CREATE UNIQUE INDEX hashtags_pkey ON public.hashtags USING btree (id)` |
| `public` | `hashtags` | `hashtags_tag_key` | `CREATE UNIQUE INDEX hashtags_tag_key ON public.hashtags USING btree (tag)` |
| `public` | `likes` | `likes_pkey` | `CREATE UNIQUE INDEX likes_pkey ON public.likes USING btree (user_id, post_id)` |
| `public` | `likes` | `likes_post_created_idx` | `CREATE INDEX likes_post_created_idx ON public.likes USING btree (post_id, created_at DESC)` |
| `public` | `media` | `media_pkey` | `CREATE UNIQUE INDEX media_pkey ON public.media USING btree (id)` |
| `public` | `media` | `media_post_idx` | `CREATE INDEX media_post_idx ON public.media USING btree (post_id, "position")` |
| `public` | `media` | `media_user_id_idx` | `CREATE INDEX media_user_id_idx ON public.media USING btree (user_id)` |
| `public` | `message_attachments` | `message_attachments_message_idx` | `CREATE INDEX message_attachments_message_idx ON public.message_attachments USING btree (message_id)` |
| `public` | `message_attachments` | `message_attachments_pkey` | `CREATE UNIQUE INDEX message_attachments_pkey ON public.message_attachments USING btree (id)` |
| `public` | `message_attachments` | `message_attachments_uploader_idx` | `CREATE INDEX message_attachments_uploader_idx ON public.message_attachments USING btree (uploader_id)` |
| `public` | `message_reactions` | `message_reactions_pkey` | `CREATE UNIQUE INDEX message_reactions_pkey ON public.message_reactions USING btree (message_id, user_id, reaction)` |
| `public` | `message_reactions` | `message_reactions_user_idx` | `CREATE INDEX message_reactions_user_idx ON public.message_reactions USING btree (user_id)` |
| `public` | `messages` | `messages_conversation_created_idx` | `CREATE INDEX messages_conversation_created_idx ON public.messages USING btree (conversation_id, created_at DESC)` |
| `public` | `messages` | `messages_pkey` | `CREATE UNIQUE INDEX messages_pkey ON public.messages USING btree (id)` |
| `public` | `messages` | `messages_reply_to_idx` | `CREATE INDEX messages_reply_to_idx ON public.messages USING btree (reply_to)` |
| `public` | `messages` | `messages_sender_idx` | `CREATE INDEX messages_sender_idx ON public.messages USING btree (sender_id)` |
| `public` | `moderation_actions` | `moderation_actions_moderator_idx` | `CREATE INDEX moderation_actions_moderator_idx ON public.moderation_actions USING btree (moderator_id)` |
| `public` | `moderation_actions` | `moderation_actions_pkey` | `CREATE UNIQUE INDEX moderation_actions_pkey ON public.moderation_actions USING btree (id)` |
| `public` | `moderation_actions` | `moderation_actions_report_idx` | `CREATE INDEX moderation_actions_report_idx ON public.moderation_actions USING btree (report_id)` |
| `public` | `moderation_actions` | `moderation_actions_target_idx` | `CREATE INDEX moderation_actions_target_idx ON public.moderation_actions USING btree (target_type, target_id)` |
| `public` | `moderation_appeals` | `moderation_appeals_action_id_user_id_key` | `CREATE UNIQUE INDEX moderation_appeals_action_id_user_id_key ON public.moderation_appeals USING btree (action_id, user_id)` |
| `public` | `moderation_appeals` | `moderation_appeals_pkey` | `CREATE UNIQUE INDEX moderation_appeals_pkey ON public.moderation_appeals USING btree (id)` |
| `public` | `moderation_appeals` | `moderation_appeals_reviewer_idx` | `CREATE INDEX moderation_appeals_reviewer_idx ON public.moderation_appeals USING btree (reviewer_id)` |
| `public` | `moderation_appeals` | `moderation_appeals_user_idx` | `CREATE INDEX moderation_appeals_user_idx ON public.moderation_appeals USING btree (user_id)` |
| `public` | `notification_preferences` | `notification_preferences_pkey` | `CREATE UNIQUE INDEX notification_preferences_pkey ON public.notification_preferences USING btree (user_id, category)` |
| `public` | `notifications` | `notifications_actor_idx` | `CREATE INDEX notifications_actor_idx ON public.notifications USING btree (actor_id)` |
| `public` | `notifications` | `notifications_pkey` | `CREATE UNIQUE INDEX notifications_pkey ON public.notifications USING btree (id)` |
| `public` | `notifications` | `notifications_recipient_created_idx` | `CREATE INDEX notifications_recipient_created_idx ON public.notifications USING btree (recipient_id, created_at DESC)` |
| `public` | `post_hashtags` | `post_hashtags_hashtag_idx` | `CREATE INDEX post_hashtags_hashtag_idx ON public.post_hashtags USING btree (hashtag_id)` |
| `public` | `post_hashtags` | `post_hashtags_pkey` | `CREATE UNIQUE INDEX post_hashtags_pkey ON public.post_hashtags USING btree (post_id, hashtag_id)` |
| `public` | `posts` | `posts_created_idx` | `CREATE INDEX posts_created_idx ON public.posts USING btree (created_at DESC)` |
| `public` | `posts` | `posts_pkey` | `CREATE UNIQUE INDEX posts_pkey ON public.posts USING btree (id)` |
| `public` | `posts` | `posts_user_created_idx` | `CREATE INDEX posts_user_created_idx ON public.posts USING btree (user_id, created_at DESC)` |
| `public` | `profiles` | `profiles_pkey` | `CREATE UNIQUE INDEX profiles_pkey ON public.profiles USING btree (id)` |
| `public` | `profiles` | `profiles_username_key` | `CREATE UNIQUE INDEX profiles_username_key ON public.profiles USING btree (username)` |
| `public` | `profiles` | `profiles_username_lower_key` | `CREATE UNIQUE INDEX profiles_username_lower_key ON public.profiles USING btree (lower(username)) WHERE (username IS NOT NULL)` |
| `public` | `reports` | `reports_assigned_idx` | `CREATE INDEX reports_assigned_idx ON public.reports USING btree (assigned_to)` |
| `public` | `reports` | `reports_pkey` | `CREATE UNIQUE INDEX reports_pkey ON public.reports USING btree (id)` |
| `public` | `reports` | `reports_reporter_idx` | `CREATE INDEX reports_reporter_idx ON public.reports USING btree (reporter_id)` |
| `public` | `reports` | `reports_status_created_idx` | `CREATE INDEX reports_status_created_idx ON public.reports USING btree (status, created_at)` |
| `public` | `reposts` | `reposts_pkey` | `CREATE UNIQUE INDEX reposts_pkey ON public.reposts USING btree (id)` |
| `public` | `reposts` | `reposts_plain_unique` | `CREATE UNIQUE INDEX reposts_plain_unique ON public.reposts USING btree (user_id, post_id) WHERE (quote_text IS NULL)` |
| `public` | `reposts` | `reposts_post_idx` | `CREATE INDEX reposts_post_idx ON public.reposts USING btree (post_id)` |
| `public` | `reposts` | `reposts_user_created_idx` | `CREATE INDEX reposts_user_created_idx ON public.reposts USING btree (user_id, created_at DESC)` |
| `public` | `reposts` | `reposts_user_post_unique_idx` | `CREATE UNIQUE INDEX reposts_user_post_unique_idx ON public.reposts USING btree (user_id, post_id)` |
| `public` | `saves` | `saves_pkey` | `CREATE UNIQUE INDEX saves_pkey ON public.saves USING btree (user_id, post_id)` |
| `public` | `saves` | `saves_post_id_idx` | `CREATE INDEX saves_post_id_idx ON public.saves USING btree (post_id)` |
| `public` | `saves` | `saves_user_created_idx` | `CREATE INDEX saves_user_created_idx ON public.saves USING btree (user_id, created_at DESC)` |
| `public` | `staff_members` | `staff_members_created_by_idx` | `CREATE INDEX staff_members_created_by_idx ON public.staff_members USING btree (created_by) WHERE (created_by IS NOT NULL)` |
| `public` | `staff_members` | `staff_members_pkey` | `CREATE UNIQUE INDEX staff_members_pkey ON public.staff_members USING btree (user_id)` |
| `public` | `stories` | `stories_expiry_idx` | `CREATE INDEX stories_expiry_idx ON public.stories USING btree (expires_at) WHERE (archived_at IS NULL)` |
| `public` | `stories` | `stories_pkey` | `CREATE UNIQUE INDEX stories_pkey ON public.stories USING btree (id)` |
| `public` | `stories` | `stories_user_created_idx` | `CREATE INDEX stories_user_created_idx ON public.stories USING btree (user_id, created_at DESC)` |
| `public` | `story_views` | `story_views_pkey` | `CREATE UNIQUE INDEX story_views_pkey ON public.story_views USING btree (story_id, viewer_id)` |
| `public` | `story_views` | `story_views_viewer_idx` | `CREATE INDEX story_views_viewer_idx ON public.story_views USING btree (viewer_id)` |
| `public` | `user_devices` | `user_devices_pkey` | `CREATE UNIQUE INDEX user_devices_pkey ON public.user_devices USING btree (id)` |
| `public` | `user_devices` | `user_devices_user_id_push_token_key` | `CREATE UNIQUE INDEX user_devices_user_id_push_token_key ON public.user_devices USING btree (user_id, push_token)` |
| `public` | `user_preferences` | `user_preferences_pkey` | `CREATE UNIQUE INDEX user_preferences_pkey ON public.user_preferences USING btree (user_id)` |
| `public` | `user_private_settings` | `user_private_settings_pkey` | `CREATE UNIQUE INDEX user_private_settings_pkey ON public.user_private_settings USING btree (user_id)` |

## Performance and safety notes

- Index presence alone does not establish workload usefulness; inspect representative `EXPLAIN (ANALYZE, BUFFERS)` plans before changing indexes.
- Supabase Advisor has reported unused indexes, but no index was dropped as part of this review.
- Migration-history drift remains unresolved. Do not use this snapshot to create or apply index migrations.
