# NEXORA API Contracts

**Audit basis:** repository documentation snapshot dated 2026-11-06.  
**Transport:** Flutter uses Supabase Auth, PostgREST, Storage, Realtime, and deployed Edge Functions where configured. There is no verified standalone NestJS/REST backend. PostgreSQL RLS and narrowly scoped trusted functions are the authorization boundary.

> This inventory is documentation-derived. Before changing a contract, trace the exact Dart call site, SQL definition, deployed function, grants, and RLS policy. Names below are documented operations; this file does not assert that every operation has passed end-to-end tests.

## 1. Verified client-used operations (documented)

| Domain | Operation / object | Current evidence | Important limitation |
|---|---|---|---|
| Authentication | Supabase Auth phone OTP UI; email/password alternative | Phone-first UI and six-digit verification path documented in implementation status | SMS provider delivery, cost, and real-device verification are external/unverified; account linking, MFA, passkeys, OAuth and recovery hardening pending |
| Profiles | Read/update own profile | Implemented profile display/edit documented | Authenticated real-device media/profile flow still needs end-to-end validation |
| Profile media | Private avatar/cover Storage upload and signed display | Private paths, owner-scoped policy, signed URL display and replacement cleanup documented | Server-side signature scanning and malware scanning pending |
| Posts | Text-only post insert; public feed query | Explicitly documented as implemented | Full post feature remains Partial; do not infer scheduling, drafts, editing, polls, or media processing |
| Post media | Multi-image/video upload to private Storage; signed media display | Flutter upload path, rollback attempt and client-side signature checks documented | Client checks are bypassable; server scanning, processing, thumbnails, resumable upload and quotas pending |
| Feed | Latest/Following paginated reads | 20-row server pages and SECURITY INVOKER following-feed RPC documented | Ranking, cursor pagination, offline cache and mixed-content ranking pending |
| Comments | List, reply, create, edit, own soft-delete, like/unlike | Connected workflows documented | Visible like counts and complete E2E evidence pending |
| Likes | Insert/delete or toggle in likes table | Documented as client-used | Verify exact call sites and RLS during source trace |
| Reposts | Repost/undo using reposts table | Public-post restriction, RLS and unique index documented | Quote repost UI pending |
| Bookmarks | Save/unsave using saves table; own saved-post library | Documented as client-used | Verify exact call sites and pagination behavior |
| Follows | Basic follow insertion/deletion; request/cancel RPC for private profiles | Implementation status documents both direct and RPC paths | Request inbox/accept UI pending; do not collapse public follow and private request semantics |
| Friendships | request/accept/decline/cancel/remove RPC family | Server-side operations and block/permission checks documented | Verify actual SQL signatures and call sites before changing payloads |
| Privacy | update_privacy_settings RPC | Atomic profile visibility/direct-message permission synchronization documented | Do not write protected privacy columns directly from client |
| Messaging | Inbox, realtime messages, read state, own edit/soft-delete, image attachments | Partial client workflow and RLS/storage restrictions documented | No E2EE; video/audio/file attachments and richer delivery indicators pending |
| Notifications | In-app list/read state/preferences; FCM Edge Function + webhook | Partial client workflow and deployed push components documented | Actual push delivery depends on secrets and registered device; email notifications not implemented |
| Communities | Community membership, invites, channel chat/member management | Partial client workflow documented | Per-invite management, moderator actions and admin tools pending |
| Stories | Story rows/views and media display | Partial client workflow documented | Highlights, close friends, reactions/replies, viewer list and cleanup worker pending |
| Safety | Reports, appeals, moderation data | Database and selected client flows documented | Full admin RBAC/dashboard and operational moderation procedures pending |
| Nearby | Opt-in approximate discovery | Documented as privacy-controlled feature | Exact coordinates must never be exposed; verify current client and RLS behavior before extension |

## 2. Database foundation is not a complete client contract

The following objects/functions may exist as schema or server foundations, but existence alone does not establish a complete UI workflow or production service:

- `friendships`, `blocks`, `conversations`, `conversation_members`, `messages`, `message_attachments`, `message_reactions`
- `notifications`, `stories`, `story_views`, `communities`, `community_members`, `reports`
- `call_sessions`, `call_participants`, `user_private_settings`, `user_preferences`
- Private media bucket and audience-aware Storage policies

Call-session rows are signaling records only. They do not provide WebRTC transport, STUN/TURN, media encryption, or reliable incoming-call delivery.

## 3. Planned trusted endpoints — NOT DEPLOYMENT CLAIMS

These are proposed contracts only. Do not call them from the app or describe them as deployed until a matching implementation, authentication policy, tests, and deployment evidence exist.

| Proposed endpoint | Intended responsibility | Release gate |
|---|---|---|
| `POST /v1/media/upload-intent` | Validate user, object purpose, limits and upload authorization | Trusted implementation, ownership checks, server-enforced limits and abuse controls |
| `POST /v1/media/process` | Queue scanning, thumbnail and transcode work | Worker, retry/dead-letter handling, status model and malware controls |
| `POST /v1/notifications/dispatch` | Trusted notification fan-out | Secret handling, authorization, idempotency and delivery observability |
| `POST /v1/moderation/actions` | Role-checked moderation actions and audit | Server-assigned RBAC, audit log, appeals and staff access review |
| `POST /v1/account/export` | Verified personal-data export | Identity re-authentication, complete data map and expiring download |
| `DELETE /v1/account` | Account deletion workflow | Re-authentication, retention/legal policy, cascading cleanup and verification |
| `POST /v1/calls/token` | Authorize WebRTC room/signaling access | WebRTC provider/infra, short-lived token, membership/block checks and TURN plan |
| `POST /v1/search` | Safe search/ranking where direct queries are insufficient | Abuse protection, privacy filtering, ranking tests and rate limits |

## 4. Contract change checklist

Before changing or adding an operation:

1. Identify the exact Flutter source file, method, and request payload.
2. Identify the actual SQL table/view/RPC/function or Edge Function and its deployed version.
3. Verify authentication requirements, grants, RLS, Storage policies and ownership derivation.
4. Record nullability, validation, pagination/order, idempotency and error behavior.
5. Add tests for owner and non-owner identities, block/private-account cases, and failure/timeout paths.
6. Update this inventory and `IMPLEMENTATION_STATUS.md` only when evidence supports the new status.

## 5. Operational safety

- Public client keys only in Flutter/Web; never embed service-role or provider secrets.
- No schema writes while remote/local migration history remains unreconciled.
- No endpoint is considered available because it appears in a roadmap.
- No SMS, media worker, TURN, push, or other paid/provider-dependent service is assumed free or activated by documentation.
- Application packaging remains paused until source/code/file completion and explicit build approval.

## 6. Verified Flutter RPC call-site inventory (read-only snapshot)

The following client calls were extracted from the current Flutter source on branch `docs/specs-i-j-k` and compared with the live PostgreSQL function catalog. Function names, identity arguments, and return types below are live database evidence; parameter keys and call-site paths are source evidence. This is a contract-parity inventory, not proof that every authorization path or end-to-end workflow has passed tests.

| RPC | Flutter call site | Client parameter keys | Live signature / return |
|---|---|---|---|
| `get_feed_page` | `lib/main.dart` | `p_mode`, `p_limit`, `p_offset` | `(p_mode text, p_limit integer, p_offset integer) → TABLE` |
| `request_follow` | `lib/main.dart` | `p_target_user_id` | `(p_target_user_id uuid) → text` |
| `cancel_follow` | `lib/main.dart` | `p_target_user_id` | `(p_target_user_id uuid) → boolean` |
| `accept_community_invite` | `lib/features/communities/communities_screen.dart` | `p_invite_code` | `(p_invite_code uuid) → TABLE` |
| `create_community_invite` | `lib/features/communities/communities_screen.dart` | `p_community_id`, `p_expires_in_hours`, `p_max_uses` | `(p_community_id uuid, p_expires_in_hours integer, p_max_uses integer) → TABLE` |
| `revoke_community_invites` | `lib/features/communities/communities_screen.dart` | `p_community_id` | `(p_community_id uuid) → integer` |
| `request_friend` | `lib/features/friends/friend_requests_screen.dart` | `p_addressee_id` | `(p_addressee_id uuid) → text` |
| `remove_friend` | `lib/features/friends/friend_requests_screen.dart` | `p_other_user_id` | `(p_other_user_id uuid) → boolean` |
| `cancel_friend_request` | `lib/features/friends/friend_requests_screen.dart` | `p_request_id` | `(p_request_id uuid) → boolean` |
| `accept_friend_request` | `lib/features/friends/friend_requests_screen.dart` | `p_request_id` | `(p_request_id uuid) → boolean` |
| `decline_friend_request` | `lib/features/friends/friend_requests_screen.dart` via `_act('decline_friend_request', ...)` | `p_request_id` | `(p_request_id uuid) → boolean` |
| `get_my_conversation_previews` | `lib/features/messaging/messages_screen.dart` | none | `() → TABLE` |
| `create_direct_conversation` | `lib/features/messaging/messages_screen.dart`; `lib/features/nearby/nearby_discovery_screen.dart` | `p_other_user_id` | `(p_other_user_id uuid) → uuid` |
| `my_nearby_presence_enabled` | `lib/features/nearby/nearby_discovery_screen.dart` | none | `() → boolean` |
| `find_nearby_people` | `lib/features/nearby/nearby_discovery_screen.dart` | `p_limit` | `(p_limit integer) → TABLE` |
| `update_my_nearby_presence` | `lib/features/nearby/nearby_discovery_screen.dart` | `p_latitude`, `p_longitude`, `p_enabled` | `(p_latitude double precision, p_longitude double precision, p_enabled boolean) → void` |
| `get_my_notification_page` | `lib/features/notifications/notifications_screen.dart` | `p_offset`, `p_limit` | `(p_offset integer, p_limit integer) → TABLE` |
| `update_privacy_settings` | `lib/features/settings/privacy_settings_screen.dart` | `p_is_private`, `p_allow_messages_from`, `p_allow_friend_requests` | `(p_is_private boolean, p_allow_messages_from text, p_allow_friend_requests boolean) → void` |

**Result of this snapshot:** 18 distinct RPC names and 20 call sites were found (19 literal call sites plus one dynamic dispatcher) in the reviewed feature screens and app entry point. Each listed name has a matching live public function with the listed identity-argument types; no missing-function or parameter-key mismatch was found in these call sites. This does not validate runtime grants, RLS outcomes, business rules, returned row decoding, or error handling. Re-run this comparison whenever a client RPC or database function changes.

**Safety boundary:** this was read-only inspection. No function, grant, schema, migration, or database object was changed. No app build or test suite was run.

## 7. Flutter table and Storage-bucket reference parity

A static scan of the Flutter `lib/` Dart files found 31 distinct literal table names used through Supabase `.from(...)` calls. All 31 names were present in the read-only live table inventory for the project at the time of review:

- `blocks`
- `comments`
- `comment_likes`
- `communities`
- `community_members`
- `community_channels`
- `conversations`
- `conversation_members`
- `friendships`
- `media`
- `messages`
- `message_attachments`
- `profiles`
- `moderation_appeals`
- `reports`
- `moderation_actions`
- `user_devices`
- `notification_preferences`
- `notifications`
- `hashtags`
- `post_hashtags`
- `user_preferences`
- `user_private_settings`
- `stories`
- `story_views`
- `posts`
- `follows`
- `staff_members`
- `saves`
- `reposts`
- `likes`

The same scan found the Storage bucket literal `nexora-media`; the live bucket inventory identifies that bucket as private. Repeated call sites are intentionally collapsed in this list.

**Scope limit:** object-name existence is not column/relationship parity. This scan does not validate selected columns, filters, inserts/updates, JSON decoding, grants, RLS decisions for each identity, or Storage object-path authorization. Those require per-operation contract review and authenticated integration tests. No schema or Storage configuration was changed.

## 8. Selected-column and embedded-relation name check

A static parser compared literal PostgREST `.select(...)` projections in 29 Flutter app/feature Dart source files with the live `information_schema.columns` inventory, recursively checking embedded relation projections (including named foreign-key relations).

- Result: **zero unknown selected columns and zero unknown embedded relation names** in the reviewed literal projections.
- This is a name-existence check only. It does not prove that the caller is allowed to read a column/row, that relationship cardinality matches UI assumptions, or that filters/order clauses and write payloads are correct.
- Dynamic/computed select strings, runtime authorization, authenticated RLS behavior, and result decoding remain outside this static check.
- No database or client source was changed by this inspection.

## 9. Insert/update/upsert payload key check

A static scan of literal `insert`, `update`, and `upsert` map payloads in the reviewed Flutter app/feature sources compared **111 literal write keys** with the live public-table column inventory.

- No literal write-key mismatch was found.
- One profile-image update uses a computed key named `column`; source inspection confirmed it is constrained to the two live profile columns `avatar_url` and `cover_url`.
- This does not verify row-level authorization, column grants, check constraints, nullability at runtime, transaction behavior, or Storage upload/delete authorization. It also does not cover maps built dynamically outside the literal payload patterns.
- No database, Storage, or runtime configuration was changed.

## 10. Literal filter and ordering column check

A static scan of recognized Supabase query-builder filter/order calls across the reviewed Flutter sources checked 150 literal database column references against the live table definitions, accounting for embedded relation prefixes and explicit `referencedTable` ordering.

- Result: **zero mismatched query-builder column references** among the 150 recognized database references.
- One string operation on an error message containing `23505` was excluded after source inspection; it is not a database filter.
- Dynamic column names and query-builder methods outside the recognized scan patterns are not covered. This is not a runtime authorization or query-execution test.

## 11. Incoming follow-request workflow

- Source: `lib/features/friends/follow_requests_screen.dart`, opened from the discovery screen.
- Read path: `public.follows` where `following_id = auth.uid()` and `status = 'pending'`, with the requester profile joined through `follows_follower_id_fkey`; pages are ordered newest-first with `follower_id` as a deterministic tie-breaker in 30-row ranges.
- Accept path: update only `status = 'accepted'`, filtered by the exact `follower_id`, current `following_id`, and pending status. Live privileges grant authenticated users UPDATE on the `status` column only (not table-wide UPDATE or ownership columns); the live UPDATE policy restricts recipients to their own incoming pending rows and rechecks block state.
- No recipient-side decline operation exists in the current live RPC/policy contract. The UI therefore offers accept only; it does not attempt a client-side DELETE or invent a decline RPC.
- This is source/schema contract evidence, not a multi-user RLS integration test.

### Follow-request screen delta after the static scan

The subsequently added `lib/features/friends/follow_requests_screen.dart` was checked separately against the same live schema snapshot: its `follows` projection and embedded requester profile columns exist, its filter/order fields exist, and its sole write key `status` is the only column-level UPDATE privilege granted to authenticated users. The screen's update is additionally constrained by the recipient-only RLS policy. This brings the source files reviewed for these literal contract checks to 30; it does not add a decline operation or replace multi-user integration testing.
