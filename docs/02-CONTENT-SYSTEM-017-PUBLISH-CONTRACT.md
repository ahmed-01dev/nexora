# NEXORA — CNT-017 Publish Flow & Client/Server Contract

**System:** CNT-017 — Post Creation & Publishing  
**Status:** Engineering contract proposal; implementation status must be verified independently  
**Branch:** `docs/specs-i-j-k`

> This document deliberately does not invent database column names, RPC names, deployed Edge Functions, or response payloads. The current repository describes direct Supabase Auth/PostgREST access with RLS as the authorization boundary; a standalone backend and the planned media upload-intent/process endpoints are not currently established as deployed services.

## 1. Contract boundary

### Verified from repository documentation
- The client uses Supabase Auth and PostgREST with the public client key.
- RLS is the database authorization boundary.
- Text-only post insertion and public-feed reads are listed as implemented.
- Post media selection/upload UI, private Storage paths, signed media display, and failed multi-file upload rollback are listed in implementation status.
- Server-side media scanning, malware scanning, processing/transcoding, thumbnails, resumable uploads, and per-user server quotas remain pending.
- The API inventory does not establish a deployed idempotent publish endpoint.

### Not implied by this contract
- No new API route is declared deployed.
- No migration, table, column, RPC, Storage policy, or Edge Function is created by this document.
- No client-supplied `author_id`, moderation state, counters, or trusted timestamps may become authoritative.
- A successful Storage upload alone does not mean a post has been published.

## 2. Logical publish operation

The UI may expose one Publish action, but the operation has distinct stages:

1. **Prepare** — validate local input for user feedback; retain a recoverable draft.
2. **Authenticate** — require a current authenticated Supabase session.
3. **Validate** — enforce server/database authorization and the currently approved content policy. Client validation is advisory only.
4. **Upload media (when applicable)** — use only the currently configured private Storage flow and user-owned paths. Do not invent a new upload-intent route.
5. **Persist post** — use the currently implemented text-post insertion path for text-only publishing. Media publishing must follow the actual existing client integration and must not be described as server-scanned.
6. **Confirm** — show Published only after the database operation has returned a confirmed post record.
7. **Recover** — on ambiguous timeout, do not blindly create a second post. Until an idempotency contract exists, surface an uncertain state and reconcile by a safe read before offering a new submission.

## 3. Client state machine

| State | Meaning | Allowed next states |
|---|---|---|
| `editing` | User is composing; draft is locally recoverable | `validating`, `discarded` |
| `validating` | Local checks are running | `editing`, `uploading`, `submitting` |
| `uploading` | One or more media objects are being uploaded | `submitting`, `failed`, `editing` |
| `submitting` | Post metadata is being persisted | `published`, `failed`, `unknown` |
| `published` | Server confirmed the post record | terminal for this attempt |
| `failed` | A definite failure was returned | `editing` |
| `unknown` | Client cannot determine whether the server committed | `reconciling` |
| `reconciling` | Client checks authoritative state before retry | `published`, `failed`, `unknown` |
| `discarded` | User explicitly discarded the draft | terminal |

Rules:
- Disable duplicate taps while a request is active, but do not treat a disabled button as a server-side duplicate guarantee.
- A timeout after submission is **unknown**, not automatically **failed**.
- Never transition to `published` from a local upload-complete event.
- Preserve draft text and selected-media references where safe after recoverable failures.
- Do not persist access tokens, service-role credentials, or signed URLs as durable draft data.

## 4. Input and authority rules

| Input or value | Authority |
|---|---|
| Authenticated user identity | Supabase Auth session, enforced again by RLS/server-side code |
| Author identity | Derived from authenticated identity; never trusted from a client field |
| Text and selected audience | User input, validated against the actual supported schema/policy |
| Storage object ownership | Actual Storage policy and trusted ownership checks |
| Media type and file size | Server-side validation required for security; client checks improve UX only |
| Created/updated timestamps | Database/server generated |
| Moderation status and counters | Trusted database/server process only |
| Published state | Confirmed persisted post record, not optimistic UI state |

The current product specification lists reference media limits of 10 files, 50 MiB per file, and 100 MiB aggregate. Treat these as product/client limits until the same or stricter limits are proven at the server boundary. Do not claim server enforcement based only on Flutter checks.

## 5. Error classification

| Class | Examples | Required UI behavior |
|---|---|---|
| Authentication | Missing/expired session | Ask user to sign in again; preserve draft |
| Authorization | RLS denial, restricted account | Show safe explanation; do not retry automatically |
| Validation | Empty content, unsupported media, limit exceeded | Identify the field/file; preserve editable draft |
| Storage | Upload denied, network interruption | Do not publish incomplete media; show retry/removal path |
| Persistence | Post insert rejected | Keep draft; report a safe error |
| Quota/rate limit | Provider or server limit | Respect retry guidance; do not loop |
| Ambiguous outcome | Timeout after request may have committed | Enter `unknown`; reconcile before another insert |
| Cleanup | Uploaded object has no committed post | Record/queue cleanup through an implemented trusted mechanism; do not claim cleanup if none exists |

Never expose raw SQL errors, access tokens, private Storage paths, signed URLs, or internal moderation signals to end users.

## 6. Required invariants

1. The client cannot publish as another account.
2. A user cannot attach another user's private object.
3. No post is exposed as published before persistence is confirmed.
4. A post's visibility and its media visibility must agree.
5. Block, private-account, and deleted-content rules apply to both post rows and media access.
6. Partial uploads cannot become publicly readable merely because upload succeeded.
7. Retry behavior must not silently create duplicates.
8. Draft recovery must not restore credentials or expired signed URLs.
9. Server-side validation remains mandatory even when Flutter performs the same checks.
10. Every claim of implementation must link to code/schema/policy evidence and a reproducible test.

## 7. Implementation sequence — no schema writes authorized

- [ ] Trace the existing Flutter composer call path and record exact source file/function references.
- [ ] Trace the current text-post insert contract and verify the real table/columns against the deployed schema.
- [ ] Trace the current multi-media upload and rollback path; distinguish Storage upload from media verification.
- [ ] Inspect deployed RLS and Storage policies read-only for author ownership and audience parity.
- [ ] Design idempotency only after confirming whether a safe existing database constraint/RPC can support it.
- [ ] Add authenticated integration tests with two synthetic users for author spoofing and cross-user media attachment.
- [ ] Add timeout/reconciliation tests before claiming retry safety.
- [ ] Reconcile migration history before any schema change; this document authorizes no migration or database mutation.

## 8. Sign-off checklist

CNT-017 may be called **text-only MVP verified** only when authenticated creation, author derivation, RLS behavior, feed visibility, and failure handling have reproducible evidence.

CNT-017 may be called **media publishing verified** only after server-enforced type/size/ownership checks, audience-aware media access, partial-upload recovery, and cleanup behavior have reproducible evidence.

CNT-017 may be called **retry-safe** only after a server-enforced idempotency mechanism or equivalent atomic deduplication behavior has been implemented and tested under an ambiguous network outcome.

Until those gates pass, use **partial** or **pending verification**, never **complete**.
