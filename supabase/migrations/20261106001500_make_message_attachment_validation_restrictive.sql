-- INSERT policies are OR-ed when permissive. Make media validation
-- restrictive so it is AND-ed with the ownership/path/membership policy.
drop policy if exists attachments_validate_image_upload on public.message_attachments;

create policy attachments_validate_image_upload
on public.message_attachments
as restrictive
for insert
to authenticated
with check (
  mime_type = any (array['image/jpeg'::text, 'image/png'::text, 'image/webp'::text])
  and size_bytes <= 10485760
  and exists (
    select 1
    from public.messages m
    where m.id = message_attachments.message_id
      and m.sender_id = (select auth.uid())
      and m.message_type = 'image'
      and m.deleted_at is null
  )
);
