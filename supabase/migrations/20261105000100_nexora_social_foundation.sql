-- NEXORA social foundation migration
-- Safe additive migration: preserves existing profiles/posts/media/follows/likes/comments/saves.
create schema if not exists private;
revoke all on schema private from public, anon, authenticated;
grant usage on schema private to authenticated;

alter table public.profiles
  add column if not exists account_type text not null default 'personal',
  add column if not exists website text,
  add column if not exists pronouns text,
  add column if not exists country_code text,
  add column if not exists social_links jsonb not null default '{}'::jsonb,
  add column if not exists updated_at timestamptz not null default now();

create table if not exists public.friendships (
  id uuid primary key default gen_random_uuid(),
  requester_id uuid not null references public.profiles(id) on delete cascade,
  addressee_id uuid not null references public.profiles(id) on delete cascade,
  status text not null default 'pending' check (status in ('pending','accepted','declined','cancelled')),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint friendships_no_self check (requester_id <> addressee_id),
  constraint friendships_unique_pair unique (requester_id, addressee_id)
);

create table if not exists public.blocks (
  blocker_id uuid not null references public.profiles(id) on delete cascade,
  blocked_id uuid not null references public.profiles(id) on delete cascade,
  created_at timestamptz not null default now(),
  primary key (blocker_id, blocked_id),
  constraint blocks_no_self check (blocker_id <> blocked_id)
);

create table if not exists public.conversations (
  id uuid primary key default gen_random_uuid(),
  created_by uuid not null references public.profiles(id) on delete restrict,
  conversation_type text not null default 'direct' check (conversation_type in ('direct','group','community')),
  title text,
  avatar_path text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  last_message_at timestamptz
);

create table if not exists public.conversation_members (
  conversation_id uuid not null references public.conversations(id) on delete cascade,
  user_id uuid not null references public.profiles(id) on delete cascade,
  role text not null default 'member' check (role in ('owner','admin','member')),
  joined_at timestamptz not null default now(),
  last_read_at timestamptz,
  muted_until timestamptz,
  archived_at timestamptz,
  primary key (conversation_id, user_id)
);

create table if not exists public.messages (
  id uuid primary key default gen_random_uuid(),
  conversation_id uuid not null references public.conversations(id) on delete cascade,
  sender_id uuid not null references public.profiles(id) on delete restrict,
  message_type text not null default 'text' check (message_type in ('text','image','video','audio','file','post','profile','location','system')),
  body text,
  reply_to uuid references public.messages(id) on delete set null,
  encryption_mode text not null default 'server_readable' check (encryption_mode in ('server_readable','e2ee_pending','e2ee')),
  ciphertext text,
  nonce text,
  edited_at timestamptz,
  deleted_at timestamptz,
  created_at timestamptz not null default now(),
  constraint messages_body_or_cipher check (body is not null or ciphertext is not null or message_type <> 'text')
);

create table if not exists public.message_attachments (
  id uuid primary key default gen_random_uuid(),
  message_id uuid not null references public.messages(id) on delete cascade,
  uploader_id uuid not null references public.profiles(id) on delete cascade,
  storage_path text not null,
  mime_type text not null,
  size_bytes bigint not null check (size_bytes > 0),
  created_at timestamptz not null default now()
);

create table if not exists public.message_reactions (
  message_id uuid not null references public.messages(id) on delete cascade,
  user_id uuid not null references public.profiles(id) on delete cascade,
  reaction text not null check (char_length(reaction) between 1 and 32),
  created_at timestamptz not null default now(),
  primary key (message_id, user_id, reaction)
);

create table if not exists public.notifications (
  id uuid primary key default gen_random_uuid(),
  recipient_id uuid not null references public.profiles(id) on delete cascade,
  actor_id uuid references public.profiles(id) on delete set null,
  notification_type text not null check (notification_type in ('like','comment','reply','follow','friend_request','friend_accepted','mention','repost','message','call','group_invite','system','security')),
  entity_type text,
  entity_id uuid,
  payload jsonb not null default '{}'::jsonb,
  read_at timestamptz,
  created_at timestamptz not null default now()
);

create table if not exists public.stories (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.profiles(id) on delete cascade,
  media_path text,
  text_content text,
  story_type text not null default 'photo' check (story_type in ('photo','video','text')),
  visibility text not null default 'followers' check (visibility in ('public','followers','close_friends')),
  created_at timestamptz not null default now(),
  expires_at timestamptz not null default (now() + interval '24 hours'),
  archived_at timestamptz,
  constraint stories_content_required check (media_path is not null or nullif(text_content,'') is not null)
);

create table if not exists public.story_views (
  story_id uuid not null references public.stories(id) on delete cascade,
  viewer_id uuid not null references public.profiles(id) on delete cascade,
  viewed_at timestamptz not null default now(),
  primary key (story_id, viewer_id)
);

create table if not exists public.communities (
  id uuid primary key default gen_random_uuid(),
  owner_id uuid not null references public.profiles(id) on delete restrict,
  name text not null check (char_length(name) between 2 and 80),
  slug text not null unique check (slug ~ '^[a-z0-9-]{3,60}$'),
  description text not null default '',
  visibility text not null default 'public' check (visibility in ('public','private','invite_only')),
  cover_path text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.community_members (
  community_id uuid not null references public.communities(id) on delete cascade,
  user_id uuid not null references public.profiles(id) on delete cascade,
  role text not null default 'member' check (role in ('owner','moderator','member')),
  joined_at timestamptz not null default now(),
  primary key (community_id, user_id)
);

create table if not exists public.reports (
  id uuid primary key default gen_random_uuid(),
  reporter_id uuid not null references public.profiles(id) on delete cascade,
  target_type text not null check (target_type in ('user','post','comment','message','story','community')),
  target_id uuid not null,
  reason text not null check (reason in ('harassment','threats','spam','scam','impersonation','sexual_content','child_safety','dangerous_content','illegal_content','copyright','other')),
  details text not null default '',
  status text not null default 'open' check (status in ('open','reviewing','actioned','dismissed','appealed')),
  created_at timestamptz not null default now(),
  resolved_at timestamptz
);

create table if not exists public.call_sessions (
  id uuid primary key default gen_random_uuid(),
  conversation_id uuid not null references public.conversations(id) on delete cascade,
  initiated_by uuid not null references public.profiles(id) on delete restrict,
  call_type text not null check (call_type in ('voice','video','group_voice','group_video')),
  status text not null default 'ringing' check (status in ('ringing','active','ended','missed','rejected','failed')),
  started_at timestamptz not null default now(),
  ended_at timestamptz
);

create table if not exists public.call_participants (
  call_id uuid not null references public.call_sessions(id) on delete cascade,
  user_id uuid not null references public.profiles(id) on delete cascade,
  joined_at timestamptz,
  left_at timestamptz,
  primary key (call_id, user_id)
);

create index if not exists friendships_addressee_status_idx on public.friendships(addressee_id,status,created_at desc);
create index if not exists blocks_blocked_idx on public.blocks(blocked_id);
create index if not exists conversation_members_user_idx on public.conversation_members(user_id,conversation_id);
create index if not exists messages_conversation_created_idx on public.messages(conversation_id,created_at desc);
create index if not exists message_attachments_message_idx on public.message_attachments(message_id);
create index if not exists notifications_recipient_created_idx on public.notifications(recipient_id,created_at desc);
create index if not exists stories_expiry_idx on public.stories(expires_at) where archived_at is null;
create index if not exists stories_user_created_idx on public.stories(user_id,created_at desc);
create index if not exists communities_visibility_created_idx on public.communities(visibility,created_at desc);
create index if not exists community_members_user_idx on public.community_members(user_id,community_id);
create index if not exists reports_status_created_idx on public.reports(status,created_at);
create index if not exists call_sessions_conversation_created_idx on public.call_sessions(conversation_id,started_at desc);

create or replace function private.is_conversation_member(p_conversation_id uuid)
returns boolean language sql stable security definer set search_path = ''
as $$
  select exists (
    select 1 from public.conversation_members cm
    where cm.conversation_id = p_conversation_id
      and cm.user_id = (select auth.uid())
  );
$$;

create or replace function private.is_conversation_creator(p_conversation_id uuid)
returns boolean language sql stable security definer set search_path = ''
as $$
  select exists (
    select 1 from public.conversations c
    where c.id = p_conversation_id
      and c.created_by = (select auth.uid())
  );
$$;

create or replace function private.is_community_member(p_community_id uuid)
returns boolean language sql stable security definer set search_path = ''
as $$
  select exists (
    select 1 from public.community_members cm
    where cm.community_id = p_community_id
      and cm.user_id = (select auth.uid())
  );
$$;

create or replace function private.is_community_owner(p_community_id uuid)
returns boolean language sql stable security definer set search_path = ''
as $$
  select exists (
    select 1 from public.communities c
    where c.id = p_community_id
      and c.owner_id = (select auth.uid())
  );
$$;

revoke all on function private.is_conversation_member(uuid) from public, anon;
revoke all on function private.is_conversation_creator(uuid) from public, anon;
revoke all on function private.is_community_member(uuid) from public, anon;
revoke all on function private.is_community_owner(uuid) from public, anon;
grant execute on function private.is_conversation_member(uuid) to authenticated;
grant execute on function private.is_conversation_creator(uuid) to authenticated;
grant execute on function private.is_community_member(uuid) to authenticated;
grant execute on function private.is_community_owner(uuid) to authenticated;

alter table public.friendships enable row level security;
alter table public.blocks enable row level security;
alter table public.conversations enable row level security;
alter table public.conversation_members enable row level security;
alter table public.messages enable row level security;
alter table public.message_attachments enable row level security;
alter table public.message_reactions enable row level security;
alter table public.notifications enable row level security;
alter table public.stories enable row level security;
alter table public.story_views enable row level security;
alter table public.communities enable row level security;
alter table public.community_members enable row level security;
alter table public.reports enable row level security;
alter table public.call_sessions enable row level security;
alter table public.call_participants enable row level security;

revoke all on public.friendships, public.blocks, public.conversations, public.conversation_members,
  public.messages, public.message_attachments, public.message_reactions, public.notifications,
  public.stories, public.story_views, public.communities, public.community_members,
  public.reports, public.call_sessions, public.call_participants from anon, authenticated;

grant select,insert,delete on public.friendships, public.blocks to authenticated;
grant update(status) on public.friendships to authenticated;
grant select,insert on public.conversations to authenticated;
grant update(title,avatar_path,updated_at) on public.conversations to authenticated;
grant select,insert,delete on public.conversation_members to authenticated;
grant update(last_read_at,muted_until,archived_at) on public.conversation_members to authenticated;
grant select,insert,delete on public.messages to authenticated;
grant update(body,edited_at,deleted_at) on public.messages to authenticated;
grant select,insert,delete on public.message_attachments to authenticated;
grant select,insert,delete on public.message_reactions to authenticated;
grant select,update on public.notifications to authenticated;
grant select,insert,update,delete on public.stories to authenticated;
grant select,insert on public.story_views to authenticated;
grant select,insert,delete on public.communities to authenticated;
grant update(name,slug,description,visibility,cover_path,updated_at) on public.communities to authenticated;
grant select,insert,delete on public.community_members to authenticated;
grant update(role) on public.community_members to authenticated;
grant select,insert on public.reports to authenticated;
grant select,insert on public.call_sessions to authenticated;
grant update(status,ended_at) on public.call_sessions to authenticated;
grant select,insert on public.call_participants to authenticated;
grant update(joined_at,left_at) on public.call_participants to authenticated;

drop policy if exists friendships_read_participant on public.friendships;
create policy friendships_read_participant on public.friendships for select to authenticated
using ((select auth.uid()) in (requester_id,addressee_id));
drop policy if exists friendships_request_self on public.friendships;
create policy friendships_request_self on public.friendships for insert to authenticated
with check (requester_id = (select auth.uid()));
drop policy if exists friendships_recipient_update on public.friendships;
create policy friendships_recipient_update on public.friendships for update to authenticated
using (addressee_id = (select auth.uid()) or requester_id = (select auth.uid()))
with check ((addressee_id = (select auth.uid()) and status in ('accepted','declined')) or (requester_id = (select auth.uid()) and status = 'cancelled'));
drop policy if exists friendships_delete_participant on public.friendships;
create policy friendships_delete_participant on public.friendships for delete to authenticated
using ((select auth.uid()) in (requester_id,addressee_id));

drop policy if exists blocks_manage_own on public.blocks;
create policy blocks_manage_own on public.blocks for all to authenticated
using (blocker_id = (select auth.uid())) with check (blocker_id = (select auth.uid()));

drop policy if exists conversations_read_members on public.conversations;
create policy conversations_read_members on public.conversations for select to authenticated
using (private.is_conversation_member(id));
drop policy if exists conversations_create_self on public.conversations;
create policy conversations_create_self on public.conversations for insert to authenticated
with check (created_by = (select auth.uid()));
drop policy if exists conversations_update_creator on public.conversations;
create policy conversations_update_creator on public.conversations for update to authenticated
using (created_by = (select auth.uid())) with check (created_by = (select auth.uid()));

drop policy if exists conversation_members_read_members on public.conversation_members;
create policy conversation_members_read_members on public.conversation_members for select to authenticated
using (private.is_conversation_member(conversation_id));
drop policy if exists conversation_members_add_by_creator on public.conversation_members;
create policy conversation_members_add_by_creator on public.conversation_members for insert to authenticated
with check (private.is_conversation_creator(conversation_id) or (user_id = (select auth.uid()) and private.is_conversation_member(conversation_id)));
drop policy if exists conversation_members_update_self on public.conversation_members;
create policy conversation_members_update_self on public.conversation_members for update to authenticated
using (user_id = (select auth.uid()) or private.is_conversation_creator(conversation_id))
with check (user_id = (select auth.uid()) or private.is_conversation_creator(conversation_id));
drop policy if exists conversation_members_remove on public.conversation_members;
create policy conversation_members_remove on public.conversation_members for delete to authenticated
using (user_id = (select auth.uid()) or private.is_conversation_creator(conversation_id));

drop policy if exists messages_read_members on public.messages;
create policy messages_read_members on public.messages for select to authenticated
using (private.is_conversation_member(conversation_id));
drop policy if exists messages_send_as_self on public.messages;
create policy messages_send_as_self on public.messages for insert to authenticated
with check (sender_id = (select auth.uid()) and private.is_conversation_member(conversation_id));
drop policy if exists messages_edit_own on public.messages;
create policy messages_edit_own on public.messages for update to authenticated
using (sender_id = (select auth.uid()) and private.is_conversation_member(conversation_id))
with check (sender_id = (select auth.uid()) and private.is_conversation_member(conversation_id));
drop policy if exists messages_delete_own on public.messages;
create policy messages_delete_own on public.messages for delete to authenticated
using (sender_id = (select auth.uid()) or private.is_conversation_creator(conversation_id));

drop policy if exists attachments_read_members on public.message_attachments;
create policy attachments_read_members on public.message_attachments for select to authenticated
using (exists (select 1 from public.messages m where m.id = message_id and private.is_conversation_member(m.conversation_id)));
drop policy if exists attachments_insert_self on public.message_attachments;
create policy attachments_insert_self on public.message_attachments for insert to authenticated
with check (uploader_id = (select auth.uid()) and exists (select 1 from public.messages m where m.id = message_id and m.sender_id = (select auth.uid()) and private.is_conversation_member(m.conversation_id)));
drop policy if exists attachments_delete_self on public.message_attachments;
create policy attachments_delete_self on public.message_attachments for delete to authenticated
using (uploader_id = (select auth.uid()));

drop policy if exists reactions_read_members on public.message_reactions;
create policy reactions_read_members on public.message_reactions for select to authenticated
using (exists (select 1 from public.messages m where m.id = message_id and private.is_conversation_member(m.conversation_id)));
drop policy if exists reactions_insert_self on public.message_reactions;
create policy reactions_insert_self on public.message_reactions for insert to authenticated
with check (user_id = (select auth.uid()) and exists (select 1 from public.messages m where m.id = message_id and private.is_conversation_member(m.conversation_id)));
drop policy if exists reactions_delete_self on public.message_reactions;
create policy reactions_delete_self on public.message_reactions for delete to authenticated
using (user_id = (select auth.uid()));

drop policy if exists notifications_read_self on public.notifications;
create policy notifications_read_self on public.notifications for select to authenticated
using (recipient_id = (select auth.uid()));
drop policy if exists notifications_update_self on public.notifications;
create policy notifications_update_self on public.notifications for update to authenticated
using (recipient_id = (select auth.uid())) with check (recipient_id = (select auth.uid()));

drop policy if exists stories_read_visible on public.stories;
create policy stories_read_visible on public.stories for select to authenticated
using (
  user_id = (select auth.uid()) or
  (archived_at is null and expires_at > now() and visibility = 'public') or
  (archived_at is null and expires_at > now() and visibility = 'followers' and exists (
    select 1 from public.follows f where f.follower_id = (select auth.uid()) and f.following_id = stories.user_id and f.status = 'accepted'
  ))
);
drop policy if exists stories_insert_self on public.stories;
create policy stories_insert_self on public.stories for insert to authenticated
with check (user_id = (select auth.uid()));
drop policy if exists stories_update_self on public.stories;
create policy stories_update_self on public.stories for update to authenticated
using (user_id = (select auth.uid())) with check (user_id = (select auth.uid()));
drop policy if exists stories_delete_self on public.stories;
create policy stories_delete_self on public.stories for delete to authenticated
using (user_id = (select auth.uid()));

drop policy if exists story_views_read_owner on public.story_views;
create policy story_views_read_owner on public.story_views for select to authenticated
using (exists (select 1 from public.stories s where s.id = story_id and s.user_id = (select auth.uid())));
drop policy if exists story_views_insert_viewer on public.story_views;
create policy story_views_insert_viewer on public.story_views for insert to authenticated
with check (viewer_id = (select auth.uid()) and exists (select 1 from public.stories s where s.id = story_id and s.archived_at is null and s.expires_at > now() and (s.user_id = (select auth.uid()) or s.visibility = 'public' or (s.visibility = 'followers' and exists (select 1 from public.follows f where f.follower_id = (select auth.uid()) and f.following_id = s.user_id and f.status = 'accepted')))));

drop policy if exists communities_read_visible on public.communities;
create policy communities_read_visible on public.communities for select to authenticated
using (owner_id = (select auth.uid()) or visibility = 'public' or private.is_community_member(id));
drop policy if exists communities_create_self on public.communities;
create policy communities_create_self on public.communities for insert to authenticated
with check (owner_id = (select auth.uid()));
drop policy if exists communities_update_owner on public.communities;
create policy communities_update_owner on public.communities for update to authenticated
using (owner_id = (select auth.uid())) with check (owner_id = (select auth.uid()));
drop policy if exists communities_delete_owner on public.communities;
create policy communities_delete_owner on public.communities for delete to authenticated
using (owner_id = (select auth.uid()));

drop policy if exists community_members_read_members on public.community_members;
create policy community_members_read_members on public.community_members for select to authenticated
using (private.is_community_member(community_id) or private.is_community_owner(community_id));
drop policy if exists community_members_join_public on public.community_members;
create policy community_members_join_public on public.community_members for insert to authenticated
with check (user_id = (select auth.uid()) and (
  private.is_community_owner(community_id) or exists (
    select 1 from public.communities c where c.id = community_id and c.visibility = 'public'
  )
));
drop policy if exists community_members_leave_or_owner_remove on public.community_members;
create policy community_members_leave_or_owner_remove on public.community_members for delete to authenticated
using (user_id = (select auth.uid()) or private.is_community_owner(community_id));
drop policy if exists community_members_owner_update on public.community_members;
create policy community_members_owner_update on public.community_members for update to authenticated
using (private.is_community_owner(community_id)) with check (private.is_community_owner(community_id));

drop policy if exists reports_create_self on public.reports;
create policy reports_create_self on public.reports for insert to authenticated
with check (reporter_id = (select auth.uid()));
drop policy if exists reports_read_self on public.reports;
create policy reports_read_self on public.reports for select to authenticated
using (reporter_id = (select auth.uid()));

drop policy if exists call_sessions_read_members on public.call_sessions;
create policy call_sessions_read_members on public.call_sessions for select to authenticated
using (private.is_conversation_member(conversation_id));
drop policy if exists call_sessions_create_member on public.call_sessions;
create policy call_sessions_create_member on public.call_sessions for insert to authenticated
with check (initiated_by = (select auth.uid()) and private.is_conversation_member(conversation_id));
drop policy if exists call_sessions_update_members on public.call_sessions;
create policy call_sessions_update_members on public.call_sessions for update to authenticated
using (private.is_conversation_member(conversation_id)) with check (private.is_conversation_member(conversation_id));

drop policy if exists call_participants_read_members on public.call_participants;
create policy call_participants_read_members on public.call_participants for select to authenticated
using (exists (select 1 from public.call_sessions c where c.id = call_id and private.is_conversation_member(c.conversation_id)));
drop policy if exists call_participants_manage_self on public.call_participants;
create policy call_participants_manage_self on public.call_participants for insert to authenticated
with check (user_id = (select auth.uid()) and exists (select 1 from public.call_sessions c where c.id = call_id and private.is_conversation_member(c.conversation_id)));
drop policy if exists call_participants_update_self on public.call_participants;
create policy call_participants_update_self on public.call_participants for update to authenticated
using (user_id = (select auth.uid())) with check (user_id = (select auth.uid()));

-- Notifications are written by trusted database triggers or server-side workers only.

-- Keep private birth-date and privacy controls out of the publicly readable profile row.
alter table public.profiles drop column if exists date_of_birth;

create table if not exists public.user_private_settings (
  user_id uuid primary key references public.profiles(id) on delete cascade,
  date_of_birth date,
  profile_visibility text not null default 'public' check (profile_visibility in ('public','private')),
  allow_friend_requests boolean not null default true,
  allow_messages_from text not null default 'followers' check (allow_messages_from in ('everyone','followers','friends','nobody')),
  allow_mentions_from text not null default 'everyone' check (allow_mentions_from in ('everyone','followers','friends','nobody')),
  show_online_status boolean not null default true,
  show_read_receipts boolean not null default true,
  discoverable boolean not null default true,
  location_visibility text not null default 'invisible' check (location_visibility in ('invisible','friends','selected')),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);
alter table public.user_private_settings enable row level security;
revoke all on public.user_private_settings from anon, authenticated;
grant select,insert,update on public.user_private_settings to authenticated;
drop policy if exists user_private_settings_read_self on public.user_private_settings;
create policy user_private_settings_read_self on public.user_private_settings for select to authenticated
using (user_id = (select auth.uid()));
drop policy if exists user_private_settings_insert_self on public.user_private_settings;
create policy user_private_settings_insert_self on public.user_private_settings for insert to authenticated
with check (user_id = (select auth.uid()));
drop policy if exists user_private_settings_update_self on public.user_private_settings;
create policy user_private_settings_update_self on public.user_private_settings for update to authenticated
using (user_id = (select auth.uid())) with check (user_id = (select auth.uid()));

create table if not exists public.user_preferences (
  user_id uuid primary key references public.profiles(id) on delete cascade,
  language_code text not null default 'ar',
  theme text not null default 'amoled' check (theme in ('amoled','light','pink_amoled','custom')),
  accent_color text not null default '#FFFFFF',
  autoplay_videos boolean not null default true,
  reduce_motion boolean not null default false,
  low_data_mode boolean not null default false,
  push_notifications_enabled boolean not null default true,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);
alter table public.user_preferences enable row level security;
revoke all on public.user_preferences from anon, authenticated;
grant select,insert,update on public.user_preferences to authenticated;
drop policy if exists user_preferences_manage_self on public.user_preferences;
create policy user_preferences_manage_self on public.user_preferences for all to authenticated
using (user_id = (select auth.uid())) with check (user_id = (select auth.uid()));


-- Safe direct-message creation: checks privacy and bilateral blocks server-side.
create or replace function private.create_direct_conversation_impl(p_other_user_id uuid)
returns uuid
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_me uuid := auth.uid();
  v_conversation_id uuid;
  v_message_policy text;
begin
  if v_me is null then
    raise exception 'not authenticated' using errcode = '28000';
  end if;
  if p_other_user_id is null or p_other_user_id = v_me then
    raise exception 'invalid recipient' using errcode = '22023';
  end if;
  if not exists (select 1 from public.profiles p where p.id = p_other_user_id) then
    raise exception 'recipient not found' using errcode = 'P0002';
  end if;
  if exists (
    select 1 from public.blocks b
    where (b.blocker_id = v_me and b.blocked_id = p_other_user_id)
       or (b.blocker_id = p_other_user_id and b.blocked_id = v_me)
  ) then
    raise exception 'messaging is unavailable for this relationship' using errcode = '42501';
  end if;

  select s.allow_messages_from into v_message_policy
  from public.user_private_settings s where s.user_id = p_other_user_id;
  v_message_policy := coalesce(v_message_policy, 'followers');

  if v_message_policy = 'nobody'
     or (v_message_policy = 'followers' and not exists (
       select 1 from public.follows f
       where f.follower_id = v_me and f.following_id = p_other_user_id and f.status = 'accepted'
     ))
     or (v_message_policy = 'friends' and not exists (
       select 1 from public.friendships fr
       where fr.status = 'accepted'
         and ((fr.requester_id = v_me and fr.addressee_id = p_other_user_id)
           or (fr.requester_id = p_other_user_id and fr.addressee_id = v_me))
     )) then
    raise exception 'recipient privacy settings do not allow this message' using errcode = '42501';
  end if;

  perform pg_advisory_xact_lock(hashtextextended(least(v_me::text, p_other_user_id::text) || ':' || greatest(v_me::text, p_other_user_id::text), 0));

  select c.id into v_conversation_id
  from public.conversations c
  where c.conversation_type = 'direct'
    and exists (select 1 from public.conversation_members cm where cm.conversation_id = c.id and cm.user_id = v_me)
    and exists (select 1 from public.conversation_members cm where cm.conversation_id = c.id and cm.user_id = p_other_user_id)
    and (select count(*) from public.conversation_members cm where cm.conversation_id = c.id) = 2
  order by c.created_at desc
  limit 1;

  if v_conversation_id is not null then
    return v_conversation_id;
  end if;

  insert into public.conversations(created_by, conversation_type)
  values (v_me, 'direct')
  returning id into v_conversation_id;

  insert into public.conversation_members(conversation_id, user_id, role)
  values (v_conversation_id, v_me, 'owner'), (v_conversation_id, p_other_user_id, 'member');

  return v_conversation_id;
end;
$$;

revoke all on function private.create_direct_conversation_impl(uuid) from public, anon;
grant execute on function private.create_direct_conversation_impl(uuid) to authenticated;

create or replace function private.on_message_insert()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
begin
  update public.conversations
  set last_message_at = new.created_at, updated_at = new.created_at
  where id = new.conversation_id;

  insert into public.notifications(recipient_id, actor_id, notification_type, entity_type, entity_id, payload)
  select cm.user_id, new.sender_id, 'message', 'message', new.id,
         jsonb_build_object('conversation_id', new.conversation_id)
  from public.conversation_members cm
  where cm.conversation_id = new.conversation_id
    and cm.user_id <> new.sender_id;

  return new;
end;
$$;
revoke all on function private.on_message_insert() from public, anon, authenticated;

drop trigger if exists nexora_message_after_insert on public.messages;
create trigger nexora_message_after_insert
after insert on public.messages
for each row execute function private.on_message_insert();

drop policy if exists profiles_visible_to_conversation_participants on public.profiles;
create policy profiles_visible_to_conversation_participants on public.profiles
for select to authenticated
using (
  exists (
    select 1 from public.conversation_members cm
    where cm.user_id = profiles.id
      and private.is_conversation_member(cm.conversation_id)
  )
);

do $$
begin
  if exists (select 1 from pg_publication where pubname = 'supabase_realtime')
     and not exists (
       select 1 from pg_publication_tables
       where pubname = 'supabase_realtime' and schemaname = 'public' and tablename = 'messages'
     ) then
    execute 'alter publication supabase_realtime add table public.messages';
  end if;
end;
$$;

-- Follow requests respect private profiles and mutual blocks.
create or replace function private.request_follow_impl(p_target_user_id uuid)
returns text language plpgsql security definer set search_path = ''
as $$
declare v_me uuid := auth.uid(); v_private boolean; v_status text;
begin
  if v_me is null then raise exception 'not authenticated' using errcode = '28000'; end if;
  if p_target_user_id is null or p_target_user_id = v_me then raise exception 'invalid follow target' using errcode = '22023'; end if;
  select p.is_private into v_private from public.profiles p where p.id = p_target_user_id;
  if not found then raise exception 'profile not found' using errcode = 'P0002'; end if;
  if exists (select 1 from public.blocks b where (b.blocker_id=v_me and b.blocked_id=p_target_user_id) or (b.blocker_id=p_target_user_id and b.blocked_id=v_me)) then
    raise exception 'following is unavailable for this relationship' using errcode = '42501';
  end if;
  insert into public.follows(follower_id,following_id,status)
  values(v_me,p_target_user_id,case when coalesce(v_private,false) then 'pending' else 'accepted' end)
  on conflict(follower_id,following_id) do nothing;
  select f.status into v_status from public.follows f where f.follower_id=v_me and f.following_id=p_target_user_id;
  return v_status;
end;
$$;

create or replace function private.cancel_follow_impl(p_target_user_id uuid)
returns boolean language plpgsql security definer set search_path = ''
as $$
declare v_me uuid := auth.uid();
begin
  if v_me is null then raise exception 'not authenticated' using errcode = '28000'; end if;
  delete from public.follows f where f.follower_id=v_me and f.following_id=p_target_user_id;
  return found;
end;
$$;

revoke all on function private.request_follow_impl(uuid) from public, anon;
revoke all on function private.cancel_follow_impl(uuid) from public, anon;
grant execute on function private.request_follow_impl(uuid) to authenticated;
grant execute on function private.cancel_follow_impl(uuid) to authenticated;

-- Close privilege-escalation paths left by broad legacy table grants.
revoke insert, update on public.profiles from authenticated;
grant update(display_name,username,bio,is_private,avatar_url,cover_url,website,pronouns,country_code,social_links,updated_at)
  on public.profiles to authenticated;

revoke insert, update on public.follows from authenticated;
grant update(status) on public.follows to authenticated;

revoke insert, update on public.friendships from authenticated;
grant select,delete on public.friendships to authenticated;

revoke update on public.posts from authenticated;
grant update(content,visibility,updated_at) on public.posts to authenticated;

revoke insert,update on public.messages from authenticated;
grant insert(conversation_id,sender_id,message_type,body,reply_to,encryption_mode) on public.messages to authenticated;
grant update(body,edited_at,deleted_at) on public.messages to authenticated;
alter table public.messages drop constraint if exists messages_encryption_mode_check;
alter table public.messages add constraint messages_encryption_mode_check check (encryption_mode = 'server_readable');

revoke insert,update on public.call_sessions from authenticated;
grant insert(conversation_id,initiated_by,call_type) on public.call_sessions to authenticated;
grant update(status,ended_at) on public.call_sessions to authenticated;

drop policy if exists conversation_members_add_by_creator on public.conversation_members;
create policy conversation_members_add_by_creator on public.conversation_members for insert to authenticated
with check (
  (private.is_conversation_creator(conversation_id) and exists (
    select 1 from public.conversations c
    where c.id = conversation_id and c.conversation_type in ('group','community')
  ))
  or (user_id = (select auth.uid()) and private.is_conversation_member(conversation_id))
);

drop policy if exists conversation_members_update_self on public.conversation_members;
create policy conversation_members_update_self on public.conversation_members for update to authenticated
using (user_id = (select auth.uid()))
with check (user_id = (select auth.uid()));

drop policy if exists messages_delete_own on public.messages;
create policy messages_delete_own on public.messages for delete to authenticated
using (sender_id = (select auth.uid()));

create or replace function private.update_privacy_settings_impl(
  p_is_private boolean,
  p_allow_messages_from text,
  p_allow_friend_requests boolean
)
returns void
language plpgsql
security definer
set search_path = ''
as $$
declare v_me uuid := auth.uid();
begin
  if v_me is null then raise exception 'not authenticated' using errcode = '28000'; end if;
  if p_allow_messages_from not in ('everyone','followers','friends','nobody') then
    raise exception 'invalid message privacy value' using errcode = '22023';
  end if;
  update public.profiles set is_private = p_is_private where id = v_me;
  insert into public.user_private_settings(user_id,profile_visibility,allow_messages_from,allow_friend_requests)
  values(v_me,case when p_is_private then 'private' else 'public' end,p_allow_messages_from,p_allow_friend_requests)
  on conflict(user_id) do update set
    profile_visibility = excluded.profile_visibility,
    allow_messages_from = excluded.allow_messages_from,
    allow_friend_requests = excluded.allow_friend_requests,
    updated_at = now();
end;
$$;
revoke all on function private.update_privacy_settings_impl(boolean,text,boolean) from public, anon;
grant execute on function private.update_privacy_settings_impl(boolean,text,boolean) to authenticated;

-- Expose only SECURITY INVOKER RPC wrappers; privileged implementation stays in the unexposed private schema.
create or replace function public.create_direct_conversation(p_other_user_id uuid)
returns uuid language sql security invoker set search_path = ''
as $$ select private.create_direct_conversation_impl(p_other_user_id); $$;
create or replace function public.request_follow(p_target_user_id uuid)
returns text language sql security invoker set search_path = ''
as $$ select private.request_follow_impl(p_target_user_id); $$;
create or replace function public.cancel_follow(p_target_user_id uuid)
returns boolean language sql security invoker set search_path = ''
as $$ select private.cancel_follow_impl(p_target_user_id); $$;
create or replace function public.update_privacy_settings(p_is_private boolean, p_allow_messages_from text, p_allow_friend_requests boolean)
returns void language sql security invoker set search_path = ''
as $fn$ select private.update_privacy_settings_impl(p_is_private,p_allow_messages_from,p_allow_friend_requests); $fn$;

revoke all on function public.create_direct_conversation(uuid) from public, anon;
revoke all on function public.request_follow(uuid) from public, anon;
revoke all on function public.cancel_follow(uuid) from public, anon;
revoke all on function public.update_privacy_settings(boolean,text,boolean) from public, anon;
grant execute on function public.create_direct_conversation(uuid) to authenticated;
grant execute on function public.request_follow(uuid) to authenticated;
grant execute on function public.cancel_follow(uuid) to authenticated;
grant execute on function public.update_privacy_settings(boolean,text,boolean) to authenticated;

grant execute on function private.create_direct_conversation_impl(uuid) to authenticated;
grant execute on function private.request_follow_impl(uuid) to authenticated;
grant execute on function private.cancel_follow_impl(uuid) to authenticated;
grant execute on function private.update_privacy_settings_impl(boolean,text,boolean) to authenticated;

-- Index foreign-key columns used by membership and ownership checks.
create index if not exists call_participants_user_idx on public.call_participants(user_id);
create index if not exists call_sessions_initiated_by_idx on public.call_sessions(initiated_by);
create index if not exists communities_owner_idx on public.communities(owner_id);
create index if not exists conversations_created_by_idx on public.conversations(created_by);
create index if not exists message_attachments_uploader_idx on public.message_attachments(uploader_id);
create index if not exists message_reactions_user_idx on public.message_reactions(user_id);
create index if not exists messages_reply_to_idx on public.messages(reply_to);
create index if not exists messages_sender_idx on public.messages(sender_id);
create index if not exists notifications_actor_idx on public.notifications(actor_id);
create index if not exists reports_reporter_idx on public.reports(reporter_id);
create index if not exists story_views_viewer_idx on public.story_views(viewer_id);

-- Merge profile visibility and conversation-member access into one SELECT policy.
drop policy if exists "Profiles visible according to privacy" on public.profiles;
drop policy if exists profiles_visible_to_conversation_participants on public.profiles;
create policy "Profiles visible according to privacy" on public.profiles
for select to authenticated
using (
  id = (select auth.uid())
  or is_private = false
  or exists (
    select 1 from public.follows f
    where f.follower_id = (select auth.uid())
      and f.following_id = profiles.id
      and f.status = 'accepted'
  )
  or exists (
    select 1 from public.conversation_members cm
    where cm.user_id = profiles.id
      and private.is_conversation_member(cm.conversation_id)
  )
  or exists (
    select 1 from public.friendships fr
    where (fr.requester_id = profiles.id and fr.addressee_id = (select auth.uid()))
       or (fr.addressee_id = profiles.id and fr.requester_id = (select auth.uid()))
  )
);

-- Private media bucket: access is granted by database ownership/visibility checks, not public URLs.
insert into storage.buckets(id,name,public,file_size_limit,allowed_mime_types)
values (
  'nexora-media',
  'nexora-media',
  false,
  52428800,
  array['image/jpeg','image/png','image/webp','image/gif','video/mp4','video/webm','audio/mpeg','audio/mp4','audio/ogg','audio/webm','application/pdf']
)
on conflict(id) do update set
  public = false,
  file_size_limit = excluded.file_size_limit,
  allowed_mime_types = excluded.allowed_mime_types;

create or replace function private.can_read_media_path(p_path text)
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select
    exists (
      select 1
      from public.media m
      join public.posts p on p.id = m.post_id
      join public.profiles pr on pr.id = p.user_id
      where m.storage_path = p_path
        and (
          p.user_id = (select auth.uid())
          or (
            not exists (
              select 1 from public.blocks b
              where (b.blocker_id = (select auth.uid()) and b.blocked_id = p.user_id)
                 or (b.blocker_id = p.user_id and b.blocked_id = (select auth.uid()))
            )
            and (pr.is_private = false or exists (
              select 1 from public.follows f
              where f.follower_id = (select auth.uid())
                and f.following_id = p.user_id and f.status = 'accepted'
            ))
            and (
              p.visibility = 'public'
              or (p.visibility = 'followers' and exists (
                select 1 from public.follows f
                where f.follower_id = (select auth.uid())
                  and f.following_id = p.user_id and f.status = 'accepted'
              ))
            )
          )
        )
    )
    or exists (
      select 1 from public.stories s
      where s.media_path = p_path
        and s.archived_at is null and s.expires_at > now()
        and (
          s.user_id = (select auth.uid())
          or (
            not exists (
              select 1 from public.blocks b
              where (b.blocker_id = (select auth.uid()) and b.blocked_id = s.user_id)
                 or (b.blocker_id = s.user_id and b.blocked_id = (select auth.uid()))
            )
            and (
              s.visibility = 'public'
              or (s.visibility = 'followers' and exists (
                select 1 from public.follows f
                where f.follower_id = (select auth.uid())
                  and f.following_id = s.user_id and f.status = 'accepted'
              ))
            )
          )
        )
    )
    or exists (
      select 1
      from public.message_attachments a
      join public.messages m on m.id = a.message_id
      where a.storage_path = p_path
        and private.is_conversation_member(m.conversation_id)
    )
    or exists (
      select 1 from public.communities c
      where c.cover_path = p_path
        and (c.owner_id = (select auth.uid()) or c.visibility = 'public' or private.is_community_member(c.id))
    );
$$;
revoke all on function private.can_read_media_path(text) from public, anon;
grant execute on function private.can_read_media_path(text) to authenticated;

drop policy if exists nexora_media_upload_own_folder on storage.objects;
create policy nexora_media_upload_own_folder on storage.objects
for insert to authenticated
with check (
  bucket_id = 'nexora-media'
  and (storage.foldername(name))[1] = (select auth.uid())::text
);

drop policy if exists nexora_media_read_authorized on storage.objects;
create policy nexora_media_read_authorized on storage.objects
for select to authenticated
using (
  bucket_id = 'nexora-media'
  and (
    (storage.foldername(name))[1] = (select auth.uid())::text
    or private.can_read_media_path(name)
  )
);

drop policy if exists nexora_media_delete_own on storage.objects;
create policy nexora_media_delete_own on storage.objects
for delete to authenticated
using (
  bucket_id = 'nexora-media'
  and (storage.foldername(name))[1] = (select auth.uid())::text
);

-- Friendship requests are created/accepted only through validated RPC operations.
create or replace function private.request_friend_impl(p_addressee_id uuid)
returns text language plpgsql security definer set search_path = ''
as $$
declare
  v_me uuid := auth.uid();
  v_status text;
  v_allowed boolean;
begin
  if v_me is null then raise exception 'not authenticated' using errcode = '28000'; end if;
  if p_addressee_id is null or p_addressee_id = v_me then raise exception 'invalid friend target' using errcode = '22023'; end if;
  if not exists (select 1 from public.profiles p where p.id = p_addressee_id) then
    raise exception 'profile not found' using errcode = 'P0002';
  end if;
  if exists (select 1 from public.blocks b where
    (b.blocker_id=v_me and b.blocked_id=p_addressee_id) or
    (b.blocker_id=p_addressee_id and b.blocked_id=v_me)) then
    raise exception 'friend requests are unavailable for this relationship' using errcode = '42501';
  end if;
  select coalesce(s.allow_friend_requests,true) into v_allowed
  from public.user_private_settings s where s.user_id=p_addressee_id;
  if coalesce(v_allowed,true) = false then
    raise exception 'recipient does not accept friend requests' using errcode = '42501';
  end if;

  perform pg_advisory_xact_lock(hashtextextended(least(v_me::text,p_addressee_id::text)||':'||greatest(v_me::text,p_addressee_id::text),0));

  update public.friendships
  set status='accepted', updated_at=now()
  where requester_id=p_addressee_id and addressee_id=v_me and status='pending';
  if found then return 'accepted'; end if;

  select f.status into v_status from public.friendships f
  where f.requester_id=v_me and f.addressee_id=p_addressee_id;
  if v_status = 'accepted' or v_status = 'pending' then return v_status; end if;

  insert into public.friendships(requester_id,addressee_id,status)
  values(v_me,p_addressee_id,'pending')
  on conflict(requester_id,addressee_id) do update
    set status='pending', updated_at=now();
  return 'pending';
end;
$$;

create or replace function private.accept_friend_request_impl(p_request_id uuid)
returns boolean language plpgsql security definer set search_path = ''
as $$
declare v_me uuid := auth.uid();
begin
  if v_me is null then raise exception 'not authenticated' using errcode = '28000'; end if;
  update public.friendships set status='accepted',updated_at=now()
  where id=p_request_id and addressee_id=v_me and status='pending';
  return found;
end;
$$;

create or replace function private.decline_friend_request_impl(p_request_id uuid)
returns boolean language plpgsql security definer set search_path = ''
as $$
declare v_me uuid := auth.uid();
begin
  if v_me is null then raise exception 'not authenticated' using errcode = '28000'; end if;
  update public.friendships set status='declined',updated_at=now()
  where id=p_request_id and addressee_id=v_me and status='pending';
  return found;
end;
$$;

create or replace function private.cancel_friend_request_impl(p_request_id uuid)
returns boolean language plpgsql security definer set search_path = ''
as $$
declare v_me uuid := auth.uid();
begin
  if v_me is null then raise exception 'not authenticated' using errcode = '28000'; end if;
  delete from public.friendships where id=p_request_id and requester_id=v_me and status='pending';
  return found;
end;
$$;

create or replace function private.remove_friend_impl(p_other_user_id uuid)
returns boolean language plpgsql security definer set search_path = ''
as $$
declare v_me uuid := auth.uid();
begin
  if v_me is null then raise exception 'not authenticated' using errcode = '28000'; end if;
  delete from public.friendships
  where status='accepted'
    and ((requester_id=v_me and addressee_id=p_other_user_id)
      or (requester_id=p_other_user_id and addressee_id=v_me));
  return found;
end;
$$;

create or replace function public.request_friend(p_addressee_id uuid)
returns text language sql security invoker set search_path=''
as $$ select private.request_friend_impl(p_addressee_id); $$;
create or replace function public.accept_friend_request(p_request_id uuid)
returns boolean language sql security invoker set search_path=''
as $$ select private.accept_friend_request_impl(p_request_id); $$;
create or replace function public.decline_friend_request(p_request_id uuid)
returns boolean language sql security invoker set search_path=''
as $$ select private.decline_friend_request_impl(p_request_id); $$;
create or replace function public.cancel_friend_request(p_request_id uuid)
returns boolean language sql security invoker set search_path=''
as $$ select private.cancel_friend_request_impl(p_request_id); $$;
create or replace function public.remove_friend(p_other_user_id uuid)
returns boolean language sql security invoker set search_path=''
as $$ select private.remove_friend_impl(p_other_user_id); $$;

revoke all on function public.request_friend(uuid) from public,anon;
revoke all on function public.accept_friend_request(uuid) from public,anon;
revoke all on function public.decline_friend_request(uuid) from public,anon;
revoke all on function public.cancel_friend_request(uuid) from public,anon;
revoke all on function public.remove_friend(uuid) from public,anon;
grant execute on function public.request_friend(uuid) to authenticated;
grant execute on function public.accept_friend_request(uuid) to authenticated;
grant execute on function public.decline_friend_request(uuid) to authenticated;
grant execute on function public.cancel_friend_request(uuid) to authenticated;
grant execute on function public.remove_friend(uuid) to authenticated;

grant execute on function private.request_friend_impl(uuid) to authenticated;
grant execute on function private.accept_friend_request_impl(uuid) to authenticated;
grant execute on function private.decline_friend_request_impl(uuid) to authenticated;
grant execute on function private.cancel_friend_request_impl(uuid) to authenticated;
grant execute on function private.remove_friend_impl(uuid) to authenticated;

create or replace function private.on_friendship_change()
returns trigger language plpgsql security definer set search_path=''
as $$
begin
  if tg_op='INSERT' and new.status='pending' then
    insert into public.notifications(recipient_id,actor_id,notification_type,entity_type,entity_id)
    values(new.addressee_id,new.requester_id,'friend_request','friendship',new.id);
  elsif tg_op='UPDATE' and old.status='pending' and new.status='accepted' then
    insert into public.notifications(recipient_id,actor_id,notification_type,entity_type,entity_id)
    values(new.requester_id,new.addressee_id,'friend_accepted','friendship',new.id);
  end if;
  return new;
end;
$$;
revoke all on function private.on_friendship_change() from public,anon,authenticated;
drop trigger if exists nexora_friendship_notifications on public.friendships;
create trigger nexora_friendship_notifications
after insert or update of status on public.friendships
for each row execute function private.on_friendship_change();

drop function if exists public.update_privacy_settings(boolean,text);
drop function if exists private.update_privacy_settings_impl(boolean,text);
