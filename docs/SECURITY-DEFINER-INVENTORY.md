# NEXORA — Live SECURITY DEFINER Function Inventory

> Read-only PostgreSQL catalog snapshot captured 2026-11-06. This lists SECURITY DEFINER functions in `public` and `private`; it does not replace a manual review of every function body.

- Functions: 32
- Public schema: 2
- Private schema: 30

| Schema | Function | Identity arguments | Returns | Owner | Function settings | anon EXECUTE | authenticated EXECUTE | PUBLIC EXECUTE |
|---|---|---|---|---|---|---:|---:|---:|
| `private` | `accept_community_invite_internal` | `p_invite_code uuid` | `TABLE(community_id uuid, community_name text)` | `postgres` | `search_path=pg_catalog, public, private, auth` | false | true | false |
| `private` | `accept_friend_request_impl` | `p_request_id uuid` | `boolean` | `postgres` | `search_path=""` | false | true | false |
| `private` | `audit_moderation_action` | `` | `trigger` | `postgres` | `search_path=""` | false | false | false |
| `private` | `audit_report_update` | `` | `trigger` | `postgres` | `search_path=""` | false | false | false |
| `private` | `can_read_media_path` | `p_path text` | `boolean` | `postgres` | `search_path=""` | false | true | false |
| `private` | `can_view_story` | `p_story_id uuid` | `boolean` | `postgres` | `search_path=""` | false | true | false |
| `private` | `cancel_follow_impl` | `p_target_user_id uuid` | `boolean` | `postgres` | `search_path=""` | false | true | false |
| `private` | `cancel_friend_request_impl` | `p_request_id uuid` | `boolean` | `postgres` | `search_path=""` | false | true | false |
| `private` | `create_community_invite_internal` | `p_community_id uuid, p_expires_in_hours integer, p_max_uses integer` | `TABLE(invite_code uuid, expires_at timestamp with time zone)` | `postgres` | `search_path=pg_catalog, public, private, auth` | false | true | false |
| `private` | `create_direct_conversation_impl` | `p_other_user_id uuid` | `uuid` | `postgres` | `search_path=""` | false | true | false |
| `private` | `decline_friend_request_impl` | `p_request_id uuid` | `boolean` | `postgres` | `search_path=""` | false | true | false |
| `private` | `enforce_follow_request_status` | `` | `trigger` | `postgres` | `search_path=""` | false | false | false |
| `private` | `find_nearby_people` | `p_limit integer` | `TABLE(id uuid, username text, display_name text, is_verified boolean, distance_band text)` | `postgres` | `search_path=pg_catalog, public, private` | false | true | false |
| `private` | `is_blocked_between` | `a uuid, b uuid` | `boolean` | `postgres` | `search_path=""` | false | true | false |
| `private` | `is_community_member` | `p_community_id uuid` | `boolean` | `postgres` | `search_path=""` | false | true | false |
| `private` | `is_community_owner` | `p_community_id uuid` | `boolean` | `postgres` | `search_path=""` | false | true | false |
| `private` | `is_conversation_creator` | `p_conversation_id uuid` | `boolean` | `postgres` | `search_path=""` | false | true | false |
| `private` | `is_conversation_member` | `p_conversation_id uuid` | `boolean` | `postgres` | `search_path=""` | false | true | false |
| `private` | `is_staff` | `allowed text[]` | `boolean` | `postgres` | `search_path=""` | false | true | false |
| `private` | `my_nearby_presence_enabled` | `` | `boolean` | `postgres` | `search_path=pg_catalog, public, private` | false | true | false |
| `private` | `notify_nexora_push` | `` | `trigger` | `postgres` | `search_path=""` | false | false | false |
| `private` | `on_friendship_change` | `` | `trigger` | `postgres` | `search_path=""` | false | false | false |
| `private` | `on_message_insert` | `` | `trigger` | `postgres` | `search_path=""` | false | false | false |
| `private` | `remove_friend_impl` | `p_other_user_id uuid` | `boolean` | `postgres` | `search_path=""` | false | true | false |
| `private` | `request_follow_impl` | `p_target_user_id uuid` | `text` | `postgres` | `search_path=""` | false | true | false |
| `private` | `request_friend_impl` | `p_addressee_id uuid` | `text` | `postgres` | `search_path=""` | false | true | false |
| `private` | `revoke_community_invites_internal` | `p_community_id uuid` | `integer` | `postgres` | `search_path=pg_catalog, public, private, auth` | false | true | false |
| `private` | `sync_community_channel_members` | `` | `trigger` | `postgres` | `search_path=pg_catalog, public, private` | false | false | false |
| `private` | `update_my_nearby_presence` | `p_latitude double precision, p_longitude double precision, p_enabled boolean` | `void` | `postgres` | `search_path=pg_catalog, public, private` | false | true | false |
| `private` | `update_privacy_settings_impl` | `p_is_private boolean, p_allow_messages_from text, p_allow_friend_requests boolean` | `void` | `postgres` | `search_path=""` | false | true | false |
| `public` | `handle_new_user` | `` | `trigger` | `postgres` | `search_path=""` | false | false | false |
| `public` | `rls_auto_enable` | `` | `event_trigger` | `postgres` | `search_path=pg_catalog` | false | false | false |

## Review notes

- The inspected functions are owned by `postgres`. Empty `search_path` is used by most private helpers; functions with explicit search paths require body-level qualification and reference review.
- A `SECURITY DEFINER` function must be reviewed for caller authorization (`auth.uid()`), safe object references, search-path control, execution grants, and data returned.
- This inventory is not a blanket approval. Do not revoke grants or alter functions without tracing all RLS policies, triggers, and RPC call sites that depend on them.
- No function, owner, grant, or schema privilege was changed to produce this report.
