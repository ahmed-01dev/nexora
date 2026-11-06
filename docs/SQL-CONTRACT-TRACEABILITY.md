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

## 7. Newly identified media authorization regression

Static comparison of migration `20261105225000_hide_deleted_message_attachments.sql` against the prior complete definition in `20261105184333_hide_deleted_post_media_from_non_owners.sql` found that the later replacement of `private.can_read_media_path(text)` dropped three checks:

- accepted-friend access for posts with `visibility = 'friends'`;
- private-account eligibility for story media;
- `posts.deleted_at IS NULL` for non-owner access to post media.

The later helper still checks direct-block relationships for its post/story/profile branches and requires non-deleted messages plus conversation membership for message attachments, but that does not compensate for the three missing checks.

A proposed corrective migration is now present on this documentation/work branch:
`supabase/migrations/20261106003000_restore_media_visibility_invariants.sql`.

Regression cases are specified in `docs/SQL-SECURITY-REGRESSION-MATRIX.md`. The correction has been statically checked for all five required predicates: friend visibility, private-story gate, deleted-post gate, deleted-message gate and block check.

**Do not apply this migration yet.** The remote/local migration-history mismatch remains unresolved; inspect the live function definition and reconcile all versions first. The file is a proposed source correction, not evidence of a deployed fix.

### Migration-count clarification after the proposed correction

The 42-file count above is the observed `main` baseline. This branch now contains one additional proposed migration (`20261106003000_restore_media_visibility_invariants.sql`), so its working tree has 43 SQL files. This does **not** reconcile the original remote/local history mismatch: the new file is a fresh proposed correction, not the missing historical migration, and no remote history was inspected or repaired.

## 8. Unresolved SQL helper dependency: `private.is_blocked_between`

Multiple local migrations and policy/function definitions reference `private.is_blocked_between(...)`, including block-aware profile visibility, direct-conversation membership, follow/friend acceptance, nearby discovery and media access. The inspected foundation migration's function declaration inventory does not define this helper, and no matching `CREATE FUNCTION` definition was located in the local migration sources inspected during this pass.

This is a source-provenance blocker, not proof that the deployed database lacks the function. It may exist in the remote schema or in the unmatched remote migration record. The exact definition, owner, SECURITY mode, `search_path`, grants and return behavior must be recovered from the live catalog and mapped to its original migration source. Do not invent a replacement or apply a guessed helper migration.

### Required read-only verification

Query `pg_proc`, `pg_namespace`, `pg_language`, `pg_roles`, and `information_schema.routine_privileges` in the connected database for the exact `private.is_blocked_between` signature. Record the full definition (`pg_get_functiondef`), owner, `prosecdef`, `proconfig`, ACL, and dependency references. Then map it to one of the remote migration history records and recover the exact source file before any schema action.
