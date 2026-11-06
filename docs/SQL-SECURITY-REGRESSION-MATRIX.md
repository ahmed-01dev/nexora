# NEXORA Media Authorization Regression Matrix

**Audit date:** 2026-11-06  
**Status:** required test plan; no database integration tests were executed.

## Why this matrix exists

The migration `20261105225000_hide_deleted_message_attachments.sql` redefines `private.can_read_media_path(text)` with an older authorization expression. Compared with the previous implementation, that replacement omits:
- `friends` visibility for post media;
- private-account eligibility for story media;
- the `posts.deleted_at IS NULL` check for non-owner post-media access.

The live Supabase definition of `private.can_read_media_path(text)` was inspected read-only and contains the friend-only post, private-story, deleted-post, deleted-message and block checks. The local GitHub migration `20261105225000_hide_deleted_message_attachments.sql` is older/different and omits some of those predicates. This is a local-source/history drift finding; it is not evidence of a current live Storage vulnerability. Do not create or apply a corrective migration until the remote/local migration history is reconciled.

## Required identity fixtures

Use isolated test identities and content, never real users:
- User A: content owner.
- User B: accepted follower of A.
- User C: accepted friend of A but not a follower.
- User D: unrelated authenticated user.
- User E: account blocked by A (and test the reverse block direction).
- A private-account fixture with a public-looking story visibility setting.
- An expired/archived story fixture and a soft-deleted post/message fixture.

## Test matrix

| Asset / condition | Owner | Accepted follower | Accepted friend only | Unrelated user | Blocked counterpart |
|---|---:|---:|---:|---:|---:|
| Public post media on public account | Allow | Allow | Allow | Allow | Deny |
| Followers-only post media | Allow | Allow | Deny | Deny | Deny |
| Friends-only post media | Allow | Deny unless also friend | Allow | Deny | Deny |
| Public post media on private account | Allow | Allow | Deny unless also follower | Deny | Deny |
| Soft-deleted post media | Allow | Deny | Deny | Deny | Deny |
| Public story on public account | Allow | Allow | Allow | Allow | Deny |
| Public-looking story on private account | Allow | Allow only if accepted follower | Deny | Deny | Deny |
| Expired or archived story media | Deny | Deny | Deny | Deny | Deny |
| Message attachment, message active and membership valid | Allow for participant | Allow for participant | Allow for participant | Deny | Deny when block invalidates direct membership |
| Message attachment after message soft-delete | Deny from attachment metadata and Storage | Deny | Deny | Deny | Deny |
| Public community cover | Allow | Allow | Allow | Allow | Apply community membership/block policy explicitly |
| Private community cover | Allow | Deny unless member | Deny unless member | Deny | Deny unless still authorized member |

**Note:** The live helper filters archived/expired stories before the owner/viewer authorization branch, so expired or archived story media is denied to everyone, including the owner. Preserve this behavior unless the product retention policy is deliberately changed.

## Test execution requirements

1. Apply the proposed correction only in a disposable staging project after migration-history reconciliation.
2. Create fixtures through supported application/database setup, with at least two distinct authenticated JWT identities.
3. Request Storage object access through the same signed URL/download path used by the app.
4. Verify both positive and negative outcomes. A 404/403 alone is insufficient unless it is confirmed not to disclose existence through metadata.
5. Verify both message attachment row visibility and Storage object visibility separately.
6. Re-run the matrix after every later migration that replaces `private.can_read_media_path`.
7. Record migration version, test identity, object path, expected result, actual result and timestamp.

## Existing tests are not substitutes

The current Flutter unit test `test/media_upload_service_test.dart` checks client-side file signatures. It does not test Storage RLS, authorization of signed URLs, private-account visibility, blocks, deleted content or server-side scanning.

No migration, SQL statement, database write, or build was executed for this audit.