# NEXORA — Live Supabase Storage Security Inventory

> Read-only snapshot captured 2026-11-06. No Storage bucket, object, policy, or grant was changed.

## Buckets

| Bucket | Public | Maximum object size | Allowed MIME types |
|---|---:|---:|---|
| `nexora-media` | false | 50 MiB | `image/jpeg`, `image/png`, `image/webp`, `image/gif`, `video/mp4`, `video/webm`, `audio/mpeg`, `audio/mp4`, `audio/ogg`, `audio/webm`, `application/pdf` |

## `storage.objects` policies

### `nexora_media_delete_own`

- Command: `DELETE`
- Roles: `{authenticated}`
- USING: `((bucket_id = 'nexora-media'::text) AND ((storage.foldername(name))[1] = (( SELECT auth.uid() AS uid))::text))`
- WITH CHECK: —

### `nexora_media_read_authorized`

- Command: `SELECT`
- Roles: `{authenticated}`
- USING: `((bucket_id = 'nexora-media'::text) AND (((storage.foldername(name))[1] = (( SELECT auth.uid() AS uid))::text) OR private.can_read_media_path(name)))`
- WITH CHECK: —

### `nexora_media_upload_own_folder`

- Command: `INSERT`
- Roles: `{authenticated}`
- USING: —
- WITH CHECK: `((bucket_id = 'nexora-media'::text) AND ((storage.foldername(name))[1] = (( SELECT auth.uid() AS uid))::text))`

## Client implementation alignment

- `MediaUploadService` writes under the authenticated user's first-level folder (`<uid>/...`) and uses `upsert: false` for profile, post, and story uploads.
- Profile images are limited client-side to 10 MiB and JPG/PNG/WebP. Post/story uploads are client-limited to 50 MiB per object; post media is additionally capped at 10 files and 100 MiB total. Bucket limit is 50 MiB per object.
- The live bucket is private. Authenticated reads are restricted to the owner folder or `private.can_read_media_path(name)`; upload and delete policies are owner-folder scoped.
- No `UPDATE` policy exists for `storage.objects`; current upload code uses new unique paths rather than upsert. Do not enable upsert without a reviewed UPDATE policy.
- Client-side file-signature checks are bypassable by modified clients. Server-side malware scanning, MIME/content verification, transcoding, and thumbnail generation remain release blockers.
- The app's media type allowlist is narrower than the bucket allowlist. The bucket accepting audio/PDF does not mean the client implements those upload flows.

## Verification limits

This is policy/configuration evidence, not a full Storage API integration test. Test authenticated owner, non-owner, blocked-user, private-post, story-expiry, conversation-member, and deleted-message access against real JWTs before release.
