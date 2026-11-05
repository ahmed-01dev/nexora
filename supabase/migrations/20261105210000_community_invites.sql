create table if not exists public.community_invites (
  id uuid primary key default gen_random_uuid(),
  community_id uuid not null references public.communities(id) on delete cascade,
  invite_code uuid not null unique default gen_random_uuid(),
  created_by uuid not null references public.profiles(id) on delete restrict,
  expires_at timestamptz not null,
  max_uses integer not null default 10 check (max_uses between 1 and 500),
  use_count integer not null default 0 check (use_count >= 0 and use_count <= max_uses),
  revoked_at timestamptz,
  created_at timestamptz not null default now()
);

create index if not exists community_invites_community_created_idx
  on public.community_invites(community_id, created_at desc);
create index if not exists community_invites_created_by_idx
  on public.community_invites(created_by);

alter table public.community_invites enable row level security;
revoke all on public.community_invites from public, anon, authenticated;

create policy community_invites_deny_direct_access
on public.community_invites for all to anon, authenticated
using (false) with check (false);

create or replace function private.create_community_invite_internal(
  p_community_id uuid,
  p_expires_in_hours integer default 168,
  p_max_uses integer default 10
)
returns table(invite_code uuid, expires_at timestamptz)
language plpgsql
security definer
set search_path = pg_catalog, public, private, auth
as $$
declare
  v_code uuid := gen_random_uuid();
  v_expires timestamptz;
begin
  if auth.uid() is null then
    raise exception 'Authentication required' using errcode = '42501';
  end if;
  if p_expires_in_hours is null or p_expires_in_hours < 1 or p_expires_in_hours > 720 then
    raise exception 'Invite expiry must be between 1 and 720 hours' using errcode = '22023';
  end if;
  if p_max_uses is null or p_max_uses < 1 or p_max_uses > 500 then
    raise exception 'Invite use limit must be between 1 and 500' using errcode = '22023';
  end if;
  if not private.is_community_owner(p_community_id) then
    raise exception 'Only the community owner can create invites' using errcode = '42501';
  end if;
  v_expires := now() + make_interval(hours => p_expires_in_hours);
  insert into public.community_invites (
    community_id, invite_code, created_by, expires_at, max_uses
  ) values (
    p_community_id, v_code, auth.uid(), v_expires, p_max_uses
  );
  return query select v_code, v_expires;
end;
$$;

create or replace function private.accept_community_invite_internal(p_invite_code uuid)
returns table(community_id uuid, community_name text)
language plpgsql
security definer
set search_path = pg_catalog, public, private, auth
as $$
declare
  v_invite public.community_invites%rowtype;
  v_name text;
  v_inserted integer := 0;
begin
  if auth.uid() is null then
    raise exception 'Authentication required' using errcode = '42501';
  end if;
  select ci.* into v_invite
  from public.community_invites ci
  where ci.invite_code = p_invite_code
    and ci.revoked_at is null
    and ci.expires_at > now()
    and ci.use_count < ci.max_uses
  for update;
  if not found then
    raise exception 'Invite is invalid, expired, revoked, or fully used' using errcode = '22023';
  end if;
  select c.name into v_name
  from public.communities c
  where c.id = v_invite.community_id;
  if exists (
    select 1 from public.community_members cm
    where cm.community_id = v_invite.community_id
      and cm.user_id = auth.uid()
  ) then
    return query select v_invite.community_id, v_name;
    return;
  end if;
  insert into public.community_members (community_id, user_id, role)
  values (v_invite.community_id, auth.uid(), 'member')
  on conflict (community_id, user_id) do nothing;
  get diagnostics v_inserted = row_count;
  if v_inserted > 0 then
    update public.community_invites
    set use_count = use_count + 1
    where id = v_invite.id;
  end if;
  return query select v_invite.community_id, v_name;
end;
$$;

revoke all on function private.create_community_invite_internal(uuid, integer, integer) from public, anon, authenticated;
grant execute on function private.create_community_invite_internal(uuid, integer, integer) to authenticated;
revoke all on function private.accept_community_invite_internal(uuid) from public, anon, authenticated;
grant execute on function private.accept_community_invite_internal(uuid) to authenticated;

create or replace function public.create_community_invite(
  p_community_id uuid,
  p_expires_in_hours integer default 168,
  p_max_uses integer default 10
)
returns table(invite_code uuid, expires_at timestamptz)
language sql
security invoker
set search_path = pg_catalog, public, private, auth
as $$
  select * from private.create_community_invite_internal(
    p_community_id, p_expires_in_hours, p_max_uses
  );
$$;

create or replace function public.accept_community_invite(p_invite_code uuid)
returns table(community_id uuid, community_name text)
language sql
security invoker
set search_path = pg_catalog, public, private, auth
as $$
  select * from private.accept_community_invite_internal(p_invite_code);
$$;

revoke all on function public.create_community_invite(uuid, integer, integer) from public, anon, authenticated;
grant execute on function public.create_community_invite(uuid, integer, integer) to authenticated;
revoke all on function public.accept_community_invite(uuid) from public, anon, authenticated;
grant execute on function public.accept_community_invite(uuid) to authenticated;
