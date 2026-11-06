# NEXORA — Live PostgreSQL Trigger Inventory

> Read-only catalog snapshot from Supabase project `wwdeexgkwpftyavbhiff`, captured 2026-11-06. Includes application and Supabase Storage platform triggers; no trigger was changed.

- Non-internal triggers: 21
- Auth: 1
- Public: 9
- Storage: 11

## `auth.users.on_auth_user_created`

- Function: `public.handle_new_user`
- Definition: `CREATE TRIGGER on_auth_user_created AFTER INSERT ON auth.users FOR EACH ROW EXECUTE FUNCTION handle_new_user()`

## `public.community_channels.sync_community_members_after_channel_insert`

- Function: `private.sync_community_channel_members`
- Definition: `CREATE TRIGGER sync_community_members_after_channel_insert AFTER INSERT ON community_channels FOR EACH ROW EXECUTE FUNCTION private.sync_community_channel_members()`

## `public.community_members.sync_community_channels_after_member_delete`

- Function: `private.sync_community_channel_members`
- Definition: `CREATE TRIGGER sync_community_channels_after_member_delete AFTER DELETE ON community_members FOR EACH ROW EXECUTE FUNCTION private.sync_community_channel_members()`

## `public.community_members.sync_community_channels_after_member_insert`

- Function: `private.sync_community_channel_members`
- Definition: `CREATE TRIGGER sync_community_channels_after_member_insert AFTER INSERT ON community_members FOR EACH ROW EXECUTE FUNCTION private.sync_community_channel_members()`

## `public.follows.enforce_follow_request_status`

- Function: `private.enforce_follow_request_status`
- Definition: `CREATE TRIGGER enforce_follow_request_status BEFORE INSERT ON follows FOR EACH ROW EXECUTE FUNCTION private.enforce_follow_request_status()`

## `public.friendships.nexora_friendship_notifications`

- Function: `private.on_friendship_change`
- Definition: `CREATE TRIGGER nexora_friendship_notifications AFTER INSERT OR UPDATE OF status ON friendships FOR EACH ROW EXECUTE FUNCTION private.on_friendship_change()`

## `public.messages.nexora_message_after_insert`

- Function: `private.on_message_insert`
- Definition: `CREATE TRIGGER nexora_message_after_insert AFTER INSERT ON messages FOR EACH ROW EXECUTE FUNCTION private.on_message_insert()`

## `public.moderation_actions.audit_moderation_action`

- Function: `private.audit_moderation_action`
- Definition: `CREATE TRIGGER audit_moderation_action AFTER INSERT ON moderation_actions FOR EACH ROW EXECUTE FUNCTION private.audit_moderation_action()`

## `public.notifications.notify_nexora_push_after_insert`

- Function: `private.notify_nexora_push`
- Definition: `CREATE TRIGGER notify_nexora_push_after_insert AFTER INSERT ON notifications FOR EACH ROW EXECUTE FUNCTION private.notify_nexora_push()`

## `public.reports.audit_report_update`

- Function: `private.audit_report_update`
- Definition: `CREATE TRIGGER audit_report_update AFTER UPDATE ON reports FOR EACH ROW EXECUTE FUNCTION private.audit_report_update()`

## `storage.buckets.enforce_bucket_name_length_trigger`

- Function: `storage.enforce_bucket_name_length`
- Definition: `CREATE TRIGGER enforce_bucket_name_length_trigger BEFORE INSERT OR UPDATE OF name ON storage.buckets FOR EACH ROW EXECUTE FUNCTION storage.enforce_bucket_name_length()`

## `storage.buckets.enforce_versioning_status_transition`

- Function: `storage.enforce_versioning_status_transition`
- Definition: `CREATE TRIGGER enforce_versioning_status_transition BEFORE UPDATE OF versioning_status ON storage.buckets FOR EACH ROW EXECUTE FUNCTION storage.enforce_versioning_status_transition()`

## `storage.buckets.protect_active_lifecycle_states`

- Function: `storage.protect_active_lifecycle_states`
- Definition: `CREATE TRIGGER protect_active_lifecycle_states BEFORE DELETE ON storage.buckets FOR EACH ROW EXECUTE FUNCTION storage.protect_active_lifecycle_states()`

## `storage.buckets.protect_bucket_control_insert`

- Function: `storage.protect_bucket_control_columns`
- Definition: `CREATE TRIGGER protect_bucket_control_insert BEFORE INSERT ON storage.buckets FOR EACH ROW EXECUTE FUNCTION storage.protect_bucket_control_columns('service_role')`

## `storage.buckets.protect_bucket_control_update`

- Function: `storage.protect_bucket_control_columns`
- Definition: `CREATE TRIGGER protect_bucket_control_update BEFORE UPDATE OF lifecycle_configuration, lifecycle_configuration_generation ON storage.buckets FOR EACH ROW EXECUTE FUNCTION storage.protect_bucket_control_columns()`

## `storage.buckets.protect_bucket_control_update_role`

- Function: `storage.enforce_bucket_lifecycle_service_role`
- Definition: `CREATE TRIGGER protect_bucket_control_update_role AFTER UPDATE OF lifecycle_configuration, lifecycle_configuration_generation ON storage.buckets FOR EACH ROW EXECUTE FUNCTION storage.enforce_bucket_lifecycle_service_role('service_role')`

## `storage.buckets.protect_buckets_delete`

- Function: `storage.protect_delete`
- Definition: `CREATE TRIGGER protect_buckets_delete BEFORE DELETE ON storage.buckets FOR EACH STATEMENT EXECUTE FUNCTION storage.protect_delete()`

## `storage.buckets.wake_lifecycle_on_policy_write`

- Function: `storage.wake_lifecycle_state`
- Definition: `CREATE TRIGGER wake_lifecycle_on_policy_write AFTER INSERT OR UPDATE OF lifecycle_configuration_generation ON storage.buckets FOR EACH ROW EXECUTE FUNCTION storage.wake_lifecycle_state()`

## `storage.buckets.wake_lifecycle_on_versioning_enable`

- Function: `storage.wake_lifecycle_state`
- Definition: `CREATE TRIGGER wake_lifecycle_on_versioning_enable AFTER UPDATE OF versioning_status ON storage.buckets FOR EACH ROW WHEN (new.lifecycle_configuration IS NOT NULL) EXECUTE FUNCTION storage.wake_lifecycle_state()`

## `storage.objects.protect_objects_delete`

- Function: `storage.protect_delete`
- Definition: `CREATE TRIGGER protect_objects_delete BEFORE DELETE ON storage.objects FOR EACH STATEMENT EXECUTE FUNCTION storage.protect_delete()`

## `storage.objects.update_objects_updated_at`

- Function: `storage.update_updated_at_column`
- Definition: `CREATE TRIGGER update_objects_updated_at BEFORE UPDATE ON storage.objects FOR EACH ROW EXECUTE FUNCTION storage.update_updated_at_column()`

## Application-trigger notes

- `auth.users` profile creation: `on_auth_user_created` calls `public.handle_new_user()` after signup.
- `follows` request status enforcement: `enforce_follow_request_status` runs before insert.
- Community membership/channel synchronization runs after member insert/delete and channel insert.
- Friendship, message, and notification triggers create downstream notifications; notifications trigger the FCM webhook helper.
- Moderation actions and report updates write audit trail entries.
- Storage schema triggers are Supabase platform-managed infrastructure; they are inventoried here for context, not owned or modified by the NEXORA app.

## Verification limits

This inventory records trigger definitions and target functions. It does not verify every trigger's runtime success, ordering with other triggers, or transaction-level side effects. No trigger DDL was run.
