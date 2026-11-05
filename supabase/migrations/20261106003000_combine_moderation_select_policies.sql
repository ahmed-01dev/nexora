-- Preserve the original owner/reporter and staff access paths while
-- consolidating duplicate permissive SELECT policies into one policy per table.

drop policy if exists mod_actions_read_staff on public.moderation_actions;
drop policy if exists mod_actions_read_target_user on public.moderation_actions;
create policy mod_actions_read_authorized
on public.moderation_actions
for select
to authenticated
using (
  private.is_staff(array['super_admin','admin','moderator','support'])
  or (target_type = 'user' and target_id = (select auth.uid()))
);

drop policy if exists appeals_read_own on public.moderation_appeals;
drop policy if exists appeals_read_staff on public.moderation_appeals;
create policy appeals_read_authorized
on public.moderation_appeals
for select
to authenticated
using (
  user_id = (select auth.uid())
  or private.is_staff(array['super_admin','admin','moderator'])
);

drop policy if exists reports_read_self on public.reports;
drop policy if exists reports_read_staff on public.reports;
create policy reports_read_authorized
on public.reports
for select
to authenticated
using (
  reporter_id = (select auth.uid())
  or private.is_staff(array['super_admin','admin','moderator','support'])
);
