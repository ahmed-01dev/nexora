# Document 09 — Implementation Roadmap

Status: Execution baseline  
Delivery model: One vertical slice at a time  
Target: A secure, testable Android-first MVP before broad platform expansion.

## 1. Execution principles
- Build working end-to-end slices, not disconnected screens.
- Preserve existing user data and schema. No destructive reset or bulk migration replay.
- Review current Supabase state and migration history before every database change.
- Keep all server secrets server-side.
- No fake users, fake OTP success, fake messages, fake counts, or demo data presented as production data.
- Keep non-funded integrations behind disabled feature flags.
- Do not start a later slice until the current slice passes its acceptance gate.

## 2. Priority tiers
### P0 — MVP core
Startup/configuration diagnostics; Guest and verified Email path where available; session restore; profile and privacy; follow/friend basics and blocking; text/image posts with limits; feed pagination; likes/comments/bookmarks; profile and public-content search; reports/moderation baseline; account deletion; RLS tests; Arabic RTL and error/loading/empty/offline states.

### P1 — Post-MVP stabilization
Direct text messaging and bounded attachments; in-app notifications and tested FCM push; communities and channels; discovery and creator tools; accessibility and localization improvements.

### P2 — Future expansion
Voice/video calling, live streaming, AI, ads, commerce, payments, advanced analytics, developer APIs and webhooks. Conditional on infrastructure, legal review, safety review, and an approved cost plan.

## 3. Phases and gates

### Phase 0 — Repository and environment stabilization
Confirm repository, branch, workflows, and protected assets. Pin Flutter/Dart versions. Fix analyzer and test failures. Keep secrets out of source control. Confirm generated Android/Web platform strategy. Add formatting, analysis, unit/widget tests, and CI artifacts where appropriate.
Gate: Clean CI on a reviewable branch; no database changes.

### Phase 1 — Identity vertical slice
Startup configuration and honest service availability. Guest mode if supported. Email/password only after delivery and recovery are confirmed. Phone OTP remains disabled until a supported SMS provider is configured and real-device delivery is proven. Implement session restoration, sign-out, profile creation/editing, username uniqueness, and privacy settings.
Gate: Two independent test accounts can sign in, edit their own profiles, sign out, and restore sessions. Unauthorized writes are rejected by database policy.

### Phase 2 — Social graph vertical slice
Follow/unfollow and pending/accepted states; friend requests; blocking; private-profile visibility; people search; opt-in nearby discovery only with clear consent.
Gate: Multi-user tests prove block and privacy rules apply to rows, media, RPCs, and relationship actions.

### Phase 3 — Content vertical slice
Text posts; bounded image upload; server-enforced ownership and media access; feed pagination; likes/comments/bookmarks; soft deletion; reports; upload failure recovery and duplicate prevention.
Gate: A user can create and view content; another user sees only content allowed by RLS; failed uploads do not silently create partial records.

### Phase 4 — Discovery and notifications
Search profiles, public posts, and hashtags; server pagination and indexes; in-app notification center and preferences; FCM registration and real-device delivery test. Show unavailable state if secrets or device registration are missing.
Gate: Search respects visibility; push is proven on a registered device or clearly disabled.

### Phase 5 — Messaging
Conversation creation and membership; text send/read; stable ordering; bounded realtime; retry/idempotency; offline states; strict attachment limits; block-aware access.
Gate: Two test users can message; a third cannot read messages or attachments; failed sends are visible and safely retryable.

### Phase 6 — Communities and moderation
Public/private/invite-only communities; membership and roles; channel chat; reports, queue, appeals, audit records; staff role enforcement at the database boundary.
Gate: Non-staff cannot access staff queues or actions; sensitive moderation actions are auditable.

### Phase 7 — MVP stabilization
Device/browser testing; Arabic RTL and responsive layout; accessibility; RLS/Storage adversarial tests; account deletion/export; error visibility; operational runbook; privacy/terms/moderation readiness; backup/restore drill; migration-history reconciliation.
Gate: All in-scope P0/P1 tests pass; no critical security defect; external dependencies disclosed.

### Phase 8 — V1
Improve messaging, communities, creator tools, discovery, localization, accessibility, and performance based on measured feedback.

### Phase 9 — V2 / scale
Only after product-market evidence and a funded operational plan: calling, streaming, AI, ads, payments, advanced integrations, and service decomposition.

## 4. Per-slice engineering sequence
1. Read feature specification.
2. Review schema, grants, RLS, Storage policies, and migration history.
3. Define API/RPC/event contracts.
4. Add reviewed additive migration if needed.
5. Implement repository/data layer.
6. Implement domain logic and validation.
7. Implement UI states.
8. Add unit, widget, integration, and security tests.
9. Run formatting, analyzer, and CI.
10. Review logs and regressions.
11. Update implementation status and known issues.
12. Merge only after acceptance gate passes.

## 5. Time estimate
For one beginner developer working primarily from an Android phone, estimates are uncertain:

| Workstream | Rough estimate |
|---|---:|
| Stabilization and setup | 1–3 weeks |
| Identity | 2–4 weeks |
| Social graph | 2–4 weeks |
| Content | 3–6 weeks |
| Discovery and notifications | 2–4 weeks |
| Messaging | 3–6 weeks |
| Communities and moderation | 3–5 weeks |
| MVP stabilization | 3–6 weeks |

Rough total: 19–38 weeks of consistent work, not a delivery promise. This excludes most P2 features and provider/legal work.

## 6. Repository organization
Preserve the existing repository structure where practical. Prefer incremental feature folders and migration files over large rewrites. Keep shared configuration in lib/core, vertical slices in lib/features, reviewed SQL in supabase/migrations, trusted functions in supabase/functions, tests in test, docs in docs, and CI/release workflows in .github/workflows.

## 7. Definition of Done
A slice is complete only when its UI, data contract, authorization, error states, tests, documentation, and CI checks agree. A screen or database table alone is not a completed feature.
