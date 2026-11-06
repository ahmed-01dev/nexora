# NEXORA — Live PostgreSQL RLS Policy Inventory

> Read-only snapshot from Supabase project `wwdeexgkwpftyavbhiff`, captured 2026-11-06. Policy expressions are copied from `pg_policies`; no policy changes were made.

- Policies: 112
- Public: 111
- Private: 1

## `private.profile_discovery_locations` — `profile_discovery_locations_owner_only`

- Command: `ALL`
- Mode: `PERMISSIVE`
- Roles: `{authenticated}`
- USING: `(user_id = ( SELECT auth.uid() AS uid))`
- WITH CHECK: `(user_id = ( SELECT auth.uid() AS uid))`

## `public.audit_logs` — `audit_logs_read_admin`

- Command: `SELECT`
- Mode: `PERMISSIVE`
- Roles: `{authenticated}`
- USING: `private.is_staff(ARRAY['super_admin'::text, 'admin'::text])`
- WITH CHECK: —

## `public.blocks` — `blocks_manage_own`

- Command: `ALL`
- Mode: `PERMISSIVE`
- Roles: `{authenticated}`
- USING: `(blocker_id = ( SELECT auth.uid() AS uid))`
- WITH CHECK: `(blocker_id = ( SELECT auth.uid() AS uid))`

## `public.call_participants` — `call_participants_manage_self`

- Command: `INSERT`
- Mode: `PERMISSIVE`
- Roles: `{authenticated}`
- USING: —
- WITH CHECK: `((user_id = ( SELECT auth.uid() AS uid)) AND (EXISTS ( SELECT 1    FROM call_sessions c   WHERE ((c.id = call_participants.call_id) AND private.is_conversation_member(c.conversation_id)))))`

## `public.call_participants` — `call_participants_read_members`

- Command: `SELECT`
- Mode: `PERMISSIVE`
- Roles: `{authenticated}`
- USING: `(EXISTS ( SELECT 1    FROM call_sessions c   WHERE ((c.id = call_participants.call_id) AND private.is_conversation_member(c.conversation_id))))`
- WITH CHECK: —

## `public.call_participants` — `call_participants_update_self`

- Command: `UPDATE`
- Mode: `PERMISSIVE`
- Roles: `{authenticated}`
- USING: `(user_id = ( SELECT auth.uid() AS uid))`
- WITH CHECK: `(user_id = ( SELECT auth.uid() AS uid))`

## `public.call_sessions` — `call_sessions_create_member`

- Command: `INSERT`
- Mode: `PERMISSIVE`
- Roles: `{authenticated}`
- USING: —
- WITH CHECK: `((initiated_by = ( SELECT auth.uid() AS uid)) AND private.is_conversation_member(conversation_id))`

## `public.call_sessions` — `call_sessions_read_members`

- Command: `SELECT`
- Mode: `PERMISSIVE`
- Roles: `{authenticated}`
- USING: `private.is_conversation_member(conversation_id)`
- WITH CHECK: —

## `public.call_sessions` — `call_sessions_update_members`

- Command: `UPDATE`
- Mode: `PERMISSIVE`
- Roles: `{authenticated}`
- USING: `private.is_conversation_member(conversation_id)`
- WITH CHECK: `private.is_conversation_member(conversation_id)`

## `public.collection_items` — `collection_items_delete_own`

- Command: `DELETE`
- Mode: `PERMISSIVE`
- Roles: `{authenticated}`
- USING: `(EXISTS ( SELECT 1    FROM collections c   WHERE ((c.id = collection_items.collection_id) AND (c.user_id = ( SELECT auth.uid() AS uid)))))`
- WITH CHECK: —

## `public.collection_items` — `collection_items_insert_own`

- Command: `INSERT`
- Mode: `PERMISSIVE`
- Roles: `{authenticated}`
- USING: —
- WITH CHECK: `((EXISTS ( SELECT 1    FROM collections c   WHERE ((c.id = collection_items.collection_id) AND (c.user_id = ( SELECT auth.uid() AS uid))))) AND (EXISTS ( SELECT 1    FROM posts p   WHERE (p.id = collection_items.post_id))))`

## `public.collection_items` — `collection_items_select_own`

- Command: `SELECT`
- Mode: `PERMISSIVE`
- Roles: `{authenticated}`
- USING: `(EXISTS ( SELECT 1    FROM collections c   WHERE ((c.id = collection_items.collection_id) AND (c.user_id = ( SELECT auth.uid() AS uid)))))`
- WITH CHECK: —

## `public.collections` — `collections_delete_own`

- Command: `DELETE`
- Mode: `PERMISSIVE`
- Roles: `{authenticated}`
- USING: `(user_id = ( SELECT auth.uid() AS uid))`
- WITH CHECK: —

## `public.collections` — `collections_insert_own`

- Command: `INSERT`
- Mode: `PERMISSIVE`
- Roles: `{authenticated}`
- USING: —
- WITH CHECK: `(user_id = ( SELECT auth.uid() AS uid))`

## `public.collections` — `collections_select_own`

- Command: `SELECT`
- Mode: `PERMISSIVE`
- Roles: `{authenticated}`
- USING: `(user_id = ( SELECT auth.uid() AS uid))`
- WITH CHECK: —

## `public.collections` — `collections_update_own`

- Command: `UPDATE`
- Mode: `PERMISSIVE`
- Roles: `{authenticated}`
- USING: `(user_id = ( SELECT auth.uid() AS uid))`
- WITH CHECK: `(user_id = ( SELECT auth.uid() AS uid))`

## `public.comment_likes` — `comment_likes_delete`

- Command: `DELETE`
- Mode: `PERMISSIVE`
- Roles: `{authenticated}`
- USING: `(user_id = ( SELECT auth.uid() AS uid))`
- WITH CHECK: —

## `public.comment_likes` — `comment_likes_insert`

- Command: `INSERT`
- Mode: `PERMISSIVE`
- Roles: `{authenticated}`
- USING: —
- WITH CHECK: `((user_id = ( SELECT auth.uid() AS uid)) AND (EXISTS ( SELECT 1    FROM comments c   WHERE (c.id = comment_likes.comment_id))))`

## `public.comment_likes` — `comment_likes_read`

- Command: `SELECT`
- Mode: `PERMISSIVE`
- Roles: `{authenticated}`
- USING: `(EXISTS ( SELECT 1    FROM comments c   WHERE (c.id = comment_likes.comment_id)))`
- WITH CHECK: —

## `public.comments` — `Delete own comments`

- Command: `DELETE`
- Mode: `PERMISSIVE`
- Roles: `{authenticated}`
- USING: `(( SELECT auth.uid() AS uid) = user_id)`
- WITH CHECK: —

## `public.comments` — `comments_insert_own`

- Command: `INSERT`
- Mode: `PERMISSIVE`
- Roles: `{authenticated}`
- USING: —
- WITH CHECK: `((user_id = ( SELECT auth.uid() AS uid)) AND (EXISTS ( SELECT 1    FROM posts p   WHERE (p.id = comments.post_id))) AND ((parent_id IS NULL) OR (EXISTS ( SELECT 1    FROM comments c   WHERE ((c.id = comments.parent_id) AND (c.post_id = comments.post_id))))))`

## `public.comments` — `comments_read_visible`

- Command: `SELECT`
- Mode: `PERMISSIVE`
- Roles: `{authenticated}`
- USING: `((EXISTS ( SELECT 1    FROM posts p   WHERE (p.id = comments.post_id))) AND ((deleted_at IS NULL) OR (user_id = ( SELECT auth.uid() AS uid))))`
- WITH CHECK: —

## `public.comments` — `comments_update_own`

- Command: `UPDATE`
- Mode: `PERMISSIVE`
- Roles: `{authenticated}`
- USING: `(user_id = ( SELECT auth.uid() AS uid))`
- WITH CHECK: `(user_id = ( SELECT auth.uid() AS uid))`

## `public.communities` — `communities_create_self`

- Command: `INSERT`
- Mode: `PERMISSIVE`
- Roles: `{authenticated}`
- USING: —
- WITH CHECK: `((owner_id = ( SELECT auth.uid() AS uid)) AND ((cover_path IS NULL) OR (((storage.foldername(cover_path))[1] = (( SELECT auth.uid() AS uid))::text) AND (EXISTS ( SELECT 1    FROM storage.objects o   WHERE ((o.bucket_id = 'nexora-media'::text) AND (o.name = communities.cover_path)))))))`

## `public.communities` — `communities_delete_owner`

- Command: `DELETE`
- Mode: `PERMISSIVE`
- Roles: `{authenticated}`
- USING: `(owner_id = ( SELECT auth.uid() AS uid))`
- WITH CHECK: —

## `public.communities` — `communities_read_visible`

- Command: `SELECT`
- Mode: `PERMISSIVE`
- Roles: `{authenticated}`
- USING: `((owner_id = ( SELECT auth.uid() AS uid)) OR (visibility = 'public'::text) OR private.is_community_member(id))`
- WITH CHECK: —

## `public.communities` — `communities_update_owner`

- Command: `UPDATE`
- Mode: `PERMISSIVE`
- Roles: `{authenticated}`
- USING: `(owner_id = ( SELECT auth.uid() AS uid))`
- WITH CHECK: `((owner_id = ( SELECT auth.uid() AS uid)) AND ((cover_path IS NULL) OR (((storage.foldername(cover_path))[1] = (( SELECT auth.uid() AS uid))::text) AND (EXISTS ( SELECT 1    FROM storage.objects o   WHERE ((o.bucket_id = 'nexora-media'::text) AND (o.name = communities.cover_path)))))))`

## `public.community_channels` — `community_channels_create_owner`

- Command: `INSERT`
- Mode: `PERMISSIVE`
- Roles: `{authenticated}`
- USING: —
- WITH CHECK: `((created_by = ( SELECT auth.uid() AS uid)) AND (private.is_community_owner(community_id) OR (EXISTS ( SELECT 1    FROM community_members cm   WHERE ((cm.community_id = community_channels.community_id) AND (cm.user_id = ( SELECT auth.uid() AS uid)) AND (cm.role = 'moderator'::text))))) AND (EXISTS ( SELECT 1    FROM conversations c   WHERE ((c.id = community_channels.conversation_id) AND (c.created_by = ( SELECT auth.uid() AS uid)) AND (c.conversation_type = 'community'::text)))))`

## `public.community_channels` — `community_channels_delete_owner`

- Command: `DELETE`
- Mode: `PERMISSIVE`
- Roles: `{authenticated}`
- USING: `private.is_community_owner(community_id)`
- WITH CHECK: —

## `public.community_channels` — `community_channels_read_members`

- Command: `SELECT`
- Mode: `PERMISSIVE`
- Roles: `{authenticated}`
- USING: `(private.is_community_member(community_id) OR private.is_community_owner(community_id))`
- WITH CHECK: —

## `public.community_invites` — `community_invites_deny_direct_access`

- Command: `ALL`
- Mode: `PERMISSIVE`
- Roles: `{anon,authenticated}`
- USING: `false`
- WITH CHECK: `false`

## `public.community_members` — `community_members_join_public`

- Command: `INSERT`
- Mode: `PERMISSIVE`
- Roles: `{authenticated}`
- USING: —
- WITH CHECK: `((user_id = ( SELECT auth.uid() AS uid)) AND (private.is_community_owner(community_id) OR (EXISTS ( SELECT 1    FROM communities c   WHERE ((c.id = community_members.community_id) AND (c.visibility = 'public'::text))))))`

## `public.community_members` — `community_members_leave_or_owner_remove`

- Command: `DELETE`
- Mode: `PERMISSIVE`
- Roles: `{authenticated}`
- USING: `((user_id = ( SELECT auth.uid() AS uid)) OR private.is_community_owner(community_id))`
- WITH CHECK: —

## `public.community_members` — `community_members_owner_update`

- Command: `UPDATE`
- Mode: `PERMISSIVE`
- Roles: `{authenticated}`
- USING: `private.is_community_owner(community_id)`
- WITH CHECK: `private.is_community_owner(community_id)`

## `public.community_members` — `community_members_read_members`

- Command: `SELECT`
- Mode: `PERMISSIVE`
- Roles: `{authenticated}`
- USING: `(private.is_community_member(community_id) OR private.is_community_owner(community_id))`
- WITH CHECK: —

## `public.conversation_members` — `conversation_members_add_by_creator`

- Command: `INSERT`
- Mode: `PERMISSIVE`
- Roles: `{authenticated}`
- USING: —
- WITH CHECK: `((private.is_conversation_creator(conversation_id) AND (EXISTS ( SELECT 1    FROM conversations c   WHERE ((c.id = conversation_members.conversation_id) AND (c.conversation_type = ANY (ARRAY['group'::text, 'community'::text])))))) OR ((user_id = ( SELECT auth.uid() AS uid)) AND private.is_conversation_member(conversation_id)))`

## `public.conversation_members` — `conversation_members_read_members`

- Command: `SELECT`
- Mode: `PERMISSIVE`
- Roles: `{authenticated}`
- USING: `private.is_conversation_member(conversation_id)`
- WITH CHECK: —

## `public.conversation_members` — `conversation_members_remove`

- Command: `DELETE`
- Mode: `PERMISSIVE`
- Roles: `{authenticated}`
- USING: `((user_id = ( SELECT auth.uid() AS uid)) OR (private.is_conversation_creator(conversation_id) AND (EXISTS ( SELECT 1    FROM conversations c   WHERE ((c.id = conversation_members.conversation_id) AND (c.conversation_type = ANY (ARRAY['group'::text, 'community'::text])))))))`
- WITH CHECK: —

## `public.conversation_members` — `conversation_members_update_self`

- Command: `UPDATE`
- Mode: `PERMISSIVE`
- Roles: `{authenticated}`
- USING: `(user_id = ( SELECT auth.uid() AS uid))`
- WITH CHECK: `(user_id = ( SELECT auth.uid() AS uid))`

## `public.conversations` — `conversations_create_self`

- Command: `INSERT`
- Mode: `PERMISSIVE`
- Roles: `{authenticated}`
- USING: —
- WITH CHECK: `(created_by = ( SELECT auth.uid() AS uid))`

## `public.conversations` — `conversations_read_members`

- Command: `SELECT`
- Mode: `PERMISSIVE`
- Roles: `{authenticated}`
- USING: `private.is_conversation_member(id)`
- WITH CHECK: —

## `public.conversations` — `conversations_update_creator`

- Command: `UPDATE`
- Mode: `PERMISSIVE`
- Roles: `{authenticated}`
- USING: `(created_by = ( SELECT auth.uid() AS uid))`
- WITH CHECK: `(created_by = ( SELECT auth.uid() AS uid))`

## `public.follows` — `Accept incoming follow requests`

- Command: `UPDATE`
- Mode: `PERMISSIVE`
- Roles: `{authenticated}`
- USING: `((following_id = ( SELECT auth.uid() AS uid)) AND (status = 'pending'::text) AND (NOT private.is_blocked_between(( SELECT auth.uid() AS uid), follower_id)))`
- WITH CHECK: `((following_id = ( SELECT auth.uid() AS uid)) AND (status = 'accepted'::text) AND (NOT private.is_blocked_between(( SELECT auth.uid() AS uid), follower_id)))`

## `public.follows` — `Create follows`

- Command: `INSERT`
- Mode: `PERMISSIVE`
- Roles: `{authenticated}`
- USING: —
- WITH CHECK: `(( SELECT auth.uid() AS uid) = follower_id)`

## `public.follows` — `Delete own follows`

- Command: `DELETE`
- Mode: `PERMISSIVE`
- Roles: `{authenticated}`
- USING: `(( SELECT auth.uid() AS uid) = follower_id)`
- WITH CHECK: —

## `public.follows` — `Read follows`

- Command: `SELECT`
- Mode: `PERMISSIVE`
- Roles: `{authenticated}`
- USING: `(((( SELECT auth.uid() AS uid) = follower_id) OR (( SELECT auth.uid() AS uid) = following_id)) AND (NOT private.is_blocked_between(( SELECT auth.uid() AS uid), CASE     WHEN (( SELECT auth.uid() AS uid) = follower_id) THEN following_id     ELSE follower_id END)))`
- WITH CHECK: —

## `public.friendships` — `friendships_delete_participant`

- Command: `DELETE`
- Mode: `PERMISSIVE`
- Roles: `{authenticated}`
- USING: `((( SELECT auth.uid() AS uid) = requester_id) OR (( SELECT auth.uid() AS uid) = addressee_id))`
- WITH CHECK: —

## `public.friendships` — `friendships_read_participant`

- Command: `SELECT`
- Mode: `PERMISSIVE`
- Roles: `{authenticated}`
- USING: `(((( SELECT auth.uid() AS uid) = requester_id) OR (( SELECT auth.uid() AS uid) = addressee_id)) AND (NOT private.is_blocked_between(( SELECT auth.uid() AS uid), CASE     WHEN (( SELECT auth.uid() AS uid) = requester_id) THEN addressee_id     ELSE requester_id END)))`
- WITH CHECK: —

## `public.friendships` — `friendships_recipient_update`

- Command: `UPDATE`
- Mode: `PERMISSIVE`
- Roles: `{authenticated}`
- USING: `((addressee_id = ( SELECT auth.uid() AS uid)) OR (requester_id = ( SELECT auth.uid() AS uid)))`
- WITH CHECK: `(((addressee_id = ( SELECT auth.uid() AS uid)) AND (status = ANY (ARRAY['accepted'::text, 'declined'::text]))) OR ((requester_id = ( SELECT auth.uid() AS uid)) AND (status = 'cancelled'::text)))`

## `public.friendships` — `friendships_request_self`

- Command: `INSERT`
- Mode: `PERMISSIVE`
- Roles: `{authenticated}`
- USING: —
- WITH CHECK: `(requester_id = ( SELECT auth.uid() AS uid))`

## `public.hashtags` — `hashtags_insert`

- Command: `INSERT`
- Mode: `PERMISSIVE`
- Roles: `{authenticated}`
- USING: —
- WITH CHECK: `(((char_length(tag) >= 1) AND (char_length(tag) <= 64)) AND (tag = lower(tag)))`

## `public.hashtags` — `hashtags_read`

- Command: `SELECT`
- Mode: `PERMISSIVE`
- Roles: `{authenticated}`
- USING: `true`
- WITH CHECK: —

## `public.likes` — `Delete own likes`

- Command: `DELETE`
- Mode: `PERMISSIVE`
- Roles: `{authenticated}`
- USING: `(( SELECT auth.uid() AS uid) = user_id)`
- WITH CHECK: —

## `public.likes` — `likes_insert_own`

- Command: `INSERT`
- Mode: `PERMISSIVE`
- Roles: `{authenticated}`
- USING: —
- WITH CHECK: `((user_id = ( SELECT auth.uid() AS uid)) AND (EXISTS ( SELECT 1    FROM posts p   WHERE (p.id = likes.post_id))))`

## `public.likes` — `likes_read_visible`

- Command: `SELECT`
- Mode: `PERMISSIVE`
- Roles: `{authenticated}`
- USING: `(EXISTS ( SELECT 1    FROM posts p   WHERE (p.id = likes.post_id)))`
- WITH CHECK: —

## `public.media` — `Add own media`

- Command: `INSERT`
- Mode: `PERMISSIVE`
- Roles: `{authenticated}`
- USING: —
- WITH CHECK: `((user_id = ( SELECT auth.uid() AS uid)) AND ((storage.foldername(storage_path))[1] = (( SELECT auth.uid() AS uid))::text) AND (EXISTS ( SELECT 1    FROM storage.objects o   WHERE ((o.bucket_id = 'nexora-media'::text) AND (o.name = media.storage_path)))) AND (EXISTS ( SELECT 1    FROM posts p   WHERE ((p.id = media.post_id) AND (p.user_id = ( SELECT auth.uid() AS uid))))))`

## `public.media` — `Delete own media`

- Command: `DELETE`
- Mode: `PERMISSIVE`
- Roles: `{authenticated}`
- USING: `(( SELECT auth.uid() AS uid) = user_id)`
- WITH CHECK: —

## `public.media` — `Read media of readable posts`

- Command: `SELECT`
- Mode: `PERMISSIVE`
- Roles: `{authenticated}`
- USING: `(EXISTS ( SELECT 1    FROM posts p   WHERE (p.id = media.post_id)))`
- WITH CHECK: —

## `public.message_attachments` — `attachments_delete_self`

- Command: `DELETE`
- Mode: `PERMISSIVE`
- Roles: `{authenticated}`
- USING: `(uploader_id = ( SELECT auth.uid() AS uid))`
- WITH CHECK: —

## `public.message_attachments` — `attachments_hide_deleted_messages`

- Command: `SELECT`
- Mode: `RESTRICTIVE`
- Roles: `{authenticated}`
- USING: `(EXISTS ( SELECT 1    FROM messages m   WHERE ((m.id = message_attachments.message_id) AND (m.deleted_at IS NULL) AND private.is_conversation_member(m.conversation_id))))`
- WITH CHECK: —

## `public.message_attachments` — `attachments_insert_self`

- Command: `INSERT`
- Mode: `PERMISSIVE`
- Roles: `{authenticated}`
- USING: —
- WITH CHECK: `((uploader_id = ( SELECT auth.uid() AS uid)) AND ((storage.foldername(storage_path))[1] = (( SELECT auth.uid() AS uid))::text) AND (EXISTS ( SELECT 1    FROM storage.objects o   WHERE ((o.bucket_id = 'nexora-media'::text) AND (o.name = message_attachments.storage_path)))) AND (EXISTS ( SELECT 1    FROM messages m   WHERE ((m.id = message_attachments.message_id) AND (m.sender_id = ( SELECT auth.uid() AS uid)) AND private.is_conversation_member(m.conversation_id)))))`

## `public.message_attachments` — `attachments_validate_image_upload`

- Command: `INSERT`
- Mode: `RESTRICTIVE`
- Roles: `{authenticated}`
- USING: —
- WITH CHECK: `((mime_type = ANY (ARRAY['image/jpeg'::text, 'image/png'::text, 'image/webp'::text])) AND (size_bytes <= 10485760) AND (EXISTS ( SELECT 1    FROM messages m   WHERE ((m.id = message_attachments.message_id) AND (m.sender_id = ( SELECT auth.uid() AS uid)) AND (m.message_type = 'image'::text) AND (m.deleted_at IS NULL)))))`

## `public.message_reactions` — `reactions_delete_self`

- Command: `DELETE`
- Mode: `PERMISSIVE`
- Roles: `{authenticated}`
- USING: `(user_id = ( SELECT auth.uid() AS uid))`
- WITH CHECK: —

## `public.message_reactions` — `reactions_insert_self`

- Command: `INSERT`
- Mode: `PERMISSIVE`
- Roles: `{authenticated}`
- USING: —
- WITH CHECK: `((user_id = ( SELECT auth.uid() AS uid)) AND (EXISTS ( SELECT 1    FROM messages m   WHERE ((m.id = message_reactions.message_id) AND private.is_conversation_member(m.conversation_id)))))`

## `public.message_reactions` — `reactions_read_members`

- Command: `SELECT`
- Mode: `PERMISSIVE`
- Roles: `{authenticated}`
- USING: `(EXISTS ( SELECT 1    FROM messages m   WHERE ((m.id = message_reactions.message_id) AND private.is_conversation_member(m.conversation_id))))`
- WITH CHECK: —

## `public.messages` — `messages_delete_own`

- Command: `DELETE`
- Mode: `PERMISSIVE`
- Roles: `{authenticated}`
- USING: `(sender_id = ( SELECT auth.uid() AS uid))`
- WITH CHECK: —

## `public.messages` — `messages_edit_own`

- Command: `UPDATE`
- Mode: `PERMISSIVE`
- Roles: `{authenticated}`
- USING: `((sender_id = ( SELECT auth.uid() AS uid)) AND private.is_conversation_member(conversation_id))`
- WITH CHECK: `((sender_id = ( SELECT auth.uid() AS uid)) AND private.is_conversation_member(conversation_id))`

## `public.messages` — `messages_read_members`

- Command: `SELECT`
- Mode: `PERMISSIVE`
- Roles: `{authenticated}`
- USING: `private.is_conversation_member(conversation_id)`
- WITH CHECK: —

## `public.messages` — `messages_send_as_self`

- Command: `INSERT`
- Mode: `PERMISSIVE`
- Roles: `{authenticated}`
- USING: —
- WITH CHECK: `((sender_id = ( SELECT auth.uid() AS uid)) AND private.is_conversation_member(conversation_id))`

## `public.moderation_actions` — `mod_actions_insert_staff`

- Command: `INSERT`
- Mode: `PERMISSIVE`
- Roles: `{authenticated}`
- USING: —
- WITH CHECK: `((moderator_id = ( SELECT auth.uid() AS uid)) AND private.is_staff(ARRAY['super_admin'::text, 'admin'::text, 'moderator'::text]))`

## `public.moderation_actions` — `mod_actions_read_authorized`

- Command: `SELECT`
- Mode: `PERMISSIVE`
- Roles: `{authenticated}`
- USING: `(private.is_staff(ARRAY['super_admin'::text, 'admin'::text, 'moderator'::text, 'support'::text]) OR ((target_type = 'user'::text) AND (target_id = ( SELECT auth.uid() AS uid))))`
- WITH CHECK: —

## `public.moderation_appeals` — `appeals_insert_own`

- Command: `INSERT`
- Mode: `PERMISSIVE`
- Roles: `{authenticated}`
- USING: —
- WITH CHECK: `((user_id = ( SELECT auth.uid() AS uid)) AND (EXISTS ( SELECT 1    FROM moderation_actions a   WHERE ((a.id = moderation_appeals.action_id) AND (a.target_type = 'user'::text) AND (a.target_id = ( SELECT auth.uid() AS uid)) AND (a.action <> 'dismiss'::text)))))`

## `public.moderation_appeals` — `appeals_read_authorized`

- Command: `SELECT`
- Mode: `PERMISSIVE`
- Roles: `{authenticated}`
- USING: `((user_id = ( SELECT auth.uid() AS uid)) OR private.is_staff(ARRAY['super_admin'::text, 'admin'::text, 'moderator'::text]))`
- WITH CHECK: —

## `public.moderation_appeals` — `appeals_update_staff`

- Command: `UPDATE`
- Mode: `PERMISSIVE`
- Roles: `{authenticated}`
- USING: `private.is_staff(ARRAY['super_admin'::text, 'admin'::text, 'moderator'::text])`
- WITH CHECK: `private.is_staff(ARRAY['super_admin'::text, 'admin'::text, 'moderator'::text])`

## `public.notification_preferences` — `notif_prefs_manage_own`

- Command: `ALL`
- Mode: `PERMISSIVE`
- Roles: `{authenticated}`
- USING: `(user_id = ( SELECT auth.uid() AS uid))`
- WITH CHECK: `(user_id = ( SELECT auth.uid() AS uid))`

## `public.notifications` — `notifications_read_self`

- Command: `SELECT`
- Mode: `PERMISSIVE`
- Roles: `{authenticated}`
- USING: `(recipient_id = ( SELECT auth.uid() AS uid))`
- WITH CHECK: —

## `public.notifications` — `notifications_respect_in_app_preference`

- Command: `SELECT`
- Mode: `RESTRICTIVE`
- Roles: `{authenticated}`
- USING: `(NOT (EXISTS ( SELECT 1    FROM notification_preferences np   WHERE ((np.user_id = ( SELECT auth.uid() AS uid)) AND (np.category = notifications.notification_type) AND (np.in_app = false)))))`
- WITH CHECK: —

## `public.notifications` — `notifications_update_self`

- Command: `UPDATE`
- Mode: `PERMISSIVE`
- Roles: `{authenticated}`
- USING: `(recipient_id = ( SELECT auth.uid() AS uid))`
- WITH CHECK: `(recipient_id = ( SELECT auth.uid() AS uid))`

## `public.post_hashtags` — `post_hashtags_delete`

- Command: `DELETE`
- Mode: `PERMISSIVE`
- Roles: `{authenticated}`
- USING: `(EXISTS ( SELECT 1    FROM posts p   WHERE ((p.id = post_hashtags.post_id) AND (p.user_id = ( SELECT auth.uid() AS uid)))))`
- WITH CHECK: —

## `public.post_hashtags` — `post_hashtags_insert`

- Command: `INSERT`
- Mode: `PERMISSIVE`
- Roles: `{authenticated}`
- USING: —
- WITH CHECK: `(EXISTS ( SELECT 1    FROM posts p   WHERE ((p.id = post_hashtags.post_id) AND (p.user_id = ( SELECT auth.uid() AS uid)))))`

## `public.post_hashtags` — `post_hashtags_read`

- Command: `SELECT`
- Mode: `PERMISSIVE`
- Roles: `{authenticated}`
- USING: `(EXISTS ( SELECT 1    FROM posts p   WHERE (p.id = post_hashtags.post_id)))`
- WITH CHECK: —

## `public.posts` — `Create own posts`

- Command: `INSERT`
- Mode: `PERMISSIVE`
- Roles: `{authenticated}`
- USING: —
- WITH CHECK: `(( SELECT auth.uid() AS uid) = user_id)`

## `public.posts` — `Delete own posts`

- Command: `DELETE`
- Mode: `PERMISSIVE`
- Roles: `{authenticated}`
- USING: `(( SELECT auth.uid() AS uid) = user_id)`
- WITH CHECK: —

## `public.posts` — `Update own posts`

- Command: `UPDATE`
- Mode: `PERMISSIVE`
- Roles: `{authenticated}`
- USING: `(( SELECT auth.uid() AS uid) = user_id)`
- WITH CHECK: `(( SELECT auth.uid() AS uid) = user_id)`

## `public.posts` — `posts_read_visible`

- Command: `SELECT`
- Mode: `PERMISSIVE`
- Roles: `{authenticated}`
- USING: `((user_id = ( SELECT auth.uid() AS uid)) OR ((deleted_at IS NULL) AND (visibility <> 'private'::text) AND (NOT private.is_blocked_between(( SELECT auth.uid() AS uid), user_id)) AND (((visibility = 'friends'::text) AND (EXISTS ( SELECT 1    FROM friendships fr   WHERE ((fr.status = 'accepted'::text) AND (((fr.requester_id = ( SELECT auth.uid() AS uid)) AND (fr.addressee_id = posts.user_id)) OR ((fr.addressee_id = ( SELECT auth.uid() AS uid)) AND (fr.requester_id = posts.user_id))))))) OR ((visibility = ANY (ARRAY['public'::text, 'followers'::text])) AND (EXISTS ( SELECT 1    FROM profiles pr   WHERE ((pr.id = posts.user_id) AND ((pr.is_private = false) OR (EXISTS ( SELECT 1            FROM follows f           WHERE ((f.follower_id = ( SELECT auth.uid() AS uid)) AND (f.following_id = posts.user_id) AND (f.status = 'accepted'::text)))))))) AND ((visibility = 'public'::text) OR (EXISTS ( SELECT 1    FROM follows f   WHERE ((f.follower_id = ( SELECT auth.uid() AS uid)) AND (f.following_id = posts.user_id) AND (f.status = 'accepted'::text)))))))))`
- WITH CHECK: —

## `public.profiles` — `Profiles visible according to privacy`

- Command: `SELECT`
- Mode: `PERMISSIVE`
- Roles: `{authenticated}`
- USING: `((id = ( SELECT auth.uid() AS uid)) OR ((NOT private.is_blocked_between(( SELECT auth.uid() AS uid), id)) AND ((is_private = false) OR (EXISTS ( SELECT 1    FROM follows f   WHERE ((f.follower_id = ( SELECT auth.uid() AS uid)) AND (f.following_id = profiles.id) AND (f.status = 'accepted'::text)))) OR (EXISTS ( SELECT 1    FROM conversation_members cm   WHERE ((cm.user_id = profiles.id) AND private.is_conversation_member(cm.conversation_id)))) OR (EXISTS ( SELECT 1    FROM friendships fr   WHERE ((fr.status = 'accepted'::text) AND (((fr.requester_id = profiles.id) AND (fr.addressee_id = ( SELECT auth.uid() AS uid))) OR ((fr.addressee_id = profiles.id) AND (fr.requester_id = ( SELECT auth.uid() AS uid))))))))))`
- WITH CHECK: —

## `public.profiles` — `Users create own profile`

- Command: `INSERT`
- Mode: `PERMISSIVE`
- Roles: `{authenticated}`
- USING: —
- WITH CHECK: `(( SELECT auth.uid() AS uid) = id)`

## `public.profiles` — `Users update own profile`

- Command: `UPDATE`
- Mode: `PERMISSIVE`
- Roles: `{authenticated}`
- USING: `(( SELECT auth.uid() AS uid) = id)`
- WITH CHECK: `(( SELECT auth.uid() AS uid) = id)`

## `public.reports` — `reports_create_self`

- Command: `INSERT`
- Mode: `PERMISSIVE`
- Roles: `{authenticated}`
- USING: —
- WITH CHECK: `(reporter_id = ( SELECT auth.uid() AS uid))`

## `public.reports` — `reports_read_authorized`

- Command: `SELECT`
- Mode: `PERMISSIVE`
- Roles: `{authenticated}`
- USING: `((reporter_id = ( SELECT auth.uid() AS uid)) OR private.is_staff(ARRAY['super_admin'::text, 'admin'::text, 'moderator'::text, 'support'::text]))`
- WITH CHECK: —

## `public.reports` — `reports_update_staff`

- Command: `UPDATE`
- Mode: `PERMISSIVE`
- Roles: `{authenticated}`
- USING: `private.is_staff(ARRAY['super_admin'::text, 'admin'::text, 'moderator'::text])`
- WITH CHECK: `private.is_staff(ARRAY['super_admin'::text, 'admin'::text, 'moderator'::text])`

## `public.reposts` — `reposts_delete`

- Command: `DELETE`
- Mode: `PERMISSIVE`
- Roles: `{authenticated}`
- USING: `(user_id = ( SELECT auth.uid() AS uid))`
- WITH CHECK: —

## `public.reposts` — `reposts_insert`

- Command: `INSERT`
- Mode: `PERMISSIVE`
- Roles: `{authenticated}`
- USING: —
- WITH CHECK: `((user_id = ( SELECT auth.uid() AS uid)) AND (EXISTS ( SELECT 1    FROM posts p   WHERE ((p.id = reposts.post_id) AND (p.visibility = 'public'::text)))))`

## `public.reposts` — `reposts_read`

- Command: `SELECT`
- Mode: `PERMISSIVE`
- Roles: `{authenticated}`
- USING: `((EXISTS ( SELECT 1    FROM posts p   WHERE (p.id = reposts.post_id))) AND (NOT private.is_blocked_between(( SELECT auth.uid() AS uid), user_id)))`
- WITH CHECK: —

## `public.saves` — `saves_delete_own`

- Command: `DELETE`
- Mode: `PERMISSIVE`
- Roles: `{authenticated}`
- USING: `(user_id = ( SELECT auth.uid() AS uid))`
- WITH CHECK: —

## `public.saves` — `saves_insert_own`

- Command: `INSERT`
- Mode: `PERMISSIVE`
- Roles: `{authenticated}`
- USING: —
- WITH CHECK: `((user_id = ( SELECT auth.uid() AS uid)) AND (EXISTS ( SELECT 1    FROM posts p   WHERE (p.id = saves.post_id))))`

## `public.saves` — `saves_select_own`

- Command: `SELECT`
- Mode: `PERMISSIVE`
- Roles: `{authenticated}`
- USING: `(user_id = ( SELECT auth.uid() AS uid))`
- WITH CHECK: —

## `public.staff_members` — `staff_members_read_self`

- Command: `SELECT`
- Mode: `PERMISSIVE`
- Roles: `{authenticated}`
- USING: `(user_id = ( SELECT auth.uid() AS uid))`
- WITH CHECK: —

## `public.stories` — `stories_delete_self`

- Command: `DELETE`
- Mode: `PERMISSIVE`
- Roles: `{authenticated}`
- USING: `(user_id = ( SELECT auth.uid() AS uid))`
- WITH CHECK: —

## `public.stories` — `stories_insert_self`

- Command: `INSERT`
- Mode: `PERMISSIVE`
- Roles: `{authenticated}`
- USING: —
- WITH CHECK: `((user_id = ( SELECT auth.uid() AS uid)) AND ((media_path IS NULL) OR (((storage.foldername(media_path))[1] = (( SELECT auth.uid() AS uid))::text) AND (EXISTS ( SELECT 1    FROM storage.objects o   WHERE ((o.bucket_id = 'nexora-media'::text) AND (o.name = stories.media_path)))))))`

## `public.stories` — `stories_read_visible`

- Command: `SELECT`
- Mode: `PERMISSIVE`
- Roles: `{authenticated}`
- USING: `private.can_view_story(id)`
- WITH CHECK: —

## `public.stories` — `stories_update_self`

- Command: `UPDATE`
- Mode: `PERMISSIVE`
- Roles: `{authenticated}`
- USING: `(user_id = ( SELECT auth.uid() AS uid))`
- WITH CHECK: `(user_id = ( SELECT auth.uid() AS uid))`

## `public.story_views` — `story_views_insert_viewer`

- Command: `INSERT`
- Mode: `PERMISSIVE`
- Roles: `{authenticated}`
- USING: —
- WITH CHECK: `((viewer_id = ( SELECT auth.uid() AS uid)) AND private.can_view_story(story_id))`

## `public.story_views` — `story_views_read_owner`

- Command: `SELECT`
- Mode: `PERMISSIVE`
- Roles: `{authenticated}`
- USING: `(EXISTS ( SELECT 1    FROM stories s   WHERE ((s.id = story_views.story_id) AND (s.user_id = ( SELECT auth.uid() AS uid)))))`
- WITH CHECK: —

## `public.user_devices` — `user_devices_delete_own`

- Command: `DELETE`
- Mode: `PERMISSIVE`
- Roles: `{authenticated}`
- USING: `(user_id = ( SELECT auth.uid() AS uid))`
- WITH CHECK: —

## `public.user_devices` — `user_devices_insert_own`

- Command: `INSERT`
- Mode: `PERMISSIVE`
- Roles: `{authenticated}`
- USING: —
- WITH CHECK: `(user_id = ( SELECT auth.uid() AS uid))`

## `public.user_devices` — `user_devices_select_own`

- Command: `SELECT`
- Mode: `PERMISSIVE`
- Roles: `{authenticated}`
- USING: `(user_id = ( SELECT auth.uid() AS uid))`
- WITH CHECK: —

## `public.user_devices` — `user_devices_update_own`

- Command: `UPDATE`
- Mode: `PERMISSIVE`
- Roles: `{authenticated}`
- USING: `(user_id = ( SELECT auth.uid() AS uid))`
- WITH CHECK: `(user_id = ( SELECT auth.uid() AS uid))`

## `public.user_preferences` — `user_preferences_manage_self`

- Command: `ALL`
- Mode: `PERMISSIVE`
- Roles: `{authenticated}`
- USING: `(user_id = ( SELECT auth.uid() AS uid))`
- WITH CHECK: `(user_id = ( SELECT auth.uid() AS uid))`

## `public.user_private_settings` — `user_private_settings_insert_self`

- Command: `INSERT`
- Mode: `PERMISSIVE`
- Roles: `{authenticated}`
- USING: —
- WITH CHECK: `(user_id = ( SELECT auth.uid() AS uid))`

## `public.user_private_settings` — `user_private_settings_read_self`

- Command: `SELECT`
- Mode: `PERMISSIVE`
- Roles: `{authenticated}`
- USING: `(user_id = ( SELECT auth.uid() AS uid))`
- WITH CHECK: —

## `public.user_private_settings` — `user_private_settings_update_self`

- Command: `UPDATE`
- Mode: `PERMISSIVE`
- Roles: `{authenticated}`
- USING: `(user_id = ( SELECT auth.uid() AS uid))`
- WITH CHECK: `(user_id = ( SELECT auth.uid() AS uid))`

## Review limitations

- A policy definition is not proof that it is correct. Policies combine with SQL grants, column-level privileges, function grants, SECURITY DEFINER behavior, and PostgREST schema exposure.
- RLS is enabled but not forced on all 39 ordinary tables. Owner/BYPASSRLS behavior is a separate trust boundary.
- No authenticated/anonymous integration tests were executed by generating this inventory.
