# NEXORA — Documentation Consistency Audit
**Audit date:** 2026-11-06  
**Scope:** repository documentation currently present on `main`, plus new design specification `02-DETAILED-SPECS-I-J-K.md`.  
**Purpose:** identify contradictions before implementation expansion. This is a documentation audit only: no app build, APK, migration, or runtime change.

## Executive result
The repository has useful architecture, API, ERD, security, implementation-status, provider-setup, and roadmap material, but it is not yet a single internally consistent master specification. Several documents describe different implementation snapshots. Treat the dated, feature-by-feature `IMPLEMENTATION_STATUS.md` and `IMPLEMENTATION_AUDIT_2026-11-05.md` as the best current implementation evidence, and treat architecture/API/ERD documents as needing synchronization. Do not infer that a table means a complete user workflow.

## Findings requiring correction

### DOC-001 — Authentication implementation conflict
- `README.md` describes phone-first signup/login using SMS OTP, with email/password as alternative.
- `IMPLEMENTATION_STATUS.md` says phone OTP is the default UI path, but SMS provider delivery, cost, and real-device verification remain external/unverified; email/password is an alternative.
- `API.md` lists only email/password as current implemented Auth operation.
- `ARCHITECTURE.md` says the current Flutter app has email/password auth.
**Resolution:** distinguish *UI path*, *configured provider*, and *verified end-to-end delivery*. Canonical wording: phone-first OTP UI exists; SMS delivery is not production-verified; email/password path exists as alternative; account linking, recovery hardening, MFA and OAuth remain pending. Do not claim phone auth is fully operational until real-device delivery and account lifecycle tests pass.

### DOC-002 — Current feature scope conflict
- `ARCHITECTURE.md` describes only basic profiles, text posts, basic follows and simple feed as current.
- `IMPLEMENTATION_STATUS.md` documents substantially more: comments, media, reposts, bookmarks, stories, messaging, communities, notifications, search, nearby, moderation and themes, each with different completion states.
**Resolution:** use `IMPLEMENTATION_STATUS.md` as the feature-level status source, updated with an audit date. Rewrite Architecture's “Current implementation boundary” as a short summary and link to the status document. Do not label all listed features complete; retain Partial/Foundation/Pending distinctions.

### DOC-003 — API contract inventory is stale/incomplete
- `API.md` calls email/password, profiles, text posts, follows, friendships, privacy and likes the current operations, but omits many implemented operations described in the status document.
- It also lists messaging, stories, communities, notifications and reports as database-backed contracts with client integration pending, while the status document now marks some of those workflows Partial or implemented in parts.
**Resolution:** split API documentation into three explicit groups: (1) verified client-used contracts, (2) database foundation with incomplete client integration, (3) planned trusted endpoints. For every item record source file/function, DB object, auth boundary, and test evidence. Never list a planned endpoint as deployed.

### DOC-004 — ERD is not a complete schema inventory
- `ERD.md` presents a useful core diagram but omits objects described in implementation status, including reposts, hashtags/post_hashtags, user devices, moderation actions/appeals, nearby-location storage, and other supporting tables.
- It does not state the exact migration version that produced each table.
**Resolution:** label current ERD as a partial conceptual diagram until generated/verified against the live schema. Add a table inventory with schema/table, migration source, RLS status, client grants, owner, and feature status. Do not run migration push/reset/replay while remote migration history is out of sync.

### DOC-005 — Security documentation and product status need a shared release checklist
- `SECURITY.md` documents strong RLS/grant hardening and still lists critical gaps: independent penetration test, authenticated RLS integration tests, media scanning/transcoding, E2EE, WebRTC/TURN, admin RBAC/dashboard, monitoring, backup/restore.
- `IMPLEMENTATION_STATUS.md` has detailed partial feature status but the release gate should map each security gap to an owner/test.
**Resolution:** preserve all known gaps; add explicit release-blocker IDs and test IDs. Do not claim production readiness because table-level RLS is enabled.

### DOC-006 — Phone-first vision vs zero-budget dependency
- SMS OTP delivery is a provider-dependent external service and may incur charges or have quota limits. It is not guaranteed free.
**Resolution:** keep the phone-first UI only if the actual provider configuration is approved and tested. If SMS is unavailable, show an honest unavailable state or use a separately verified email/guest path. No fake OTP and no silent paid service activation.

### DOC-007 — Document 02 coverage is incomplete in repository
- The current `docs/` directory did not contain the original 118-system catalog or a complete detailed specification for all systems.
- New `02-DETAILED-SPECS-I-J-K.md` covers slots 63–90 based on the handoff allocation, and explicitly marks titles/numbering for reconciliation.
**Resolution:** restore/add canonical Document 01 and the missing detailed sections; verify all 118 IDs and names before calling Document 02 complete. Do not silently rename or renumber systems.

### DOC-008 — Release/build language can mislead
- GitHub workflows can run analysis/tests or create debug/release artifacts, but source CI does not prove APK installation, store signing, real-device behavior, SMS, push, or RLS integration.
- Android package ID is documented as `com.example.nexora`, requiring final unique ID and matching Firebase registration before public release.
**Resolution:** each workflow and README statement must state artifact type, signing status, environment and what it does not verify. Debug APK is test-only. No APK build is to be initiated while the user’s current instruction is to complete code/files before building the application.

### DOC-009 — Migration history is a hard operational blocker
- `IMPLEMENTATION_STATUS.md` reports 43 remote migration records and 42 local SQL migration files, with version/name alignment incomplete.
**Resolution:** do not use `supabase db push`, reset, or replay. First obtain exact remote migration SQL/history, map each remote version to repository source, create and verify recoverable backups, then plan a non-destructive reconciliation. This is not a documentation-only cleanup; it requires explicit operational review.

### DOC-010 — Cost/availability claims need a provider inventory
- Free-tier availability, quotas, backup retention, SMS delivery, push delivery and worker execution are distinct dependencies.
**Resolution:** every integration must have provider, current plan, quota, credentials owner, data shared, cost trigger, fallback, test evidence, and disable switch. No assumption that “free SDK” means free hosting or unlimited use.

## Canonical source-of-truth hierarchy
1. **Actual deployed schema and grants** verified read-only against the connected Supabase project, with migration provenance.
2. **Implementation status and audit evidence** for whether code paths exist and what tests actually ran.
3. **Feature-specific API contracts** for operation names and server/client boundaries.
4. **Architecture/security specifications** for intended design and mandatory constraints.
5. **Roadmap and catalog** for intended scope and priority.
6. **UI text/README marketing copy** must never override technical evidence.

If sources disagree, mark the item **CONFLICT / NOT VERIFIED** until reconciled. Never choose the more optimistic claim.

## Required reconciliation sequence
1. Restore canonical Document 01 (all 118 exact IDs and titles).
2. Reconcile Document 02 sections A–M, including the new I–K section, and mark missing details explicitly.
3. Generate a live schema/table/RLS/grant inventory and map each table to its migration source.
4. Reconcile API.md against actual Dart calls, SQL RPC definitions, and Edge Function deployments.
5. Update Architecture's current-state description to link to the dated implementation status.
6. Map Security release blockers to acceptance test IDs and test evidence.
7. Reconcile remote migration history before any schema-changing operation.
8. Review provider inventory, quotas, secrets ownership, and Zero Budget fallbacks.
9. Only after all documentation and source files are complete, reviewed and tested should an application build be considered.

## Current non-build commitment
Until the complete source/code/file set is prepared and reviewed, do not dispatch APK/AAB/Web packaging workflows or call a debug artifact an application delivery. Source-only checks may be used only when needed to validate source changes and must be described as such.


## Addendum — CNT-017 documentation pass (2026-11-06)

The following artifacts now exist on the documentation branch:

- `02-CONTENT-SYSTEM-017.md`: functional working specification.
- `02-CONTENT-SYSTEM-017-ACCEPTANCE.md`: 29-case verification matrix; test plan only, not pass evidence.
- `02-CONTENT-SYSTEM-017-PUBLISH-CONTRACT.md`: client state machine, authority boundaries, error classes, invariants, and implementation gates.
- `README.md`: links the three CNT-017 artifacts and explicitly pauses APK/AAB/Web build workflows during source/specification completion.

### CNT-017 evidence reconciliation

| Topic | Current documented evidence | Required disposition |
|---|---|---|
| Text-only creation | API and implementation status list text-post insertion as implemented | Keep as implemented in status, but require authenticated integration evidence before release sign-off |
| Media selection/upload | Flutter-side media selection/upload and rollback are documented | Do not equate client validation/rollback with server-side inspection |
| File limits | 10 files / 50 MiB each / 100 MiB aggregate appear as client limits | Do not claim server enforcement until verified at the trusted boundary |
| Private media | Private bucket and audience-aware policies are described | Verify actual deployed policies and signed URL behavior read-only |
| Processing/scanning | Media process endpoint is listed as planned; scanning/transcoding/thumbnails remain pending | Keep pending; do not create UI claims that imply these services exist |
| Idempotency | No deployed idempotent publish contract is established in API/status evidence | Treat ambiguous timeout as unknown and reconcile before retry; implement/test server deduplication before claiming retry safety |
| Orphan cleanup | Client rollback is documented for failed multi-file upload | Verify database/storage outcomes; do not claim a durable background cleanup queue without evidence |

### Next implementation evidence gates

1. Locate the exact Flutter composer source file and call chain; record file paths and function names in a traceability table.
2. Locate the exact post insert and media upload calls; compare their payloads with the actual schema and Storage policies.
3. Verify author identity is derived from the authenticated session and cannot be overridden by client payload.
4. Verify cross-user Storage attachment attempts with two synthetic authenticated accounts.
5. Verify private/friends-only post media access matches post-row visibility, including blocks and soft deletion.
6. Verify the timeout-after-commit case; until a server-enforced idempotency mechanism exists, do not label publish retries safe.
7. Attach reproducible test evidence before changing any status from Partial/Pending to Implemented.

### Scope guardrails

- The original 118-system catalog and complete Document 02 remain absent from the repository snapshot reviewed for this branch. Do not fabricate systems 18–27 or claim 63–90 titles are canonical.
- The older 1–50 master prompt numbering is a separate catalog and must not be merged with Document 02's 1–118 numbering.
- Migration history reconciliation remains a hard stop for schema writes.
- This addendum authorizes no Supabase mutation, migration, provider activation, application build, or artifact release.


## Addendum — API, architecture and ERD reconciliation (2026-11-06)

Three documentation corrections were committed on this branch after comparing the files with the dated implementation-status record:

- `API.md` now separates documented client-used operations, database foundations, and proposed endpoints. It explicitly marks planned endpoints as not deployed and adds a contract-change evidence checklist.
- `ARCHITECTURE.md` no longer describes the current Flutter implementation as only email/password + basic profiles + text posts + follows + simple feed. It points to the dated implementation status and records the verified partial-feature boundaries and provider limitations.
- `ERD.md` now explicitly identifies itself as a partial conceptual diagram and defines the fields required for a future read-only live-schema inventory.

### Remaining verification work

These edits reconcile documentation wording only. They do **not** establish source-level traceability or runtime correctness. Still outstanding:

1. Inspect the Flutter source tree and map each API operation to exact Dart file/method and request shape.
2. Read-only inspect deployed PostgreSQL tables, columns, functions, grants, RLS policies and Storage policies.
3. Map every remote migration record to the exact local SQL file; current history mismatch remains a hard stop.
4. Generate a complete ERD and inventory from the verified live schema, not from this conceptual document.
5. Run authenticated integration tests with separate synthetic users only after test identities/environment are safely prepared and without weakening production policies.
6. Reconcile remaining implementation-status claims against code and test artifacts.

No Supabase writes, migrations, builds, provider activation, or release actions were performed as part of this documentation pass.


## Addendum — static source traceability pass (2026-11-06)

A new `SOURCE-TO-CONTRACT-TRACEABILITY.md` records inspected source locations and observed client operations for authentication, feed/follows, hashtags, comments, friendships, communities, media, messaging, nearby discovery, notifications/push, privacy and moderation.

### Scope and limits

- The source snapshot inspected was the default `main` branch; this is a static source audit, not a claim that those source files were modified in this documentation PR.
- Concrete client call sites and RPC/table names are recorded where observed. No unverified SQL signatures, return schemas or deployed-state claims were invented.
- The push Edge Function source reads service secrets at runtime and sends through FCM HTTP v1; deployment secrets and actual delivery remain unverified.
- Nearby client code sends coordinates to a trusted RPC. The returned result shape and SQL implementation still require inspection to confirm approximate-only disclosure.
- Media signature checks and upload size limits exist in client code; they do not replace server-side scanning or server-enforced quotas.

The traceability file is linked from README. The next gate remains read-only inspection of SQL function definitions, grants, RLS/Storage policies and migration history. No database writes, migrations, provider activation, builds or packaging were performed.


## Addendum — focused SQL contract trace (2026-11-06)

Added `SQL-CONTRACT-TRACEABILITY.md` after static inspection of the feed paging, nearby discovery, community invite, and push-notification migrations plus the corresponding client/Edge Function files.

Confirmed from the local `main` migration directory listing: **42 SQL files**. The previously recorded remote migration history count is **43**. The mismatch therefore remains; this pass does not identify or repair the missing mapping.

Notable contract evidence:
- Feed paging is a SECURITY INVOKER RPC with bounded page size and authenticated-only execute.
- Nearby discovery persists rounded coordinates in a private table and returns coarse distance bands; public wrappers are SECURITY INVOKER.
- Community invite direct table access is revoked; trusted functions enforce owner, expiry and use limits.
- Push dispatch is trigger → Vault webhook secret → Edge Function → FCM HTTP v1; successful real-device delivery remains unverified.

These are local-source findings only. No live database catalog query, schema write, migration, secret change, provider activation or build was performed.

## Addendum — live Supabase and migration-source reconciliation (2026-11-06)

### Media authorization: live state versus local source

A read-only catalog query against the connected NEXORA Supabase project confirmed that the live `private.can_read_media_path(text)` definition contains friend-only post access, private-account story gating, soft-deleted-post denial for non-owners, block checks, and non-deleted-message/conversation-membership checks.

The local GitHub migration `20261105225000_hide_deleted_message_attachments.sql` contains an older/different replacement that omits some of those checks. Therefore this is **local migration source/history drift**, not a demonstrated current live Storage vulnerability. The temporary manually drafted migration was removed from this branch; no new migration should be created until source history is reconciled using the proper local Supabase CLI workflow.

The live helper is owned by `postgres`, is `SECURITY DEFINER`, uses an empty `search_path`, and its ACL lists `postgres` and `authenticated`. Archived/expired story filtering occurs before the owner/viewer branch, so such media is denied to everyone, including the owner.

### Block helper and private schema exposure

The live database contains `private.is_blocked_between(a uuid, b uuid)`. It is owned by `postgres`, `SECURITY DEFINER`, uses an empty `search_path`, and checks `public.blocks` in both directions. Its ACL grants EXECUTE to `authenticated`.

The local foundation migration grants authenticated USAGE on schema `private`, while RLS policies call this helper. This is expected only if the `private` schema is not exposed through PostgREST. A read-only `current_setting('pgrst.db_schemas', true)` query returned NULL, so the configured exposed-schema list was not verified. Confirm in Supabase Data API settings that `private` is excluded. Do not revoke EXECUTE blindly because policy evaluation depends on it.

### Remote/local migration inventory

Read-only listings returned **43 remote migration records** and **42 SQL files on GitHub main**. Name/version comparison found:

- 21 exact version-and-name matches.
- 14 same-name migrations with different timestamps.
- 8 remote-only names.
- 7 local-only names.

The full names and 14 timestamp mappings are recorded in `docs/SQL-CONTRACT-TRACEABILITY.md`. Remote-only foundation/security migrations may contain the original source for helpers missing from the local source tree, but that is not yet proven. Do not run `db push`, reset, replay, repair migration history or apply new migrations until exact SQL source and version mapping are recovered and a recoverable backup is verified.

### Supabase advisors

Read-only advisors returned:

- **Security warning:** Leaked Password Protection is disabled in Supabase Auth. Review and enable it in Auth password security settings. [Remediation guide](https://supabase.com/docs/guides/auth/password-security#password-strength-and-leaked-password-protection). No Auth setting was changed.
- **Performance info:** 43 indexes were reported unused at the observation time. This is not a deletion recommendation; measure query plans under realistic workload before considering removal. [Unused-index guidance](https://supabase.com/docs/guides/database/database-linter?lint=0005_unused_index).

### CI/build workflow guard

Static inspection found only `.github/workflows/flutter-ci.yml` and `.github/workflows/android-preview.yml`; no AAB/Web release workflow was present. The work branch removes the preview workflow's automatic push trigger and adds a required `confirm_source_complete` boolean input. It also sets `permissions: contents: read` on Flutter CI. No workflow was dispatched and no build was run.

All Supabase checks in this addendum were read-only. No database mutation, migration, secret change, Auth setting change, provider activation, CI dispatch or APK/AAB/Web build was performed.

### Live object-presence cross-check

Read-only catalog checks also confirmed that `public.community_channels`, `public.community_invites`, the community-invite RPC family, `get_my_conversation_previews`, `get_feed_page`, `get_my_notification_page`, `reposts_user_post_unique_idx`, and `profiles_username_lower_key` exist in the live database. This shows that some local-only/timestamp-mismatched migration names correspond to objects already present remotely; it does not prove exact source-file provenance. Do not apply them again based on filenames alone.

### Live RLS and Storage baseline

Read-only catalog checks found RLS enabled on all 38 ordinary `public` tables and the 1 ordinary `private` table. The `nexora-media` bucket is private, has a 50 MiB object limit, and allows a wider MIME set than the restrictive message-attachment policy. Selected live policies enforce post visibility/block checks, story visibility, non-deleted message attachment reads, image-only message attachment inserts up to 10 MiB, denied direct invite-table access, and owner-only nearby-location rows. This is a policy-definition review, not authenticated integration testing.

### Live push Edge Function parity

Supabase reports `send-push-notification` as ACTIVE version 6 with `verify_jwt = false`. The deployed `index.ts` content was fetched read-only and compared with `main/supabase/functions/send-push-notification/index.ts`; the files match exactly (7,677 characters). The function performs its own authentication: trusted webhook-secret path or bearer-token `auth.getUser` path, with the user path restricted to notifications where the caller is the actor. Flutter uses Firebase Messaging `onRegistered` to obtain a Firebase Installation ID (FID), stores it in `user_devices.push_token`, and the Edge Function sends with FCM HTTP v1 `message.fid`, which matches the FID registration model. Secret values and actual device delivery were not tested.
