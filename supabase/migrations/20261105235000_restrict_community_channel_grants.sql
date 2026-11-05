-- Remove broad default table grants from authenticated clients.
-- RLS does not protect against TRUNCATE, so grant only operations the UI needs.
revoke all privileges on table public.community_channels from anon, authenticated;
grant select, insert, delete on table public.community_channels to authenticated;
