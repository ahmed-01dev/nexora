-- Remove expired opt-in nearby coordinates regularly, not only when
-- another user refreshes nearby discovery or updates their own location.
create extension if not exists pg_cron with schema pg_catalog;

grant usage on schema cron to postgres;
grant all privileges on all tables in schema cron to postgres;

do $$
declare
  v_job_id bigint;
begin
  select jobid into v_job_id
  from cron.job
  where jobname = 'nexora-cleanup-expired-nearby-locations'
  limit 1;

  if v_job_id is not null then
    perform cron.unschedule(v_job_id);
  end if;

  perform cron.schedule(
    'nexora-cleanup-expired-nearby-locations',
    '*/15 * * * *',
    $job$
      delete from private.profile_discovery_locations
      where updated_at <= now() - interval '24 hours';
    $job$
  );
end;
$$;
