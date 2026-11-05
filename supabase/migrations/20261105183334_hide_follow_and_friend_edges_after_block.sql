-- Hide follow and friendship edges from either participant while a mutual
-- block exists. The relationship data is retained so an unblock can restore it.
drop policy if exists "Read follows" on public.follows;
create policy "Read follows"
on public.follows
for select
to authenticated
using (
  (
    (select auth.uid()) = follower_id
    or (select auth.uid()) = following_id
  )
  and not private.is_blocked_between(
    (select auth.uid()),
    case
      when (select auth.uid()) = follower_id then following_id
      else follower_id
    end
  )
);

drop policy if exists friendships_read_participant on public.friendships;
create policy friendships_read_participant
on public.friendships
for select
to authenticated
using (
  (
    (select auth.uid()) = requester_id
    or (select auth.uid()) = addressee_id
  )
  and not private.is_blocked_between(
    (select auth.uid()),
    case
      when (select auth.uid()) = requester_id then addressee_id
      else requester_id
    end
  )
);
