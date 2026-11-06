# Requirements audit — 6 November 2026

Audit baseline: application commit `5e70fd4`. Reviewed the original ten-page RFP, START_HERE and every linked coding-pack specification, current source, test definitions and saved execution evidence. This is a source/evidence review, not a fresh execution of the full acceptance suite or customer sign-off. No application code or data was changed by this audit.

**Conclusion: the local demonstration implements the main financial/offline journeys, but neither full demo acceptance nor the complete production RFP is finished.** The earlier “remaining gaps” lists were incomplete: they emphasized language/accessibility and omitted several product, operational, documentation and smaller demo-interface gaps.

## How to read this audit

- **Implemented (demo):** source plus execution evidence support the bounded synthetic workflow. This does not mean production acceptance.
- **Partial:** a subset exists; the remaining work is named.
- **Missing:** no implementation/deliverable was found in this workspace.
- **Unverified:** implementation or documentation exists, but the required execution/review evidence is missing or outdated.
- **Approval pending:** TUIF must define or approve it; that does not transfer the vendor's implementation/content responsibility to TUIF.
- **Optional/deferred:** explicitly outside required demo scope or a later-phase vision, not a silently waived RFP requirement.

The RFP is [the supplied PDF](../RfpDocuments_6a117cf26110482d92618ed039e0786d.pdf). A line-numbered extraction is preserved in [requirements-rfp-extract.txt](evidence/requirements-rfp-extract.txt). References below use printed section and PDF page because extracted line wrapping is not a contractual requirement boundary. Each normative bullet/clause is accounted for, with repeated wording grouped. Section 1 is organisational background, not an application acceptance checklist.

## 1. RFP product, offline and inclusion requirements

| Ref | Requirement | Current status / what remains |
|---|---|---|
| §2 p1 | Comprehensive platform spanning SHGs, MEGs, enterprises, clusters, markets and governance | **Partial.** Six-member/two-group demo, one enterprise. MEG/cluster/market features not implemented. §5 phases the broader vision; do not label every later-phase item a Phase 1 defect. |
| §2 p1 | Operate with limited connectivity and interruptions | **Implemented (demo).** Encrypted cached records and queued capture within an eight-hour lease. Production offline dataset/workflow boundary and retention still need agreement. |
| §2 p1 | Local language, voice navigation, minimal entry, simple interface | **Partial.** EN/HI, labelled controls, presets/dropdowns; no voice navigation and no participant usability acceptance. |
| §2 p1 | Mobile for members, Sakhis and field teams | **Partial.** Participant/Sakhi/manager synthetic personas exist. Separate production field-team roles and permissions require the BRD. |
| §2 p1 | Separate portal for managers/administrators | **Implemented (demo)** manager portal; **missing** production administrator/user/role-management workflows. |
| §2 p1 | Advanced monitoring/reporting/analytics | **Partial.** Aggregates, group scope, transactions and support queue. No agreed reporting catalogue, exports or advanced analysis implementation. |
| §2 p1 | Content management | **Missing.** Bundled read-only help and static content endpoint; no author/reviewer/publisher UI. |
| §2.1 pp1–2 | Enter/save/access relevant data offline | **Implemented (demo)** for scoped cached data, attendance, registration, financial entries and help requests. Submission/reversal/support progression are online by deliberate demo scope. Full production boundary remains unapproved. |
| §2.1 p2 | Automatically sync on reconnection | **Implemented (demo)** through periodic 15-second foreground checks, foreground resume and save/retry triggers. Not a proven OS background-sync service. Agree background behaviour if needed. |
| §2.1 p2 | Failed/pending notifications and pending/success/failure visibility | **Partial.** Persistent queue, confirmed/pending/error labels exist. Per-item `sending` currently falls through to “needs attention” rather than its own syncing label; fix this UX gap. |
| §2.1 p2 | Prevent duplicate submissions | **Implemented (demo).** Operation receipts, payload hashes, transaction identity and lost-ack tests. |
| §2.1 p2 | Consistency and multi-device conflict resolution | **Implemented (demo).** Version checks, explicit review, superseding unsent edits, serialized financial acceptance and independent Android-store evidence. Production contention/scale not established. |
| §2.1 p2 | Reliable sync mechanism ensuring integrity/continuity | **Partial production readiness.** Inspectable demo protocol works; serial dataset lock and whole-state local storage require workload sizing, load/long-history tests and architecture approval. |
| §2.2 p2 | English | **Implemented draft.** Core interface/resources exist; some ancillary labels remain raw codes. |
| §2.2 p2 | Hindi | **Partial.** Draft UI/help works; fluent terminology review, remaining raw codes/accessibility strings and participant acceptance pending. |
| §2.2 p2 | Odia | **Missing translated product.** Worksheet and candidate Odia script decision only; translations, fonts, recordings and task tests pending. |
| §2.2 p2 | Ho | **Missing translated product.** Worksheet and candidate Warang Citi direction only; community script/terminology validation and implementation pending. |
| §2.2 p2 | Santhali | **Missing translated product.** Worksheet and candidate Ol Chiki direction only; community validation and implementation pending. |
| §2.2 p2 | Multilingual UI and language selection | **Partial.** EN/HI toggle only, resets to English on a new process; other locales not working. Registration also omits the planned preference options required by the demo contract. |
| §2.2 p2 | Voice-assisted navigation | **Missing.** TTS reading of help is not navigation or speech recognition. |
| §2.2 p2 | Audio instructions through key functions | **Partial.** Device-generated EN/HI help-card reading when compatible voices exist. No reviewed bundled recordings, broader in-flow guidance or verified five-language playback. Android requires installed offline voices. |
| §2.2 p2 | Simple language/icons/visual cues/intuitive navigation | **Partial/unverified usability.** Visible labels and redesigned hierarchy exist; no field-user study establishes intuitiveness. |
| §2.2 p2 | Minimise manual input | **Partial.** Amount presets and categorical inputs exist; several support/profile fields remain typed; voice/assisted entry absent. Feasible minimum must be validated with users. |
| §2.2 p2 | Consistent language across user-facing functions | **Partial.** Raw audit actions, English “Tab … of …” semantics and some fixed English date/technical text remain. |
| §2.2 p2 | Operable for limited reading/writing ability | **Unverified.** Large text/keyboard/contrast checks are useful but do not establish this user outcome. TalkBack speech and participant tasks outstanding. |
| §2.2 p2 | Demonstrate language/accessibility during design and UAT | **Approval pending.** Local screenshots/tests are not TUIF design review or UAT. |
| §3 pp2–3 | Digitise records/transparency/financial accountability | **Partial.** Canonical ledger, passbook, reversal and audit demonstrate mechanisms; operational outcomes not measured. |
| §3 pp2–3 | Profitability/business planning/market access | **Partial/deferred scope.** Cash surplus only; business planning and market functionality absent. Decide Phase 1 enterprise scope; do not claim profitability from cash totals. |
| §3 p3 | Real-time monitoring/reporting/reduce paper | **Partial.** Poll/refreshed server summaries, explicit freshness. Offline unsent activity is not visible centrally; no outcome evidence. |
| §3 p3 | Digital inclusion/voice interaction/adoption | **Partial/unverified.** Voice navigation and adoption evidence missing. |
| §4 p3 | AI voice assistant and chatbot | **Missing live AI.** Four deterministic help cards and device TTS are not these AI modules. |
| §4–5 p3 | Predictive analytics/recommendation engine | **Deferred vision.** No implementation; §5 places advanced AI/analytics later. Do not invent a fully defined Phase 1 requirement. |
| §5 p3 | Module 1: Registration & Profiling | **Partial module.** Offline registration, duplicate handling and profile-update API exist; no ordinary profile-edit screen, production onboarding/recovery or approved complete profile schema. |
| §5 p3 | Module 2: SHG Management | **Partial module.** Seeded groups/membership, attendance and submission; no create/edit group, group lifecycle, membership administration or meeting scheduling workflow. Exact baseline needs BRD. |
| §5 p3 | Module 3: SHG Financial Management | **Partial module.** Deposits, seeded principal repayments, passbooks and full reversals. No withdrawals, loan origination, interest, fees, schedules or agreed maker/checker policy. These are scope decisions to settle, not assumed universally mandatory accounting rules. |
| §5 p3 | Module 4: Enterprise Management | **Partial module.** One seeded enterprise, sale/expense, cash surplus. No enterprise onboarding/editing/business planning; category is fixed to `seeds` in entry UI. Inventory/receivables/profit rules require agreement if included. |
| §5 p3 | Module 5: Smart Sakhi Monitoring | **Partial module.** Assigned support workflow only; no approved caseload/visits/coaching/activity indicators and supervisory monitoring implementation. Those examples are proposed scope, not explicit RFP field lists. |
| §5 p3 | Common AI voice/chat modules across all phases, progressively enhanced | **Missing agreed Phase 1 baseline.** Optional live AI in the demo does not remove this RFP obligation. Define tasks, corpus, languages, fallback, providers and acceptance before building/pricing. |

## 2. RFP engineering, delivery and acceptance clauses

| Ref | Requirement | Current status / remaining work |
|---|---|---|
| §6 p3 | Secure, reliable, maintainable, fit-for-purpose, cost-effective | **Partial.** Local demo evidence; no production capacity/security/cost acceptance. |
| §6.1 p3 | Flutter mobile and web | **Implemented.** Android profile APK and Flutter web release built. Other native platforms are not explicitly mandated in the supplied RFP; confirm fleet. |
| §6.1 p3 | Node.js backend/APIs | **Implemented.** TypeScript/Fastify/PostgreSQL API. |
| §6.1 pp3–4 | Hosting in TUIF AWS | **Missing.** Localhost only. |
| §6.1 p3 | Firebase Authentication or Cognito, TUIF-selected | **Missing.** Custom restricted demo identity only. Production mode disables demo login; it does not provide replacement production authentication. |
| §6.1 p4 | TUIF approval of key choices | **Approval pending.** Local user feedback is not TUIF architecture approval. |
| §6.2 p4 | Complete functional maintainable source for every component | **Implemented for demo.** Local repository, locks, migrations/API/source archive. Full production scope not written. |
| §6.2 p4 | TUIF-approved repository accessible throughout development | **Unverified/not delivered.** No evidence of client repository approval or access. |
| §6.2 p4 | Version history and release management | **Partial.** Git commits/checksummed packages exist; client release process/CI and production release approvals absent. |
| §6.2 p4 | Handover ownership of source/assets | **Prepared locally, not formally handed over.** Contractual transfer and receipt/acceptance pending. |
| §6.2 p4 | Secure coding, validation, errors, auth and access controls | **Partial.** Schemas, scoped permissions and error envelope tested; production identity and independent security review missing. |
| §6.2 p4 | No hardcoded credentials/secrets | **Implemented demo safeguards.** Configured hashes, ignored local secrets and scanned ordinary packages. Production secrets management remains to implement. |
| §6.2 p4 | Protect participant/SHG/financial data | **Partial.** Native encryption and actor scope tested on synthetic data. Production retention, access policy, key lifecycle/recovery and assessment pending. |
| §6.2 p4 | Secure transmission | **Partial.** Release source excludes local HTTP exception; supplied local profile APK deliberately uses loopback HTTP. Actual HTTPS hosted endpoints/certificates unconfigured. |
| §6.2 pp4–5 | Structured/readable/modular/documented source and consistent conventions | **Partial.** Shared packages and analysis exist; large UI file, compact API implementation and demo storage design need maintainability review for production. |
| §6.2 p5 | Support future modules/integration without major redevelopment | **Unverified at production scope.** Shared boundaries exist; no scale/migration validation for whole-state cache, JSONB records and global write lock. |
| §6.2 p5 | Regular code reviews/quality checks | **Partial.** Historical review and automated logs exist; no fresh full independent review of latest redesign or client-reviewed development process. |
| §6.2 p5 | Disclose all dependencies/licences/recurring costs | **Partial.** Locks, bundled notices, Unicode/OFL/MIT provenance present. Consolidated notice omits recent TTS/Vengeance additions; complete current dependency/cost disclosure still needed. |
| §6.2 p5 | Assess library reliability/security/maintenance/compatibility | **Partial.** Builds/tests pass. Production dependency assessment and current Flutter-TTS Kotlin migration warning follow-up pending. |
| §6.2 p5 | Vendor review/testing responsibility including AI-generated code | **Partial.** Test evidence available; vendor review/sign-off still required. AI generation does not waive accountability. |
| §6.2 p5 | Maintain technical docs throughout development | **Partial.** Many docs exist but capability/runbook/implementation notes contain stale audio/key-count statements. Reconcile them. |
| §6.2 p5 | Source, DB, APIs, config, deployment scripts and docs handover | **Partial.** Local demo archive exists; AWS/production release assets and formal delivery pending. |
| §6.2 p5 | Enable independent operation/maintenance by TUIF or successor | **Partial.** Clean local startup evidence; no independent AWS deployment/restore/rollback or knowledge transfer. |
| §6.3 p5 | Accessible UX/UI suitable for intended users | **Partial/unverified.** New layouts exist; field tasks, local-language acceptance and latest visual rubric incomplete. |
| §6.3 p5 | Database/model/relationship design | **Partial.** Demo migrations and constraints exist. Production model/relationship constraints and migration approach need approval. |
| §6.3 p5 | API/data-exchange/integration specifications | **Partial.** Demo OpenAPI exists. Production integrations, identity and new module contracts undefined. |
| §6.3 p5 | Workflows, screen wireframes and navigation from approved BRD | **Partial.** Demo flows/comps exist; full module wireframes and approved BRD alignment absent. |
| §6.3 p5 | Review approved BRD/wireframes; approve changes | **Approval pending.** Approved BRD not supplied. Demo decisions must not be presented as it. |
| §6.3 pp5–6 | Offline/multilingual/accessibility architecture | **Partial.** Demo offline design and two locales implemented; five-language/voice/production design incomplete. |
| §6.3 p6 | Present architecture/design for TUIF approval | **Approval pending.** No written acceptance evidence. |
| §6.4 p6 | Milestone technical reviews and functionality/test demonstrations | **Pending formal process.** Local tests/screens/recordings are available; no documented TUIF milestone reviews. |
| §6.4 p6 | Periodic module demos against BRD/incorporate feedback | **Partial.** User UI feedback incorporated; approved BRD/module validation still pending. |
| §6.4 p6 | Record/prioritise/resolve observations and obtain approval | **Partial.** Issue notes exist; complete client-owned observation/closure register and approvals missing. |
| §6.5 p6 | Cooperate with security/vulnerability/penetration assessment | **Pending.** No completed TUIF-arranged assessment evidence. |
| §6.5 p6 | Fix attributable vulnerabilities; provide retest evidence | **Pending assessment and remediation.** Do not interpret absent findings as a clean security report. |
| §6.5 p6 | Resolve/retest critical/high findings before release or approved exception | **Unverified release gate.** No production release/security approval. |
| §6.6 p6 | TUIF approval of key libraries; disclose charges/concerns | **Approval pending.** User's VengeanceUI request is not TUIF approval of the production stack. |
| §6.7 p6 | Functional/integration/regression tests across supported devices/browsers | **Partial.** PostgreSQL/domain/widget/native-emulator/Chrome evidence. Fleet/browser support matrix and physical low-end devices absent. Latest UI has no new native run. |
| §6.7 p6 | Automated checks where practical | **Implemented demo checks.** 23 API tests in historical last backend run; latest 11 UI/speech tests, one opt-in preview skipped in normal run; preview run separately passes. These are different suites, not a completion percentage. |
| §6.7 p6 | Document results/defects and close release blockers | **Partial.** A20 incomplete, startup target unmet and new source-review gaps below. Full acceptance cannot be claimed. |
| §6.8 p7 | Set up/deploy AWS development and UAT | **Missing.** No deployed customer environments. |
| §6.8 p7 | Access controls, secure configuration, logging and monitoring | **Missing production setup.** Demo audit is not operational monitoring; API request logger is disabled. |
| §6.8 p7 | Sized AWS infrastructure proposal | **Missing approved detailed configuration.** Local architecture/production mapping is not a sized design. |
| §6.8 p7 | Itemised hosting/database/storage/backup/other recurring estimates | **Missing final estimate.** Need workload, retention and cost assumptions. |
| §6.9 p7 | Own development/UAT deployments and resolve issues | **Pending.** Local server is not either AWS environment. |
| §6.9 p7 | Tested production scripts/config/prerequisites/rollback | **Missing.** Compose/local runbook only; no verified AWS deploy/rollback. Container execution itself was not tested here. |
| §6.9 p7 | Production release after TUIF acceptance/security approval | **Approval pending.** Supplied APK is development-signed ARM64 profile, not a distribution release. |
| §6.10 p7 | Docs for components/stack/APIs/config/dependencies/AWS/build/deploy | **Partial.** Local docs exist; AWS instructions and current consolidated state missing. |
| §6.10 p7 | Professional PowerPoint: architecture/features/modules/workflows/UI/capabilities | **Missing .pptx deliverable.** Scope DOCX and compliance XLSX exist but do not satisfy this presentation clause. |
| §6.10 p7 | Handover/knowledge-transfer session | **Missing formal session and evidence.** |
| §6.11 p7 | Scope/UAT/critical defects/security/observation closure/source/doc handover | **Not accepted.** Multiple implementation and acceptance gaps remain. |
| §6.11 pp7–8 | Propose warranty duration, arrangements and response timelines | **Missing agreed commercial terms.** No fixed duration is mandated by the RFP; vendor must propose it. |
| §6.11 pp7–8 | Implement/test/approve all functions; hand over user/technical docs, presentation, deployment/admin access | **Partial local artifacts; production handover pending.** No complete user training manual, production access or client approval. |
| §6.11 p8 | Deliver warranty support for agreed period | **Future contractual obligation.** Not something this demo can mark complete. |

## 3. Proposal, payment and final acceptance clauses

The existing `outputs/tuif_scope_20261106` DOCX and 56-row compliance workbook are **scope/planning artifacts**, not submitted technical/financial proposals. They were inspected read-only. No mailbox search was performed in this audit; submission status cannot be established beyond local evidence and the project brief.

| Ref | Required clause | Status / next action |
|---|---|---|
| §13.1 p8 | Company profile and relevant experience | **Proposal pending.** Gather verified company evidence. |
| §13.1 p8 | Understanding and proposed approach | **Partial.** Brief/scope document available; assemble final technical PDF. |
| §13.1 p8 | Detailed methodology/implementation plan | **Partial.** Demo work packages and production scope planning; complete staffed delivery methodology. |
| §13.1 p8 | Offline/multilingual experience | **Evidence pending.** Demo can illustrate current approach, not be labelled a completed client deployment. |
| §13.1 p8 | Low-digital-literacy application experience | **Evidence pending.** Validate truthful experience claims. |
| §13.1 p8 | Prior application links/demos where available | **Pending verified examples.** Separate own products from team members' previous employment work. |
| §13.1 p8 | Work plan/timeline | **Missing final staffed timeline.** |
| §13.1 p8 | Team composition and key CVs | **Missing final proposal evidence.** Do not invent availability or CVs. |
| §13.1 p8 | One/two similar assignments; references where available | **Pending verified evidence.** No invented client references. |
| §13.1 p8 | Additional capability information | **Partial.** Working local demo/test evidence can be included with limitations. |
| §13.2 p8 | Development cost | **Missing final financial proposal.** |
| §13.2 p8 | AWS cost | **Missing itemised approved assumptions/estimate.** |
| §13.2 p8 | AI subscription cost | **Missing provider/usage-based estimate.** |
| §13.2 p8 | Professional fees | **Missing final costing.** |
| §13.2 p8 | Taxes/statutory charges | **Missing final reviewed financial figures.** |
| §13.2 p8 | Other incidental costs | **Missing complete breakdown**, including language/voice effort where applicable. |
| §13.2 p8 | INR inclusive of applicable taxes | **Pending final financial PDF.** |
| §13.3 pp8–9 | Two separate technical/financial PDFs, email, deadline and subjects | **No final pair/submission evidence found locally.** Supplied RFP states 9 Nov 2026, 17:00 IST. Current amendments/address authenticity were not reverified; no email was sent by this audit. |
| §14 p9 M1 20% | Approved base document/work plan/finalised requirements | **Approval pending.** Local planning documents are not written TUIF acceptance. |
| §14 p9 M2 20% | Approved UI/wireframes/DB/architecture | **Approval pending.** |
| §14 p9 M3 30% | Demonstrate all agreed Phase 1 modules against BRD | **Partial implementation; approval pending.** |
| §14 p9 M4 20% | Testing/UAT/production readiness | **Incomplete.** |
| §14 p9 M5 10% | Source/docs/presentation/knowledge transfer | **Partial artifacts; incomplete formal handover.** |
| §14 p9 | Invoice/supporting documents and satisfactory written review | **Commercial process pending.** No milestone may be deemed payable merely from demo tests. |
| §18 p9 | Review against approved BRD/scope/technical/quality standards | **Pending approved baseline and TUIF review.** |
| §18 p9 | Module/doc/output validation | **Pending client acceptance.** |
| §18 p9 | Functional testing and UAT for intended workflows | **Partial local functional tests; no representative UAT.** |
| §18 p9 | Resolve/resubmit in-scope observations within agreed timelines without extra charge | **Open obligation.** Agree tracking/closure and fix the audited gaps. |
| §18 pp9–10 | Complete final handover, UAT, critical-defect resolution and knowledge transfer | **Incomplete.** |
| §18 p10 | Written TUIF approval before any milestone/assignment is complete | **Missing approval evidence.** |
| §19 p10 | Amendment/withdrawal/no award or preparation-cost guarantee | **Commercial condition**, not a software feature. Verify current tender status separately before submission. |
| §19 p10 | Handover project assets under contract; no unauthorised confidential-data sharing | **Pending formal ownership handover.** Demo is synthetic; production handling/provider disclosures must follow the agreed contract. No production data access was exercised in this audit. |

## 4. Required demo capabilities D01–D19

| ID | Scope | Audit result |
|---|---|---|
| D01 P0 | Restricted login/bootstrap/offline lease | Implemented demo; production identity remains separate. |
| D02 P0 | Offline SHG/member profiles | Implemented reads. Ordinary profile editing/group lifecycle not part of this bounded read requirement. |
| D03 P0 | Durable attendance | Implemented; saved intent/restart coverage in prior native/controller evidence. |
| D04 P0 | Savings entry/review/persistence/retry/sync | Implemented financial path; review omits group in the final confirmation and unsaved form retention has a gap (below). |
| D05 P0 | Confirmed/pending passbook | Implemented with UI regression evidence. |
| D06 P0 | Queue/status/retry/conflicts | Partial presentation: `sending` mapped to attention; retry/conflict/discard mechanisms exist. |
| D07 P0 | Server-derived dashboard/group/member detail | Implemented; savings summary drill-down removed in latest redesign; audit pagination incomplete. |
| D08 P0 | Fully localised main journey/system states | Partial: matched resources do not cover raw audit/semantic/date strings. Hindi reviewed wording remains unverified. |
| D09 P1 | Principal-only repayment | Implemented with cap/concurrency evidence. Interest/disbursement not required by demo. |
| D10 P1 | Revision-safe online meeting finalisation | Implemented with race tests. |
| D11 P1 | Offline enterprise sale/expense/cash summary | Implemented bounded arithmetic; category fixed to seeds and no full enterprise lifecycle. |
| D12 P1 | Offline member registration/duplicate review | Partial UI: durable saved intent works; form lacks group display/selection, only EN/HI preferences and name-only review. |
| D13 P1 | Create/assign/progress/resolve support | Implemented for seeded actors; only one Sakhi fixture means meaningful cross-Sakhi reassignment demonstration is limited. |
| D14 P1 | Offline help and reviewed audio when available | Text help implemented; device TTS conditional. Reviewed recordings absent under explicit demo exception. |
| D15 P1 | WhatsApp preview creates real support record | Implemented simulation; no external messages. |
| D16 P1 | Online reasoned reversal/audit | Implemented ledger/reason path; activity presentation/localisation/paging incomplete. |
| D17 P2 | Live spoken expense draft | Optional demo, missing. Do not confuse help TTS with speech-to-text input. |
| D18 P2 | Live grounded knowledge assistant | Optional demo, missing. RFP common chatbot remains a production requirement. |
| D19 P2 | Official WhatsApp test connection | Optional and missing. Not explicitly required by the original RFP; do not block core delivery on it. |

## 5. Additional demo-spec gaps found directly in current source

These were not adequately enumerated in the previous gap report. Source locations refer to baseline `5e70fd4`; later edits may move line numbers. Findings are source-inspected, not newly reproduced on a device in this audit.

| ID / requirement | Evidence | Remaining change or validation |
|---|---|---|
| G01 — §02 preserve form input on back/failure | `packages/ui/lib/pop_ui.dart:2063` entry allocates local controllers; disposes them after dialog completion. Registration/input dialogs behave similarly. | Persist recoverable unsubmitted drafts or confirm discard on back; ensure reopen restores input. Saved outbox intent durability is already implemented and is a different requirement. |
| G02 — §02 M11 / §04 language preferences | `pop_ui.dart:2460` registration uses `['en','hi']`, `groups.first`, review text only `name.text`. | Show assigned group (picker when multiple), expose other supported preference codes clearly marked Planned, review language/livelihood/contact/group before save. Never advertise translated screens that do not exist. |
| G03 — §02 M06 / PRD core review | `pop_ui.dart:2140` final review includes member/type/amount/date, not group. | Keep group visible in the final confirmation too, as required by the core journey. |
| G04 — §07 complete EN/HI labels and locale dates | `pop_ui.dart:2790` support audit and `:2970` activity use raw action strings; `src/vengeance.dart:178` hardcodes English tab semantics; entry/capabilities include fixed English date text. | Localise user-facing actions, semantic phrases and date presentation; inspect all routes, not only ARB key parity. Names/user-entered descriptions must remain as entered. |
| G05 — §02 M07 syncing status | `pop_ui.dart:2238` state mapping has acknowledged/pending/retry branches, but sending becomes needsAttention. | Give sending/blocked/conflict/rejected appropriate distinct translated states; verify announcement timing. |
| G06 — §02 W05 / §04 bounded pagination | `pop_ui.dart:2940` requests `/v1/audit-events` once, without offset/load-more; API `app.ts:113` defaults to first100. | Add paging, refresh and request/error retry. Current view cannot expose all history after100 events; `auditLoaded` is set before request success. |
| G07 — §04 paginate lists | `services/api/src/app.ts:84–99` groups/passbook/meeting/enterprise histories return full arrays. | Add consistent bounded pagination for growing histories, with corresponding UI. Support/audit endpoints are bounded; bootstrap remains whole-dataset by demo design. |
| G08 — §07 atomic content updates | Help reads `rootBundle` in `pop_ui.dart:2869`; server reports `contentVersion:1`; controller does not fetch/install versioned content. | Bundled offline content works, but no update install/version rollback path. Implement if retaining that capability promise; static bundle is the actual current behaviour. |
| G09 — §02 overview metric drill-down | `pop_ui.dart:1365` savings panel has no action; the other three metrics have `InkWell`. | Restore savings supporting-record navigation. Top-navigation/colour changes are authorised design changes, not themselves defects. |
| G10 — WP6/current visual rubric | `docs/VISUAL_REVIEW.md` scores an older design; latest `BLUEPRINT_UI.md` explicitly disclaims fresh independent/native acceptance. | Review and score latest UI against all eight rubric dimensions, capture all required core viewports/locales, fix failures. Do not reuse historical36/40. |
| G11 — §02 every async view loading/error/retry | Help FutureBuilder only tests `hasData`; activity sets loaded before network success. | Handle help load/parse failure and activity retry explicitly rather than indefinite loading/empty result. |
| G12 — §07 Hindi review before client-facing recording | Help/ARB metadata remains draft; no named fluent reviewer evidence. | Arrange and document fluent review. This is also a demo presentation condition, not solely a future production nicety. |
| G13 — WP7 current truthful handoff | CAPABILITY_MATRIX says170 keys/no audio controls; IMPLEMENTATION_NOTES/RUNBOOK describe speech as wholly unavailable; recent checks show197 UI keys and conditional TTS. | Reconcile current capability, user instructions, dependency notices and test summary; retain historical evidence with dates. |
| G14 — WP6/7 actual latest native evidence | `output/blueprint/app-*` are widget previews; latest APK only built/signed. Recordings/native proof show earlier UI. | Fresh native core journey/EN-HI captures on latest APK; refresh recording or clearly date the existing historical functional evidence. |
| G15 — §03 reserved attachment interface | No attachment abstraction surfaced in inspected domain/API/storage boundary. Required demo deliberately has no uploads. | Small architecture/documentation gap: reserve an interface if maintaining that spec promise; implementing file upload is not a P0/P1 requirement. |
| G16 — full RFP profiling vs server-only support | `member.update` exists in API/controller and conflict tests, but no normal edit-profile form invokes it. | Provide ordinary profile editing as part of approved Module1 scope; do not cite conflict tests as proof that users can initiate a profile edit. |

## 6. Acceptance evidence A01–A27

This table reports **existing** evidence, not fresh executions. Latest UI/speech runs are at baseline5e70fd4; financial/native proofs largely predate the latest purely visual changes. A test-level pass does not erase the detailed UI/spec gaps above.

| ID | Evidence-based disposition | Outstanding qualification |
|---|---|---|
| A01 | Existing pass: seed/API/portal numeric checkpoints | No new reset performed by this audit. |
| A02 | Existing pass: actor scope/guessed IDs/role spoof | Production identity unimplemented. |
| A03 | Existing Android pass: offline durable savings | Rerun latest APK for current release evidence. |
| A04 | Existing Android pass: force-stop immutable IDs/payload | Same latest-build qualification. |
| A05 | Existing pass: once-only ledger/correct totals/pending clears | Same latest-build qualification. |
| A06 | Existing native + HTTP pass: response lost after commit | Same latest-build qualification. |
| A07 | Existing pass: changed replay rejected | Inspect API log/test. |
| A08 | Existing API/controller/widget pass: one intent/worker/effect | Latest widget repeated-confirm test also passes. |
| A09 | Existing pass: separate Android user installation + cursor cases | Two independent stores, not two physical phones or field trial. |
| A10 | Existing controlled API barrier and native atomic-state evidence | Not a production load/crash-fuzz campaign. |
| A11 | Existing API/controller/widget pass: conflict/re-edit | Ordinary profile-edit UI still absent; tests use injected profile edits. |
| A12 | Existing pass: native repayment/arithmetic/concurrency | Principal-only model. |
| A13 | Existing pass: latest revision/close-post race | Does not establish all production meeting policies. |
| A14 | Existing pass: expense/reversal/effective ledger | No full enterprise accounting. |
| A15 | Existing Android pass: saved registration restart/zero balance/duplicate | Registration form coverage gaps G02 remain. |
| A16 | Existing browser/API pass: simulator + support lifecycle | Not live WhatsApp delivery. |
| A17 | Existing pass: lease lock/scope/reauth preservation | Offline revocation inherently waits for contact or lease expiry. |
| A18 | Existing API/controller pass: dataset mismatch/pending retention | No new current native reset run. |
| A19 | Existing native encryption/secret scan/release-config evidence | Current profile APK signature/package checks pass; no penetration-test claim. |
| A20 | **Partial / not passed.** EN/HI/200%/keyboard/contrast evidence | Actual TalkBack speech, residual localisation and latest native layout acceptance remain. |
| A21 | Existing pass: network/backoff/401/independent queue | Periodic foreground sync, not guaranteed background scheduling. |
| A22 | Implemented UI disclosures; **handoff partial** | Stale docs in G13 prevent a blanket current-artifact truthfulness pass. |
| A23 | Existing pass: role/relationship/reversal restrictions | Full production permission matrix unapproved. |
| A24 | Existing pass: reconcile before ambiguous discard | Keep financial corrections through reversal. |
| A25 | Existing pass: money bounds/principal cap/reversal/pending types | Bounded demo integer model. |
| A26 | Existing pass for text with **permitted recorded-audio exception** | Conditional device TTS now added; no reviewed clip or actual audible acceptance evidence. |
| A27 | Existing clean local-source/isolated Postgres/encrypted-client reproduction | Docker execution absent; newest packaged revision not freshly reproduced by a second engineer. |

Timing is separate from this numbered matrix: latest stored activity-launch samples are **4,099 / 3,163 / 2,640 ms**, all above the **2,000 ms** target. These Android measurements say `LaunchState: COLD` (activity process launches with retained app data), not warm-process UI timing. Cache-initialisation times below2s must not be substituted for full launch. One historical durable-save observation was65ms against300ms; more representative-device samples are needed. See [gaps-startup.json](evidence/gaps-startup.json) and [TEST_RESULTS.md](TEST_RESULTS.md).

## 7. Scope boundaries and priority

**Fixable locally now:** G01–G11/G13/G16 within their approved demo/module scope; reconcile documentation, update current visual review, extend pagination/content/version handling and regenerate review evidence. Do not call every missing implementation “blocked on the client.”

**Needs real people/devices in addition to engineering:** reviewed five-language content and audio, script/terminology validation, TalkBack listening, physical-device performance, participant tasks/UAT. The vendor remains responsible for sourcing translation/voice delivery; the project brief attributes validation support to TUIF. That clarification was not reverified in email during this audit.

**Needs production scope/account decisions plus implementation:** full five modules, reporting/admin/content management, AI voice/chat baseline, Firebase/Cognito, TUIF AWS environments, monitoring/backups/recovery, security assessment/remediation, production release/rollback, support terms and knowledge transfer. Lack of AWS credentials does not prevent preparing scoped architecture, cost assumptions, infrastructure code or documentation first.

**Do not inflate the requirement:** official WhatsApp is optional; predictive/recommendation engines and cluster/market ecosystem features are progressively phased; no exact budget, warranty duration, production device fleet or final financial rules are supplied. Confirm them instead of inventing acceptance criteria. The user-authorised blue/white/top-navigation redesign supersedes the original proposed colour/sidebar compositions; it does not waive interaction, accessibility or correctness requirements.

Recommended order: close known demo correctness/usability/documentation gaps → current native/accessibility/performance evidence → agree complete Phase1 BRD/report/AI baseline → deliver language/voice and remaining modules → production identity/AWS/security/operations → UAT, formal documents/presentation, handover and written acceptance. Proposal preparation is a separate milestone and should not wait for optional demo integrations.

## Evidence index

- Current source: `packages/ui/lib/pop_ui.dart`, `packages/ui/lib/src/{workspace,vengeance,speech}.dart`, `packages/domain/lib/pop_domain.dart`, `apps/mobile/lib/store.dart`, `services/api/src/{app,mutations,domain,db}.ts`.
- API tests and evidence: `services/api/test/api.test.ts`, `docs/evidence/redesign-api-tests.txt` (23 passed).
- Latest UI: `docs/evidence/blueprint-ui-tests.txt`, `blueprint-analysis.txt`, `blueprint-browser.json`, `blueprint-app-previews.txt`, `blueprint-{web,android}-build.txt`, `blueprint-apk-signature.txt`.
- Native financial proof: `docs/evidence/android-durability.json`, `android-server-checkpoints.json`, `redesign-native-proof.json`, `redesign-server-proof.json`.
- Encryption/startup: `docs/evidence/gaps-encryption.txt`, `gaps-startup.json`, `clean-startup.txt`, `clean-native-roundtrip.txt`.
- Language/voice: `docs/localization/DECISION.md`, translation worksheets, `packages/ui/lib/src/speech.dart`, `packages/ui/test/speech_test.dart`, `docs/GAP_CLOSURE.md`.
- Historical reports are evidence with dates, not automatically current acceptance: `TEST_RESULTS.md`, `VISUAL_REVIEW.md`, `CAPABILITY_MATRIX.md`, `IMPLEMENTATION_NOTES.md`, `RUNBOOK.md`.

## Appendix: screen inventory and work-package gates

| Screen | Source requirement | Audit disposition |
|---|---|---|
| M01 | Demo entry/personas/code/language/download | Implemented for demo; production auth missing. |
| M02 | Greeting/meeting/work/sync/main action | Implemented redesigned composition. User authorised layout/colour changes; final usability acceptance pending. |
| M03 | Groups/members/search/add member | Implemented seeded reads/search/registration entry point. No production group administration. |
| M04 | Identity/confirmed/pending/principal/history | Implemented; latest native and TalkBack checks pending. |
| M05 | Attendance/entries/totals/save status/submit | Implemented; production meeting lifecycle beyond seeded session absent. |
| M06 | Amount/presets/note/date/review/confirm | Implemented financial path; G01/G03 draft retention and review completeness gaps. |
| M07 | Sync states/contact/reasons/retry/conflicts | Implemented mechanics; G05 state presentation gap. |
| M08 | Cash sales/expenses/surplus/entries | Implemented fixture workflow; category and enterprise-management scope limited. |
| M09 | Assigned requests/progression/resolution/origin | Implemented; updates online as documented. |
| M10 | Offline cards/audio availability/request help | Implemented text and conditional TTS; reviewed recordings absent; G08/G11 update/error paths incomplete. |
| M11 | Registration fields/review/draft/confirmed | Partial; G01/G02. Persisted operation recovery is implemented. |
| W01 | Metrics/freshness/groups/support/activity | Implemented data/layout; G09 savings drill-down missing. |
| W02 | Groups/filter/member drawer/history | Implemented routed member detail instead of drawer, documented deviation; no need to rebuild a drawer solely for literal visual matching. |
| W03 | Attendance/amounts/submission/version explanation | Implemented demo workflow and race/error handling. |
| W04 | Status/owner filters/detail/trail/reassignment/resolution | Implemented; audit trail displays raw action codes (G04). |
| W05 | Actor/subject/actions/times/operation/correction | Partial: first page only, refresh/error/localisation gaps (G04/G06). |
| W06 | Revision/availability/reset/capability/fault controls | Implemented demo controls/disclosures; stale documentation must be reconciled. |
| X01 | Labelled simulated chat/contact/topics/reference/result | Implemented bounded expense-help scenario; live transport intentionally absent. |

| Work package | Current gate result |
|---|---|
| WP0 toolchain/setup | Local native-PostgreSQL setup reproduced historically; Docker configuration checked, execution unverified. |
| WP1 seed/contracts/arithmetic | Existing real-PostgreSQL evidence passes bounded demo scenarios. |
| WP2 shared UI/real reads/encryption | Implemented; recent source layout changes do not have complete new native captures. |
| WP3 core offline/sync | Existing A01–A10 multilayer/native evidence; no fresh full current-APK rerun in this audit. |
| WP4 operational workflows | Bounded arithmetic/mutation workflows implemented; registration/ordinary profile UI gaps described above. |
| WP5 support/help/simulation | Implemented bounded paths; recorded audio explicitly excepted; content update and error path incomplete. |
| WP6 refinement/accessibility | Not closed: current rubric, actual TalkBack, residual localisation/forms and field usability evidence pending. |
| WP7 handoff | Artifacts exist; not fully closed because acceptance gaps, stale docs and latest-build native reproduction remain. |
| WP8 live integrations | Optional demo and not implemented; RFP AI baseline still needs separate production delivery. |

Required handoff outputs checked: source/locks/migrations/seed/env/Compose/local startup, local ARM64 profile APK, self-contained web build, OpenAPI, saved test evidence, historical screenshots/recordings, local reset/recovery instructions and licence artifacts exist. A dedicated current capability presentation slide, formal PowerPoint/user training materials, consolidated current dependency/cost disclosure and production operations/handover are not established by those files. Backup instructions currently mention `pg_dump`; there is no verified production restore/rollback procedure.
