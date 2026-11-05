-- Privacy settings are written through update_privacy_settings(), which
-- synchronizes profiles.is_private and user_private_settings.profile_visibility.
revoke insert, update on table public.user_private_settings from authenticated;
