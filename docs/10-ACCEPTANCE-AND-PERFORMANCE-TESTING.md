# Document 10 — Acceptance, Quality & Performance Testing

Status: MVP test baseline  
Rule: A feature is not complete because its screen exists. It is complete only after its real data path, authorization, failure behavior, and acceptance tests pass.

## 1. Test status vocabulary
- NOT RUN — not executed.
- PASS — executed and met expected result.
- FAIL — executed and did not meet expected result.
- BLOCKED — cannot execute because a documented dependency is unavailable.
- NOT APPLICABLE — outside release scope, with reason.

Severity:
- P0: security, data loss, identity, or core availability defect; blocks release.
- P1: core workflow defect; blocks MVP unless explicitly excluded.
- P2: limited defect with safe workaround.
- P3: cosmetic or low-impact improvement.

## 2. Identity and session tests
| ID | Scenario | Expected result | Severity |
|---|---|---|---|
| AUTH-001 | Launch without configured backend | Honest setup/unavailable state; no false success | P1 |
| AUTH-002 | Guest entry where enabled | Guest is distinguished from registered account | P1 |
| AUTH-003 | Valid email signup | Account/session created only after Auth confirms | P0 |
| AUTH-004 | Duplicate email | Clear error; no duplicate profile | P1 |
| AUTH-005 | Invalid credentials | Access denied; no sensitive diagnostic leakage | P1 |
| AUTH-006 | Restore valid session | Correct user restored | P0 |
| AUTH-007 | Sign out | Local and remote session cleared | P0 |
| AUTH-008 | Phone OTP while provider disabled | Unavailable; no fake OTP or success | P0 |
| AUTH-009 | Modify another user's profile through API | Database rejects write | P0 |
| AUTH-010 | Delete account then reuse old session | Access revoked per deletion policy | P0 |

## 3. Social graph tests
| ID | Scenario | Expected result | Severity |
|---|---|---|---|
| SOC-001 | Follow public account | One relationship created | P1 |
| SOC-002 | Duplicate follow | No duplicate relationship | P1 |
| SOC-003 | Follow private account | Pending request until accepted | P1 |
| SOC-004 | Accept/decline/cancel | Correct state transition only | P1 |
| SOC-005 | Block either participant | Both sides lose access per block policy | P0 |
| SOC-006 | Search private/blocked account | Only permitted discovery fields returned | P0 |
| SOC-007 | Nearby discovery disabled | No location stored or returned | P0 |
| SOC-008 | Nearby discovery enabled | Coarse, consent-based results only | P1 |
| SOC-018 | Nearby discovery on Android 13+ with location/notification permissions denied or granted | Generated release manifest declares INTERNET/network-state, coarse/fine location, and notification permissions; location consent remains opt-in; denied/denied-forever states show recovery guidance without writing coordinates | P1 |
| SOC-009 | Recipient opens incoming follow-request inbox | Only pending requests addressed to the authenticated recipient are listed; private requester details remain hidden unless normal profile RLS permits them | P0 |
| SOC-010 | Recipient accepts a follow request | Only the recipient may change their own incoming pending row to accepted; the status column is the only direct client-updatable field | P0 |
| SOC-011 | Request is cancelled or either side blocks before acceptance | Acceptance affects zero rows or is denied; no relationship is created after the block | P0 |
| SOC-014 | Refresh, load more, or accept in the follow-request inbox concurrently | Refresh is held while acceptance is in flight; acceptance and refresh are held while paging is in flight; stale pages cannot overwrite refreshed state; offsets count fetched rows and decrement when accepted rows leave the pending set | P1 |
| SOC-015 | Unfollow an account from the accepted following list | Successful unfollow removes that account from the current following list; the followers list remains unchanged; any in-flight page is invalidated and the backend offset is adjusted; relationship tile state is not reused for a different profile | P1 |
| SOC-016 | Accept/decline/cancel a friendship request repeatedly | Only one action per request ID is in flight; controls show a busy state; success reloads both request directions and failure leaves the row actionable | P1 |
| SOC-017 | Refresh friendship requests from empty and populated states | Pull-to-refresh remains available with zero incoming/outgoing rows and after a failed refresh; no unhandled refresh future escapes the UI | P2 |
| SOC-012 | Open accepted followers/following lists | Correct direction and accepted-only rows; no blocked relationship leaks; hidden private profile details and internal user-ID fragments remain hidden; deterministic 30-row pagination, load-more, and refresh | P1 |
| SOC-013 | Measure follower/following page performance | Capture representative EXPLAIN ANALYZE and latency at realistic relationship counts; verify whether the explicit created_at/user-ID sort needs a reconciled composite index before proposing DDL | P1 |
| SOC-019 | Load another followers/following page while new relationships change the ordered result set | Duplicate relationship IDs are not rendered twice; backend offset advances by rows fetched, not rows newly rendered | P2 |

## 4. Content and media tests
| ID | Scenario | Expected result | Severity |
|---|---|---|---|
| CNT-001 | Create text post | One persisted post in allowed feeds | P0 |
| CNT-002 | Upload supported image | Validated media stored and shown to authorized viewers | P1 |
| CNT-003 | Unsupported MIME/signature | Rejected by trusted validation | P0 |
| CNT-004 | Exceed file/count quota | Rejected with clear error | P1 |
| CNT-005 | Interrupt upload | No false success; partial state recoverable | P0 |
| CNT-006 | Retry upload | Idempotent or safely deduplicated | P1 |
| CNT-007 | Like/unlike | State and counts remain consistent | P1 |
| CNT-008 | Comment/reply | Correct parent, author, and post relationship | P1 |
| CNT-009 | Delete own post | Deleted content not exposed to unauthorized viewers | P0 |
| CNT-010 | Delete another user's post | Rejected | P0 |
| CNT-011 | Friends-only/private post media | Storage authorization matches post visibility | P0 |
| CNT-012 | Paginate feed | Stable ordering, no unintended duplicates | P1 |

## 5. Messaging tests
| ID | Scenario | Expected result | Severity |
|---|---|---|---|
| MSG-001 | Create direct conversation | Correct participants only | P1 |
| MSG-002 | Send text message | Persisted once and visible to participants | P0 |
| MSG-003 | Non-member reads conversation | Denied by RLS | P0 |
| MSG-004 | Block participant | Access follows documented block policy | P0 |
| MSG-005 | Retry after timeout | No duplicate message | P1 |
| MSG-006 | Send while offline | Pending/failed state is explicit | P1 |
| MSG-007 | Read attachment | Requires membership and non-deleted message | P0 |
| MSG-008 | Realtime reconnect | No unbounded duplicate subscription | P1 |

## 6. Moderation and community tests
- Normal users cannot read staff moderation queues.
- Normal users cannot assign or resolve reports as staff.
- Users can report only supported targets with valid fields.
- Users cannot forge reviewer, resolution, or staff metadata.
- Community owners/moderators can perform only granted actions.
- Removed or blocked users lose access per community policy.
- Sensitive actions create audit records without logging secrets.
- Appeals are submitted by affected users and decided only by authorized staff.
Any staff privilege bypass is P0.

## 7. RLS and Storage security matrix
Test with anonymous visitor, authenticated owner, unrelated user, accepted follower/friend, pending requester, blocked participant, and authorized moderator/staff.

For every exposed table, RPC, and Storage bucket, test:
1. SELECT own row.
2. SELECT another user's row.
3. INSERT with forged owner/role fields.
4. UPDATE protected columns.
5. DELETE another user's row.
6. RPC without required role.
7. Storage access with altered object path.
8. Access after block, deletion, or soft-delete.

Any unauthorized read/write or privilege escalation is P0 and blocks release.

## 8. Offline and recovery tests
| ID | Scenario | Expected result |
|---|---|---|
| OFF-001 | Launch offline | Only locally cached permitted data appears |
| OFF-002 | Draft post offline | Local draft, not published |
| OFF-003 | Network returns | Sync follows explicit retry policy |
| OFF-004 | Sync fails | Item remains visibly pending/failed |
| OFF-005 | Session expires offline | Sensitive operations require re-authentication |
| OFF-006 | Duplicate retry | No duplicate server records |
| OFF-007 | App killed during upload | Recoverable state or explicit failure |

## 9. Accessibility and UX tests
- Arabic screens use correct RTL ordering and alignment.
- Mixed Arabic/English, usernames, URLs, and numbers remain readable.
- Text scaling does not hide essential actions.
- TalkBack labels exist for important controls.
- Touch targets work on small Android screens.
- Loading, empty, error, offline, disabled, and permission-denied states are explicit.
- Repeated taps cannot submit duplicate operations.
- Dialogs and keyboard do not obscure required form actions.
- Contrast is reviewed in AMOLED and light themes.
- Reduced-motion/transparency preferences are respected where implemented.

## 10. Performance targets
Initial targets only; not guarantees across all hardware or networks.

| Metric | Initial target |
|---|---:|
| Cold start on reference low/mid-range device | <= 4 seconds |
| Local interaction response | <= 200 ms for common actions |
| Cached screen render | <= 1.5 seconds |
| First feed content on stable connection | <= 3 seconds |
| Scroll smoothness | Target 60 FPS where device permits |
| Search first page on small test dataset | <= 2 seconds |
| Network timeout | Bounded and surfaced with retry |
| Memory | No sustained growth during repeated navigation |
| Image upload | Compressed and bounded by documented quota |

Record device model, Android version, app version, network type, dataset size, and measurement method for every performance result.

## 11. CI requirements
1. Checkout intended commit.
2. Install a pinned Flutter SDK.
3. Resolve dependencies.
4. Check formatting.
5. Run Flutter analyzer.
6. Run unit and widget tests.
7. Run SQL/RLS tests in a controlled test database where configured.
8. Build Android artifacts only in the explicitly approved build workflow.
9. Avoid printing secrets.
10. Fail on P0/P1 analyzer or test failures.

A green source CI run does not prove Android device behavior, production Auth delivery, real-user RLS integration, or push delivery.

## 12. Release gates
- Internal build: app starts, navigation works, no known core-route crash, no secrets in source.
- Alpha: identity, profile, social graph, and content core pass; P0 security tests pass.
- Closed beta: multi-user integration tests pass; support and error processes exist.
- Release candidate: all in-scope P0/P1 tests pass; privacy, deletion, provider dependencies, real-device tests, and backup/restore drill are documented.
- Public release: security/legal/privacy reviews complete; moderation and incident response are staffed; monitoring and quota controls exist; no unresolved P0 defect.

## 13. Test record template
TEST ID:
Feature:
Build / Commit:
Device:
Android version:
Network:
Test accounts and roles:
Preconditions:
Steps:
Expected result:
Actual result:
Status: NOT RUN / PASS / FAIL / BLOCKED / NOT APPLICABLE
Severity:
Evidence:
Issue:
Retest result:

## 14. No-go conditions
Do not release if any P0 authorization/privacy defect remains; a core flow silently loses data; secrets are in the client or repository; provider-dependent features are advertised without end-to-end proof; account deletion/privacy behavior is misleading; or a required P0/P1 test is failing or unexecuted without approved exclusion.


### Follow-request inbox implementation note
The client inbox currently supports accepting incoming pending follow requests only. Recipient-side decline is not part of the live backend contract; do not test or claim a decline action until a trusted, authorized server operation is added. SOC-009 through SOC-011 are acceptance criteria and remain NOT RUN until authenticated multi-user integration tests execute.

### Client error privacy unit coverage

`test/app_error_test.dart` verifies safe Arabic mappings for network, authentication, RLS, and unknown failures, and asserts raw email/token-like exception text is not written to debug logs. It does not test production telemetry or end-to-end recovery.

| SOC-020 | Recycle a relationship tile to another profile while relationship reads or follow/block actions are pending | Old profile responses/actions cannot overwrite the new profile's relationship state or display a stale success state; only the original target receives the requested action | P1 |
| SEC-021 | End a Supabase session outside the account-screen logout flow while FCM is registered | A `signedOut` event triggers owner-scoped device cleanup; the last known owner is retained after session clearing; no other account's device row is deleted | P1 |
| APP-022 | Pull to refresh empty messages and stories screens; force a refresh network failure | Empty states remain scrollable and refreshable; refresh errors are captured by the owning FutureBuilder without an unhandled refresh-future exception | P2 |
| APP-023 | Receive a realtime image message before attachment metadata is visible, then switch accounts during lookup | Signed URL lookup retries a bounded number of times for late metadata and stops immediately when the authenticated viewer changes | P1 |
| APP-024 | Switch accounts during message-image upload, metadata insertion, or attachment deletion | No subsequent write or Storage cleanup is attempted under the new account; any ambiguous completed send is not blindly retried | P1 |
| SOC-021 | Change the target profile while a friendship action is pending | The prior target's completion cannot clear busy state, reload the new target with stale data, or display an error/success against the wrong profile | P1 |

| SEC-022 | A delayed FCM `onUnregistered` callback for account A arrives after account B registers the same FID | The queued callback is attributed to A, removes only A's device row, and does not clear B's in-memory registration; repeated unregister events preserve FIFO ownership | P1 |

| MOD-001 | Submit a report with an unsupported target type, malformed target UUID, or reason outside the live `reports` CHECK constraints | Client rejects the invalid payload before network submission; PostgreSQL constraints and RLS remain authoritative for bypassed clients | P1 |

| MOD-002 | Account changes while report submission is in flight | The client does not show success in the new session; it explains that the result may need reconciliation and does not blindly resubmit | P1 |

| APP-025 | Start loading more comments, then refresh or submit a new comment before the older page returns | The stale page response cannot replace the refreshed list or overwrite the current offset/loading state | P1 |

| APP-026 | Switch accounts while notification page loading, marking read, or opening a notification | Old-session data is not rendered into the new account and navigation to the old notification target is stopped | P1 |

| APP-027 | Switch accounts while the followers/following list page is loading | A page fetched for the previous user is discarded and cannot populate the new session's list | P1 |

| APP-028 | Sign out or switch accounts while loading or creating a community channel | Stale channel rows are cleared; follow-up membership/channel writes stop after owner change; rollback is attempted only under the original owner | P1 |

| APP-029 | Switch accounts while viewing or managing community members | The previous account's member list is hidden; role/remove actions require the same viewer that loaded the list and stop after session change | P1 |

| APP-030 | Switch accounts while the conversation list is visible | Previous account conversation previews are hidden until a fresh page loads for the new viewer; stale taps cannot open old conversations | P1 |

| APP-031 | Switch accounts after confirming a block but before its database insert | Block creation stops when the confirmed viewer is no longer authenticated; it never retries as the new account | P1 |
| APP-032 | Switch accounts while the blocked-account list is loading or before unblocking | Stale rows are hidden; unblock is allowed only for the viewer who loaded the list | P1 |
| APP-033 | Switch accounts while privacy settings load or save | Settings from the previous viewer are not displayed or saved under the new session | P1 |
| APP-034 | Switch accounts while friend/follow requests load or while an action completes | Old request lists are hidden and stale actions do not mutate the new viewer's UI | P1 |

| APP-035 | Switch accounts while a profile friendship control is loading or an RPC is running | The control stops showing the previous viewer's state and disables actions for a mismatched session | P1 |

| APP-036 | Switch accounts while nearby presence, location, or nearby messaging is in progress | Location/presence writes and conversation creation stop when the captured viewer changes; stale nearby results are discarded | P1 |
| APP-037 | Switch accounts while notification preferences load, save, or request push permission | Previous account settings are hidden; preference writes are bound to the viewer who loaded them | P1 |
| APP-038 | Switch accounts while viewing personal moderation history or submitting an appeal | The previous account's actions are hidden and appeal insertion is bound to the captured account | P1 |
| APP-039 | Switch reviewer accounts while moderation appeals load or a decision dialog is open | Stale appeal rows are hidden and decisions are accepted only for the reviewer who loaded the queue | P1 |

| APP-040 | Switch accounts while community discovery, membership, invite acceptance, invite management, or community creation is in progress | Previous-account community rows are hidden; membership/invite actions are bound to the loaded viewer and stale results are discarded | P1 |
