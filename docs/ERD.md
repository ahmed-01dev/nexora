# NEXORA Database ERD

The diagram shows the current core and newly added foundation tables. It is not a claim that every related client workflow is complete.

```mermaid
erDiagram
  profiles ||--o{ posts : creates
  profiles ||--o{ follows : follows
  profiles ||--o{ friendships : requests
  profiles ||--o{ blocks : blocks
  profiles ||--o{ conversations : creates
  conversations ||--o{ conversation_members : contains
  conversations ||--o{ messages : contains
  profiles ||--o{ messages : sends
  messages ||--o{ message_attachments : has
  messages ||--o{ message_reactions : receives
  profiles ||--o{ notifications : receives
  profiles ||--o{ stories : publishes
  stories ||--o{ story_views : viewed_by
  profiles ||--o{ communities : owns
  communities ||--o{ community_members : has
  profiles ||--o{ reports : files
  conversations ||--o{ call_sessions : starts
  call_sessions ||--o{ call_participants : includes
  profiles ||--o{ user_private_settings : configures
  profiles ||--o{ user_preferences : chooses
  posts ||--o{ comments : has
  posts ||--o{ likes : receives
  posts ||--o{ media : contains
  posts ||--o{ saves : saved_by
```

## Table groups
- Identity: profiles, user_private_settings, user_preferences.
- Social graph: follows, friendships, blocks.
- Publishing: posts, media, likes, comments, saves, stories, story_views.
- Messaging: conversations, conversation_members, messages, message_attachments, message_reactions.
- Communities: communities, community_members.
- Safety: reports.
- Realtime call foundation: call_sessions, call_participants.
- Notifications: notifications.

## Security model
All newly added public tables have RLS enabled. Anonymous SELECT is revoked. User-scoped data is filtered by auth.uid() or a narrowly scoped membership helper. Column-level update grants are used on sensitive membership, conversation, message, notification, and call fields.
