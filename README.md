# NEXORA

NEXORA is an Arabic-first, privacy-conscious social platform for Android and web.

## Current implementation

- Supabase email/password registration and sign-in.
- Automatic profile creation through the database auth trigger.
- Profile display and editing (display name, username, bio, public/private account).
- Dark AMOLED interface with Arabic RTL layout.
- Android APK and web build workflow through GitHub Actions.

## Backend

Supabase project: configured separately from this repository. The current database includes profiles, posts, media, follows, likes, comments, and saves, with row-level security enabled.

## Required GitHub Actions secrets

Open **Settings → Secrets and variables → Actions** in this repository and add:

- `SUPABASE_URL`: the project's HTTPS URL.
- `SUPABASE_ANON_KEY`: the project's public anon/publishable client key.

Never add a `service_role` or secret key to the mobile/web app, source code, or GitHub variables. The client key is public by design; database access must remain protected by RLS.

Until both secrets are configured, the app intentionally displays a setup screen instead of attempting an unsafe or fake connection.

## Build

Latest configuration refresh: rebuild after updating repository Actions secrets.

Every push to `main` runs Flutter analysis and tests, then builds:
- `app-release.apk` for Android.
- The Flutter web application.

Download the `nexora-release` artifact from the successful run under the repository's **Actions** tab.

## Security principles

- Enforce authorization on the backend, not only in the client.
- Keep RLS enabled for user data.
- Use least-privilege database grants and storage policies.
- Do not claim end-to-end encryption until key management and protocol implementation have been independently reviewed.

## Development

The primary development workflow is Android phone + GitHub. The project targets zero-cost development using free tiers where practical.
