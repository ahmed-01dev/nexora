-- Return the current user's recent conversation list with one latest-message
-- preview per conversation. SECURITY INVOKER keeps underlying RLS in force.
create or replace function public.get_my_conversation_previews()
returns table (
  conversation_id uuid,
  conversation_type text,
  conversation_title text,
  conversation_created_at timestamptz,
  last_message_at timestamptz,
  peer_id uuid,
  peer_username text,
  peer_display_name text,
  peer_avatar_url text,
  latest_message_id uuid,
  latest_body text,
  latest_message_type text,
  latest_created_at timestamptz,
  latest_sender_id uuid,
  latest_deleted_at timestamptz
)
language sql
stable
security invoker
set search_path = public, pg_temp
as $function$
  with mine as (
    select cm.conversation_id, cm.joined_at, c.conversation_type,
           c.title, c.created_at, c.last_message_at
    from public.conversation_members cm
    join public.conversations c on c.id = cm.conversation_id
    where cm.user_id = (select auth.uid())
      and cm.archived_at is null
    order by coalesce(c.last_message_at, c.created_at) desc, c.id desc
    limit 60
  ),
  latest as (
    select distinct on (m.conversation_id)
           m.conversation_id, m.id, m.body, m.message_type,
           m.created_at, m.sender_id, m.deleted_at
    from public.messages m
    join mine on mine.conversation_id = m.conversation_id
    order by m.conversation_id, m.created_at desc, m.id desc
  )
  select mine.conversation_id, mine.conversation_type, mine.title,
         mine.created_at, mine.last_message_at,
         peer.id, peer.username, peer.display_name, peer.avatar_url,
         latest.id,
         case when latest.deleted_at is null then latest.body else null end,
         latest.message_type, latest.created_at, latest.sender_id,
         latest.deleted_at
  from mine
  left join lateral (
    select p.id, p.username, p.display_name, p.avatar_url
    from public.conversation_members other_member
    join public.profiles p on p.id = other_member.user_id
    where other_member.conversation_id = mine.conversation_id
      and other_member.user_id <> (select auth.uid())
    order by other_member.joined_at asc, other_member.user_id
    limit 1
  ) peer on true
  left join latest on latest.conversation_id = mine.conversation_id
  order by coalesce(mine.last_message_at, mine.created_at) desc,
           mine.conversation_id desc;
$function$;

revoke all on function public.get_my_conversation_previews() from public, anon;
grant execute on function public.get_my_conversation_previews() to authenticated;
