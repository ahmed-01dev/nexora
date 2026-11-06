# NEXORA Source-to-Contract Traceability

**Audit date:** 2026-11-06  
**Source snapshot:** working branch `docs/specs-i-j-k` at the time of this update; changes remain in open PR #3 and are not yet merged to `main`.  
**Purpose:** map documented feature claims to source files and concrete Supabase operations without implying runtime verification.

> This is a static source inspection. It does not prove deployed SQL matches local migrations, that provider credentials are configured, or that workflows pass on a real device. Source files are cited by path and symbol/operation so the next audit can reproduce the trace.

## 1. Authentication and account entry

| Concern | Source location | Observed operation | Evidence boundary |
|---|---|---|---|
| Phone normalization | `lib/features/auth/phone_number.dart` | Egyptian phone normalization helper | Helper exists; this alone does not prove SMS delivery |
| OTP request | `lib/main.dart` around lines 326–331 | `auth.signInWithOtp(phone: normalized, channel: OtpChannel.sms)` | Client invokes SMS OTP; provider delivery and cost are external |
| OTP verification | `lib/main.dart` around lines 358–363 | `auth.verifyOTP(...)` | UI verification call exists; recovery/linking/MFA are separate gaps |

## 2. Social graph and feed

| Concern | Source location | Observed operation | Evidence boundary |
|---|---|---|---|
| Feed page | `lib/main.dart` around lines 718 onward | RPC `get_feed_page` | Client uses server-paged feed contract; exact deployed definition must be compared with migration and database |
| Follow request lifecycle | `lib/main.dart`; `lib/features/friends/follow_requests_screen.dart` | RPCs `request_follow`, `cancel_follow`; incoming reads from `follows`; recipient updates only `status = 'accepted'` | Incoming requests are paged and can be accepted under the live recipient-only UPDATE policy; recipient-side decline is not available in the current backend contract |
| Hashtag feed lookup | `lib/main.dart` around lines 945 onward | Join query across `post_hashtags`, `posts`, `hashtags`, `profiles` | Source proves this query path, not ranking/search safety or a full search service |
| Accepted followers/following | `FriendsScreen` in `lib/main.dart` | Directional reads from `follows` with `profiles` joins through the two live FK constraints; reuses `request_follow` / `cancel_follow` | First 100 accepted relationships only; profile RLS can hide a private user's joined details, and no list pagination beyond 100 is implemented |
| Hashtag service | `lib/features/search/hashtag_service.dart` | Reads/writes hashtag association objects | Unit test exists at `test/hashtag_service_test.dart`; integration/RLS behavior remains distinct |

## 3. Comments, friendships and communities

| Concern | Source location | Observed operation | Evidence boundary |
|---|---|---|---|
| Comments | `lib/features/comments/comments_screen.dart` | `comments` and `comment_likes` operations | UI/source workflow exists; do not infer independent RLS integration coverage |
| Friend requests | `lib/features/friends/friend_requests_screen.dart` | RPC family: `request_friend`, `accept_friend_request`, `decline_friend_request`, `cancel_friend_request`, `remove_friend`; reads `friendships` | Client call sites exist; server-side authorization must be verified from deployed function definitions and policies |
| Community invites | `lib/features/communities/communities_screen.dart` | `accept_community_invite`, `create_community_invite`, `revoke_community_invites` | Client integration exists; invite expiry/use-limit enforcement must be checked in SQL |
| Community channels | `lib/features/communities/community_channels_screen.dart` | `community_channels`, `conversations`, `conversation_members` | Channel conversation wiring exists; moderator/admin tools remain distinct |
| Community membership | `lib/features/communities/community_members_screen.dart` | `community_members` | Member screen exists; role privilege correctness needs SQL/RLS verification |

## 4. Media and messaging

| Concern | Source location | Observed operation | Evidence boundary |
|---|---|---|---|
| Post/profile/story media | `lib/features/media/media_upload_service.dart` | Private bucket `nexora-media`; `uploadBinary`, metadata operations and cleanup | Client checks actual signatures; code comments correctly state server scanning is still required |
| Upload limits | `lib/features/media/media_upload_service.dart` | 50 MiB/file, 10 files, 100 MiB aggregate post media | These are client constants; server-side enforcement and per-user quota are separate |
| Failed upload rollback | `lib/features/media/media_upload_service.dart` | Attempts metadata and Storage cleanup after a later upload fails | Best-effort cleanup is not a durable background orphan sweeper |
| Message attachments | `lib/features/messaging/message_attachment_service.dart` | `messages`, `message_attachments`, private Storage | Source path exists; server signature scanning and non-image attachment types remain pending |
| Messaging UI | `lib/features/messaging/messages_screen.dart` | `get_my_conversation_previews`, `create_direct_conversation`, `messages`, `conversation_members`, `profiles` | Inbox/conversation client workflow exists; no E2EE protocol is present in this trace |

## 5. Nearby discovery and privacy

| Concern | Source location | Observed operation | Evidence boundary |
|---|---|---|---|
| Presence state | `lib/features/nearby/nearby_discovery_screen.dart` | RPC `my_nearby_presence_enabled` | Opt-in state is queried |
| Nearby search | Same file | RPC `find_nearby_people` with `p_limit: 50` | Client requests results; approximate distance and no exact-coordinate disclosure must be proven in SQL return shape |
| Presence update | Same file | RPC `update_my_nearby_presence` with latitude/longitude/enabled | Exact coordinates are sent to trusted server-side function; never expose them in public client results |
| Direct conversation | Same file | RPC `create_direct_conversation` | Client action exists; block/privacy checks belong to database/server boundary |

## 6. Notifications and push

| Concern | Source location | Observed operation | Evidence boundary |
|---|---|---|---|
| Device registration and sign-out cleanup | `lib/features/notifications/nexora_push_service.dart`; `lib/main.dart` | Firebase Messaging FID registration; upsert/delete `user_devices`; sign-out suspends registration, invalidates in-flight upserts, deletes using the captured account ID, and retains that owner for the asynchronous `onUnregistered` callback | Cleanup is best-effort because the service catches deletion failures; offline cleanup and multi-account behavior still require physical-device tests |
| Notification preferences | `lib/features/notifications/notification_preferences_screen.dart` | `notification_preferences` | Preference UI/client data path exists |
| Notification feed | `lib/features/notifications/notifications_screen.dart` | RPC `get_my_notification_page`; `notifications` read state | In-app list path exists; not proof of successful push delivery |
| Push Edge Function | `supabase/functions/send-push-notification/index.ts` | Reads Supabase and Firebase secrets, validates bearer/webhook path, checks preferences/devices, calls FCM HTTP v1 | Function source exists; runtime secret presence, webhook authentication configuration, FCM response handling and device delivery require deployment tests |

## 7. Moderation and account privacy

| Concern | Source location | Observed operation | Evidence boundary |
|---|---|---|---|
| Privacy settings | `lib/features/settings/privacy_settings_screen.dart` | RPC `update_privacy_settings`; reads `profiles`, `user_private_settings` | Client uses privacy RPC rather than direct protected-field writes |
| Reports/moderation | `lib/features/moderation/report_dialog.dart`, `moderation_queue_screen.dart`, `moderation_appeals_screen.dart`, `my_moderation_screen.dart` | Report, queue and appeal UI surfaces | UI presence does not establish secure staff-role assignment or a complete operational moderation program |

## 8. Evidence gaps and next verification gates

1. Compare every RPC name and parameter in this document with the exact deployed PostgreSQL function signature, SECURITY mode, search_path and EXECUTE grants.
2. Compare every table/storage operation with live RLS and Storage policy definitions, including owner and non-owner identities.
3. Verify that SQL migration history maps exactly to local SQL files before any migration command. The previously recorded remote/local migration mismatch remains a stop condition.
4. Add authenticated integration tests for two unrelated users, blocks, private accounts, deleted content, expired invites and revoked membership.
5. Test OTP, push and media on real devices only after provider configuration is known and costs/quotas are understood.
6. Do not treat static code inspection, passing unit tests or CI analysis as proof of production behavior.

## 9. Explicitly not established by this audit

- Production SMS delivery, OAuth, MFA, passkeys or full account recovery.
- E2EE, WebRTC calls, STUN/TURN or call notification reliability.
- Server-side malware scanning, transcoding, thumbnails, resumable uploads or CDN.
- Complete admin RBAC, moderation escalation and child-safety operations.
- Full live-schema ERD or reconciled migration history.
- Production crash monitoring, backup/restore drill, penetration test or store readiness.

No source code, database schema, deployed function, provider configuration, or build workflow was changed by this traceability document.

| Startup failure presentation | `lib/main.dart`; `lib/core/app_error.dart` | Supabase initialization failures are reported centrally and the setup screen receives a generic Arabic message | Provider configuration and retry/recovery behavior still require device validation |

| Late FCM registration / duplicate sign-out callback | `lib/features/notifications/nexora_push_service.dart`; `lib/main.dart` | Suspended or signed-out registration callbacks do not overwrite the captured owner or upsert; duplicate unregister invocation is skipped | Firebase timing, offline cleanup and account-switch behavior require physical Android testing |

| Media upload during account switch | `lib/features/media/media_upload_service.dart` | Profile/story uploads re-check owner after Storage; post uploads re-check before each file, before Storage, and before metadata insert; rollback runs only under the original active owner | A just-uploaded object can remain orphaned if the session changes before cleanup; server-side cleanup and physical-device testing remain pending |

| Delayed FCM unregister after account switch | `lib/features/notifications/nexora_push_service.dart`; `lib/features/notifications/fcm_registration_ownership.dart`; `test/fcm_registration_ownership_test.dart` | Pending FID unregister callbacks use FIFO captured owners; tracked registration is cleared only for an exact FID/owner match | Actual Firebase callback ordering, offline cleanup, and multi-account device behavior require physical Android testing |

| Flutter framework exception privacy | `lib/core/app_error.dart`; `test/app_error_test.dart` | Framework errors are routed to the central type-only reporter without invoking the raw default Flutter exception presenter | Production telemetry privacy and redaction require separate provider/configuration review |

| Report input validation | `lib/features/moderation/report_submission_validation.dart`; `lib/features/moderation/report_dialog.dart`; `test/report_submission_validation_test.dart` | Client validates six live target types, eleven live reason codes, and UUID-shaped target IDs before insert | PostgreSQL CHECK constraints and RLS remain authoritative; authenticated multi-user report tests are pending |

| Report completion across session change | `lib/features/moderation/report_dialog.dart` | The dialog confirms the reporter session still matches after the insert before showing success; changed sessions receive a reconciliation warning | Request outcome reconciliation and duplicate prevention require a server-side idempotency contract |

| Message attachment session continuity | `lib/features/messaging/message_attachment_service.dart`; `docs/10-ACCEPTANCE-AND-PERFORMANCE-TESTING.md` | Upload/delete operations re-check owner before follow-up writes; rollback is limited to the original session; signed URL is discarded after viewer change | Ambiguous completed send, orphan cleanup, and real-device session-switch tests remain pending |

| Comment pagination refresh race | `lib/features/comments/comments_screen.dart` | Refresh/reload advances a request generation; stale load-more completions cannot overwrite the newer list or its pagination state | Backend concurrent-insert behavior and authenticated integration tests remain pending |

| Notification account-switch safety | `lib/features/notifications/notifications_screen.dart` | Page results, read updates, and target navigation are bound to the captured viewer ID and stopped if the session changes | Authenticated multi-user and device session-switch tests remain pending |

| Followers/following session continuity | `lib/main.dart` (`FriendsScreen._fetchPage`) | Page query captures the viewer ID and rejects results if the authenticated user changes before completion | Device-level account-switch and authenticated RLS integration tests remain pending |
