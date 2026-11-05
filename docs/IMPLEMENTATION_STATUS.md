# NEXORA Implementation Status

Last audited: 2026-11-05

Status meanings:
- **Implemented**: real code/database operation exists and has been verified.
- **Foundation**: schema or interface exists, but user-facing workflow is incomplete.
- **Pending**: not implemented.
- **External dependency**: requires a provider, credentials, infrastructure, or legal review.

## Verified baseline
- [x] Flutter Android/Web project and GitHub Actions workflows.
- [x] Supabase email/password registration and login.
- [x] Basic profile display/edit.
- [x] Text-only post creation and public feed query.
- [x] Real comment listing, reply-to-comment, posting, own-comment soft deletion, and per-comment like/unlike UI connected to Supabase.
- [x] Feed mode switch (Latest / Following) with server-side 20-row pagination, stable ordering, duplicate filtering, refresh, and RLS-respecting queries.
- [x] Post like state and toggle backed by the existing `likes` table.
- [x] Repost and undo-repost actions backed by the existing `reposts` table, restricted in the client to public posts and enforced again by database RLS; duplicate submissions are constrained by a unique database index.
- [x] Save/unsave bookmarks backed by the existing `saves` table, plus a saved-posts library in the profile that reads the user's own saved posts under RLS.
- [x] Basic follow insertion/deletion.
- [x] Central Flutter error presentation/logging.
- [x] Existing CI run passed analysis, tests, Android release APK build, and web build (run 41929549503).
- [x] Additive PostgreSQL foundation migration applied and verified for RLS on all newly added tables.
- [x] Anonymous role has no SELECT privilege on the newly added social tables.
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
- [x] Private media bucket with authenticated upload, ownership/audience read checks, delete-own policy, and signed URL delivery.
- [ ] Background transcoding, thumbnail generation, malware scanning, resumable uploads, and CDN optimization.
- [x] Privacy center controls for profile visibility and who can start a new direct message.
- [ ] RLS integration tests with real authenticated test users.

## Product feature status
| Feature | Status | Notes |
|---|---|---|
| Authentication | Partial | Email/password only; no OAuth, phone OTP, MFA, passkeys, or device center. |
| Profiles | Partial | Basic editable text profile, paginated own-post timeline (50 per page), and saved-posts library; no avatar/cover upload or profile highlights. |
| Followers | Partial | Follow state loads from DB; private accounts create pending requests through a server-side function; request inbox/accept UI pending. |
| Friends | Partial | Server-side request/accept/decline/cancel/remove operations with block and permission checks; incoming/outgoing request inbox and profile action buttons. Group roles and friend activity pending. |
| Feed | Partial | Latest public feed and Following feed now load in 20-row server pages with stable ordering, duplicate filtering, refresh, and existing RLS privacy/block checks; ranking, cursor pagination, offline cache, and mixed content pending. |
| Posts | Partial | Text, multi-image and video upload to private storage; feed displays signed image/video URLs; post likes, public-post repost/undo-repost, save/unsave bookmarks, and a saved-posts library are wired to existing tables. Like/repost/save counts, quote repost UI, polls, drafts, scheduling, edit/restore, and media processing pending. |
| Comments | Partial | Real comments screen loads newest comments first in ordered 100-row server pages with load-older, keeps replies visible when their parent is on an older page, supports nested replies, posting, editing and soft-deleting own comments, and per-comment like/unlike; visible like counts and moderation UX pending. Build verification intentionally paused until feature/code implementation is complete. |
| Stories | Partial | Text/photo/video stories with 24-hour expiry, viewer, view records, and visibility/block checks. Highlights, close friends, reactions/replies, viewer list, and cleanup worker pending. |
| Reels/Video | Partial | Vertical swipe feed plays public uploaded videos; no transcoding, adaptive bitrate, captions, creator editing, or long-form channels yet. |
| Messaging | Partial | Direct text chat UI, realtime message stream, latest-message auto-scroll that respects manual scroll position, last-read update, server-side block/privacy check, in-app message notification trigger, and own-message edit/soft-delete actions exist. Attachments, typing, delivery states, group UX, and E2EE pending. |
| E2EE | Pending | No cryptographic protocol or key lifecycle implemented. |
| Voice/video calls | Foundation | Call records only; WebRTC, STUN/TURN, push call delivery pending. |
| Communities | Foundation | Tables and RLS exist; discovery, channels, admin workflows pending. |
| Notifications | Partial | In-app center lists real message/friend notifications, marks read, and routes to the relevant conversation/request screen. Push/email delivery, grouping, and full preferences pending. |
| Search | Partial | Basic profile search only. |
| Nearby | Pending | Must remain disabled until consent, approximate geolocation, and safety protections are implemented. |
| Moderation | Foundation | User reports table; admin queue, enforcement, appeals, and audit workflow pending. |
| Admin dashboard | Pending | No trusted RBAC or admin web console yet. |
| Monetization | Pending | No payment provider, tax, payouts, or legal readiness. |
| Live streaming | Pending | No streaming provider/ingest infrastructure. |
| AI features | Pending | No model integration or consent controls. |
| Localization | Partial | Arabic RTL baseline; English and additional locale resources pending. |
| Themes | Partial | AMOLED-first theme system and light/pink theme definitions exist; persisted in-app theme selector pending. |
| PWA | Partial | Web build exists; installability, offline strategy, and deployment still need verification. |

## Release gate
NEXORA is **not yet production-ready for public launch**. Public release requires the remaining critical features to be implemented or intentionally excluded, security review, real-user end-to-end tests, storage/media validation, privacy/legal documents, monitoring, backups, and an operational support/moderation process.
