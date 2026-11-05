drop policy if exists notifications_respect_in_app_preference on public.notifications;
create policy notifications_respect_in_app_preference
on public.notifications
as restrictive
for select
to authenticated
using (
  not exists (
    select 1
    from public.notification_preferences np
    where np.user_id = (select auth.uid())
      and np.category = notifications.notification_type
      and np.in_app = false
  )
);
