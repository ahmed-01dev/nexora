-- A direct-conversation creator must not be able to remove the other
-- participant from a 1:1 conversation. Self-removal remains allowed, and
-- creators retain member-management rights in group/community conversations.
drop policy if exists conversation_members_remove on public.conversation_members;
create policy conversation_members_remove
on public.conversation_members
for delete
to authenticated
using (
  user_id = (select auth.uid())
  or (
    private.is_conversation_creator(conversation_id)
    and exists (
      select 1
      from public.conversations c
      where c.id = conversation_members.conversation_id
        and c.conversation_type in ('group','community')
    )
  )
);
