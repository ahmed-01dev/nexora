# NEXORA — BEYOND SOCIAL

NEXORA is an Arabic-first, AMOLED-first social platform being developed in phased releases with Flutter and Supabase.

## Current implementation

The repository contains a working Flutter Android/Web codebase and a Supabase PostgreSQL backend. Implemented areas include:

- Phone-first signup/login using SMS OTP with Egyptian and international phone normalization; email/password is an alternative.
- Profiles, profile media, public/following feeds, posts, likes, reposts, bookmarks, comments, and hashtags.
- Follow/friend requests, account blocking, privacy controls, and opt-in approximate nearby discovery.
- Direct messaging with realtime updates, read state, and image attachments.
- Stories, vertical public-video feed, communities, channels, reports, moderation queue, and appeals workflows.
- In-app notification center and per-category notification preferences.
- Firebase Cloud Messaging integration code, deployed Supabase Edge Function, and database webhook trigger. Real-device push delivery still requires valid Firebase/Supabase Edge Function secrets and an Android device registered for push.
- AMOLED, light, and pink theme options.

See [implementation status](docs/IMPLEMENTATION_STATUS.md) for the feature-by-feature state and remaining work. Implemented code does not mean every workflow has passed end-to-end testing with real users/devices.

## Known production gaps

NEXORA is not yet production-ready for public launch. Important remaining work includes:

- End-to-end tests using separate authenticated users, real Android devices, and browser sessions.
- SMS provider configuration, phone OTP delivery verification, account linking, MFA, and recovery hardening.
- Push delivery verification on a registered Android device; email notifications are not implemented.
- WebRTC media transport, STUN/TURN, and reliable incoming-call delivery. Current call records alone are not voice/video calling.
- E2EE is not implemented. Direct messages are server-readable; do not describe them as end-to-end encrypted.
- Media transcoding, adaptive bitrate, thumbnails, malware scanning, resumable uploads, and CDN processing.
- Full admin dashboard, independent penetration test, crash monitoring, backup/restore drills, legal/privacy review, and operational moderation procedures.
- Full localization beyond the current Arabic-first RTL interface.

## Backend and secrets

The connected Supabase project is configured outside the Flutter client. The client may use only the public Supabase URL and anon/publishable key.

Never commit or expose:
- Supabase `service_role` or secret keys.
- Firebase service-account JSON/private keys.
- Database passwords, signing keys, OAuth client secrets, or TURN credentials.

Store server-side credentials in Supabase Edge Function secrets or a dedicated secret manager. The Firebase Android `google-services.json` contains app configuration, not an Admin SDK private key; keep it in the intended project configuration path and do not confuse it with the service-account JSON.

## Database

The `supabase/migrations/` directory contains the schema and security changes applied during development. Public tables have RLS enabled; verify grants and policies after every schema change. Nearby discovery is opt-in, stores rounded coordinates in a private schema, returns coarse distance bands, and expires stale presence after 24 hours.

## Android preview APK

- The Android platform folder is generated during the preview build if it is not committed.
- The workflow uses Flutter 3.47.9 and Java 17, runs analysis and tests, then builds a **debug-only APK**.
- Open **Actions → NEXORA Android Preview APK** and download the artifact named `nexora-debug-apk`.
- This artifact is for installation/testing only. It is not signed for Google Play and does not make provider-dependent features production-ready.

## CI and release builds

- `.github/workflows/flutter-ci.yml` runs Flutter dependency installation, static analysis, and tests on pushes and pull requests.
- `.github/workflows/android-web-build.yml` is a manual release workflow. It builds Android APK/AAB and Flutter Web only when explicitly dispatched.
- Do not run the release workflow until the source/configuration audit is complete and release is explicitly approved.

## Project engineering documents

- [08 — Zero-budget costs, dependencies and risks](docs/08-ZERO-BUDGET-COSTS-RISKS.md)
- [09 — Implementation roadmap](docs/09-IMPLEMENTATION-ROADMAP.md)
- [10 — Acceptance, quality and performance testing](docs/10-ACCEPTANCE-AND-PERFORMANCE-TESTING.md)

## Development principles

- PostgreSQL RLS and trusted server functions are the authorization boundary.
- Never trust client-supplied ownership, role, recipient, or moderation fields.
- No fake users, followers, messages, likes, or verification.
- No false E2EE or calling claims.
- Keep server secrets server-side.
- Label incomplete integrations accurately and test them before launch.
