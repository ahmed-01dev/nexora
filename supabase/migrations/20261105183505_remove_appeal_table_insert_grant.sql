-- Revoke the table-level INSERT grant so restricted column-level
-- privileges on moderation appeals actually take effect.
revoke insert on table public.moderation_appeals from authenticated;
grant insert (user_id, action_id, message)
on table public.moderation_appeals
to authenticated;
