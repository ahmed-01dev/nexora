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
- [x] Basic follow insertion/deletion.
- [x] Central Flutter error presentation/logging.
- [x] Existing CI run passed analysis, tests, Android release APK build, and web build (run 41929549503).
- [x] Additive PostgreSQL foundation migration applied and verified for RLS on all newly added tables.
- [x] Anonymous role has no SELECT privilege on the newly added social tables.

## Database foundation added
- [x] Friendships and blocks.
- [x] Conversations, conversation members, messages, attachments, reactions.
- [x] Notifications.
- [x] Stories and story views.
- [x] Communities and community membership.
- [x] Reports.
- [x] Call sessions and participants (signaling records only; not WebRTC).
- [x] Private account settings and user preferences.
- [ ] Storage buckets, upload policies, and media pipeline.
- [ ] RLS integration tests with real authenticated test users.

## Product feature status
| Feature | Status | Notes |
|---|---|---|
| Authentication | Partial | Email/password only; no OAuth, phone OTP, MFA, passkeys, or device center. |
| Profiles | Partial | Basic text profile; no avatar/cover upload or profile highlights. |
| Followers | Partial | Basic follow action; follow state initialization and private follow-request UX need work. |
| Friends | Foundation | Database table/policies exist; full request/accept UI pending. |
| Feed | Partial | Basic public text feed; no ranking, pagination cursor, offline cache, or mixed content. |
| Posts | Partial | Text only; media, polls, drafts, scheduling, edit/restore pending. |
| Comments | Partial | Existing table; complete nested/reaction/moderation UX pending. |
| Stories | Foundation | Tables exist; upload, viewer, archive, close-friends, expiry worker pending. |
| Reels/Video | Pending | No transcoding, adaptive playback, or creator workflow. |
| Messaging | Foundation | Tables and RLS exist; realtime chat UI, attachment pipeline, delivery/read UX pending. |
| E2EE | Pending | No cryptographic protocol or key lifecycle implemented. |
| Voice/video calls | Foundation | Call records only; WebRTC, STUN/TURN, push call delivery pending. |
| Communities | Foundation | Tables and RLS exist; discovery, channels, admin workflows pending. |
| Notifications | Foundation | Table exists; triggers, delivery worker, push provider pending. |
| Search | Partial | Basic profile search only. |
| Nearby | Pending | Must remain disabled until consent, approximate geolocation, and safety protections are implemented. |
| Moderation | Foundation | User reports table; admin queue, enforcement, appeals, and audit workflow pending. |
| Admin dashboard | Pending | No trusted RBAC or admin web console yet. |
| Monetization | Pending | No payment provider, tax, payouts, or legal readiness. |
| Live streaming | Pending | No streaming provider/ingest infrastructure. |
| AI features | Pending | No model integration or consent controls. |
| Localization | Partial | Arabic RTL baseline; English and additional locale resources pending. |
| Themes | Partial | AMOLED direction being established; persisted light/pink/custom theme selector pending. |
| PWA | Partial | Web build exists; installability, offline strategy, and deployment still need verification. |

## Release gate
NEXORA is **not yet production-ready for public launch**. Public release requires the remaining critical features to be implemented or intentionally excluded, security review, real-user end-to-end tests, storage/media validation, privacy/legal documents, monitoring, backups, and an operational support/moderation process.
