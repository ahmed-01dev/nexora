create or replace function public.get_my_notification_page(p_offset integer default 0, p_limit integer default 50)
returns table (
  id uuid,
  actor_id uuid,
  notification_type text,
  entity_type text,
  entity_id uuid,
  payload jsonb,
  read_at timestamptz,
  created_at timestamptz,
  profiles jsonb
)
language sql
stable
security invoker
set search_path = pg_catalog, public
as $$
  select n.id, n.actor_id, n.notification_type, n.entity_type, n.entity_id,
         n.payload, n.read_at, n.created_at,
         case when p.id is null then null
              else jsonb_build_object('display_name', p.display_name, 'username', p.username)
         end as profiles
  from public.notifications n
  left join public.profiles p on p.id = n.actor_id
  where n.recipient_id = (select auth.uid())
    and not exists (
      select 1 from public.notification_preferences np
      where np.user_id = (select auth.uid())
        and np.category = n.notification_type
        and np.in_app = false
    )
  order by n.created_at desc, n.id desc
  limit least(greatest(coalesce(p_limit, 50), 1), 100)
  offset greatest(coalesce(p_offset, 0), 0);
$$;
revoke all on function public.get_my_notification_page(integer, integer) from public, anon;
grant execute on function public.get_my_notification_page(integer, integer) to authenticated;
