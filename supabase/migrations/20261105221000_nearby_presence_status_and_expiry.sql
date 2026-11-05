create or replace function public.update_my_nearby_presence(p_latitude double precision, p_longitude double precision, p_enabled boolean)
returns void language plpgsql security definer set search_path = pg_catalog, public, private as $$
declare v_user_id uuid := (select auth.uid());
begin
  if v_user_id is null then raise exception 'Authentication required' using errcode = '28000'; end if;
  delete from private.profile_discovery_locations where updated_at <= now() - interval '24 hours';
  if p_enabled is not true then delete from private.profile_discovery_locations where user_id = v_user_id; return; end if;
  if p_latitude is null or p_longitude is null or p_latitude < -90 or p_latitude > 90 or p_longitude < -180 or p_longitude > 180 then
    raise exception 'Invalid location coordinates' using errcode = '22023';
  end if;
  insert into private.profile_discovery_locations(user_id, latitude_approx, longitude_approx, updated_at)
  values (v_user_id, round(p_latitude::numeric, 2), round(p_longitude::numeric, 2), now())
  on conflict (user_id) do update set latitude_approx = excluded.latitude_approx, longitude_approx = excluded.longitude_approx, updated_at = now();
end;
$$;
create or replace function public.my_nearby_presence_enabled()
returns boolean language sql stable security definer set search_path = pg_catalog, public, private as $$
  select exists (select 1 from private.profile_discovery_locations where user_id = (select auth.uid()) and updated_at > now() - interval '24 hours');
$$;
revoke all on function public.my_nearby_presence_enabled() from public, anon;
grant execute on function public.my_nearby_presence_enabled() to authenticated;
