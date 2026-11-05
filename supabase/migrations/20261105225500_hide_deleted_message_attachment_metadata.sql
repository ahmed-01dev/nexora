drop policy if exists attachments_hide_deleted_messages on public.message_attachments;
create policy attachments_hide_deleted_messages on public.message_attachments as restrictive for select to authenticated using (exists (select 1 from public.messages m where m.id = message_attachments.message_id and m.deleted_at is null and private.is_conversation_member(m.conversation_id)));
