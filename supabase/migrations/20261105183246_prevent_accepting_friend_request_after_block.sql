-- A pending request must not be accepted after either participant blocks
-- the other account.
create or replace function private.accept_friend_request_impl(p_request_id uuid)
returns boolean
language plpgsql
security definer
set search_path = ''
as $function$
declare
  v_me uuid := (select auth.uid());
  v_requester uuid;
begin
  if v_me is null then
    raise exception 'not authenticated' using errcode = '28000';
  end if;

  select f.requester_id
    into v_requester
  from public.friendships f
  where f.id = p_request_id
    and f.addressee_id = v_me
    and f.status = 'pending'
  for update;

  if not found then
    return false;
  end if;

  if private.is_blocked_between(v_me, v_requester) then
    raise exception 'friend requests are unavailable for this relationship' using errcode = '42501';
  end if;

  update public.friendships
  set status = 'accepted',
      updated_at = now()
  where id = p_request_id
    and addressee_id = v_me
    and status = 'pending';

  return found;
end;
$function$;

revoke all on function private.accept_friend_request_impl(uuid) from public, anon;
grant execute on function private.accept_friend_request_impl(uuid) to authenticated;
