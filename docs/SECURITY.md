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
