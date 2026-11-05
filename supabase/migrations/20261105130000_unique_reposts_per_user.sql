-- Prevent duplicate repost rows for the same account and post.
-- Preflight on 2026-11-05 found no duplicate (user_id, post_id) pairs.
create unique index if not exists reposts_user_post_unique_idx
  on public.reposts (user_id, post_id);
