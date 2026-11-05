# NEXORA Implementation Status

Last audited: 2026-11-05

Status meanings:
- **Implemented**: real code/database operation exists and has been verified.
- **Foundation**: schema or interface exists, but user-facing workflow is incomplete.
- **Pending**: not implemented.
- **External dependency**: requires a provider, credentials, infrastructure, or legal review.

## Verified baseline
- [x] Flutter Android/Web project and GitHub Actions workflows.
- [x] Phone-first authentication UI: phone OTP signup/login with Egyptian mobile normalization and OTP verification over SMS only; email/password remains an explicit alternative. Supabase SMS provider configuration, delivery costs/limits, and real-device OTP delivery remain external setup and end-to-end verification items.
- [x] Basic profile display/edit, with database-enforced case-insensitive username uniqueness to prevent handles differing only by letter case.
- [x] Profile avatar and cover image selection/upload UI, private Storage paths, profile path persistence, signed-URL display, and replacement cleanup; authenticated upload/read policy paths are configured. End-to-end upload with a real authenticated device session remains to be validated.
- [x] Client-side media signature checks for profile images, post/story JPG/PNG/WebP/GIF images, and MP4/WebM videos, with unit coverage; server-side file-signature scanning and malware scanning remain required because client validation can be bypassed.
- [x] Failed multi-file post uploads now attempt to roll back both previously inserted media metadata rows and uploaded Storage objects before returning the original error.
- [x] Text-only post creation and public feed query.
- [x] Real comment listing, reply-to-comment, posting, own-comment soft deletion, and per-comment like/unlike UI connected to Supabase.
- [x] Feed mode switch (Latest / Following) with server-side 20-row pagination, stable ordering, duplicate filtering, refresh, and RLS-respecting queries.
- [x] Post like state and toggle backed by the existing `likes` table.
- [x] Repost and undo-repost actions backed by the existing `reposts` table, restricted in the client to public posts and enforced again by database RLS; duplicate submissions are constrained by a unique database index.
- [x] Save/unsave bookmarks backed by the existing `saves` table, plus a saved-posts library in the profile that reads the user's own saved posts under RLS.
- [x] Basic follow insertion/deletion.
- [x] Central Flutter error presentation/logging.
- [x] Latest source-only CI run passed Flutter analysis and unit/widget tests (run 42081293244). This run did not build an APK/AAB or Web release; the release workflow remains manual-only.
- [x] Additive PostgreSQL foundation migration applied and verified for RLS on all newly added tables.
- [x] Anonymous role has no SELECT privilege on the newly added social tables.
- [x] Community-channel grants were narrowed to SELECT/INSERT/DELETE for authenticated clients; unnecessary UPDATE/TRUNCATE/REFERENCES/TRIGGER/MAINTAIN privileges were removed and verified.
- [x] PUBLIC execute was revoked from private friendship implementation helpers and trigger-only audit functions; authenticated execute remains only where the invoker RPC wrappers require it.
- [x] Follow-up privilege audit found and fixed a missed PUBLIC execute grant on `private.request_friend_impl(uuid)`; anon execution is now false while authenticated execution and the public RPC wrapper remain available.
- [x] Consolidated moderation SELECT policies on reports, appeals, and moderation actions while preserving the same owner/reporter and staff visibility rules; the three Supabase multiple-permissive-policy performance warnings are resolved.
- [x] Profile visibility now denies non-owner access when either side has blocked the other, including indirect access through friendships or shared conversations.
- [x] Direct updates to `profiles.is_private` are revoked; privacy changes must use the RPC that keeps `profiles.is_private` and `user_private_settings.profile_visibility` synchronized.
- [x] Direct INSERT/UPDATE access to `user_private_settings` is revoked; the authenticated privacy RPC is the only client path for changes and preserves synchronization.
- [x] Private-profile visibility requires an accepted follow or accepted friendship (or an allowed shared conversation); pending/declined friend requests no longer grant access.
- [x] Private avatar/cover Storage reads now use the same accepted-follow, accepted-friendship, shared-conversation, and block rules as profile-row visibility.
- [x] Private-account status now overrides public story visibility for both story rows and signed media access; only the owner or accepted followers can view private-account stories.
- [x] Signed media for friends-only posts now follows the same accepted-friend visibility rule as the post row, while preserving block and private-account checks.
- [x] Signed media for soft-deleted posts is denied to non-owners, matching the post-row visibility policy; owners can still access their own content.
- [x] Blocking either participant now revokes access to existing direct conversations through the shared membership helper; group/community conversations remain unaffected. Verified function definition and execute grants in Postgres.
- [x] Friend-request acceptance and pending-follow acceptance now re-check mutual block state at the database boundary, preventing requests created before a block from being accepted afterward.
- [x] Follow and friendship relationship rows are hidden from both participants while a mutual block exists; records are retained so unblocking can restore the prior relationship.
- [x] A creator can no longer remove the other participant from a direct 1:1 conversation; self-removal remains allowed, and group/community creators retain member-management rights.
- [x] Appeal submissions are limited to the user's own `user_id`, `action_id`, and `message`; status, reviewer, resolution time, ID, and creation time cannot be forged on INSERT. Verified column privileges after revoking the broad table-level INSERT grant.
- [x] Profile handles have a verified unique index on `lower(username)`, preventing case-only duplicate handles. Notification UPDATE grants are restricted to `read_at`; recipient, actor, type, payload, and entity metadata columns cannot be changed by authenticated clients. Verified with PostgreSQL privilege checks.
- [x] Removed the permissive message-attachment SELECT policy that bypassed deleted-message filtering; the remaining restrictive SELECT policy requires a non-deleted message and conversation membership.
- [x] Made image attachment MIME/10 MiB/message-type validation restrictive, so it is combined with uploader ownership, user-folder path, existing Storage object, and conversation-membership checks rather than OR-ed with them.
- [x] Unique database index prevents duplicate reposts per user/post; applied and verified after a duplicate preflight returned no existing duplicate pairs.

## Database foundation added
- [x] Friendships and blocks.
- [x] Conversations, conversation members, messages, attachments, reactions.
- [x] Notifications.
- [x] Stories and story views.
- [x] Communities and community membership.
- [x] Reports.
- [x] Call sessions and participants (signaling records only; not WebRTC).
- [x] Private account settings and user preferences.
- [x] Private media bucket with authenticated upload, ownership/audience read checks, profile avatar/cover path visibility checks, delete-own policy, and signed URL delivery.
- [ ] Background transcoding, thumbnail generation, malware scanning, resumable uploads, and CDN optimization.
- [x] Privacy center controls for profile visibility, who can start a new direct message, account blocking from people discovery, and a live blocked-accounts list with unblock actions.
- [ ] RLS integration tests with real authenticated test users.

## Product feature status
| Feature | Status | Notes |
|---|---|---|
| Authentication | Partial | Phone OTP is the default signup/login path with E.164 normalization and six-digit verification; email/password remains an alternative. New email signups enforce 12+ characters with at least one letter and digit in the client only; server-side password policy and leaked-password checks remain unconfigured. Supabase SMS-provider delivery/configuration, phone linking for existing email accounts, MFA, passkeys, OAuth, and device center remain pending. |
| Profiles | Partial | Editable text profile, avatar and cover image upload to private Storage, signed-URL rendering on profile/person/post cards, old own-image cleanup, paginated own-post timeline (50 per page), and saved-posts library; authenticated end-to-end upload validation and profile highlights pending. |
| Followers | Partial | Follow state loads from DB; private accounts create pending requests through a server-side function; request inbox/accept UI pending. |
| Friends | Partial | Server-side request/accept/decline/cancel/remove operations with block and permission checks; incoming/outgoing request inbox and profile action buttons. Group roles and friend activity pending. |
| Feed | Partial | Latest public feed and Following feed now load in 20-row server pages with stable ordering, duplicate filtering, refresh, and existing RLS privacy/block checks. Following now includes accepted friends as well as accepted follows through a SECURITY INVOKER server-side paged RPC (avoids large client-side ID lists) so friends-only posts appear; ranking, cursor pagination, offline cache, and mixed content remain pending. |
| Posts | Partial | Text, multi-image and video upload to private storage; feed displays signed image/video URLs; post likes, public-post repost/undo-repost, save/unsave bookmarks, and a saved-posts library are wired to existing tables. Like/repost/save counts, quote repost UI, polls, drafts, scheduling, edit/restore, and media processing pending. |
| Comments | Partial | Real comments screen loads newest comments first in ordered 100-row server pages with load-older, keeps replies visible when their parent is on an older page, supports nested replies, posting, editing and soft-deleting own comments, per-comment like/unlike, and report action for other users' comments; visible like counts pending. CI analysis and unit tests run after code changes; full Android/Web build remains intentionally paused until feature/code implementation is complete. |
| Stories | Partial | Text/photo/video stories with 24-hour expiry, viewer, view records, and visibility/block checks. Highlights, close friends, reactions/replies, viewer list, and cleanup worker pending. |
| Reels/Video | Partial | Vertical swipe feed plays public uploaded videos; no transcoding, adaptive bitrate, captions, creator editing, or long-form channels yet. |
| Messaging | Partial | Direct text chat, RLS-safe inbox preview RPC, realtime updates, last-read state, privacy/block enforcement, own-message edit/soft-delete, and image attachments through private Storage with signed URLs, non-deleted-message visibility filtering, and restrictive 10 MiB/MIME metadata validation are implemented; server-side file-signature scanning remains pending. Video/audio/file attachments, typing, delivery/read indicators, richer group UX, and E2EE remain pending. |
| E2EE | Pending | No cryptographic protocol or key lifecycle implemented. |
| Voice/video calls | Foundation | Call records only; WebRTC, STUN/TURN, call UI/media transport, and reliable incoming-call delivery pending. |
| Communities | Partial | Public/private/invite-only communities, owner-issued UUID invite codes (7-day expiry, 10-use limit), authenticated invite acceptance, revoke-all-active-invites control, channel chat with automatic membership sync, owner member management, and moderator channel creation. Per-invite management, moderator moderation actions, and admin tools pending. |
| Notifications | Partial | In-app center uses stable 50-row server pagination, marks one/all read, and routes message/friend-request events. Per-category in-app and push preferences are editable. FCM Edge Function and database webhook trigger are deployed; actual delivery still requires valid Edge Function secrets, a signed-in Android device registering its Firebase Installation ID, and a real-device delivery test. Device registration upserts now have owner-scoped UPDATE grants for `user_id`, `platform`, and `push_token`. Email delivery and grouping remain pending. |
| Search | Partial | Profile discovery searches username/display name; public-post text search and exact normalized hashtag search both use stable server-side 30-row pagination, refresh, and load-more. Publishing indexes unique Arabic/Latin tags into the existing hashtags/post_hashtags tables; trending, ranking, and advanced filters pending. |
| Nearby | Partial | Opt-in screen and foreground geolocation permission flow are implemented. Coordinates are rounded to two decimals before storage in a private RLS-protected table; public RPC wrappers call privileged helpers in the non-exposed private schema. Results return only coarse distance bands, exclude private accounts and mutual blocks, and expire after 24 hours. Android permission declarations and a distance-label unit test are included. Real-device/browser permission and multi-user RLS integration tests remain pending. |
| Moderation | Partial | Account reporting from people search and post menus; account blocking from people search, post menus, and story viewer through a shared confirmation service, plus a blocked-accounts manager with unblock; post, comment, story, community, and received-message reporting; target-specific report dialog labels; staff-only active/all report queue, 30-row pagination, privacy-respecting target previews (when RLS permits), self-assignment, dismiss-with-resolution-note, user moderation history, appeals submission/status display, and staff appeal decisions (upheld/overturned). Target previews use normal RLS and never bypass privacy. Existing audit triggers record report updates. Automated enforcement actions and complete case workflow pending. |
| Admin dashboard | Pending | No trusted RBAC or admin web console yet. |
| Monetization | Pending | No payment provider, tax, payouts, or legal readiness. |
| Live streaming | Pending | No streaming provider/ingest infrastructure. |
| AI features | Pending | No model integration or consent controls. |
| Localization | Partial | Arabic RTL baseline; English and additional locale resources pending. |
| Themes | Partial | AMOLED, light, and pink AMOLED themes; in-app selector persists the chosen theme in the existing per-user `user_preferences` row and restores it after authentication. Supported theme values are normalized with a safe AMOLED fallback and covered by unit tests; full-screen light-theme contrast audit and custom accent editor pending. |
| PWA | Partial | Web build exists; installability, offline strategy, and deployment still need verification. |

## Release gate
NEXORA is **not yet production-ready for public launch**. Public release requires the remaining critical features to be implemented or intentionally excluded, security review, real-user end-to-end tests, storage/media validation, privacy/legal documents, monitoring, backups, and an operational support/moderation process.
