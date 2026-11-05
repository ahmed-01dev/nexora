-- Recipients may only mark their own notifications as read.
-- Notification content and routing metadata are server-managed.
revoke update on table public.notifications from authenticated;

revoke update (
  actor_id,
  created_at,
  entity_id,
  entity_type,
  id,
  notification_type,
  payload,
  recipient_id
) on table public.notifications from authenticated;

grant update (read_at) on table public.notifications to authenticated;
