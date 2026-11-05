create extension if not exists pg_net with schema extensions;

create schema if not exists private;

create or replace function private.notify_nexora_push()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_webhook_secret text;
begin
  select decrypted_secret
    into v_webhook_secret
    from vault.decrypted_secrets
   where name = 'nexora_push_webhook_secret';

  if v_webhook_secret is null or v_webhook_secret = '' then
    return new;
  end if;

  perform net.http_post(
    url := 'https://wwdeexgkwpftyavbhiff.supabase.co/functions/v1/send-push-notification',
    body := jsonb_build_object('notification_id', new.id),
    headers := jsonb_build_object(
      'Content-Type', 'application/json',
      'x-nexora-webhook-secret', v_webhook_secret
    ),
    timeout_milliseconds := 5000
  );

  return new;
end;
$$;

revoke all on function private.notify_nexora_push() from public, anon, authenticated;

drop trigger if exists notify_nexora_push_after_insert on public.notifications;

create trigger notify_nexora_push_after_insert
after insert on public.notifications
for each row
execute function private.notify_nexora_push();
