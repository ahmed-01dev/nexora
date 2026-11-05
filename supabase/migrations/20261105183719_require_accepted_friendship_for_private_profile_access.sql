-- A pending/declined/cancelled friend request must not grant access to a
-- private profile. Only an accepted friendship can satisfy this visibility path.
drop policy if exists "Profiles visible according to privacy" on public.profiles;

create policy "Profiles visible according to privacy"
on public.profiles
for select
to authenticated
using (
  id = (select auth.uid())
  or (
    not private.is_blocked_between((select auth.uid()), id)
    and (
      is_private = false
      or exists (
        select 1
        from public.follows f
        where f.follower_id = (select auth.uid())
          and f.following_id = profiles.id
          and f.status = 'accepted'
      )
      or exists (
        select 1
        from public.conversation_members cm
        where cm.user_id = profiles.id
          and private.is_conversation_member(cm.conversation_id)
      )
      or exists (
        select 1
        from public.friendships fr
        where fr.status = 'accepted'
          and (
            (fr.requester_id = profiles.id and fr.addressee_id = (select auth.uid()))
            or
            (fr.addressee_id = profiles.id and fr.requester_id = (select auth.uid()))
          )
      )
    )
  )
);
