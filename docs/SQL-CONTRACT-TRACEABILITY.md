# NEXORA SQL Contract Traceability

**Audit date:** 2026-11-06  
**SQL source snapshot:** `main` branch.  
**Method:** static inspection of selected local migration files only. No database connection or mutation was performed.

> These findings describe local SQL source. They do not prove that every migration is applied remotely or that the deployed definitions are identical.

## 1. Feed paging contract

**Source:** `supabase/migrations/20261105184622_add_server_side_feed_page_rpc.sql`

- Public RPC: `public.get_feed_page(p_mode text default 'latest', p_limit integer default 20, p_offset integer default 0)`.
- Returns: `id uuid, user_id uuid, content text, visibility text, created_at timestamptz, profiles jsonb`.
- Uses `SECURITY INVOKER`, preserving table RLS for the underlying reads.
- Accepts only `latest` and `following`; invalid mode raises SQLSTATE `22023`.
- Limit is clamped to 1–50; offset to 0–100000.
- Latest mode returns public, non-deleted posts. Following mode includes self, accepted follows and accepted friendships.
- PUBLIC/anon execute is revoked; authenticated execute is granted.

**Client:** `lib/main.dart` invokes `get_feed_page` (around line 718). Static source inspection confirms the client/server contract name, but does not prove remote function parity or feed behavior under real RLS identities.

## 2. Nearby discovery contract and privacy boundary

**Sources:**
- `supabase/migrations/20261105220000_nearby_opt_in_approximate_discovery.sql`
- `supabase/migrations/20261105221000_nearby_presence_status_and_expiry.sql`
- `supabase/migrations/20261105222000_harden_nearby_discovery_function_boundary.sql`

Final public RPC wrappers documented in the hardening migration:

| RPC | Parameters | Result |
|---|---|---|
| `update_my_nearby_presence` | `p_latitude double precision, p_longitude double precision, p_enabled boolean` | void |
| `find_nearby_people` | `p_limit integer default 30` | `id, username, display_name, is_verified, distance_band` |
| `my_nearby_presence_enabled` | none | boolean |

Observed safeguards in local SQL:

- Coordinates are rounded to two decimal places before persistence in the private discovery table.
- Private location table privileges are revoked from PUBLIC, anon and authenticated direct access.
- Discovery output returns coarse distance bands, not coordinates.
- Results are limited to 25 km and a maximum of 50 rows.
- Stale presence older than 24 hours is ignored/cleaned by the location functions.
- Private profiles and mutually blocked users are excluded.
- Privileged logic is moved into the non-exposed `private` schema; public wrappers are `SECURITY INVOKER` and authenticated-only execute is granted.

**Client:** `lib/features/nearby/nearby_discovery_screen.dart` invokes these RPCs. The client sends coordinates to the opt-in update RPC; the result contract does not return them. This is a promising privacy boundary in local source, but must still be verified against the deployed function definitions and actual device permission lifecycle.

## 3. Community invite contract

**Source:** `supabase/migrations/20261105210000_community_invites.sql`

- Direct table access to `public.community_invites` is revoked from PUBLIC, anon and authenticated; an explicit deny policy is installed.
- Owner-only invite creation is performed by a private SECURITY DEFINER implementation.
- Expiry is constrained to 1–720 hours; maximum uses to 1–500.
- Acceptance locks the invite row, rejects revoked/expired/exhausted codes, and increments use count only when a new membership row is inserted.
- Public invoker wrappers are `create_community_invite`, `accept_community_invite`, and `revoke_community_invites`; execute is granted to authenticated.
- The implementation uses a private helper and owner check; callers cannot directly update invite counters or metadata through table grants.

**Client:** `lib/features/communities/communities_screen.dart` calls the invite operations. Runtime concurrency and membership/RLS behavior still need integration tests.

## 4. Push notification dispatch chain

**Sources:**
- `supabase/migrations/20261105233000_nexora_fcm_push_delivery_webhook.sql`
- `supabase/functions/send-push-notification/index.ts`
- `lib/features/notifications/nexora_push_service.dart`

Local source chain:

1. An AFTER INSERT trigger on `public.notifications` invokes private trigger function `private.notify_nexora_push()`.
2. The trigger reads `nexora_push_webhook_secret` from Vault and returns without dispatch if it is missing.
3. It sends an HTTP POST to the project's `send-push-notification` Edge Function with the notification ID and webhook-secret header.
4. The Edge Function reads Supabase URL, service-role, anon and Firebase service-account secrets at runtime.
5. It validates a webhook-secret path or a bearer-authenticated user path, then checks notification/push preferences and registered Android devices before sending via FCM HTTP v1.
6. The Flutter client registers Firebase Messaging installations and upserts/removes rows in `user_devices`.

**Operational gates:** verify the Vault secret and Edge Function secret match, confirm deployed URL/project alignment, validate FCM service-account scope, exercise both webhook and user authorization paths, test disabled preferences, and confirm real-device receipt. Source presence is not proof of successful delivery. Never place any of these secrets in Flutter or GitHub source.

## 5. Migration inventory count

A fresh read-only listing of `supabase/migrations` on `main` returned **42 local SQL migration files**. The prior implementation audit recorded **43 remote migration history records**. This confirms the count mismatch remains unresolved; it does not identify which remote version is missing locally.

Do not run `supabase db push`, reset, replay, repair migration history, or apply any migration until every remote version is mapped to exact SQL source and a recoverable backup is verified.

## 6. Not covered by this SQL pass

- Full inspection of every migration and every deployed object.
- Live catalog comparison of function definitions, ownership, SECURITY mode, search_path, grants, RLS and Storage policies.
- Independent authenticated tests for owner, non-owner, blocked, private and deleted-content cases.
- Confirmation that the current remote database has all 42 local migrations in the expected order.
- Any database mutation or migration repair.

This document is a focused contract trace, not a complete database security certification.

## 7. Live media authorization verification

The local migration `20261105225000_hide_deleted_message_attachments.sql` redefines `private.can_read_media_path(text)` with an older expression that omits friend-only post access, private-account story gating and soft-deleted-post denial for non-owners.

A read-only query against the connected Supabase project `nexora` (project ref `wwdeexgkwpftyavbhiff`) retrieved the **live deployed** `private.can_read_media_path(text)` definition. The live definition includes all of those predicates, plus block checks and the non-deleted-message/conversation-membership check. Therefore:

- This is a **local migration source/history drift**, not a demonstrated current live Storage vulnerability.
- The live helper is owned by `postgres`, is `SECURITY DEFINER`, uses an empty `search_path`, and its ACL lists `postgres` and `authenticated`.
- Archived/expired story filtering occurs before the owner/viewer branch, so expired or archived story media is denied to everyone, including its owner.
- No corrective migration is needed for the currently observed live function. Do not add or apply a new migration until the local source history is reconciled.

The regression matrix in `docs/SQL-SECURITY-REGRESSION-MATRIX.md` remains a test plan for future changes; it has not been executed against authenticated Storage requests.

## 8. Live block-helper verification

The live database contains `private.is_blocked_between(a uuid, b uuid)`. Read-only catalog inspection returned:

- Owner: `postgres`.
- `SECURITY DEFINER`, `STABLE`, empty `search_path`.
- ACL: `postgres` and `authenticated`.
- Definition checks `public.blocks` in both directions.

The local foundation migration's function inventory does not define this helper, despite later local policies/functions referencing it. This is another source-provenance gap, not proof that the deployed database lacks the function. Its original migration source must be recovered and mapped; do not synthesize a replacement.

## 9. Remote/local migration reconciliation snapshot

A fresh read-only Supabase migration listing returned **43 remote records**. A fresh GitHub listing of `main/supabase/migrations` returned **42 local SQL files**.

Matching by migration name and version gives:

- **21 exact version + name matches**.
- **14 same-name migrations with different version timestamps**.
- **8 remote-only migration names**.
- **7 local-only migration names**.

Remote-only names:
- `nexora_social_foundation_20261105`
- `nexora_story_visibility_hardening`
- `nexora_column_privilege_hardening`
- `nexora_media_path_ownership_hardening`
- `nexora_social_security_hardening_v2`
- `nexora_social_core_tables_v2`
- `nexora_moderation_staff_devices_v2`
- `restrict_notification_updates_to_read_at`

Local-only names:
- `nexora_social_foundation`
- `unique_reposts_per_user`
- `conversation_previews_rpc`
- `profile_media_access`
- `community_channels`
- `community_invites`
- `restrict_notification_update_columns`

The 14 same-name/different-version mappings are:

| Migration name | Remote version | Local filename version |
|---|---:|---:|
| nearby_opt_in_approximate_discovery | 20261105141247 | 20261105220000 |
| nearby_presence_status_and_expiry | 20261105141309 | 20261105221000 |
| harden_nearby_discovery_function_boundary | 20261105141659 | 20261105222000 |
| respect_in_app_notification_preferences | 20261105142226 | 20261105223000 |
| notification_preferences_paged_feed_rpc | 20261105142323 | 20261105224000 |
| hide_deleted_message_attachments | 20261105142851 | 20261105225000 |
| hide_deleted_message_attachment_metadata | 20261105142927 | 20261105225500 |
| validate_image_message_attachment_uploads | 20261105143331 | 20261105230000 |
| nexora_fcm_push_delivery_webhook | 20261105151018 | 20261105233000 |
| restrict_community_channel_grants | 20261105175432 | 20261105235000 |
| revoke_public_execute_private_helpers | 20261105175513 | 20261105235500 |
| remove_redundant_message_attachment_read_policy | 20261105180622 | 20261106001000 |
| make_message_attachment_validation_restrictive | 20261105180641 | 20261106001500 |
| enforce_case_insensitive_profile_usernames | 20261105180734 | 20261106002000 |

This is a concrete mismatch inventory, not a safe repair plan. The remote-only foundation/security migrations may contain the source for live helpers such as `private.is_blocked_between`; that is a candidate to investigate, not an established mapping. Recover those exact source files and compare their effects before deciding how to reconcile.

**Hard stop:** no `db push`, reset, replay, migration repair, or new corrective migration until the exact remote/local history and SQL content have been reconciled and a recoverable backup is verified.
