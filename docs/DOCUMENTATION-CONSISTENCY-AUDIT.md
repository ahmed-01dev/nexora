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
