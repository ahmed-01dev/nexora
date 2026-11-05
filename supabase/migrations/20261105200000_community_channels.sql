-- Community discussion channels backed by the existing conversations/messages model.
create table if not exists public.community_channels (
  id uuid primary key default gen_random_uuid(),
  community_id uuid not null references public.communities(id) on delete cascade,
  conversation_id uuid not null unique references public.conversations(id) on delete cascade,
  name text not null check (char_length(btrim(name)) between 2 and 60),
  slug text not null check (slug ~ '^[a-z0-9-]{2,60}$'),
  created_by uuid not null references auth.users(id) on delete restrict,
  created_at timestamptz not null default now(),
  unique (community_id, slug)
);

create index if not exists community_channels_created_by_idx
  on public.community_channels(created_by);

alter table public.community_channels enable row level security;
revoke all on public.community_channels from anon;
grant select, insert, delete on public.community_channels to authenticated;

drop policy if exists community_channels_read_members on public.community_channels;
create policy community_channels_read_members
on public.community_channels for select to authenticated
using (private.is_community_member(community_id) or private.is_community_owner(community_id));

drop policy if exists community_channels_create_owner on public.community_channels;
create policy community_channels_create_owner
on public.community_channels for insert to authenticated
with check (
  created_by = (select auth.uid())
  and (
    private.is_community_owner(community_id)
    or exists (
      select 1 from public.community_members cm
      where cm.community_id = community_channels.community_id
        and cm.user_id = (select auth.uid())
        and cm.role = 'moderator'
    )
  )
  and exists (
    select 1 from public.conversations c
    where c.id = conversation_id
      and c.created_by = (select auth.uid())
      and c.conversation_type = 'community'
  )
);

drop policy if exists community_channels_delete_owner on public.community_channels;
create policy community_channels_delete_owner
on public.community_channels for delete to authenticated
using (private.is_community_owner(community_id));

create or replace function private.sync_community_channel_members()
returns trigger
language plpgsql
security definer
set search_path = pg_catalog, public, private
as $$
begin
  if tg_table_name = 'community_members' then
    if tg_op = 'INSERT' then
      insert into public.conversation_members (conversation_id, user_id, role)
      select ch.conversation_id, new.user_id, 'member'
      from public.community_channels ch
      where ch.community_id = new.community_id
      on conflict (conversation_id, user_id) do nothing;
      return new;
    elsif tg_op = 'DELETE' then
      delete from public.conversation_members cm
      using public.community_channels ch
      where ch.community_id = old.community_id
        and cm.conversation_id = ch.conversation_id
        and cm.user_id = old.user_id;
      return old;
    end if;
  elsif tg_table_name = 'community_channels' and tg_op = 'INSERT' then
    insert into public.conversation_members (conversation_id, user_id, role)
    select new.conversation_id, cm.user_id,
           case when cm.user_id = new.created_by then 'owner' else 'member' end
    from public.community_members cm
    where cm.community_id = new.community_id
    on conflict (conversation_id, user_id) do nothing;
    return new;
  end if;
  return null;
end;
$$;

revoke all on function private.sync_community_channel_members() from public, anon, authenticated;

drop trigger if exists sync_community_channels_after_member_insert on public.community_members;
create trigger sync_community_channels_after_member_insert
after insert on public.community_members
for each row execute function private.sync_community_channel_members();

drop trigger if exists sync_community_channels_after_member_delete on public.community_members;
create trigger sync_community_channels_after_member_delete
after delete on public.community_members
for each row execute function private.sync_community_channel_members();

drop trigger if exists sync_community_members_after_channel_insert on public.community_channels;
create trigger sync_community_members_after_channel_insert
after insert on public.community_channels
for each row execute function private.sync_community_channel_members();
