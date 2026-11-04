# NEXORA API Contracts

## Current transport
The current Flutter app talks to Supabase Auth and the PostgREST Data API using the public client key. RLS is the authorization boundary. No standalone NestJS/REST backend currently exists.

## Current implemented operations
- Auth: email/password sign-up and sign-in through Supabase Auth.
- Profiles: read and update the signed-in user's profile.
- Posts: insert text posts and read public posts.
- Follows: server-validated `request_follow` and `cancel_follow` RPCs; private profiles produce pending requests.
- Friendships: `request_friend`, `accept_friend_request`, `decline_friend_request`, `cancel_friend_request`, and `remove_friend` RPCs with block and recipient-permission checks.
- Privacy: `update_privacy_settings` atomically updates profile visibility and direct-message permission.
- Likes: insert/delete likes on posts.

## Database-backed contracts added (client integration pending)
- Friendships: `friendships` with pending/accepted/declined/cancelled states.
- Blocks: `blocks`.
- Messaging: `conversations`, `conversation_members`, `messages`, `message_attachments`, `message_reactions`.
- Notifications: `notifications` (trusted server/trigger writes only).
- Stories: `stories`, `story_views`.
- Communities: `communities`, `community_members`.
- Safety: `reports`.
- Call signaling records: `call_sessions`, `call_participants`.

## Required server endpoints before public release
Use versioned Edge Functions or a separately deployed backend for operations that must not be client-forgeable:
- `POST /v1/media/upload-intent`: validate ownership, file limits, and issue upload authorization.
- `POST /v1/media/process`: enqueue thumbnail/transcode jobs.
- `POST /v1/notifications/dispatch`: trusted notification fan-out.
- `POST /v1/moderation/actions`: role-checked moderator actions and audit records.
- `POST /v1/account/export` and `DELETE /v1/account`: verified data export/deletion.
- `POST /v1/calls/token`: authorize WebRTC signaling/room access.
- `POST /v1/search`: safe search and ranking where direct table queries are insufficient.

These endpoints are contracts/planned work, not deployed services.
