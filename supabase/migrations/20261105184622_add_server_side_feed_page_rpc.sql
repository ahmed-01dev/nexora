-- Server-side feed paging avoids sending thousands of follow/friend IDs in a
-- PostgREST IN filter. SECURITY INVOKER preserves table RLS for posts,
-- profiles, follows, and friendships.
create or replace function public.get_feed_page(
  p_mode text default 'latest',
  p_limit integer default 20,
  p_offset integer default 0
)
returns table (
  id uuid,
  user_id uuid,
  content text,
  visibility text,
  created_at timestamptz,
  profiles jsonb
)
language plpgsql
stable
security invoker
set search_path = public, pg_temp
as $function$
begin
  if p_mode not in ('latest', 'following') then
    raise exception 'Invalid feed mode' using errcode = '22023';
  end if;

  return query
  select
    p.id,
    p.user_id,
    p.content,
    p.visibility,
    p.created_at,
    jsonb_build_object(
      'id', pr.id,
      'username', pr.username,
      'display_name', pr.display_name,
      'avatar_url', pr.avatar_url
    ) as profiles
  from public.posts p
  join public.profiles pr on pr.id = p.user_id
  where p.deleted_at is null
    and (
      (p_mode = 'latest' and p.visibility = 'public')
      or (
        p_mode = 'following'
        and (
          p.user_id = (select auth.uid())
          or exists (
            select 1
            from public.follows f
            where f.follower_id = (select auth.uid())
              and f.following_id = p.user_id
              and f.status = 'accepted'
          )
          or exists (
            select 1
            from public.friendships fr
            where fr.status = 'accepted'
              and (
                (fr.requester_id = (select auth.uid()) and fr.addressee_id = p.user_id)
                or
                (fr.addressee_id = (select auth.uid()) and fr.requester_id = p.user_id)
              )
          )
        )
      )
    )
  order by p.created_at desc, p.id desc
  limit least(greatest(coalesce(p_limit, 20), 1), 50)
  offset least(greatest(coalesce(p_offset, 0), 0), 100000);
end;
$function$;

revoke all on function public.get_feed_page(text, integer, integer) from public, anon;
grant execute on function public.get_feed_page(text, integer, integer) to authenticated;
