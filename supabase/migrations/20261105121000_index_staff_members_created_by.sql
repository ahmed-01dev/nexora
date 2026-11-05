-- Add the missing index identified by the Supabase performance advisor.
-- Additive and safe: does not alter or delete existing rows.
create index if not exists staff_members_created_by_idx
  on public.staff_members (created_by)
  where created_by is not null;
