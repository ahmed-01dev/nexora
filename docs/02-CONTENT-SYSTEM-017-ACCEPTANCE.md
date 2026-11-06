# NEXORA — CNT-017 Verification & Acceptance Matrix

**System:** CNT-017 — Post Creation & Publishing  
**Document:** 02 / Section C  
**Status:** test specification; not execution evidence  
**Baseline reviewed:** `IMPLEMENTATION_STATUS.md`, `API.md`, `ERD.md`, `SECURITY.md`, `08-ZERO-BUDGET-COSTS-RISKS.md` on 2026-11-06.

> This document defines what must be verified. A listed test is not evidence that it has passed. No APK/AAB build, deployment, migration, or live-provider test is performed by authoring this matrix.

## 1. Current evidence boundary

| Capability | Repository evidence | Acceptance interpretation |
|---|---|---|
| Text-only post creation | API contract lists text post insert; implementation status marks text-only creation implemented | Verify against a real authenticated session and database row |
| Public feed read | API contract lists public post reads; implementation status marks public feed implemented | Verify read visibility and pagination independently |
| Media selection and upload UI | Implementation status records profile/post/story signature checks and post upload rollback | UI/client checks do not replace server validation |
| Composer client limits | Implementation status records 10 files, 50 MiB/file, 100 MiB combined | Treat as client-side evidence only until server-side enforcement is verified |
| Media storage | SECURITY describes private `nexora-media` bucket and user-prefixed paths | Verify actual Storage policies and signed URL audience for each post visibility |
| Media processing | API lists upload-intent/process as required future endpoints | Pending; do not claim scanning, thumbnails, transcoding, or resumable upload |
| Idempotent publish | Not established by the current API/implementation evidence | Required design gate before reliable retry semantics can be signed off |
| Per-user server quotas and rate limits | Zero-budget document lists them as required controls; implementation evidence is incomplete | Pending verification |
| Moderation integration | Reports foundation exists; no proof that publish-time media scanning or full moderation pipeline is complete | Do not represent as complete |

## 2. Acceptance cases

### A. Identity, ownership, and authorization

| ID | Scenario | Expected result | Priority |
|---|---|---|---|
| CNT017-T01 | Signed-out client attempts to create a post | Request is rejected; no row or public media object is created | P0 |
| CNT017-T02 | Authenticated user submits a post with another user's `author_id` | Server ignores/rejects the supplied identity; author is derived from authenticated identity | P0 |
| CNT017-T03 | User attempts to attach a Storage object owned by another account | Request is rejected; no cross-account attachment is created | P0 |
| CNT017-T04 | User attempts to edit or delete another user's post | Denied by database/backend authorization | P0 |
| CNT017-T05 | Mutually blocked accounts access each other's restricted content | Visibility follows the block rules consistently for post rows and media URLs | P0 |

### B. Content validation and media boundaries

| ID | Scenario | Expected result | Priority |
|---|---|---|---|
| CNT017-T06 | Text contains only whitespace and no media | Rejected with a clear validation message | P0 |
| CNT017-T07 | Valid text-only post | One post is created and appears in the appropriate feed after server confirmation | P0 |
| CNT017-T08 | User selects more than 10 media files | Client prevents submission; server independently rejects an over-limit request | P0 |
| CNT017-T09 | One file exceeds 50 MiB | Client and server reject it; draft text remains available | P0 |
| CNT017-T10 | Combined media exceeds 100 MiB | Client and server reject it; no partial public post is created | P0 |
| CNT017-T11 | File extension/MIME claims image but file signature is invalid | Server-side validation rejects the object before public access | P0 |
| CNT017-T12 | Unsupported media type or malformed/corrupt file | Rejected safely; no untrusted content is served | P0 |
| CNT017-T13 | Image contains EXIF location metadata | Metadata is stripped or excluded from public delivery unless an explicit product decision permits it | P1 |
| CNT017-T14 | Private/friends-only post media is requested by an unauthorized viewer | Storage access is denied or a non-resolvable response is returned | P0 |

### C. Reliability, retry, and cleanup

| ID | Scenario | Expected result | Priority |
|---|---|---|---|
| CNT017-T15 | Device goes offline before submission | Local draft remains; UI does not claim the post was published | P0 |
| CNT017-T16 | Upload fails after some files were uploaded | No incomplete post is exposed; uploaded objects/metadata are rolled back or queued for safe cleanup | P0 |
| CNT017-T17 | Database insert fails after successful upload | No orphaned object remains indefinitely; cleanup is observable and retry-safe | P0 |
| CNT017-T18 | Server commits but client loses the response | Retry with the same idempotency identity returns the original post rather than creating a duplicate | P0 |
| CNT017-T19 | User taps Publish repeatedly during a slow request | Only one logical post is created; button/loading state is accessible and honest | P0 |
| CNT017-T20 | App closes during composition | Draft recovery follows the documented local persistence policy; no silent data loss | P1 |

### D. Privacy, abuse, and user feedback

| ID | Scenario | Expected result | Priority |
|---|---|---|---|
| CNT017-T21 | Private account creates a post | Default audience and feed visibility follow the account privacy policy | P0 |
| CNT017-T22 | Account is suspended/restricted from publishing | Server rejects publishing even if the client UI is bypassed | P0 |
| CNT017-T23 | User exceeds server-side publish/upload rate limit | Request is throttled with a safe retry indication; no partial post is exposed | P1 |
| CNT017-T24 | Post contains markup/script-like text | Rendered as inert text; no script/HTML execution | P0 |
| CNT017-T25 | Post is deleted by its owner | It disappears from non-owner feeds and its media access follows deletion policy | P0 |
| CNT017-T26 | Publish fails due to quota/provider outage | Explainable failure state; preserve draft; never show false success | P0 |

### E. Accessibility and localization

| ID | Scenario | Expected result | Priority |
|---|---|---|---|
| CNT017-T27 | Composer is used in Arabic RTL | Reading order, cursor movement, mixed Arabic/Latin text, and controls remain correct | P1 |
| CNT017-T28 | Composer is used with screen reader and large text | Controls have meaningful labels, focus order is logical, and errors are announced | P1 |
| CNT017-T29 | Upload is in progress or fails | Status is communicated in text, not color alone | P1 |

## 3. Required evidence for each test

A test may be marked **PASS** only when its evidence is attached to the verification record:

1. Test ID, date, app commit SHA, schema/migration version, and environment.
2. Test identity and role (use synthetic accounts; never record passwords or OTPs).
3. Exact request path/RPC and sanitized input shape.
4. Expected and actual result.
5. Database row/constraint or policy evidence where relevant.
6. Storage policy/object evidence for media cases.
7. Relevant sanitized logs and screenshot/video when UI behavior is under test.
8. Cleanup confirmation for failure/retry cases.

Do not paste service-role keys, access tokens, signed URLs that are still valid, phone numbers, or private user content into test evidence.

## 4. Release gates

### Gate A — Text-only MVP
- T01–T07, T15, T19, T21–T22, T24–T26 pass.
- Text-only publishing works with an authenticated account and public feed read.
- No claim of complete media publishing is made.

### Gate B — Media publishing
- T03, T08–T14, T16–T18, T23 and T25 pass.
- Server-side file signature validation, ownership checks, audience-aware Storage access, and cleanup are demonstrated.
- The 10-file / 50-MiB per-file / 100-MiB aggregate limits are enforced on the server, not only Flutter.
- Malware scanning, thumbnails, video transcoding, and resumable uploads remain explicitly marked pending unless separately implemented and verified.

### Gate C — Public launch
- All P0 cases pass; P1 cases have documented disposition.
- Independent security review and automated RLS tests with separate user identities are complete.
- Backup/restore, monitoring, moderation response, privacy/data deletion, and provider/quota readiness are signed off.
- No paid dependency is enabled without an explicit budget decision.

## 5. Known blockers and non-claims

- The current API document lists text post insert/read as implemented; it lists media upload-intent and processing endpoints as required future endpoints, not deployed services.
- Client-side media signature checks and upload rollback are documented, but they do not prove server-side scanning or enforcement.
- The implementation status records client limits of 10 files, 50 MiB per file, and 100 MiB combined. Server-side per-user quotas remain pending.
- The security baseline says malware scanning, server-side transcoding, thumbnails, and resumable uploads remain pending.
- The current API and status documents do not establish an idempotency contract for post publishing. Treat it as a required implementation gate, not an existing capability.
- This matrix does not authorize schema changes or production migrations. Reconcile migration history before any database write.

## 6. Traceability

- Functional behavior: `docs/02-CONTENT-SYSTEM-017.md`
- Current operations: `docs/API.md`
- Data relationships: `docs/ERD.md`
- Authorization/media baseline: `docs/SECURITY.md`
- Implementation evidence: `docs/IMPLEMENTATION_STATUS.md`
- Cost and provider constraints: `docs/08-ZERO-BUDGET-COSTS-RISKS.md`
- Cross-document conflicts: `docs/DOCUMENTATION-CONSISTENCY-AUDIT.md`
