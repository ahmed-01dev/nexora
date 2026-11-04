# NEXORA Security Baseline

## Secrets
- Flutter and web clients may contain only the public Supabase publishable/anon key.
- Never commit service_role, secret API keys, database passwords, OAuth client secrets, TURN credentials, or signing credentials.
- Store server secrets in Supabase Edge Function secrets or a dedicated secret manager.
- Rotate any secret that has been exposed.

## Database
- All client-exposed public tables require RLS.
- Grants and RLS are separate controls. Revoke anon access and grant authenticated only the operations required.
- Authorization must be based on auth.uid() and server-controlled app metadata, never user-editable user_metadata.
- Restrict column-level UPDATE grants for ownership, role, recipient, and identity columns.
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
- No media storage policies/pipeline.
- No E2EE.
- No WebRTC/TURN implementation.
- No admin RBAC/dashboard.
- No production crash monitoring or backup/restore drill.
