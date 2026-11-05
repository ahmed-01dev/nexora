-- Make private avatar/cover media access match profile visibility:
-- accepted follow, accepted friendship, or a shared permitted conversation.
-- Blocks continue to override all non-owner access.
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
            not private.is_blocked_between((select auth.uid()), p.user_id)
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
            not private.is_blocked_between((select auth.uid()), s.user_id)
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
