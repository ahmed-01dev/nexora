# NEXORA Database ERD

The diagram shows the current core and newly added foundation tables. It is not a claim that every related client workflow is complete.

```mermaid
erDiagram
  profiles ||--o{ posts : creates
  profiles ||--o{ follows : follows
  profiles ||--o{ friendships : requests
  profiles ||--o{ blocks : blocks
  profiles ||--o{ conversations : creates
  conversations ||--o{ conversation_members : contains
  conversations ||--o{ messages : contains
  profiles ||--o{ messages : sends
  messages ||--o{ message_attachments : has
  messages ||--o{ message_reactions : receives
  profiles ||--o{ notifications : receives
  profiles ||--o{ stories : publishes
  stories ||--o{ story_views : viewed_by
  profiles ||--o{ communities : owns
  communities ||--o{ community_members : has
  profiles ||--o{ reports : files
  conversations ||--o{ call_sessions : starts
  call_sessions ||--o{ call_participants : includes
  profiles ||--o{ user_private_settings : configures
  profiles ||--o{ user_preferences : chooses
  posts ||--o{ comments : has
  posts ||--o{ likes : receives
  posts ||--o{ media : contains
  posts ||--o{ saves : saved_by
```

## Table groups

- Identity and preferences: `profiles`, `user_private_settings`, `user_preferences`.
- Social graph: `follows`, `friendships`, `blocks`.
- Publishing and discovery: `posts`, `media`, `likes`, `reposts`, `saves`, `comments`, `comment_likes`, `hashtags`, `post_hashtags`, `collections`, `collection_items`, `stories`, `story_views`.
- Messaging: `conversations`, `conversation_members`, `messages`, `message_attachments`, `message_reactions`.
- Communities: `communities`, `community_members`, `community_channels`, `community_invites`.
- Safety and moderation: `reports`, `moderation_actions`, `moderation_appeals`, `staff_members`, `audit_logs`.
- Realtime call foundation: `call_sessions`, `call_participants`.
- Notifications and devices: `notifications`, `notification_preferences`, `user_devices`.
- Private discovery storage: `private.profile_discovery_locations`.

## Security model
All newly added public tables have RLS enabled. Anonymous SELECT is revoked. User-scoped data is filtered by auth.uid() or a narrowly scoped membership helper. Column-level update grants are used on sensitive membership, conversation, message, notification, and call fields.


## Completeness and provenance warning

This ERD is a **partial conceptual diagram**, not a generated inventory of the deployed database. It does not prove that every table, column, foreign key, index, policy, grant, or migration mapping is represented. Do not use it alone to write migrations or infer exact client payloads.

The live inventory and table groups below now name these supporting areas, but the Mermaid relationship diagram remains conceptual and does not draw every FK or operational relationship. In particular, the diagram does not yet show all relationships for reposts, hashtags, collections, user-device registration, moderation actions/appeals, nearby-location storage, notification preferences, community invites, or audit records.

This is an ERD completeness limitation, not evidence that those live objects are absent.

## Live table inventory snapshot — 2026-11-06

Read-only catalog queries returned **38 ordinary tables in `public` and one ordinary table in `private`**; a separate `pg_class` check returned no views or materialized views in those schemas. All 39 ordinary tables were previously verified to have RLS enabled.

### Public tables (38)

- `audit_logs`
- `blocks`
- `call_participants`
- `call_sessions`
- `collection_items`
- `collections`
- `comment_likes`
- `comments`
- `communities`
- `community_channels`
- `community_invites`
- `community_members`
- `conversation_members`
- `conversations`
- `follows`
- `friendships`
- `hashtags`
- `likes`
- `media`
- `message_attachments`
- `message_reactions`
- `messages`
- `moderation_actions`
- `moderation_appeals`
- `notification_preferences`
- `notifications`
- `post_hashtags`
- `posts`
- `profiles`
- `reports`
- `reposts`
- `saves`
- `staff_members`
- `stories`
- `story_views`
- `user_devices`
- `user_preferences`
- `user_private_settings`

### Private tables (1)

- `profile_discovery_locations`

## Verified foreign-key relationships — 2026-11-06

The following **57 foreign-key constraints** were read directly from `pg_constraint`. Column order is preserved for composite keys. These are live catalog relationships, not inferred from application code.

| Source | Constraint | References |
|---|---|---|
| `private.profile_discovery_locations.user_id` | `profile_discovery_locations_user_id_fkey` | `public.profiles.id` |
| `public.blocks.blocked_id` | `blocks_blocked_id_fkey` | `public.profiles.id` |
| `public.blocks.blocker_id` | `blocks_blocker_id_fkey` | `public.profiles.id` |
| `public.call_participants.call_id` | `call_participants_call_id_fkey` | `public.call_sessions.id` |
| `public.call_participants.user_id` | `call_participants_user_id_fkey` | `public.profiles.id` |
| `public.call_sessions.conversation_id` | `call_sessions_conversation_id_fkey` | `public.conversations.id` |
| `public.call_sessions.initiated_by` | `call_sessions_initiated_by_fkey` | `public.profiles.id` |
| `public.collection_items.collection_id` | `collection_items_collection_id_fkey` | `public.collections.id` |
| `public.collection_items.post_id` | `collection_items_post_id_fkey` | `public.posts.id` |
| `public.collections.user_id` | `collections_user_id_fkey` | `public.profiles.id` |
| `public.comment_likes.comment_id` | `comment_likes_comment_id_fkey` | `public.comments.id` |
| `public.comment_likes.user_id` | `comment_likes_user_id_fkey` | `public.profiles.id` |
| `public.comments.parent_id` | `comments_parent_id_fkey` | `public.comments.id` |
| `public.comments.post_id` | `comments_post_id_fkey` | `public.posts.id` |
| `public.comments.user_id` | `comments_user_id_fkey` | `public.profiles.id` |
| `public.communities.owner_id` | `communities_owner_id_fkey` | `public.profiles.id` |
| `public.community_channels.community_id` | `community_channels_community_id_fkey` | `public.communities.id` |
| `public.community_channels.conversation_id` | `community_channels_conversation_id_fkey` | `public.conversations.id` |
| `public.community_invites.community_id` | `community_invites_community_id_fkey` | `public.communities.id` |
| `public.community_invites.created_by` | `community_invites_created_by_fkey` | `public.profiles.id` |
| `public.community_members.community_id` | `community_members_community_id_fkey` | `public.communities.id` |
| `public.community_members.user_id` | `community_members_user_id_fkey` | `public.profiles.id` |
| `public.conversation_members.conversation_id` | `conversation_members_conversation_id_fkey` | `public.conversations.id` |
| `public.conversation_members.user_id` | `conversation_members_user_id_fkey` | `public.profiles.id` |
| `public.conversations.created_by` | `conversations_created_by_fkey` | `public.profiles.id` |
| `public.follows.follower_id` | `follows_follower_id_fkey` | `public.profiles.id` |
| `public.follows.following_id` | `follows_following_id_fkey` | `public.profiles.id` |
| `public.friendships.addressee_id` | `friendships_addressee_id_fkey` | `public.profiles.id` |
| `public.friendships.requester_id` | `friendships_requester_id_fkey` | `public.profiles.id` |
| `public.likes.post_id` | `likes_post_id_fkey` | `public.posts.id` |
| `public.likes.user_id` | `likes_user_id_fkey` | `public.profiles.id` |
| `public.media.post_id` | `media_post_id_fkey` | `public.posts.id` |
| `public.media.user_id` | `media_user_id_fkey` | `public.profiles.id` |
| `public.message_attachments.message_id` | `message_attachments_message_id_fkey` | `public.messages.id` |
| `public.message_attachments.uploader_id` | `message_attachments_uploader_id_fkey` | `public.profiles.id` |
| `public.message_reactions.message_id` | `message_reactions_message_id_fkey` | `public.messages.id` |
| `public.message_reactions.user_id` | `message_reactions_user_id_fkey` | `public.profiles.id` |
| `public.messages.conversation_id` | `messages_conversation_id_fkey` | `public.conversations.id` |
| `public.messages.reply_to` | `messages_reply_to_fkey` | `public.messages.id` |
| `public.messages.sender_id` | `messages_sender_id_fkey` | `public.profiles.id` |
| `public.moderation_actions.report_id` | `moderation_actions_report_id_fkey` | `public.reports.id` |
| `public.moderation_appeals.action_id` | `moderation_appeals_action_id_fkey` | `public.moderation_actions.id` |
| `public.notifications.actor_id` | `notifications_actor_id_fkey` | `public.profiles.id` |
| `public.notifications.recipient_id` | `notifications_recipient_id_fkey` | `public.profiles.id` |
| `public.post_hashtags.hashtag_id` | `post_hashtags_hashtag_id_fkey` | `public.hashtags.id` |
| `public.post_hashtags.post_id` | `post_hashtags_post_id_fkey` | `public.posts.id` |
| `public.posts.user_id` | `posts_user_id_fkey` | `public.profiles.id` |
| `public.reports.reporter_id` | `reports_reporter_id_fkey` | `public.profiles.id` |
| `public.reposts.post_id` | `reposts_post_id_fkey` | `public.posts.id` |
| `public.reposts.user_id` | `reposts_user_id_fkey` | `public.profiles.id` |
| `public.saves.post_id` | `saves_post_id_fkey` | `public.posts.id` |
| `public.saves.user_id` | `saves_user_id_fkey` | `public.profiles.id` |
| `public.stories.user_id` | `stories_user_id_fkey` | `public.profiles.id` |
| `public.story_views.story_id` | `story_views_story_id_fkey` | `public.stories.id` |
| `public.story_views.viewer_id` | `story_views_viewer_id_fkey` | `public.profiles.id` |
| `public.user_preferences.user_id` | `user_preferences_user_id_fkey` | `public.profiles.id` |
| `public.user_private_settings.user_id` | `user_private_settings_user_id_fkey` | `public.profiles.id` |

### Remaining ERD evidence gaps

This inventory records object names and types only. It does not replace the detailed per-object inventory of:

| Field | Required evidence |
|---|---|
| Columns and constraints | Live catalog definition, including nullability and defaults |
| Foreign keys and indexes | Live catalog definitions |
| RLS enabled/forced | Live table flags |
| Policies | Exact policy expressions and command scope |
| Grants | Role and operation/column-level privileges |
| Migration provenance | Exact remote migration version mapped to local SQL source |
| Client usage | Dart source file and call-site reference |
| Feature owner/status | Matching entry in IMPLEMENTATION_STATUS.md |
| Test evidence | Reproducible test identifier and result |

### Catalog-level structural and RLS snapshot

The same read-only catalog pass recorded:

| Metric | Live result |
|---|---:|
| Public columns | 250 |
| Private columns | 4 |
| Total columns | 254 |
| NOT NULL columns | 193 |
| Columns with defaults | 114 |
| Primary-key constraints | 39 |
| Foreign-key constraints | 67 |
| Unique constraints | 9 |
| Check constraints | 51 |
| Indexes | 106 |
| RLS-enabled ordinary tables | 39 / 39 |
| RLS-forced ordinary tables | 0 / 39 |
| Public policies | 111 |
| Private policies | 1 |

All 38 public tables and the one private table have RLS enabled. None has FORCE ROW LEVEL SECURITY. This is an important distinction: table owners and roles with BYPASSRLS can bypass ordinary RLS, so policy presence alone does not establish end-to-end access safety. The policy counts above are catalog counts, not a correctness verdict; every policy expression, grant, SECURITY DEFINER path, and actual authenticated/anonymous behavior still requires review.

The 67 foreign keys and 106 indexes are structural counts only. Their names, referenced columns, delete/update actions, partial predicates, and query-plan suitability are not exhaustively documented in this ERD snapshot. No index was added or removed.

### Migration safety

The implementation audit records a mismatch between remote migration history and local migration files. Until every remote version is mapped to exact source SQL and a recoverable backup is verified, do not run `supabase db push`, reset, replay, or any schema-changing operation. This ERD update does not authorize database changes.
