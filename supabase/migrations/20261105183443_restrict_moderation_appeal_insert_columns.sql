-- Limit appeal INSERT to fields supplied by the appeal author.
-- A follow-up migration also removes the table-level INSERT grant so these
-- column restrictions are effective.
revoke insert (id, created_at, resolved_at, reviewer_id, status)
on table public.moderation_appeals
from authenticated;

grant insert (user_id, action_id, message)
on table public.moderation_appeals
to authenticated;
