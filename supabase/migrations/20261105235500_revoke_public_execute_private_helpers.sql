-- Private implementation functions must not inherit PUBLIC execute access.
-- Authenticated execute remains only where SECURITY INVOKER public RPC wrappers call them.
revoke execute on function private.accept_friend_request_impl(uuid) from public, anon;
revoke execute on function private.decline_friend_request_impl(uuid) from public, anon;
revoke execute on function private.cancel_friend_request_impl(uuid) from public, anon;
revoke execute on function private.remove_friend_impl(uuid) from public, anon;

-- Trigger-only functions are never callable by API clients.
revoke all on function private.audit_moderation_action() from public, anon, authenticated;
revoke all on function private.audit_report_update() from public, anon, authenticated;
