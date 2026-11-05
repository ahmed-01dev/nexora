-- Usernames are compared case-insensitively by discovery/search UI.
-- Prevent visually duplicate handles that differ only by letter case.
create unique index if not exists profiles_username_lower_key
on public.profiles (lower(username))
where username is not null;
