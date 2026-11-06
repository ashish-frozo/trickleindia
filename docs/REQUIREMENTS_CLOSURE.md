# Requirements follow-up — 6 November 2026

This is the implementation follow-up to REQUIREMENTS_AUDIT.md, whose baseline remains commit 5e70fd4. It does not replace or erase that line-by-line audit. The user confirmed that AWS, approved repository and acceptance contacts are unavailable and instructed us to proceed without them.

## Delivered changes

| Audit gap | Implemented change | Verification / remaining limit |
|---|---|---|
| G01 | Actor/dataset-scoped encrypted form drafts, financial typing debounce and close recovery, profile/registration close recovery | Domain persistence/reset tests; profile typing before abrupt process death is not continuously persisted |
| G02 | Group selection, five language preference codes with planned labels, complete registration review | Shared client implementation; only EN/HI screens exist |
| G03 | Group included in final financial review; confirmed meeting remains frozen through save | Shared client; financial API tests retained |
| G04 | Translated action labels and Hindi tab semantics, locale dates | Matching EN/HI resources; fluent review still absent |
| G05 | Separate sending, blocked, conflict and rejected states | Shared UI and regression checks |
| G06 | Audit loading/error/retry, refresh and 50-row paging | Browser navigation and API tests |
| G07 | Bounded groups and financial-history API pages, totals independent of page size | API test; client still keeps a whole scoped bootstrap, so production scalability is not solved |
| G08 | Versioned content fetch, validated atomic installation and cached fallback; manager draft editor | API publish/replay/conflict tests, domain invalid-update test and browser editor check |
| G09 | Savings total links to supporting group records | Rebuilt portal review |
| G10 | Current EN/HI desktop/tablet screenshots and keyboard check | No fresh independent score or participant acceptance |
| G11 | Help failure/retry and audit retry states | Shared client; UI regression tests |
| G12 | Updated language worksheets | Fluent review and recorded audio remain outstanding |
| G13 | Capability/runbook/implementation/delivery updates, training guide/deck, operations preparation | Current evidence and limits are documented here |
| G14 | Rebuilt Android profile artifact | Fresh on-device core journey/TalkBack/launch evidence remains outstanding |
| G15 | Reserved attachment contract documented | No upload implementation is required by the demo and none is advertised |
| G16 | Ordinary Sakhi Edit profile action from passbook | Existing versioned API and conflict handling retained |

Additional implemented workflows: manager group creation/editing, meeting scheduling with attendance initialization, enterprise creation/editing and business plans, expense categories, scoped Sakhi visit intake and follow-up completion, confirmed-balance CSV export, manager content publishing with audit records. These are bounded implementations, not completion of every production-module rule in the RFP.

Identity groundwork: official Cognito JWT verification, database-controlled role mapping, session exchange, web/native PKCE clients, explicit provisioning utility and release signing safeguard. No AWS account or live callback has been tested. The app remains a labelled proposal demo; production organisation bootstrap and migration are not supplied.

Operations: backup utility with private output permissions and an isolated transactional restore utility that refuses non-empty targets. A test database was restored successfully. Recovery objectives and AWS operation are unverified.

## Current evidence

- API: 32 passing tests against PostgreSQL, including new workflow scope/version/replay rules and identity verification/mapping.
- Domain: 12 passing tests in the latest saved run, including draft recovery and invalid-content rollback.
- UI: 12 passing tests, one existing skip; includes CSV quoting/formula protection and existing large-text/offline/conflict checks.
- Static analysis: no issues in shared packages and both apps.
- Browser: closure-browser.json records no page errors and keyboard activation; closure-workflows.json verifies a populated help editor and actual CSV download. Current screenshots are in output/closure.
- Assets: all 260 EN/HI message keys match and static UI references resolve; palette contrast checks pass.
- Restore: closure-restore.txt records migration versions 1–4 and restored entity counts from the disposable test database. Counts include historical test datasets, not production participants.
- Training: seven-slide PowerPoint rendered and visually checked; no clipping or overlapping text observed.

Evidence filenames use the `closure-` prefix. Historical native recordings and earlier timing measurements are not proof of this revision's on-device acceptance.

## Still open — not all caused by missing credentials

Full five-module production detail, financial product rules beyond the bounded principal model, comprehensive report/admin catalogue, live AI and voice navigation, reviewed five-language content/recordings, production organisation bootstrap/data migration, cloud infrastructure and load/security validation still require work. Actual TalkBack listening, representative physical-device startup performance, participant UAT and formal acceptance are not completed. The earlier measured launch target remains unmet; it is not waived by faster unit tests.

TUIF AWS deployment and approved repository transfer cannot be performed without their environment. No account, reviewer, acceptance signature, SLA, commercial price, CV/reference or production deployment has been fabricated. OPERATIONS_PREPARATION.md and USER_TRAINING.md provide usable preparation while those resources are absent. Formal technical/financial proposals and complete infrastructure-as-code are not delivered by this follow-up.
