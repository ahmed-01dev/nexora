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

`test/app_error_test.dart` verifies safe Arabic mappings for network, authentication, RLS, and unknown failures. It does not test log sinks, production telemetry, or end-to-end recovery.

| SOC-020 | Recycle a relationship tile to another profile while relationship reads or follow/block actions are pending | Old profile responses/actions cannot overwrite the new profile's relationship state or display a stale success state; only the original target receives the requested action | P1 |
