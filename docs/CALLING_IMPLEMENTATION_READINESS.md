# NEXORA Calling — Implementation Readiness

Date: 2026-11-05  
Repository: `ahmed-01dev/nexora`  
Branch: `main`

## Current verified state

- Flutter has no call screen, call service, WebRTC package, LiveKit SDK, signaling channel, or STUN/TURN configuration.
- Supabase contains `public.call_sessions` and `public.call_participants`, but these are call metadata tables only.
- `call_sessions` currently records conversation, initiator, call type, status, start and end timestamps.
- `call_participants` records call/user membership and join/leave timestamps.
- Constraints validate supported call types and statuses and enforce the foreign keys.
- Authenticated table grants are SELECT-only. INSERT/UPDATE RLS policies exist but do not grant those SQL privileges. Do not broaden grants until a server-mediated call lifecycle is implemented.
- No call-related database triggers or signaling RPCs were found in the live catalog.
- Current CI run `42092718684` passed Flutter dependency installation, analysis, and tests. This does not validate real-time calling.

## Required architecture before enabling calls

1. Select a media provider and deployment model. The provider must support Flutter Android, audio/video, room lifecycle, reconnect handling, and short-lived access tokens. A self-hosted option still requires an internet-reachable media server and TURN deployment; an SDK alone is not a working calling service.
2. Keep provider API secrets on a trusted server/Edge Function. Never ship provider secrets or service-role keys in the Flutter app.
3. Implement an authenticated token-issuance endpoint. It must verify the Supabase user, conversation membership, recipient privacy, bilateral blocks, call limits, and allowed call type before minting a short-lived room token.
4. Implement a server-owned call lifecycle: create/ring, accept, reject, cancel, join, leave, end, timeout/missed, and stale-session cleanup. Enforce legal status transitions and idempotency.
5. Implement incoming-call delivery and navigation using push notifications, including terminated/background app behavior and notification permission handling.
6. Implement the Flutter call client with explicit microphone/camera permission UX, audio route controls, mute/camera state, speaker/Bluetooth handling, connection quality, reconnecting, and deterministic cleanup.
7. Add multi-user integration tests for blocked users, private conversations, unauthorized room-token requests, replayed/expired tokens, duplicate accepts, caller cancellation, missed calls, and participant departure.
8. Test on at least two physical Android devices over Wi-Fi and mobile networks, including restrictive NAT networks where TURN relay is required.

## Release gates

- Do not expose a call button that implies a working call until signaling and media transport are both deployed and tested.
- Do not let clients directly set arbitrary call status or add other users as participants.
- Do not enable broad INSERT/UPDATE grants on the current call tables as a shortcut.
- Do not store provider API secrets in Flutter, GitHub source, or chat.
- Real voice/video calling remains a release blocker until provider selection, server deployment, credentials, integration tests, and physical-device tests are complete.

## External dependency decision

The repository and current project connection do not identify an approved calling provider or provide its deployment credentials. This is an intentional decision gate: selecting and deploying a provider without the project owner's account, cost, and infrastructure approval would risk creating recurring charges or an exposed service. The implementation should proceed only after that dependency is provisioned.
