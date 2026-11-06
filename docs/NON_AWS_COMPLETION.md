# Non-AWS implementation and release record — 6 November 2026

This supersedes the current-status section of REQUIREMENTS_CLOSURE.md. The original line-by-line REQUIREMENTS_AUDIT.md remains historical evidence. The user directed implementation to continue without a TUIF AWS environment, approved repository or acceptance contacts. No production environment, approved business rules, recordings, language review or acceptance signatures have been invented.

## Implemented

| Workstream | Delivered | Evidence / boundary |
|---|---|---|
| Five modules | Profiling, group/meeting administration, principal-based financial records, enterprise cash/plans, Sakhi visits/follow-ups | PHASE_ONE_BASELINE.md defines the exact candidate rules; unsupported financial products are not silently claimed |
| Programme reports | Five scoped snapshot reports, 50-row display pages, whole-filter CSV export, confirmed totals and refresh timestamps | Snapshot/report tests; integer paise and CSV formula protection; whole-snapshot bootstrap remains |
| Organisation and identities | Empty-organisation bootstrap; manager/Sakhi/participant mappings, assignments, disable/re-enable, last-manager protection and online session revocation | PostgreSQL scope/version/replay/audit tests; actual identity tenant/callback acceptance unavailable |
| Opening import | Strict structured JSON, dry run, reviewed hash, reconciliation totals, atomic/idempotent commit, provenance and conservative rollback | Concurrent retry, invalid input, version/session and post-edit rollback refusal tests; real source data not supplied |
| Help and voice | Offline cited help, optional consented provider-selected cards, exact role-limited navigation commands and explicit review before opening | Provider boundary tests and repeated-listening/page-reentry widget tests; no autonomous financial actions or real provider call |
| Languages/audio | 348 matching EN/HI resources, persisted actor language choice, script-specific reviewed-pack builder, source/hash/placeholder checks and recorded-audio manifest validation | Five validation tests; Odia/Ho/Santhali worksheets remain unreviewed and inactive; no fabricated audio |
| Persistence and access | Debounced encrypted financial/profile/registration drafts, native encrypted storage, role checks, restricted audit entity types | Domain recovery and native encryption tests; automatic browser PKCE callback handling implemented |
| Release reliability | Pinned CI, disposable DB guard, source credential checks, dependency audit, OpenAPI contract, build and packaging scripts | Remote CI not run without an approved repository; no production signing credentials |
| Operations/handover | Bootstrap/import guide, incident/recovery instructions, restored-backup drill from prior follow-up, current training guide/deck and acceptance worksheet | Actual disaster recovery objectives and participant acceptance remain external |

## Verification

- PostgreSQL API: 51/51 tests passed, including identity mapping, import reconciliation, exact-once retries and assistant boundaries.
- Database guard: three nonconnecting test cases reject remote/query-override/non-test targets before destructive tests run.
- Domain: 12/12 passed; native encrypted-storage reopen/unkeyed-reader check: 1/1 passed.
- UI: 18 passed, one existing visual-preview skip. Static analysis: no issues across both apps and shared packages. Platform build and browser/device results are saved under `docs/evidence/nonaws-*` after final integration.
- Local synthetic load: 1,006 members, 100 reads at concurrency eight; p50 228.83 ms, p95 478.47 ms. Twenty identical financial retries produced exactly one effect. This uses Fastify injection with PostgreSQL, not network/TLS capacity. Full result: `docs/evidence/nonaws-load.json`.
- Production npm audit found zero advisories in the saved run. This is not a penetration-test certification.
- Both platform builds succeeded. The 46.9 MB ARM64 profile APK verifies under Android development signing; it is not a production-signed release. Browser desktop/tablet EN/HI, keyboard activation, report download, invalid import, identity editor, cited help, money-command rejection and microphone disclosure passed with no page errors.
- The ordinary APK upgraded without clearing device data. A fully disconnected ₹200 contribution survived process restart with the identical operation ID, then changed Rani’s confirmed savings from ₹1,600 to ₹1,800 and cleared the queue. PostgreSQL independently confirms exactly one transaction and one receipt: `nonaws-native-server-proof.json`.
- An earlier ₹200 preflight remained connected through a surviving keep-alive socket and was correctly recorded online. It is preserved and explicitly excluded from offline acceptance in `nonaws-native-preflight.json`; the successful test force-stopped after disconnecting to close all sockets. The synthetic programme total is now ₹5,400. No demo reset was used.
- Native help and microphone consent were exercised; Hindi preference survived process restart and English was restored. Captures use a 360dp emulator at normal text scale; 200% layout checks are widget evidence, not TalkBack acceptance. Actual recognition and spoken output were not certified.
- Latest retained-data cold activity launches: 2.766 s, 2.309 s and 2.632 s. These exceed the 2-second target. They are emulator activity timings, not proof of full cached-content availability or physical-device acceptance. The startup requirement remains open.
- Eight-slide training deck rendered and visually checked. Current image gallery: `output/nonaws/index.html`.

## Acceptance still requiring external evidence

1. TUIF AWS deployment, approved repository transfer, production signing/domain configuration and live identity callback checks.
2. Actual data-owner source mapping/reconciliation and approval of the candidate Phase 1 rules/report catalogue.
3. Fluent EN/HI terminology review; complete Odia, Ho and Santhali translations, permitted recordings and participant comprehension review. Script candidates are documented, not accepted by a customer.
4. Live provider verification if online assistance is selected; actual device microphone/TTS/TalkBack checks with suitable services and permissions.
5. Representative physical-device startup/accessibility and participant UAT. Earlier emulator full cached-start measurements exceeded the two-second target; a fast unit test does not close that requirement.
6. Contractual/commercial proposal details, support ownership, warranty and service levels require accountable organisational inputs. No CV, reference, price, reviewer or signature is fabricated.

This record establishes implemented local engineering scope. It does not label the full RFP or production release as accepted. The remaining boundaries and prerequisites are explicit so local review cannot be mistaken for customer approval.
