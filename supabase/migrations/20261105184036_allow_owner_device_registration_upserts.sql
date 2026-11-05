-- Allow an authenticated user to upsert only their own device identity
-- fields. The existing user_devices_update_own RLS policy enforces ownership.
grant update (user_id, platform, push_token)
on table public.user_devices
to authenticated;
