# Document 08 — Zero-Budget Costs, Dependencies & Risks

Status: Project baseline  
Scope: NEXORA MVP  
Financial rule: No paid dependency is required to build or test the MVP. Free tiers are quota-limited and may change; this document does not promise unlimited free hosting.

## 1. Non-negotiable rules
1. No paid API, subscription, payment method, or usage upgrade may be activated automatically.
2. Every external provider must be isolated behind an adapter so it can be replaced.
3. A feature that needs unavailable infrastructure remains disabled and is not represented as operational.
4. Never bypass provider quotas, terms, or rate limits.
5. Do not put server secrets in Flutter, Web builds, Git history, issues, or chat.
6. Free-tier availability is not an SLA or a guarantee of production capacity.

## 2. MVP dependency baseline
| Capability | Initial approach | Cost posture | MVP decision |
|---|---|---|---|
| Android client | Flutter/Dart | Open source | Required |
| Source control / CI | GitHub Free within quotas | Quota-limited | Required |
| Database / Auth / Storage | Existing Supabase project and current plan | Free-plan limits; verify quotas | Required, constrained |
| Realtime | Supabase Realtime | Quota-limited | Limited |
| Push notifications | Firebase Cloud Messaging | No direct per-message fee in normal FCM model; setup and delivery still required | Optional until device test passes |
| Search | PostgreSQL full-text search and indexes | Within database capacity | Required |
| Image preparation | On-device compression and validation | No processing service | Required |
| Maps | OpenStreetMap data with compliant tile/geocoding provider | Provider policies apply | Not required |
| Email delivery | Existing Auth email/provider configuration | Limits and deliverability vary | Optional; verify |
| SMS / WhatsApp OTP | Supported external delivery provider | Not guaranteed free | Disabled until configured and tested |
| AI | Provider adapter only | External model APIs may be paid | Disabled |
| Voice/video | WebRTC plus TURN/SFU infrastructure | Reliable relay/media infrastructure may cost money | Deferred |
| Live streaming | Media ingest, transcoding, distribution | Operational cost expected | Deferred |
| Payments / payouts | Licensed provider and compliance | Fees and legal requirements | Deferred |
| Ads | Ad network and policy review | Provider and operational constraints | Deferred |

## 3. Authentication decision
The product vision prefers phone-first signup. The current repository has phone OTP UI and provider integration, but the Supabase project audit says Phone Auth is disabled and no working SMS delivery has been verified.

- Do not claim phone signup is operational until provider setup and a real-device delivery test pass.
- For a zero-budget development path, use Guest mode and/or Email only where delivery and recovery are verified.
- Do not substitute a hard-coded OTP, fake success state, or client-only verification.
- Keep phone flow unavailable or behind a disabled feature flag until configured.

## 4. Quota and capacity controls
- Define per-user upload count and size limits on the server, not only in the client.
- Compress images before upload and reject unsupported formats.
- Paginate feeds, search results, messages, notifications, and moderation queues.
- Avoid unbounded realtime subscriptions and repeated polling.
- Add request rate limits to signup, search, follows, comments, messages, uploads, and reports.
- Monitor database, storage, bandwidth, Edge Function, and CI usage against the current provider plan.
- Provide clear errors when quotas or provider availability prevent an operation.
- Keep export and backup procedures independent of any one provider where feasible.

## 5. Deferred features
SMS / WhatsApp OTP, external AI generation, TURN/SFU calling, live streaming, transcoding, CDN delivery, payments, payouts, ad billing, and large-scale media scanning are not MVP commitments. Do not show them as live until dependencies are funded, configured, secured, and tested.

## 6. Risk register
| Risk | Likelihood | Impact | Mitigation |
|---|---|---|---|
| Supabase free quota exhausted | Medium/high as usage grows | High | Usage limits, monitoring, graceful degradation, export plan |
| Provider free tier changes | Medium | High | Provider adapters and periodic review |
| SMS costs or delivery failure | High until configured | High | Disable phone OTP until verified |
| Storage abuse / oversized media | High | High | Server-side quotas, signature checks, cleanup |
| Unauthorized access / RLS gap | Medium | Critical | Least privilege, RLS tests, security review |
| Spam and automated abuse | High | High | Rate limits, reporting, throttles, moderation |
| Single developer / mobile-only workflow | High | High | Small vertical slices, CI, recovery docs |
| Premature scaling | Medium | High | Modular monolith; split only with evidence |
| Vendor lock-in | Medium | Medium/high | SQL migrations, export drills, adapters |
| False feature-completion claims | Medium | High | Status labels and acceptance gates |

## 7. Release rules
Every release identifies provider and plan, quotas, active/degraded/disabled features, expected costs, export/recovery path, operational owner, and incident response path.

No-go: if an MVP-critical workflow depends on a paid or unverified provider, replace it with a tested free path or exclude it.

## 8. Explicit non-promises
NEXORA does not promise unlimited free hosting, guaranteed availability, zero cost at global scale, free SMS/WhatsApp, free AI inference, or million-user capacity on free tiers. Scaling requires measured demand and a separate cost decision.
