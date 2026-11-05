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
