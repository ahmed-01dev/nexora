# NEXORA — Repository and Supabase Audit
Date: 2026-11-05
Repository: ahmed-01dev/nexora
Branch: main
Supabase project: wwdeexgkwpftyavbhiff

## Verified environment
- GitHub repository exists, is public, and the connected GitHub integration has push/admin permissions.
- Default branch: main.
- Supabase project status: ACTIVE_HEALTHY; PostgreSQL 17; region eu-west-3.
- Flutter dependencies include Riverpod, GoRouter, Supabase Flutter, image_picker, and video_player.
- Client configuration uses SUPABASE_URL and SUPABASE_ANON_KEY build defines. No service-role key is present in .env.example.
- Latest observed workflows on commit 031dd30e623b30b0f378dcc4738a6ea1107c3d54: Android/Web build SUCCESS, Flutter CI SUCCESS, Pages deploy SUCCESS.

## Existing implementation
The repository already contains Flutter app modules for friends, media upload/gallery, messaging, notifications, Reels, privacy settings, and stories. It also contains architecture, API, ERD, security, and implementation status documentation.
The app's own implementation status marks authentication, profiles, feed, posts, comments, stories, messaging, notifications, search, localization, and themes as partial; E2EE, Nearby, admin dashboard, monetization, livestreaming, and AI are pending or external dependencies.

## Supabase inventory
- 36 public base tables were enumerated.
- All 36 enumerated public tables have RLS enabled and at least one policy.
- Existing tables include profiles, posts, media, follows, friendships, blocks, comments, likes, reposts, saves, stories, conversations, conversation_members, messages, communities, notifications, reports, moderation_actions, moderation_appeals, staff_members, audit_logs, and user settings/devices.
- Seven migrations are registered in the connected project.
- Storage bucket nexora-media exists, is private, and has a 50 MiB per-object limit.
- No Edge Functions are currently deployed.
- Existing call tables are signaling records only; this does not establish working WebRTC calls.
- Existing message storage is not end-to-end encrypted.

## Advisor findings
### Security
- Supabase Auth leaked-password protection is disabled (WARN). This is an Auth dashboard/configuration action; it is not changed by a SQL migration.

### Performance
- One actionable missing foreign-key index: public.staff_members.created_by.
- 46 indexes are currently reported unused. Do not remove them based on this initial report: the project is newly active and workload history is insufficient to establish that they are unnecessary.

## Release blockers / next implementation order
1. Enable leaked-password protection in Supabase Auth and verify the setting.
2. Run authenticated multi-user RLS integration tests, including private profiles, blocks, message membership, and storage ownership.
3. Validate current app flows on real authenticated accounts and small Android screens.
4. Finish relationship request UX, feed pagination/mixed content, and notification preferences.
5. Implement real media processing and push delivery only after provider configuration.
6. Treat E2EE, WebRTC/TURN, live streaming, payments, and admin RBAC as separate security-reviewed delivery phases.

## Preservation notes
No existing user records or tables were deleted. No service-role or secret key was added to the repository. No claim of production readiness is made by this audit.
