# NEXORA — Live PostgreSQL Column Inventory

> Read-only catalog snapshot from Supabase project `wwdeexgkwpftyavbhiff`, captured 2026-11-06. This file records deployed column metadata only; it is not a migration script. Do not use it to generate DDL until remote/local migration provenance is reconciled.

- Schemas inspected: `public`, `private`
- Tables: 39 (38 public, 1 private)
- Columns: 254

## `private.profile_discovery_locations`

| # | Column | PostgreSQL type | Nullable | Default |
|---:|---|---|---|---|
| 1 | `user_id` | `uuid` | NO | — |
| 2 | `latitude_approx` | `numeric` | NO | — |
| 3 | `longitude_approx` | `numeric` | NO | — |
| 4 | `updated_at` | `timestamp with time zone` | NO | `now()` |

## `public.audit_logs`

| # | Column | PostgreSQL type | Nullable | Default |
|---:|---|---|---|---|
| 1 | `id` | `bigint` | NO | — |
| 2 | `actor_id` | `uuid` | YES | — |
| 3 | `action` | `text` | NO | — |
| 4 | `entity_type` | `text` | NO | — |
| 5 | `entity_id` | `uuid` | YES | — |
| 6 | `metadata` | `jsonb` | NO | `'{}'::jsonb` |
| 7 | `created_at` | `timestamp with time zone` | NO | `now()` |

## `public.blocks`

| # | Column | PostgreSQL type | Nullable | Default |
|---:|---|---|---|---|
| 1 | `blocker_id` | `uuid` | NO | — |
| 2 | `blocked_id` | `uuid` | NO | — |
| 3 | `created_at` | `timestamp with time zone` | NO | `now()` |

## `public.call_participants`

| # | Column | PostgreSQL type | Nullable | Default |
|---:|---|---|---|---|
| 1 | `call_id` | `uuid` | NO | — |
| 2 | `user_id` | `uuid` | NO | — |
| 3 | `joined_at` | `timestamp with time zone` | YES | — |
| 4 | `left_at` | `timestamp with time zone` | YES | — |

## `public.call_sessions`

| # | Column | PostgreSQL type | Nullable | Default |
|---:|---|---|---|---|
| 1 | `id` | `uuid` | NO | `gen_random_uuid()` |
| 2 | `conversation_id` | `uuid` | NO | — |
| 3 | `initiated_by` | `uuid` | NO | — |
| 4 | `call_type` | `text` | NO | — |
| 5 | `status` | `text` | NO | `'ringing'::text` |
| 6 | `started_at` | `timestamp with time zone` | NO | `now()` |
| 7 | `ended_at` | `timestamp with time zone` | YES | — |

## `public.collection_items`

| # | Column | PostgreSQL type | Nullable | Default |
|---:|---|---|---|---|
| 1 | `collection_id` | `uuid` | NO | — |
| 2 | `post_id` | `uuid` | NO | — |
| 3 | `added_at` | `timestamp with time zone` | NO | `now()` |

## `public.collections`

| # | Column | PostgreSQL type | Nullable | Default |
|---:|---|---|---|---|
| 1 | `id` | `uuid` | NO | `gen_random_uuid()` |
| 2 | `user_id` | `uuid` | NO | — |
| 3 | `name` | `text` | NO | — |
| 4 | `created_at` | `timestamp with time zone` | NO | `now()` |
| 5 | `updated_at` | `timestamp with time zone` | NO | `now()` |

## `public.comment_likes`

| # | Column | PostgreSQL type | Nullable | Default |
|---:|---|---|---|---|
| 1 | `user_id` | `uuid` | NO | — |
| 2 | `comment_id` | `uuid` | NO | — |
| 3 | `created_at` | `timestamp with time zone` | NO | `now()` |

## `public.comments`

| # | Column | PostgreSQL type | Nullable | Default |
|---:|---|---|---|---|
| 1 | `id` | `uuid` | NO | `gen_random_uuid()` |
| 2 | `post_id` | `uuid` | NO | — |
| 3 | `user_id` | `uuid` | NO | — |
| 4 | `content` | `text` | NO | — |
| 5 | `created_at` | `timestamp with time zone` | YES | `now()` |
| 6 | `parent_id` | `uuid` | YES | — |
| 7 | `edited_at` | `timestamp with time zone` | YES | — |
| 8 | `deleted_at` | `timestamp with time zone` | YES | — |

## `public.communities`

| # | Column | PostgreSQL type | Nullable | Default |
|---:|---|---|---|---|
| 1 | `id` | `uuid` | NO | `gen_random_uuid()` |
| 2 | `owner_id` | `uuid` | NO | — |
| 3 | `name` | `text` | NO | — |
| 4 | `slug` | `text` | NO | — |
| 5 | `description` | `text` | NO | `''::text` |
| 6 | `visibility` | `text` | NO | `'public'::text` |
| 7 | `cover_path` | `text` | YES | — |
| 8 | `created_at` | `timestamp with time zone` | NO | `now()` |
| 9 | `updated_at` | `timestamp with time zone` | NO | `now()` |

## `public.community_channels`

| # | Column | PostgreSQL type | Nullable | Default |
|---:|---|---|---|---|
| 1 | `id` | `uuid` | NO | `gen_random_uuid()` |
| 2 | `community_id` | `uuid` | NO | — |
| 3 | `conversation_id` | `uuid` | NO | — |
| 4 | `name` | `text` | NO | — |
| 5 | `slug` | `text` | NO | — |
| 6 | `created_by` | `uuid` | NO | — |
| 7 | `created_at` | `timestamp with time zone` | NO | `now()` |

## `public.community_invites`

| # | Column | PostgreSQL type | Nullable | Default |
|---:|---|---|---|---|
| 1 | `id` | `uuid` | NO | `gen_random_uuid()` |
| 2 | `community_id` | `uuid` | NO | — |
| 3 | `invite_code` | `uuid` | NO | `gen_random_uuid()` |
| 4 | `created_by` | `uuid` | NO | — |
| 5 | `expires_at` | `timestamp with time zone` | NO | — |
| 6 | `max_uses` | `integer` | NO | `10` |
| 7 | `use_count` | `integer` | NO | `0` |
| 8 | `revoked_at` | `timestamp with time zone` | YES | — |
| 9 | `created_at` | `timestamp with time zone` | NO | `now()` |

## `public.community_members`

| # | Column | PostgreSQL type | Nullable | Default |
|---:|---|---|---|---|
| 1 | `community_id` | `uuid` | NO | — |
| 2 | `user_id` | `uuid` | NO | — |
| 3 | `role` | `text` | NO | `'member'::text` |
| 4 | `joined_at` | `timestamp with time zone` | NO | `now()` |

## `public.conversation_members`

| # | Column | PostgreSQL type | Nullable | Default |
|---:|---|---|---|---|
| 1 | `conversation_id` | `uuid` | NO | — |
| 2 | `user_id` | `uuid` | NO | — |
| 3 | `role` | `text` | NO | `'member'::text` |
| 4 | `joined_at` | `timestamp with time zone` | NO | `now()` |
| 5 | `last_read_at` | `timestamp with time zone` | YES | — |
| 6 | `muted_until` | `timestamp with time zone` | YES | — |
| 7 | `archived_at` | `timestamp with time zone` | YES | — |

## `public.conversations`

| # | Column | PostgreSQL type | Nullable | Default |
|---:|---|---|---|---|
| 1 | `id` | `uuid` | NO | `gen_random_uuid()` |
| 2 | `created_by` | `uuid` | NO | — |
| 3 | `conversation_type` | `text` | NO | `'direct'::text` |
| 4 | `title` | `text` | YES | — |
| 5 | `avatar_path` | `text` | YES | — |
| 6 | `created_at` | `timestamp with time zone` | NO | `now()` |
| 7 | `updated_at` | `timestamp with time zone` | NO | `now()` |
| 8 | `last_message_at` | `timestamp with time zone` | YES | — |

## `public.follows`

| # | Column | PostgreSQL type | Nullable | Default |
|---:|---|---|---|---|
| 1 | `follower_id` | `uuid` | NO | — |
| 2 | `following_id` | `uuid` | NO | — |
| 3 | `status` | `text` | NO | `'accepted'::text` |
| 4 | `created_at` | `timestamp with time zone` | YES | `now()` |

## `public.friendships`

| # | Column | PostgreSQL type | Nullable | Default |
|---:|---|---|---|---|
| 1 | `id` | `uuid` | NO | `gen_random_uuid()` |
| 2 | `requester_id` | `uuid` | NO | — |
| 3 | `addressee_id` | `uuid` | NO | — |
| 4 | `status` | `text` | NO | `'pending'::text` |
| 5 | `created_at` | `timestamp with time zone` | NO | `now()` |
| 6 | `updated_at` | `timestamp with time zone` | NO | `now()` |

## `public.hashtags`

| # | Column | PostgreSQL type | Nullable | Default |
|---:|---|---|---|---|
| 1 | `id` | `uuid` | NO | `gen_random_uuid()` |
| 2 | `tag` | `text` | NO | — |
| 3 | `created_at` | `timestamp with time zone` | NO | `now()` |

## `public.likes`

| # | Column | PostgreSQL type | Nullable | Default |
|---:|---|---|---|---|
| 1 | `user_id` | `uuid` | NO | — |
| 2 | `post_id` | `uuid` | NO | — |
| 3 | `created_at` | `timestamp with time zone` | YES | `now()` |

## `public.media`

| # | Column | PostgreSQL type | Nullable | Default |
|---:|---|---|---|---|
| 1 | `id` | `uuid` | NO | `gen_random_uuid()` |
| 2 | `post_id` | `uuid` | NO | — |
| 3 | `user_id` | `uuid` | NO | — |
| 4 | `media_type` | `text` | NO | — |
| 5 | `storage_path` | `text` | NO | — |
| 6 | `position` | `integer` | YES | `0` |
| 7 | `created_at` | `timestamp with time zone` | YES | `now()` |

## `public.message_attachments`

| # | Column | PostgreSQL type | Nullable | Default |
|---:|---|---|---|---|
| 1 | `id` | `uuid` | NO | `gen_random_uuid()` |
| 2 | `message_id` | `uuid` | NO | — |
| 3 | `uploader_id` | `uuid` | NO | — |
| 4 | `storage_path` | `text` | NO | — |
| 5 | `mime_type` | `text` | NO | — |
| 6 | `size_bytes` | `bigint` | NO | — |
| 7 | `created_at` | `timestamp with time zone` | NO | `now()` |

## `public.message_reactions`

| # | Column | PostgreSQL type | Nullable | Default |
|---:|---|---|---|---|
| 1 | `message_id` | `uuid` | NO | — |
| 2 | `user_id` | `uuid` | NO | — |
| 3 | `reaction` | `text` | NO | — |
| 4 | `created_at` | `timestamp with time zone` | NO | `now()` |

## `public.messages`

| # | Column | PostgreSQL type | Nullable | Default |
|---:|---|---|---|---|
| 1 | `id` | `uuid` | NO | `gen_random_uuid()` |
| 2 | `conversation_id` | `uuid` | NO | — |
| 3 | `sender_id` | `uuid` | NO | — |
| 4 | `message_type` | `text` | NO | `'text'::text` |
| 5 | `body` | `text` | YES | — |
| 6 | `reply_to` | `uuid` | YES | — |
| 7 | `encryption_mode` | `text` | NO | `'server_readable'::text` |
| 8 | `ciphertext` | `text` | YES | — |
| 9 | `nonce` | `text` | YES | — |
| 10 | `edited_at` | `timestamp with time zone` | YES | — |
| 11 | `deleted_at` | `timestamp with time zone` | YES | — |
| 12 | `created_at` | `timestamp with time zone` | NO | `now()` |

## `public.moderation_actions`

| # | Column | PostgreSQL type | Nullable | Default |
|---:|---|---|---|---|
| 1 | `id` | `uuid` | NO | `gen_random_uuid()` |
| 2 | `report_id` | `uuid` | YES | — |
| 3 | `moderator_id` | `uuid` | NO | — |
| 4 | `target_type` | `text` | NO | — |
| 5 | `target_id` | `uuid` | NO | — |
| 6 | `action` | `text` | NO | — |
| 7 | `reason` | `text` | NO | `''::text` |
| 8 | `expires_at` | `timestamp with time zone` | YES | — |
| 9 | `created_at` | `timestamp with time zone` | NO | `now()` |

## `public.moderation_appeals`

| # | Column | PostgreSQL type | Nullable | Default |
|---:|---|---|---|---|
| 1 | `id` | `uuid` | NO | `gen_random_uuid()` |
| 2 | `action_id` | `uuid` | NO | — |
| 3 | `user_id` | `uuid` | NO | — |
| 4 | `message` | `text` | NO | — |
| 5 | `status` | `text` | NO | `'open'::text` |
| 6 | `reviewer_id` | `uuid` | YES | — |
| 7 | `created_at` | `timestamp with time zone` | NO | `now()` |
| 8 | `resolved_at` | `timestamp with time zone` | YES | — |

## `public.notification_preferences`

| # | Column | PostgreSQL type | Nullable | Default |
|---:|---|---|---|---|
| 1 | `user_id` | `uuid` | NO | — |
| 2 | `category` | `text` | NO | — |
| 3 | `push` | `boolean` | NO | `true` |
| 4 | `in_app` | `boolean` | NO | `true` |
| 5 | `email` | `boolean` | NO | `false` |
| 6 | `updated_at` | `timestamp with time zone` | NO | `now()` |

## `public.notifications`

| # | Column | PostgreSQL type | Nullable | Default |
|---:|---|---|---|---|
| 1 | `id` | `uuid` | NO | `gen_random_uuid()` |
| 2 | `recipient_id` | `uuid` | NO | — |
| 3 | `actor_id` | `uuid` | YES | — |
| 4 | `notification_type` | `text` | NO | — |
| 5 | `entity_type` | `text` | YES | — |
| 6 | `entity_id` | `uuid` | YES | — |
| 7 | `payload` | `jsonb` | NO | `'{}'::jsonb` |
| 8 | `read_at` | `timestamp with time zone` | YES | — |
| 9 | `created_at` | `timestamp with time zone` | NO | `now()` |

## `public.post_hashtags`

| # | Column | PostgreSQL type | Nullable | Default |
|---:|---|---|---|---|
| 1 | `post_id` | `uuid` | NO | — |
| 2 | `hashtag_id` | `uuid` | NO | — |

## `public.posts`

| # | Column | PostgreSQL type | Nullable | Default |
|---:|---|---|---|---|
| 1 | `id` | `uuid` | NO | `gen_random_uuid()` |
| 2 | `user_id` | `uuid` | NO | — |
| 3 | `content` | `text` | YES | `''::text` |
| 4 | `visibility` | `text` | NO | `'public'::text` |
| 5 | `created_at` | `timestamp with time zone` | YES | `now()` |
| 6 | `updated_at` | `timestamp with time zone` | YES | `now()` |
| 7 | `deleted_at` | `timestamp with time zone` | YES | — |

## `public.profiles`

| # | Column | PostgreSQL type | Nullable | Default |
|---:|---|---|---|---|
| 1 | `id` | `uuid` | NO | — |
| 2 | `username` | `text` | YES | — |
| 3 | `display_name` | `text` | YES | — |
| 4 | `bio` | `text` | YES | `''::text` |
| 5 | `avatar_url` | `text` | YES | — |
| 6 | `cover_url` | `text` | YES | — |
| 7 | `is_verified` | `boolean` | YES | `false` |
| 8 | `is_private` | `boolean` | YES | `false` |
| 9 | `created_at` | `timestamp with time zone` | YES | `now()` |
| 10 | `account_type` | `text` | NO | `'personal'::text` |
| 11 | `website` | `text` | YES | — |
| 12 | `pronouns` | `text` | YES | — |
| 13 | `country_code` | `text` | YES | — |
| 15 | `social_links` | `jsonb` | NO | `'{}'::jsonb` |
| 16 | `updated_at` | `timestamp with time zone` | NO | `now()` |

## `public.reports`

| # | Column | PostgreSQL type | Nullable | Default |
|---:|---|---|---|---|
| 1 | `id` | `uuid` | NO | `gen_random_uuid()` |
| 2 | `reporter_id` | `uuid` | NO | — |
| 3 | `target_type` | `text` | NO | — |
| 4 | `target_id` | `uuid` | NO | — |
| 5 | `reason` | `text` | NO | — |
| 6 | `details` | `text` | NO | `''::text` |
| 7 | `status` | `text` | NO | `'open'::text` |
| 8 | `created_at` | `timestamp with time zone` | NO | `now()` |
| 9 | `resolved_at` | `timestamp with time zone` | YES | — |
| 10 | `assigned_to` | `uuid` | YES | — |
| 11 | `resolution_note` | `text` | YES | — |

## `public.reposts`

| # | Column | PostgreSQL type | Nullable | Default |
|---:|---|---|---|---|
| 1 | `id` | `uuid` | NO | `gen_random_uuid()` |
| 2 | `user_id` | `uuid` | NO | — |
| 3 | `post_id` | `uuid` | NO | — |
| 4 | `quote_text` | `text` | YES | — |
| 5 | `created_at` | `timestamp with time zone` | NO | `now()` |

## `public.saves`

| # | Column | PostgreSQL type | Nullable | Default |
|---:|---|---|---|---|
| 1 | `user_id` | `uuid` | NO | — |
| 2 | `post_id` | `uuid` | NO | — |
| 3 | `created_at` | `timestamp with time zone` | YES | `now()` |

## `public.staff_members`

| # | Column | PostgreSQL type | Nullable | Default |
|---:|---|---|---|---|
| 1 | `user_id` | `uuid` | NO | — |
| 2 | `role` | `text` | NO | — |
| 3 | `created_by` | `uuid` | YES | — |
| 4 | `created_at` | `timestamp with time zone` | NO | `now()` |

## `public.stories`

| # | Column | PostgreSQL type | Nullable | Default |
|---:|---|---|---|---|
| 1 | `id` | `uuid` | NO | `gen_random_uuid()` |
| 2 | `user_id` | `uuid` | NO | — |
| 3 | `media_path` | `text` | YES | — |
| 4 | `text_content` | `text` | YES | — |
| 5 | `story_type` | `text` | NO | `'photo'::text` |
| 6 | `visibility` | `text` | NO | `'followers'::text` |
| 7 | `created_at` | `timestamp with time zone` | NO | `now()` |
| 8 | `expires_at` | `timestamp with time zone` | NO | `(now() + '24:00:00'::interval)` |
| 9 | `archived_at` | `timestamp with time zone` | YES | — |

## `public.story_views`

| # | Column | PostgreSQL type | Nullable | Default |
|---:|---|---|---|---|
| 1 | `story_id` | `uuid` | NO | — |
| 2 | `viewer_id` | `uuid` | NO | — |
| 3 | `viewed_at` | `timestamp with time zone` | NO | `now()` |

## `public.user_devices`

| # | Column | PostgreSQL type | Nullable | Default |
|---:|---|---|---|---|
| 1 | `id` | `uuid` | NO | `gen_random_uuid()` |
| 2 | `user_id` | `uuid` | NO | — |
| 3 | `platform` | `text` | NO | — |
| 4 | `push_token` | `text` | NO | — |
| 5 | `device_label` | `text` | YES | — |
| 6 | `last_seen_at` | `timestamp with time zone` | NO | `now()` |
| 7 | `created_at` | `timestamp with time zone` | NO | `now()` |

## `public.user_preferences`

| # | Column | PostgreSQL type | Nullable | Default |
|---:|---|---|---|---|
| 1 | `user_id` | `uuid` | NO | — |
| 2 | `language_code` | `text` | NO | `'ar'::text` |
| 3 | `theme` | `text` | NO | `'amoled'::text` |
| 4 | `accent_color` | `text` | NO | `'#FFFFFF'::text` |
| 5 | `autoplay_videos` | `boolean` | NO | `true` |
| 6 | `reduce_motion` | `boolean` | NO | `false` |
| 7 | `low_data_mode` | `boolean` | NO | `false` |
| 8 | `push_notifications_enabled` | `boolean` | NO | `true` |
| 9 | `created_at` | `timestamp with time zone` | NO | `now()` |
| 10 | `updated_at` | `timestamp with time zone` | NO | `now()` |

## `public.user_private_settings`

| # | Column | PostgreSQL type | Nullable | Default |
|---:|---|---|---|---|
| 1 | `user_id` | `uuid` | NO | — |
| 2 | `date_of_birth` | `date` | YES | — |
| 3 | `profile_visibility` | `text` | NO | `'public'::text` |
| 4 | `allow_friend_requests` | `boolean` | NO | `true` |
| 5 | `allow_messages_from` | `text` | NO | `'followers'::text` |
| 6 | `allow_mentions_from` | `text` | NO | `'everyone'::text` |
| 7 | `show_online_status` | `boolean` | NO | `true` |
| 8 | `show_read_receipts` | `boolean` | NO | `true` |
| 9 | `discoverable` | `boolean` | NO | `true` |
| 10 | `location_visibility` | `text` | NO | `'invisible'::text` |
| 11 | `created_at` | `timestamp with time zone` | NO | `now()` |
| 12 | `updated_at` | `timestamp with time zone` | NO | `now()` |

## Safety and interpretation

- Snapshot is read-only and contains no row data, secrets, or credential values.
- Nullability/defaults are catalog metadata. Constraints, foreign keys, indexes, grants, RLS policies, triggers, and function behavior are tracked separately in `ERD.md` and audit documents.
- No schema writes, migration repair, migration replay, or database changes were performed to create this inventory.
