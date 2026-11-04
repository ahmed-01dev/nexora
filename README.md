# NEXORA — BEYOND SOCIAL

NEXORA is an AMOLED-first, Arabic-first social platform under active phased development.

## Current verified app capabilities
- Supabase email/password registration and sign-in.
- Basic profile display and editing.
- Public text posts and feed.
- Follow/unfollow with server-side checks for private profiles and blocks.
- Basic privacy center for profile visibility and who can start direct messages.
- Direct text conversations with realtime message updates and read timestamps.
- In-app notification records when a new direct message is sent.
- Private image/video upload for posts, with signed URL viewing in the feed.
- Basic vertical video feed for public video posts.
- AMOLED-first theme, with light and optional pink theme definitions.

## Important limitations
NEXORA is not yet production-ready for public launch. Current gaps include:
- Stories, friend-request UI, full groups/communities, and notification center UX.
- E2EE is not implemented. Direct messages are server-readable; the UI says so.
- Voice/video calling has database signaling records only; no WebRTC/STUN/TURN service.
- Video transcoding, adaptive bitrate, thumbnail generation, malware scanning, and CDN processing are not deployed.
- No admin dashboard/RBAC, appeals workflow, push provider, monetization, livestreaming, or AI integrations.
- Arabic RTL is the current UI language; full English/French/Spanish/German localization is pending.
- Automated RLS tests with distinct authenticated users and an independent penetration test are pending.

See [implementation status](docs/IMPLEMENTATION_STATUS.md), [architecture](docs/ARCHITECTURE.md), [ERD](docs/ERD.md), [API boundaries](docs/API.md), and [security baseline](docs/SECURITY.md).

## Backend
Supabase project is configured outside the repository. Add the following GitHub Actions repository secrets:

- `SUPABASE_URL`: the project's HTTPS URL.
- `SUPABASE_ANON_KEY`: the public anon/publishable client key.

Never add a `service_role` or secret key to the mobile/web app, source code, or GitHub Actions build arguments.

## Database migrations
- `supabase/migrations/20261105000100_nexora_social_foundation.sql` — additive social graph, messaging, notifications, stories, communities, reports, call records, privacy settings, RLS, private storage, and restricted RPCs.

The migration is idempotent for the current schema and was applied to the connected Supabase project. Verify RLS and grants after any future changes.

## Build
GitHub Actions runs Flutter analysis/tests, Android APK, Android App Bundle, and Flutter Web builds. Download artifacts from the successful run in the repository's Actions tab.

The GitHub Pages deployment workflow is configured, but repository Pages enablement must succeed before a public URL is available.

## Development principles
- Backend RLS is the authorization boundary.
- No fake followers, messages, likes, or verification.
- No false E2EE claims.
- Keep server secrets server-side.
- Mark incomplete integrations explicitly.
- Keep the app buildable at every phase.
