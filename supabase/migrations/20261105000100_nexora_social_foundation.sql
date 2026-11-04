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
  add column if not exists date_of_birth date,
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

grant select,insert,update,delete on public.friendships, public.blocks to authenticated;
grant select,insert,update on public.conversations to authenticated;
grant select,insert,update,delete on public.conversation_members to authenticated;
grant select,insert,update,delete on public.messages to authenticated;
grant select,insert,delete on public.message_attachments to authenticated;
grant select,insert,delete on public.message_reactions to authenticated;
grant select,update on public.notifications to authenticated;
grant select,insert,update,delete on public.stories to authenticated;
grant select,insert on public.story_views to authenticated;
grant select,insert,update,delete on public.communities to authenticated;
grant select,insert,update,delete on public.community_members to authenticated;
grant select,insert on public.reports to authenticated;
grant select,insert,update on public.call_sessions to authenticated;
grant select,insert,update on public.call_participants to authenticated;

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
with check (viewer_id = (select auth.uid()) and exists (select 1 from public.stories s where s.id = story_id));

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
