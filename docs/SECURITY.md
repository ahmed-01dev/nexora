# NEXORA Security Baseline

## Secrets
- Flutter and web clients may contain only the public Supabase publishable/anon key.
- Never commit service_role, secret API keys, database passwords, OAuth client secrets, TURN credentials, or signing credentials.
- Store server secrets in Supabase Edge Function secrets or a dedicated secret manager.
- Rotate any secret that has been exposed.

## Verified database hardening (2026-11-05)

- All current `public` tables have RLS enabled.
- The `anon` role has no table-level privileges on the current `public` application tables.
- Authenticated grants on `community_channels` are limited to SELECT, INSERT, and DELETE; broad UPDATE/TRUNCATE/REFERENCES/TRIGGER/MAINTAIN privileges were removed.
- Authenticated users can update only `notifications.read_at`; notification recipient, actor, type, payload, and entity metadata are not client-updatable. The grant was verified directly against PostgreSQL privileges.
- PUBLIC execute was removed from internal friendship implementation helpers and trigger-only audit functions. Keep private helper grants limited to the invoker RPC wrappers and RLS policies that need them.
- Follow-up catalog audit found one missed exception (`private.request_friend_impl(uuid)`); PUBLIC execute was revoked while preserving authenticated execution through the public invoker wrapper. Verified: anon cannot execute the private helper, authenticated can execute the helper and `public.request_friend`.
- Supabase Security Advisor still reports leaked-password protection disabled; this is a dashboard setting and must be enabled before public launch.

## Database
- All client-exposed public tables require RLS.
- Grants and RLS are separate controls. Revoke anon access and grant authenticated only the operations required.
- Authorization must be based on auth.uid() and server-controlled app metadata, never user-editable user_metadata.
- Restrict column-level UPDATE grants for ownership, role, recipient, and identity columns.
- Enforce case-insensitive uniqueness for profile usernames because discovery compares handles without regard to case.
- Private date of birth and privacy preferences belong in user_private_settings, not publicly readable profiles.
- SECURITY DEFINER helpers must use an empty/fixed search_path, fully qualified objects, minimal execute grants, and an explicit auth.uid() check.

## Messaging
- Current database stores normal message body text as server-readable content.
- The presence of ciphertext columns or an encryption_mode value is not E2EE.
- E2EE remains disabled until an established audited protocol is implemented on clients with identity keys, prekeys, session lifecycle, device verification, encrypted attachments, recovery, and independent review.
- Never expose message content in analytics or logs.

## Media
- Validate file extension, MIME type, actual file signature, size, and ownership.
- NEXORA uses the private `nexora-media` bucket; upload paths must start with the authenticated user ID.
- Storage SELECT checks linked post/story/message/community audience through a narrowly scoped private helper. Signed URLs are short-lived.
- Message attachment metadata SELECT requires a non-deleted message and conversation membership; the older permissive SELECT policy was removed.
- Message attachment INSERT validation is a RESTRICTIVE policy, so MIME/10 MiB/message-type checks are AND-ed with the permissive uploader/path/ownership/membership policy. This is metadata validation; server-side file-signature scanning remains pending.
- Use private storage by default; public delivery must be an explicit per-media decision.
- Use short-lived signed URLs for private media.
- Add malware scanning and server-side video transcoding before accepting untrusted files at scale.
- Do not trust client-provided storage paths or MIME types.

## Location and minors
- Nearby must be opt-in, approximate, time-limited, and disabled by default.
- Never expose exact coordinates, home/work patterns, or background tracking by default.
- Prevent unrestricted adult-to-minor discovery and messaging.
- Date of birth is private account data and must not be readable through public profile queries.

## Moderation
- User reports are private to the reporter and trusted moderation roles.
- Admin roles must be assigned server-side; never accept role flags from profile/user metadata.
- Every moderator/admin action must be auditable and appealable.
- Define retention, escalation, child-safety response, copyright, and emergency procedures before launch.

## Known release blockers
- No independent penetration test.
- No automated RLS tests with separate user identities.
- Private media Storage ownership/audience policies are configured; malware scanning, server-side transcoding, thumbnails, resumable uploads, and CDN optimization remain pending.
- No E2EE.
- No WebRTC/TURN implementation.
- No admin RBAC/dashboard.
- No production crash monitoring or backup/restore drill.

## Follow-up hardening — 2026-11-05

- Mutual blocks now override non-owner profile visibility, follow/friend relationship visibility, pending follow/friend acceptance, direct-conversation membership, and associated message/attachment access. Group/community conversations remain available after a block.
- A pending or declined friendship cannot grant access to a private profile; only accepted friendships do. Direct client writes to `profiles.is_private` and `user_private_settings` are revoked in favor of the privacy RPC that synchronizes both representations.
- Private-account privacy overrides a story's per-story public setting for both story-row reads and Storage signed URLs. Friends-only post media uses the same accepted-friend rule as the post row; soft-deleted post media is hidden from non-owners.
- Direct-conversation creators cannot remove the other participant from a 1:1 conversation; group/community creators retain member-management permissions.
- Moderation appeal INSERT is restricted to `user_id`, `action_id`, and `message`; appeal status, reviewer, and resolution metadata remain staff-controlled.
- Device registration upserts have owner-scoped UPDATE privileges for the device identity fields, with the existing RLS ownership policy still enforced.
- The account-screen logout action now calls `_signOutNexora()` to delete the current user's FID row and unregister Firebase Messaging before Supabase sign-out. This cleanup is best-effort if the network/database operation fails; multi-account and offline logout tests remain required.
- Client-side media signature checks and a 100 MiB aggregate post upload limit are implemented. These do not replace server-side media signature verification, malware scanning, or server-side storage quotas.
- The following-feed query now uses a SECURITY INVOKER paged RPC that includes accepted follows and accepted friendships while preserving table RLS.
- Supabase Security Advisor's only remaining finding is leaked-password protection disabled. The project currently cannot enable this feature on its Free plan; the email signup UI's 12-character rule is client-side only and is not a substitute.
- Migration history remains unsynchronized: do not run `supabase db push`, reset, or replay local migrations until every remote migration is mapped to exact source SQL and a recoverable backup exists.

## Live Storage policy snapshot — 2026-11-06

See `docs/STORAGE-SECURITY-INVENTORY.md` for the deployed bucket and `storage.objects` policy definitions. The only bucket, `nexora-media`, is private with a 50 MiB object limit. Authenticated uploads/deletes are owner-folder scoped; reads are owner-folder or `private.can_read_media_path(name)` authorized. There is no Storage UPDATE policy, and current client uploads use `upsert: false` with unique paths. The bucket MIME allowlist is broader than the app's actual upload support. Server-side media scanning/processing remains a release blocker.

### SECURITY DEFINER function inventory

See `docs/SECURITY-DEFINER-INVENTORY.md` for the 32 live SECURITY DEFINER functions across `public` and `private`, their signatures, owners, function-level settings, and anon/authenticated/PUBLIC EXECUTE flags. This is an inventory, not a blanket approval; review each function body, caller authorization, schema exposure, and grants before release.

### FCM device-registration race protection

`NexoraPushService` now increments a registration generation before explicit sign-out cleanup. A registration upsert captures the current user and generation; if the request completes after sign-out or account change, it deletes the just-written row for the original owner. This reduces stale device rows caused by an in-flight registration racing with logout. Cleanup remains best-effort under network/database failure and still requires offline, multi-account, and physical-device tests.

### Private schema API exposure — release gate

The authenticated role has USAGE on `private` and EXECUTE on multiple SECURITY DEFINER helpers there; anon/PUBLIC have no schema USAGE. These grants support RLS policies and internal wrapper functions. Do not revoke them blindly. Verify the hosted Supabase Dashboard → API → Exposed schemas setting excludes `private` before release; the database-side PostgREST setting was not readable from the SQL session, so exposure remains unverified.

FCM registration is suspended immediately before explicit sign-out and is resumed only by an initial or newly signed-in auth session. The auth listener no longer resumes registration for arbitrary token-refresh/user-update events while sign-out is in progress. Notification-permission requests recheck the signed-in/suspended state after the permission prompt.
If the Supabase sign-out call fails after device cleanup, the account screen resumes FCM registration for the still-authenticated user before rethrowing the sign-out error; this avoids leaving a live session with push registration suspended.

### FCM unregister callback ownership

Before unregistering Firebase Messaging, the service captures the authenticated account ID. The asynchronous `onUnregistered` callback deletes the FID row using that captured owner rather than reading `currentUser` after sign-out may have cleared it. This prevents the callback from silently skipping cleanup solely because the session has already ended. Database/network deletion failures remain best-effort and require offline and physical-device validation.

### Client diagnostic logging

The shared Flutter error reporter logs the source and exception runtime type rather than the raw exception string, because backend/plugin errors can contain phone numbers, email addresses, identifiers, or server response details. Stack traces remain available in debug logs; production crash/telemetry export is not configured or claimed.

### Startup error disclosure

The startup fallback screen now receives a generic Arabic error message from `AppErrorService.message` rather than rendering the raw Supabase initialization exception. Detailed exception values are not displayed to the user; the central reporter logs the error type and stack for local diagnostics. Provider-side configuration and startup recovery still require device validation.

FCM device cleanup is also triggered by Supabase `signedOut` auth events, not only the account-screen sign-out button. The service preserves the last known installation owner when the auth session has already been cleared, so remote revocation/session invalidation can still target the correct `user_devices` row. Cleanup remains best-effort and must be verified on a physical device and under offline conditions.

### Late FCM registration callback after sign-out

The Android push listener no longer overwrites the captured installation owner when a delayed `onRegistered` event arrives while signed out or while registration is suspended. Such callbacks do not start a device-row upsert. `unregisterCurrentDevice()` also short-circuits the duplicate invocation caused by both the account-screen sign-out path and the global `signedOut` auth listener. Cleanup remains best-effort and requires physical-device/offline/account-switch testing.

### Media upload account-switch handling

`MediaUploadService` verifies that the requested owner matches the active Supabase user before remote writes and re-checks after profile/story Storage uploads and around each post-media Storage/metadata operation. On a failed bulk upload, client cleanup is attempted only while the original owner remains the active session; it is not attempted with a newly signed-in account. This prevents cross-account cleanup attempts but cannot guarantee removal of an object uploaded just before a session change. Add server-side orphan cleanup and test sign-out/account-switch timing on a device. Client-side signature checks remain bypassable and are not malware scanning.

### FCM delayed unregister across account switching

Pending unregister operations now retain their account owner in a per-FID FIFO queue. A delayed `onUnregistered` callback consumes the queued owner rather than trusting the currently signed-in account, and it clears the in-memory tracked registration only when both FID and owner match. This prevents a prior account's callback from clearing a newly registered account's state when Firebase reuses the same FID. The pure ownership rules are unit-tested; Firebase event ordering and actual row cleanup remain device-test requirements.

### Flutter framework error logging

The global `FlutterError.onError` handler must not call `FlutterError.presentError`, because that default presenter writes the raw exception message to debug output. NEXORA now routes framework exceptions through `AppErrorService.report`, which logs only the exception runtime type and stack trace. Unit coverage asserts that sample email/token-like values are not emitted. Re-check this boundary if crash telemetry or a third-party reporter is introduced.

### Report target validation

The report dialog validates target type and reason against the live `reports` CHECK constraint values and requires a canonical UUID-shaped target ID before insert. This is input hygiene only; the deployed PostgreSQL constraints, RLS, and server-side ownership rules remain authoritative. Validation logic has dedicated unit coverage.

Report submission also checks that the same authenticated user remains active after the insert returns. If the account changed during the request, the dialog does not report success in the new session and warns against an immediate blind retry. This is a client-side stale-result guard; it does not replace database RLS or an idempotent server endpoint.

### Message attachment account-switch handling

Message image upload and deletion now keep subsequent database/Storage operations scoped to the original authenticated user. Rollback is skipped if the session has changed, and signed URLs are not returned after a viewer switch. This avoids using the new account's session for old-account cleanup or exposing a stale signed URL to a new viewer. If a message commit completes while the client session changes, the UI outcome may be ambiguous; do not blindly retry without reconciliation. Device tests and an idempotent send contract remain pending.

### Community-channel session continuity

Community channel screens now require a live user for reads and creation. Reads discard results if the viewer changes while the request is in flight. Creation rechecks the original owner between each database write and limits rollback to the original authenticated session, never a newly signed-in account. A switch after a partial insert can leave a conversation orphan; server-side reconciliation and real-device multi-account tests remain pending.

### Community member action session binding

The member list stores the viewer ID associated with its successful load. If the current session no longer matches, the previous member list is hidden and role/removal actions are blocked. Actions recheck the actor after database completion before refreshing or mutating local state. This is UI race protection; RLS and community-role policies remain the security boundary.

### Conversation-list viewer binding

The conversation list is associated with the authenticated viewer ID that loaded its previews. If the current viewer changes, old previews are hidden and stale rows cannot open a chat. The new-conversation flow also verifies that the original viewer remains active after the picker and after conversation creation. This protects against stale UI/session races; conversation membership RLS remains authoritative.

### Block, privacy, and relationship-request session binding

Block creation rechecks the authenticated actor after its existing-block lookup and after insertion. The blocked-account screen associates its rows with the viewer who loaded them and refuses stale unblocks. Privacy settings reads verify the viewer between profile/settings queries and bind the save RPC to the viewer whose settings were loaded. Friend and follow request lists/actions similarly reject stale viewer state. These are client-side session-race protections only; database RLS and RPC authorization remain authoritative. Real-device multi-account tests and partial-write reconciliation remain pending.

Profile-level friendship controls now capture the viewer ID for both relationship reads and request/accept/cancel/remove RPCs. A session mismatch disables the control and suppresses stale results or action feedback. This remains client-side race protection; the friendship RPCs and RLS policies must enforce actor/target authorization server-side.

### Nearby, notification preference, and moderation session binding

Nearby presence/discovery reads and writes capture the viewer ID and discard stale results after session changes; location updates recheck the session after OS permission/location awaits. Direct-conversation creation from nearby results is similarly bound to the captured viewer. Notification preference reads/writes and push-permission continuation are tied to the account that loaded the preferences. Personal moderation history/appeals and reviewer appeal decisions also capture and recheck the authenticated actor. These client checks complement, but do not replace, server-side RLS/RPC authorization. Physical-device location, permission, multi-account, and moderator-role integration tests remain pending.

### Community discovery and management session binding

Community discovery now checks the authenticated viewer after the community query and membership query, including empty-page results. Membership changes, invite acceptance/creation/revocation, and community creation capture the viewer and suppress stale UI updates after a session change. Community creation still has a partial-insert orphan risk if the session changes after the community row is inserted but before owner membership is committed; this requires server-side transactional creation/reconciliation. RLS remains authoritative and device-level multi-account tests are pending.

### Story feed and composer session binding

Story feed queries and bounded signed-URL batches are bound to the viewer that initiated the load; results are discarded after a session change. Opening a story from a stale feed is blocked. The story composer also records the account that opened it and refuses to publish its draft/media under a different account. Story-view tracking uses the viewer captured at viewer initialization. Signed URLs already issued may remain valid until expiry, so revocation/short-lived URL behavior remains a separate Storage concern.

The moderation report queue now captures the reviewer identity for report-page reads, target previews, assignment, and dismissal. Stale queue data is hidden after account changes, and decision UI updates are suppressed if the reviewer changes during the request. Server-side moderator role/RLS policies remain authoritative; real-device moderator account-switch tests are pending.
