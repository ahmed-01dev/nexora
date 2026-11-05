-- Keep privileged location access in the non-exposed private schema.
drop function if exists private.update_my_nearby_presence(double precision, double precision, boolean);
drop function if exists private.find_nearby_people(integer);
drop function if exists private.my_nearby_presence_enabled();

create or replace function private.update_my_nearby_presence(p_latitude double precision, p_longitude double precision, p_enabled boolean)
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

create or replace function private.find_nearby_people(p_limit integer default 30)
returns table (id uuid, username text, display_name text, is_verified boolean, distance_band text)
language sql stable security definer set search_path = pg_catalog, public, private as $$
  with me as (
    select latitude_approx::double precision as lat, longitude_approx::double precision as lon
    from private.profile_discovery_locations where user_id = (select auth.uid()) and updated_at > now() - interval '24 hours'
  ), candidates as (
    select p.id, p.username, p.display_name, p.is_verified,
      6371.0 * 2.0 * asin(sqrt(least(1.0,
        power(sin(radians((l.latitude_approx::double precision - me.lat) / 2.0)), 2)
        + cos(radians(me.lat)) * cos(radians(l.latitude_approx::double precision))
        * power(sin(radians((l.longitude_approx::double precision - me.lon) / 2.0)), 2)
      ))) as distance_km
    from me join private.profile_discovery_locations l on l.user_id <> (select auth.uid()) and l.updated_at > now() - interval '24 hours'
    join public.profiles p on p.id = l.user_id
    where p.is_private = false and not exists (
      select 1 from public.blocks b where (b.blocker_id = (select auth.uid()) and b.blocked_id = p.id)
      or (b.blocker_id = p.id and b.blocked_id = (select auth.uid()))
    )
  )
  select c.id, c.username, c.display_name, c.is_verified,
    case when c.distance_km < 5 then 'under_5_km' when c.distance_km < 15 then '5_15_km' else '15_25_km' end
  from candidates c where c.distance_km <= 25 order by c.distance_km asc, c.id asc
  limit least(greatest(coalesce(p_limit, 30), 1), 50);
$$;

create or replace function private.my_nearby_presence_enabled()
returns boolean language sql stable security definer set search_path = pg_catalog, public, private as $$
  select exists (select 1 from private.profile_discovery_locations where user_id = (select auth.uid()) and updated_at > now() - interval '24 hours');
$$;

revoke all on function private.update_my_nearby_presence(double precision, double precision, boolean) from public, anon;
revoke all on function private.find_nearby_people(integer) from public, anon;
revoke all on function private.my_nearby_presence_enabled() from public, anon;
grant execute on function private.update_my_nearby_presence(double precision, double precision, boolean) to authenticated;
grant execute on function private.find_nearby_people(integer) to authenticated;
grant execute on function private.my_nearby_presence_enabled() to authenticated;

create or replace function public.update_my_nearby_presence(p_latitude double precision, p_longitude double precision, p_enabled boolean)
returns void language sql security invoker set search_path = pg_catalog, public, private
as $$ select private.update_my_nearby_presence(p_latitude, p_longitude, p_enabled); $$;
create or replace function public.find_nearby_people(p_limit integer default 30)
returns table (id uuid, username text, display_name text, is_verified boolean, distance_band text)
language sql stable security invoker set search_path = pg_catalog, public, private
as $$ select * from private.find_nearby_people(p_limit); $$;
create or replace function public.my_nearby_presence_enabled()
returns boolean language sql stable security invoker set search_path = pg_catalog, public, private
as $$ select private.my_nearby_presence_enabled(); $$;

revoke all on function public.update_my_nearby_presence(double precision, double precision, boolean) from public, anon;
revoke all on function public.find_nearby_people(integer) from public, anon;
revoke all on function public.my_nearby_presence_enabled() from public, anon;
grant execute on function public.update_my_nearby_presence(double precision, double precision, boolean) to authenticated;
grant execute on function public.find_nearby_people(integer) to authenticated;
grant execute on function public.my_nearby_presence_enabled() to authenticated;

drop policy if exists profile_discovery_locations_owner_only on private.profile_discovery_locations;
create policy profile_discovery_locations_owner_only on private.profile_discovery_locations
for all to authenticated using (user_id = (select auth.uid())) with check (user_id = (select auth.uid()));
