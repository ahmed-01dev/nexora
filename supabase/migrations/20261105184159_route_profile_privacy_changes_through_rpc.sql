-- Keep profiles.is_private and user_private_settings.profile_visibility in sync
-- by forcing changes through the SECURITY DEFINER update_privacy_settings RPC.
revoke update (is_private)
on table public.profiles
from authenticated;
