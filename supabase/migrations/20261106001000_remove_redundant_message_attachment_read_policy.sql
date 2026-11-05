-- The old permissive policy OR-ed with the deleted-message filter,
-- allowing attachment metadata for deleted messages to remain visible.
-- Keep only attachments_hide_deleted_messages, which also requires membership.
drop policy if exists attachments_read_members on public.message_attachments;
