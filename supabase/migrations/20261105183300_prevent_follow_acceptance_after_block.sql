-- A pending follow request cannot be accepted after either participant blocks
-- the other account.
drop policy if exists "Accept incoming follow requests" on public.follows;
create policy "Accept incoming follow requests"
on public.follows
for update
to authenticated
using (
  following_id = (select auth.uid())
  and status = 'pending'
  and not private.is_blocked_between((select auth.uid()), follower_id)
)
with check (
  following_id = (select auth.uid())
  and status = 'accepted'
  and not private.is_blocked_between((select auth.uid()), follower_id)
);
