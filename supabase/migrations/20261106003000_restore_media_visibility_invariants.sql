-- Restore the complete media visibility contract after
-- 20261105225000_hide_deleted_message_attachments.sql replaced the helper
-- with an older version that omitted friend-only posts, private-story
-- visibility, and soft-deleted-post filtering.
--
-- This file is a proposed source correction. Do not apply it until the
-- remote/local migration history mismatch has been reconciled and reviewed.

-- Hide media for soft-deleted posts from non-owners, matching posts_read_visible.
create or replace function private.can_read_media_path(p_path text)
returns boolean
language sql
stable
security definer
set search_path = ''
as $function$
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
            p.deleted_at is null
            and not private.is_blocked_between((select auth.uid()), p.user_id)
            and (
              (
                p.visibility = 'friends'
                and exists (
                  select 1 from public.friendships fr
                  where fr.status = 'accepted'
                    and (
                      (fr.requester_id = p.user_id and fr.addressee_id = (select auth.uid()))
                      or
                      (fr.addressee_id = p.user_id and fr.requester_id = (select auth.uid()))
                    )
                )
              )
              or (
                p.visibility = any (array['public'::text, 'followers'::text])
                and (
                  pr.is_private = false
                  or exists (
                    select 1 from public.follows f
                    where f.follower_id = (select auth.uid())
                      and f.following_id = p.user_id
                      and f.status = 'accepted'
                  )
                )
                and (
                  p.visibility = 'public'
                  or exists (
                    select 1 from public.follows f
                    where f.follower_id = (select auth.uid())
                      and f.following_id = p.user_id
                      and f.status = 'accepted'
                  )
                )
              )
            )
          )
        )
    )
    or exists (
      select 1
      from public.stories s
      join public.profiles story_profile on story_profile.id = s.user_id
      where s.media_path = p_path
        and s.archived_at is null
        and s.expires_at > now()
        and (
          s.user_id = (select auth.uid())
          or (
            not private.is_blocked_between((select auth.uid()), s.user_id)
            and (
              story_profile.is_private = false
              or exists (
                select 1 from public.follows f
                where f.follower_id = (select auth.uid())
                  and f.following_id = s.user_id
                  and f.status = 'accepted'
              )
            )
            and (
              s.visibility = 'public'
              or (s.visibility = 'followers' and exists (
                select 1 from public.follows f
                where f.follower_id = (select auth.uid())
                  and f.following_id = s.user_id
                  and f.status = 'accepted'
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
        and m.deleted_at is null
        and private.is_conversation_member(m.conversation_id)
    )
    or exists (
      select 1 from public.communities c
      where c.cover_path = p_path
        and (c.owner_id = (select auth.uid()) or c.visibility = 'public' or private.is_community_member(c.id))
    )
    or exists (
      select 1 from public.profiles pr
      where (pr.avatar_url = p_path or pr.cover_url = p_path)
        and (
          pr.id = (select auth.uid())
          or (
            not private.is_blocked_between((select auth.uid()), pr.id)
            and (
              pr.is_private = false
              or exists (
                select 1 from public.follows f
                where f.follower_id = (select auth.uid())
                  and f.following_id = pr.id
                  and f.status = 'accepted'
              )
              or exists (
                select 1 from public.friendships fr
                where fr.status = 'accepted'
                  and (
                    (fr.requester_id = pr.id and fr.addressee_id = (select auth.uid()))
                    or
                    (fr.addressee_id = pr.id and fr.requester_id = (select auth.uid()))
                  )
              )
              or exists (
                select 1 from public.conversation_members cm
                where cm.user_id = pr.id
                  and private.is_conversation_member(cm.conversation_id)
              )
            )
          )
        )
    );
$function$;

revoke all on function private.can_read_media_path(text) from public, anon;
grant execute on function private.can_read_media_path(text) to authenticated;
