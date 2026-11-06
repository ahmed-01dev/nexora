# Document 02 — Detailed System Specifications: Sections I–K
**Scope:** catalog slots 63–90. **Status:** design baseline, not implementation proof. **Repository baseline:** `ahmed-01dev/nexora`, checked 2026-11-06.

> **Catalog reconciliation warning:** the original 118-system Document 01 is not present in the repository's current `docs/` directory. This file follows the handoff allocation I=63–70, J=71–80, K=81–90 and defines a concrete working scope. Before final sign-off, compare every title/ID with canonical Document 01. Do not treat these labels as verified historical catalog wording.

## Global requirements
- Zero-budget MVP: no paid ads, payment processor, marketplace payouts, paid AI moderation, paid anti-bot vendor, or always-on worker.
- A design/specification does not mean code, migration, provider, staff process, or feature exists.
- Backend authorization is authoritative. UI hiding is not security. Never trust client-supplied role, payment status, moderation outcome, impression count, or job completion.
- Keep incomplete/paid integrations disabled by default. No fake success states.
- Minimize sensitive data, redact secrets from logs, use idempotency for retryable mutations, and audit privileged actions.

# I — Ads & Commerce Systems (63–70)
All eight systems are **P2 / deferred** for the zero-budget MVP. No ad SDK, billing, checkout, or payout service is to be integrated now.

### SYS-063 — Advertising Campaign Management
**Purpose/actors:** future advertiser campaign lifecycle; advertiser, reviewer, administrator, viewer.  
**Flow:** advertiser draft → submit creative/destination → policy review → approve/reject with reason → schedule/pause/end → archive. Only approved, eligible campaigns can be delivered.  
**Data (future):** `advertisers`, `ad_campaigns`, `ad_creatives`, `campaign_review_events`; owner, objective, schedule, budget ceiling, destination, creative reference, state, review reason, timestamps. Never store payment credentials.  
**Access/contracts:** advertiser owns drafts; reviewer role is server-controlled. Future RPCs: `create_campaign`, `submit_campaign_for_review`, `review_campaign`, `pause_campaign`. RLS isolates advertisers; client cannot approve or set delivery metrics.  
**Abuse/failure:** prohibited products, impersonation, malicious links, rejected-campaign resubmission. Fail closed and preserve draft.  
**Acceptance:** pending/rejected/paused/expired campaign never serves; cross-advertiser reads denied; every decision audited.  
**Cost/phase:** P2, disabled; no ad network.

### SYS-064 — Ad Placement & Delivery
**Purpose:** future placement selection and transparent sponsored-content rendering.  
**Flow:** placement configured → eligible approved campaign selected → clear Sponsored label → deduplicated impression event → frequency cap → hide/report feedback.  
**Data:** `ad_placements`, `ad_impressions`, `ad_feedback`, aggregate counters. Avoid fingerprinting and cross-app identifiers.  
**Access/contracts:** future `get_ad_placement`, `record_ad_impression`, `hide_sponsored_item`. Client cannot create trusted billing impressions; server validates idempotency and eligibility.  
**Abuse/failure:** duplicate/fake impressions, over-frequency, ad service outage. Omit ad on outage; organic feed remains functional.  
**Acceptance:** every ad labeled; server-side caps; hide/report persists; no ad blocks core feed.  
**Cost/phase:** P2, disabled; no ad SDK.

### SYS-065 — Ad Consent, Targeting & Frequency
**Purpose:** privacy-preserving user controls if ads are later introduced.  
**Policy:** contextual-only initial model; prohibit sensitive-trait inference, precise-location targeting, contact harvesting, cross-site tracking, and protected-trait targeting.  
**Data:** versioned consent receipt, preference state, coarse context, frequency counters, retention metadata. General Terms acceptance is not ad consent.  
**Access/contracts:** user controls own preferences. Future `get_ad_preferences`, `update_ad_preferences`, `withdraw_ad_consent`. No personalized targeting when consent is missing or ambiguous.  
**Acceptance:** granular revocable consent; conservative defaults; no sensitive attributes; caps enforced.  
**Cost/phase:** P2, no profiling pipeline in MVP.

### SYS-066 — Advertiser Billing & Budget Ledger
**Purpose:** future auditable campaign charge accounting.  
**Flow:** approved campaign → provider-hosted checkout → signed webhook → idempotent immutable ledger entry → budget reconciliation/refund.  
**Data:** `billing_ledger`, `provider_payment_events`, `campaign_budget_reservations`; provider references only, never PAN/CVV.  
**Access/contracts:** future `create_checkout_session`, `payment_webhook`, `reconcile_campaign_balance`. Only trusted webhook/service can append financial state; client cannot update/delete ledger.  
**Abuse/failure:** forged/replayed webhook, amount/currency mismatch, duplicate refund. Verify signature, timestamp, account, amount, currency, event uniqueness; quarantine unknown events.  
**Acceptance:** duplicate webhook has one effect; forged event rejected; refund history retained.  
**Cost/phase:** P2; requires paid/approved provider, tax/legal/accounting and operations review.

### SYS-067 — Creator & Brand Collaboration Marketplace
**Purpose:** future opt-in collaboration between creators and verified brands.  
**Flow:** creator opts in → brand submits brief → offer → accept/decline/counter → deliverable review → sponsorship disclosure → completion/dispute.  
**Data:** `creator_marketplace_profiles`, `brand_profiles`, `collaboration_offers`, `deliverables`, `disputes`.  
**Access/contracts:** creators control discoverability; brands see only opted-in fields. Future `opt_in_creator_marketplace`, `submit_collaboration_offer`, `respond_to_offer`, `open_collaboration_dispute`.  
**Abuse/failure:** scams, harassment, undisclosed sponsorship, coercion. Reporting/blocking applies; do not promise escrow/payment protection.  
**Acceptance:** opt-out removes discoverability; private contact data stays private; sponsored work is disclosed.  
**Cost/phase:** P2; no marketplace or payout in MVP.

### SYS-068 — Product Catalog & Merchant Listings
**Purpose:** future merchant-owned listings distinct from ordinary user posts.  
**Flow:** merchant verification → draft listing → category/media validation → review → active listing → edit/stock update → archive.  
**Data:** `merchants`, `product_listings`, `product_media`, `catalog_categories`, `listing_review_events`.  
**Access/contracts:** merchant edits own listing; public reads approved active listings. Future `create_listing`, `submit_listing`, `review_listing`, `archive_listing`. Client cannot forge merchant verification.  
**Abuse/failure:** counterfeit/prohibited goods, misleading price/stock, malicious URLs. Reject/suspend and preserve report trail.  
**Acceptance:** only approved listings discoverable; ownership enforced; price and currency explicit; material edits may trigger re-review.  
**Cost/phase:** P2; no catalog or checkout required for MVP.

### SYS-069 — Orders, Fulfillment & Disputes
**Purpose:** future order lifecycle with payment and shipment states kept separate.  
**Flow:** order request → server price snapshot → pending payment → verified payment → merchant acceptance → fulfillment → delivered/cancelled/disputed → resolution.  
**Data:** `orders`, `order_items`, `order_status_events`, `shipment_updates`, `order_disputes`; immutable item/price/currency snapshot.  
**Access/contracts:** buyer reads own orders; merchant reads only required fields for own listings; staff dispute access audited. Future `create_order`, `cancel_order`, `record_shipment_update`, `open_order_dispute`. Client cannot set paid/delivered.  
**Abuse/failure:** fake shipment, changed listing price, duplicate order, chargeback. Idempotency and immutable history.  
**Acceptance:** price snapshot stable; cross-merchant isolation; payment and fulfillment independent; duplicate request creates one order.  
**Cost/phase:** P2; requires legal, consumer protection, logistics and support review.

### SYS-070 — Payments, Refunds & Payouts
**Purpose:** future safe payment boundary.  
**Flow:** hosted checkout → signed event → immutable transaction → refund/chargeback → eligibility checks → provider payout → reconciliation.  
**Data:** `payment_transactions`, `refunds`, provider-tokenized `payout_accounts`, `payout_batches`, `financial_audit_events`. Never store card/bank login credentials.  
**Access/contracts:** future `create_payment_intent`, `provider_payment_webhook`, `request_refund`, `execute_payout`. Only trusted service writes payment state; high-risk finance actions need dual control.  
**Abuse/failure:** webhook replay, over-refund, destination change, fraud/sanctions flag. Freeze ambiguous state and require review.  
**Acceptance:** signed events only; immutable ledger; idempotent processing; refund cannot exceed refundable balance; payout destination reverified.  
**Cost/phase:** P2 disabled; provider fees, KYC/AML, tax/legal, fraud ops and support are prerequisites.

# J — Trust & Safety Systems (71–80)
Safety rules apply consistently across feed, profile, search, messages, stories, communities, realtime and media URLs. Reports are allegations, not findings. Block is backend access control, not just a UI filter.

### SYS-071 — User & Content Reporting
**Purpose/flow:** authenticated user selects account/content/message/story/community, reason and optional context; server validates target and rate limits; report is stored; reporter gets safe reference/status; authorized reviewer triages.  
**Data:** existing `reports` foundation; reporter, target type/id, reason, safe context, state, timestamps; evidence refs separately access-controlled.  
**Access/contracts:** user creates and reads own safe report status only; reviewer reads authorized queue. Future `create_report`, `get_my_reports`, staff-only `assign_report`, `resolve_report`. Reporter cannot edit resolution or staff notes.  
**Abuse/failure:** duplicate spam, retaliation, invalid target. Rate-limit and deduplicate without discarding materially new evidence.  
**Acceptance:** reporter isolation; no client-set resolution; reviewer action audited; invalid target safely rejected.  
**Phase:** P0. Repo documents report foundation/workflow; every target and RLS path still requires multi-user tests.

### SYS-072 — Blocking, Muting & Interaction Restrictions
**Purpose/flow:** block/mute → server persists relationship → all surfaces and media permissions recalculate → message/invite/notification paths suppress → unblock restores only future permitted interactions.  
**Data:** existing `blocks`; optional separate `user_mutes` for scoped/expiring mute. Do not conflate mute with block.  
**Access/contracts:** only blocker manages own block. Existing block operations where present; future `mute_user`, `unmute_user`. Policies must cover RPC, search, realtime and signed Storage URLs.  
**Abuse/failure:** race with message send, stale caches, resurfacing via shared content. Recheck at server boundaries and invalidate caches.  
**Acceptance:** blocked user cannot access restricted profile/media or initiate prohibited messaging; unblock does not auto-follow.  
**Phase:** P0. Block-aware database policies are documented; end-to-end surface coverage remains to be proven.

### SYS-073 — Moderation Queue & Case Triage
**Purpose/flow:** reports/signals → priority → assignment → minimum-evidence review → decision → action → close/escalate.  
**Data:** future `moderation_cases`, `moderation_assignments`, `moderation_evidence_refs`, `moderation_case_events`; preserve `reports` as intake.  
**Access/contracts:** staff roles must be server-controlled, never user metadata. Future `list_moderation_queue`, `assign_moderation_case`, `get_case_evidence`, `escalate_case`. No generic admin SQL endpoint.  
**Abuse/failure:** queue scraping, compromised reviewer, overexposure, conflicting decisions. Least privilege, audit, escalation.  
**Acceptance:** ordinary user cannot enumerate cases; reviewer cannot forge assignment; access/actions logged; intake survives queue outage.  
**Phase:** P0 minimal manual review; P1 full console. Existing report tables do not prove secure staff UI.

### SYS-074 — Policy Enforcement & Sanctions
**Purpose:** proportionate content/account actions: hide/remove, warning, scoped restriction, temporary/permanent suspension, restoration.  
**Data:** future append-oriented `enforcement_actions`, `account_restrictions`, `content_moderation_states`, `enforcement_events`; actor, target, scope, reason, start/expiry, case reference.  
**Access/contracts:** trusted moderation service only. Future `apply_enforcement_action`, `expire_restriction`, `restore_account_access`. User reads safe notice only.  
**Abuse/failure:** wrong-account ban, indefinite temporary ban, staff abuse. Confirm severe action; require second review for permanent removal; preserve history.  
**Acceptance:** expiry works; scope enforced across features; action has reason/audit; reversal restores only intended access.  
**Phase:** P0 basic content action; P1 mature sanctions engine.

### SYS-075 — Appeals & Independent Review
**Purpose/flow:** notice → eligible appeal and deadline → user submits evidence → reviewer independent of original decision where feasible → uphold/modify/reverse → safe explanation.  
**Data:** existing appeal workflow is described in repo status; canonical `appeals`, `appeal_events`, evidence refs, linked action, submitter, state and decision.  
**Access/contracts:** affected user reads own appeal only; reviewer resolves; client cannot set outcome. Existing/planned `submit_appeal`, `get_my_appeals`, staff-only `review_appeal`, `resolve_appeal`.  
**Abuse/failure:** duplicate appeals, upload interruption, conflicted reviewer. Preserve recoverable drafts; show deadline/state.  
**Acceptance:** cannot appeal for another account; only staff resolves; reversal and enforcement state update atomically; internal notes hidden.  
**Phase:** P1; severe sanctions need an appeal path before public launch.

### SYS-076 — Spam, Automation & Abuse Prevention
**Purpose:** prevent spam, fake engagement, scraping, credential attacks and harassment.  
**Controls:** server-side rate limits/cooldowns, idempotency, bounded pagination, suspicious burst signals, upload caps, reporting/block feedback. Client timers are not security.  
**Data:** private short-retention security counters/events; minimize IP/device signals and avoid invasive fingerprinting.  
**Access/contracts:** trusted server guards auth, posting, comments, follow, messages, reports, search and uploads. Client cannot read/edit risk counters.  
**Failure:** false positives or distributed abuse. Throttle high-risk mutations while preserving safe read-only use; provide appeal/support path.  
**Acceptance:** server throttles repeated mutation; clock changes do not bypass; retries do not duplicate; false-positive recovery exists.  
**Phase:** P0 baseline using PostgreSQL/Edge Functions; no paid anti-bot vendor.

### SYS-077 — Identity Authenticity & Impersonation
**Purpose:** handle impersonation reports and any future verification program without misleading users.  
**Flow:** report → evidence review → decision → badge/status issue or revoke → audit. Phone/email verification is not proof of real-world identity.  
**Data:** future `identity_claims`, `verification_reviews`, `verification_badges`, `impersonation_cases`; minimize identity documents and retention.  
**Access/contracts:** client cannot set `is_verified`; future `submit_identity_claim`, `get_verification_status`, staff-only `review_identity_claim`, `revoke_verification`.  
**Abuse/failure:** stolen documents, fake badge sales, account takeover. No paid badges; revoke compromised claims.  
**Acceptance:** badge cannot be self-assigned; meaning is public; revoked state propagates; evidence is restricted.  
**Phase:** P1/P2; absent until policy and secure reviewer process exist.

### SYS-078 — Child Safety, Age Assurance & Sensitive Content
**Purpose:** conservative protection for minors and age-sensitive experiences.  
**Policy:** no adult content, age-restricted commerce, targeted ads or unrestricted stranger contact without jurisdiction-specific legal review and safeguards. Do not infer age from appearance/social graph. DOB remains private.  
**Data:** only necessary age band/assurance state if lawful and approved; private DOB never public.  
**Access/contracts:** server-enforced restrictions; trusted age state cannot be client-edited; future restricted reporting/escalation workflow.  
**Abuse/failure:** grooming, exploitation, age misrepresentation, accidental exposure. Accessible report/block; preserve evidence securely; protect reporter/child identity.  
**Acceptance:** private DOB not public; restrictions apply server-side; staff access audited; no unsupported compliance claim.  
**Phase:** P0 safety policy/reporting; advanced assurance P2. Global compliance is not zero-cost.

### SYS-079 — Content Integrity & Community Standards
**Purpose:** consistent rules, content labels, policy versions and repeat-violation handling.  
**Flow:** publish validation → policy review/labels → report/review → correction/enforcement → policy version update.  
**Data:** future `policy_versions`, `content_labels`, `content_review_events`. Do not claim media is authentic/AI-generated without reliable provenance.  
**Access/contracts:** author controls permitted labels; trusted review state is staff-only. Future `get_policy_version`, `set_content_label`, staff `set_review_state`.  
**Failure:** brigading, false labels, inconsistent enforcement. Version decisions and offer appeal for consequential action.  
**Acceptance:** decision stores policy version; author cannot override review state; labels do not imply unsupported verification.  
**Phase:** P1; basic rules and report taxonomy required for MVP.

### SYS-080 — Safety Audit, Transparency & Incident Response
**Purpose:** accountability for privileged safety actions and security incidents.  
**Data:** append-only `moderation_audit_events`, `security_incidents`, aggregate `transparency_metrics`. Exclude passwords, OTPs, tokens, message bodies and unnecessary sensitive data.  
**Flow:** signal/action → severity → owner → containment → evidence preservation → legally required notice → remediation → post-incident review.  
**Access/contracts:** audit not client-writable/deletable; limited security staff reads; future `open_security_incident`, `update_incident_status`, `publish_transparency_summary`.  
**Failure:** audit tampering, overcollection, disclosure. Separate privileges, retention policy, access logs and redaction.  
**Acceptance:** privileged actions emit events; secrets redacted; user cannot alter audit; incident owner/status traceable.  
**Phase:** P0 audit foundation; P1 staffed incident runbook and aggregate transparency.

# K — Operations & Administration Systems (81–90)
Administrative authority never comes from a profile field or user-editable metadata. Every privileged operation is checked server-side and audited.

### SYS-081 — Administrative Identity & RBAC
**Purpose:** staff identity, role, scope and permission model. Proposed roles: support-readonly, moderator, senior-moderator, security-operator, system-admin; finance role only if commerce is approved.  
**Data:** private `staff_memberships`, `staff_role_permissions`, `staff_access_events`. Avoid broad admin boolean.  
**Access/contracts:** trusted operator assigns/revokes roles with MFA/review; future `get_my_staff_capabilities`, `grant_staff_role`, `revoke_staff_role`. Every RPC/Edge Function rechecks role; no `user_metadata` authority.  
**Failure:** stale claims, ex-staff access, privilege escalation. Revoke sessions and test immediate denial.  
**Acceptance:** self-promotion impossible; moderator cannot grant admin; revoked staff loses access; actions audited.  
**Phase:** P0 security prerequisite; manual secure assignment initially.

### SYS-082 — Admin Console & Internal Tools
**Purpose:** restricted interface for report triage, appeals, safe account lookup, takedowns, restrictions and incidents.  
**Flow:** staff login → capability check → scoped queue → minimum data → confirm high-impact action → trusted mutation → audit receipt.  
**Data:** use scoped read models; do not duplicate all user data or expose arbitrary SQL.  
**Contracts:** task-specific endpoints from SYS-073–080; no generic `admin_execute_sql`. UI guard is not authorization.  
**Failure:** session theft, accidental mass action/export. MFA, short sessions, re-auth, pagination and audit.  
**Acceptance:** direct API call by non-staff denied; action confirmation identifies target/consequence; unauthorized modules inaccessible.  
**Phase:** P1 after RBAC tests; until then restricted dashboard operations only.

### SYS-083 — Platform Configuration & Feature Flags
**Purpose:** safe staged enable/disable of features and provider integrations.  
**Data:** private `platform_settings`, `feature_flags`, `feature_flag_rules`, `configuration_audit_events`; key, schema, environment, rollout, expiry, owner and reason. No secrets in client-readable config.  
**Contracts/access:** future `get_public_feature_config`, `set_feature_flag`, `rollback_feature_flag`; only authorized admin writes; flags never replace RLS.  
**Failure:** malformed/stale config or accidental rollout. Fail closed for paid/unverified capabilities; retain safe fallback.  
**Acceptance:** disabled feature cannot be invoked directly; rollback works; schema validated; secrets never reach client.  
**Phase:** P0 local flags; P1 server-controlled flags.

### SYS-084 — Service Health, Logging & Diagnostics
**Purpose:** diagnose auth/API/Edge Function/database/storage/push/job/client errors without leaking user data.  
**Data:** structured logs with correlation ID, feature, status, duration, redacted error class. Never log credentials, OTP, tokens, message body, private media URL or precise location.  
**Contracts/access:** common error envelope and server correlation IDs; future allowlisted `submit_client_diagnostic`. Operational logs are private and staff-scoped.  
**Failure:** log injection, secret leakage, telemetry quota. Sanitize, cap payload/rate, disable optional telemetry safely.  
**Acceptance:** errors correlate; secret-redaction tests pass; diagnostic upload can be disabled; quota exhaustion does not crash core app.  
**Phase:** P0 basic logs; P1 crash service only after cost/privacy review.

### SYS-085 — Product Analytics & Operational Metrics
**Purpose:** privacy-minimized measurement of adoption and reliability. MVP candidates: signup success, feed latency, post success, report intake, push outcomes and crash summaries. No message text or sensitive traits.  
**Data:** allowlisted aggregate events, separate from identity/operational logs, purpose and retention recorded.  
**Contracts/access:** future `record_product_event`; validate event schema and rate-limit. Staff sees aggregates only; never expose raw user activity to advertisers.  
**Failure:** event spam, re-identification, storage growth. Aggregate early, minimize identifiers, cap retention.  
**Acceptance:** no sensitive content; unknown fields rejected; metrics can be disabled; counts have documented tolerance.  
**Phase:** P1; no paid analytics SDK required.

### SYS-086 — Customer Support & User Requests
**Purpose:** safe route for account access, privacy, abuse and general requests.  
**Flow:** category/details → reference ID → triage → response/status → closure/escalation. Export/deletion use verified dedicated flows, not informal ticket handling.  
**Data:** future `support_tickets`, `support_messages`, `support_status_events`; never copy OTP/password or unnecessary private messages.  
**Access/contracts:** user sees own tickets; staff scope is assigned; sensitive cases route to safety/security. Future `create_support_ticket`, `get_my_support_tickets`, `reply_to_support_ticket`.  
**Failure:** spam and social engineering. Never ask for credentials; recovery uses Auth provider verification.  
**Acceptance:** owner isolation; no credential collection; sensitive categories restricted; status visible.  
**Phase:** P1; human response capacity must be disclosed honestly.

### SYS-087 — Background Jobs & Scheduled Tasks
**Purpose:** bounded async notifications, cleanup, retention and reconciliation.  
**Data:** future `job_outbox`, `job_attempts`, `scheduled_task_runs`, dead-letter records; reuse existing outbox/trigger patterns rather than duplicate them.  
**Flow:** transactional enqueue → leased claim → idempotent execution → bounded retry → dead-letter → operator review.  
**Access/contracts:** trusted worker only; conceptual `enqueue_domain_event`, `claim_job_batch`, `complete_job`, `fail_job`; clients cannot enqueue arbitrary code/read other payloads.  
**Failure:** duplicate execution, poison job, quota exhaustion. Idempotency, lease, jitter and bounded attempts.  
**Acceptance:** retry has one business effect; failed job observable; no infinite retry; UI does not claim completion before result.  
**Phase:** P0 essential bounded jobs only; no paid queue/always-on worker.

### SYS-088 — Backup, Restore & Data Recovery
**Purpose:** recover from accidental deletion, migration error and provider incident.  
**Policy:** backup is not verified until restore is tested. Free-tier retention/PITR varies; never promise it without checking active plan.  
**Operations:** versioned migrations, encrypted logical export where permitted, separate media-object plan, restore runbook, checksums, approved RPO/RTO.  
**Access:** named operators only; encrypted short-lived artifacts; never commit backups to Git.  
**Acceptance:** dated backup source; successful isolated restore drill; integrity/media references checked; limitations disclosed; deletion obligations reconciled.  
**Phase:** P0 recovery plan before public launch. If reliable backup requires paid plan, disclose launch blocker.

### SYS-089 — Deployment, Release & Environment Management
**Purpose:** separate dev/test/prod and controlled release.  
**Flow:** reviewed change → CI → migration/security review → staging validation → artifact → controlled deploy → smoke test → rollback/forward-fix.  
**Config:** environment-specific public client config; secrets remain server-side. Android application ID, Firebase registration, signing, redirect URLs and Supabase Auth URLs must match.  
**Access/contracts:** release maintainers only; CI records commit, toolchain, environment and artifact hash.  
**Failure:** wrong project, secret in APK/logs, migration breakage, lost signing key. Stop release on mismatch.  
**Acceptance:** artifact maps to commit/environment; no production secret in APK; migration recovery plan exists; debug APK never called store-ready.  
**Phase:** P0. Existing workflows exist; application ID/signing/config still need verification.

### SYS-090 — Operational Governance & Vendor Review
**Purpose:** maintain accountable ownership, dependency/cost inventory, change control and exit strategy.  
**Artifacts:** owner, data owner, provider, license, quota/cost, data exposure, change proposal, risk assessment, migration, release note, deprecation plan.  
**Flow:** proposal → security/privacy/cost/accessibility/data review → approval → implementation/tests → release → post-check → docs update.  
**Access:** critical changes require second reviewer where practical; no silent paid dependency.  
**Failure:** hidden recurring cost, incompatible license, abandoned provider, schema drift. Review inventory periodically.  
**Acceptance:** every production dependency has owner/license/cost/data/exit plan; schema change has migration/tests; integration can be disabled.  
**Phase:** P0 lightweight governance using GitHub docs/PRs.

# Cross-system authorization matrix
| Actor | Own data | Other public data | Private data | Moderation cases | Platform config | Financial records |
|---|---|---|---|---|---|---|
| Anonymous | No writes | Public-only | No | No | No | No |
| Authenticated user | Permitted own rows | Authorized/public rows | No unless explicitly shared | Own safe report/appeal status | Sanitized public flags | Own safe status only if introduced |
| Moderator | Own data | Assigned case scope | Minimum case scope | Assigned cases | No | No |
| Senior moderator | Own data | Escalation scope | Minimum escalation scope | Escalated cases | No | No |
| Security operator | Own data | Incident scope | Incident minimum | Security cases | Limited security config | No |
| System admin | No blanket content access | Only documented need | Only documented need | Operational scope | Authorized config | No by default |
| Finance operator (future) | No blanket profile access | No | No | No | No | Finance scope only |

This is policy intent, not proof of enforcement. Implement through grants, RLS, trusted functions and audit. Hiding UI is never authorization.

# Cross-document traceability and repository reality
| IDs | Domain | Repository evidence checked | Remaining proof/work |
|---|---|---|---|
| 63–70 | Ads/commerce | No verified ads/catalog/orders/payments in current repo baseline | Keep absent/disabled; future contracts only |
| 71 | Reporting | `reports` foundation and workflow documented | Verify all target types, duplicate limits, reporter isolation, reviewer authority |
| 72 | Blocking | `blocks` and block-aware profile/storage policies documented | Test feed/profile/message/story/search/realtime/signed URL end-to-end |
| 73–75 | Queue/enforcement/appeals | README/status describe moderation queue and appeals | Verify trusted roles, direct API denial, appeal isolation, audit and atomic reversal |
| 76 | Abuse | Partial controls only; no comprehensive anti-abuse claim | Server rate limits on every mutation and adversarial tests |
| 77 | Identity | No verified identity verification program | Keep absent until policy and secure review process |
| 78 | Child safety | Safety/privacy baseline only | Legal review, age-appropriate design and named escalation owner |
| 79–80 | Integrity/audit | Some report and DB audit foundation | Version policies; map every privileged action to append-only audit |
| 81–82 | RBAC/admin | DB hardening exists; complete staff RBAC/console not verified | Prove role source, direct API denial and least-privilege console |
| 83 | Flags | Complete server flag service not verified | Fail-closed provider flags and safe public config |
| 84–85 | Diagnostics/analytics | Basic client error handling; full analytics not verified | Redaction, correlation, privacy-minimized event schema |
| 86 | Support | Complete ticketing workflow not verified | Define safe support path and realistic response capacity |
| 87 | Jobs | Some triggers/outbox patterns exist | Prove idempotency, bounded retry and quota behavior |
| 88 | Recovery | Migration history exists; restore drill unverified | Encrypted backup and isolated restore test |
| 89 | Release | CI/build workflows exist | Verify env separation, app ID, signing, migration gate |
| 90 | Governance | Docs and PR workflow exist | Require owner/license/cost/risk review for dependencies |

## Required acceptance/security tests
1. Cross-account RLS tests for every table and RPC in scope.
2. Direct API tests bypassing Flutter for all staff actions.
3. Staff escalation tests: user metadata tampering, stale JWT/session, revoked role.
4. Block propagation across feed, profile, search, messages, stories, realtime and signed media.
5. Report/appeal isolation and valid state-transition tests.
6. Audit completeness, tamper resistance and secret-redaction tests.
7. Feature flags fail closed for paid/unconfigured integrations.
8. If commerce is ever activated: webhook signature, replay, amount/currency, idempotency, refund and payout tests.
9. Isolated backup/restore and release rollback/forward-fix drill.
10. RTL/accessibility checks for reporting, blocking, appeals and staff-facing safety states.

## Zero-budget release classification
- **MVP permitted:** reporting, blocking, basic manual moderation, scoped restrictions, minimal audit, basic diagnostics, documented operator process, bounded jobs within existing quotas.
- **Conditional:** appeals, staff console, push, analytics, support tooling and backup automation; activate only after end-to-end and quota verification.
- **Disabled/deferred:** ads, advertiser billing, creator payouts, checkout, marketplace, paid AI moderation, paid identity verification, external anti-bot, always-on paid workers.
- **Never fake:** identity verification, payment, shipment, ad impression billing, moderation review, backup success, push delivery or async completion.

## Sign-off checklist
- [ ] Reconcile canonical titles/IDs with Document 01.
- [ ] Map every data object to Document 05 schema and migration state.
- [ ] Map every operation to Document 06 API/RPC/event contract.
- [ ] Map every permission to Document 07 grants/RLS/security controls.
- [ ] Map every provider/cost to Document 08.
- [ ] Map phases/dependencies to Document 09.
- [ ] Map every acceptance test to Document 10.
- [ ] Keep all unverified items explicitly pending; do not infer implementation from this specification.
