-- Blocking either participant revokes access to an existing direct
-- conversation (messages, members, attachments, and previews) for both sides.
-- Group/community conversations are unaffected.
create or replace function private.is_conversation_member(p_conversation_id uuid)
returns boolean
language sql
stable
security definer
set search_path = ''
as $function$
  select exists (
    select 1
    from public.conversation_members cm
    join public.conversations c on c.id = cm.conversation_id
    where cm.conversation_id = p_conversation_id
      and cm.user_id = (select auth.uid())
      and (
        c.conversation_type <> 'direct'
        or not exists (
          select 1
          from public.conversation_members other_member
          where other_member.conversation_id = cm.conversation_id
            and other_member.user_id <> (select auth.uid())
            and private.is_blocked_between((select auth.uid()), other_member.user_id)
        )
      )
  );
$function$;

revoke all on function private.is_conversation_member(uuid) from public, anon;
grant execute on function private.is_conversation_member(uuid) to authenticated;
