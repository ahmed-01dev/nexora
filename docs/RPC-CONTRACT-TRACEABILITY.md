# NEXORA — Client RPC to Live Contract Traceability

> Read-only snapshot of the live PostgreSQL catalog on 2026-11-06. The entries below are the RPC names found in the current Dart client and matched to deployed `public` signatures. This is not an authenticated integration test.

## Client-callable public RPCs

All 17 listed functions exist in `public`. Each has EXECUTE for `authenticated` and no EXECUTE for `anon`. Each public wrapper is `SECURITY INVOKER` (not SECURITY DEFINER). The app call argument names match the deployed signatures.

| Public RPC | Deployed arguments | Implementation / authorization evidence |
|---|---|---|
| `accept_community_invite` | `p_invite_code uuid` | Delegates to `private.accept_community_invite_internal`, SECURITY DEFINER; helper checks `auth.uid()` and validates invite expiry/revocation/usage before membership mutation |
| `accept_friend_request` | `p_request_id uuid` | Delegates to `private.accept_friend_request_impl`, SECURITY DEFINER; helper checks authenticated recipient, pending status, and block relationship |
| `cancel_follow` | `p_target_user_id uuid` | Delegates to `private.cancel_follow_impl`, SECURITY DEFINER; helper checks `auth.uid()` and deletes only the caller's outgoing relationship |
| `cancel_friend_request` | `p_request_id uuid` | Delegates to `private.cancel_friend_request_impl`, SECURITY DEFINER; helper checks `auth.uid()` and caller ownership of pending request |
| `create_community_invite` | `p_community_id uuid, p_expires_in_hours integer, p_max_uses integer` | Delegates to `private.create_community_invite_internal`, SECURITY DEFINER; helper checks authentication, bounded expiry/use limits, and community ownership |
| `create_direct_conversation` | `p_other_user_id uuid` | Delegates to `private.create_direct_conversation_impl`, SECURITY DEFINER; helper checks authentication, recipient validity, blocks, and messaging privacy |
| `find_nearby_people` | `p_limit integer` | Public invoker wrapper delegates to private SECURITY DEFINER helper; helper scopes origin to `auth.uid()`, excludes private profiles and either-direction blocks, expires stale location rows, caps result limit at 50 and distance at 25 km |
| `get_feed_page` | `p_mode text, p_limit integer, p_offset integer` | Public invoker function; body explicitly checks `auth.uid()` and validates feed mode |
| `get_my_conversation_previews` | no arguments | Public invoker function; body explicitly scopes rows to `auth.uid()` |
| `get_my_notification_page` | `p_offset integer, p_limit integer` | Public invoker function; body explicitly scopes rows to `auth.uid()` |
| `my_nearby_presence_enabled` | no arguments | Public invoker wrapper delegates to private SECURITY DEFINER helper; helper scopes lookup to `auth.uid()` and 24-hour freshness |
| `remove_friend` | `p_other_user_id uuid` | Delegates to `private.remove_friend_impl`, SECURITY DEFINER; helper checks authentication and deletes only an accepted relationship involving caller |
| `request_follow` | `p_target_user_id uuid` | Delegates to `private.request_follow_impl`, SECURITY DEFINER; helper checks authentication, self-follow, target existence, block relationship, and privacy |
| `request_friend` | `p_addressee_id uuid` | Delegates to `private.request_friend_impl`, SECURITY DEFINER; helper checks authentication, self-target, target existence, block relationship, and friend-request privacy |
| `revoke_community_invites` | `p_community_id uuid` | Delegates to `private.revoke_community_invites_internal`, SECURITY DEFINER; helper checks authentication and community ownership |
| `update_my_nearby_presence` | `p_latitude double precision, p_longitude double precision, p_enabled boolean` | Delegates to private SECURITY DEFINER helper; helper checks authentication, validates coordinate bounds, expires stale rows, and deletes caller's location when disabled |
| `update_privacy_settings` | `p_is_private boolean, p_allow_messages_from text, p_allow_friend_requests boolean` | Delegates to `private.update_privacy_settings_impl`, SECURITY DEFINER; helper checks authentication and validates allowed message-privacy values |

## Review findings

- No name or argument-name mismatch was found between the inspected Dart RPC call sites and the live `public` function signatures.
- The inspected public RPCs are not executable by `anon`; they are executable by `authenticated`.
- Every inspected SECURITY DEFINER implementation helper either explicitly checks `auth.uid()` or derives its caller ID from it before reading or mutating caller-scoped records.
- The nearby-discovery helper returns coarse distance bands, not coordinates; it excludes private profiles and users blocked in either direction.
- Public wrapper functions include fixed function-level search paths. SECURITY DEFINER helper search paths are recorded separately in `SECURITY-DEFINER-INVENTORY.md`.
- This catalog/source comparison does not prove the hosted PostgREST exposed-schema configuration, authenticated RLS behavior under real sessions, or correct UX under concurrent requests. Keep `private` excluded from exposed schemas and run two-user integration tests before release.
- No database function, grant, schema setting, or runtime service was changed for this audit.
