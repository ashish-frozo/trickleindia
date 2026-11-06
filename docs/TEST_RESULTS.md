# Verification report

Verification dates: original implementation 5 November 2026; UI redesign 6 November 2026. This report distinguishes executed checks from manual acceptance still requiring equipment. Synthetic data only. No production-readiness claim.

## Automated results

- 23 API integration tests against real PostgreSQL 18.3: `evidence/api-tests.txt`.
- 10 domain/controller tests: `evidence/domain-tests.txt`.
- 8 Flutter widget tests on the redesign: `evidence/redesign-ui-tests.txt` (the original 6-test run is retained as `evidence/ui-tests.txt`).
- Native macOS encrypted SQLite reopen/unkeyed-reader test: `evidence/native-encryption-test.txt` and the final verification log.
- Real HTTP API + encrypted native-store restart/lost-acknowledgment roundtrip: `evidence/native-api-roundtrip.txt`.
- 8 Android process/installation phases: `evidence/android-*.txt`, summarised in `evidence/android-summary.json`.

The profile comparison regression was confirmed failing when the proposed values were deliberately omitted (`profile-review-red.txt`), then passed with the fix. That negative log is intentional.

The Android phases cover bootstrap, real route disconnection/durable savings save, force-stop recovery, sync, a second Android user installation with independent storage, offline registration, registration restart/sync and a real dropped HTTP response after financial commit. `android-durability.json` compares operation ID, transaction ID, full payload, payload hash and immutable metadata across force-stop. `android-server-checkpoints.json` independently verifies seven members, savings 500000 and principal 490000 paise after native registration/repayment.

Flutter static analysis, API TypeScript compilation, ARM64 Android and release web builds were run. Asset verification checks all 191 bilingual keys, static message references, bundled help/audio states and nine text/background contrast pairs (minimum 5.13:1 among tested pairs). The portal uses a real browser and real API; keyboard Enter activates Support, reduced motion and grayscale vision emulation were verified; its support recording verifies a stable replay reference and open counts 1→2→1. The pinned, repeatable root `npm run test:portal` also passes against Chrome156 with Playwright1.64.1 (`evidence/portal-reproducible.txt`). Raw browser checks are in `evidence/portal-*.txt`; keyboard focus and page-error results are in `evidence/web-keyboard.json`.

## RFP-led UI redesign

The shared Flutter UI now uses bundled regular/semibold Noto fonts, a forest/sage theme, a task-led mobile home, a passbook with separate confirmed/pending money, and a dedicated responsive programme workspace. The portal adds aligned group/member tables, scoped group drill-down, compact filters and grouped support actions. `docs/design/RFP_UI_REQUIREMENTS.md` maps the supplied ten-page RFP to the implementation and full-production gaps.

The 23 real PostgreSQL API tests were rerun (`redesign-api-tests.txt`). The eight widget tests cover English/Hindi at 200%, keyboard and modal behavior, repeated confirmation, conflict review, group drill-down and first-viewport pending balances. The programme group test also reaches and activates Support with Tab/Enter and asserts both groups retain principal outstanding in the 768px layout. The tablet regression was confirmed failing before the missing field was restored (`redesign-tablet-red.txt`). Token/message checks are in `redesign-assets-and-contrast.txt`; the once-only mechanical design scan returned no findings (`redesign-detector.json`).

An ordinary redesigned ARM64 profile APK saved ₹200 offline, recovered the same operation after force-stop/reopen, and reconciled to Rani's ₹1,400 confirmed savings with an empty queue. PostgreSQL independently confirmed one transaction and one receipt: `redesign-native-proof.json`, `redesign-server-proof.json`. The initial final-state automation wait incorrectly expected the label and value in one semantics node; it was corrected to wait for the amount and assert the connection separately. No business assertion was weakened. Final portal/Android captures are in `output/redesign`; first-review captures are retained separately. The independent finish review disposition is **ship**, with its tablet-principal material finding resolved in both languages (`docs/design/FINISH_REVIEW.md`). A truncated Hindi toolbar title at 200% remains an optional refinement; the member, amount and action are legible. These captures include the accepted contribution (overall savings ₹5,000), whereas the fresh fixture starts at ₹4,800.

The five-language and voice/audio expectations of the full RFP are not all implemented: the demo has English/Hindi and explicit unavailable/planned states for the remaining capabilities. The previously documented TalkBack speech and full cached-start acceptance gaps remain open.

## Acceptance mapping

“Passed” identifies the executed layers below; it does not imply a physical-device field trial. Screenshots establish appearance, while API/client assertions establish financial effects.

| ID | Result and evidence |
|---|---|
| A01 | Passed: real seeded aggregate API and portal show six members, two groups, savings 480000, principal 500000, surplus 120000. |
| A02 | Passed: three scoped bootstrap identities, guessed IDs denied, role spoof rejected; separate Android profile bootstrap. |
| A03 | Passed on Android: actual API route removed, durable contribution, confirmed 120000/pending 20000. |
| A04 | Passed on Android: force-stop/reopen recovers identical immutable envelope and one pending amount. |
| A05 | Passed: Android pending clears, exactly one transaction, Rani 140000; server groups/aggregate checkpoints and portal. |
| A06 | Passed on Android and real HTTP integration: commit then socket close, pull/receipt reconciles one financial effect. |
| A07 | Passed: changed payload reuse and reused transaction ID rejected; original effect unchanged. |
| A08 | Passed: repeated review confirmation produces one intent; barrier-controlled reentrant client sync has one upload; eight concurrent server retries have one effect. |
| A09 | Passed: second Android user installation starts with no session/cache and retrieves accepted contribution; invisible page and version/page replay checks. |
| A10 | Passed: controlled PostgreSQL writer barrier, pre/post-commit bootstrap and raw cursor pagination; atomic native state transactions and restart. |
| A11 | Passed: stale attendance/profile return winner; unsent edits supersede; widget conflict review retains original and links a new versioned intent. |
| A12 | Passed: Android ₹100 repayment → Rani190000/overall490000; racing server repayments cannot overdraw principal. |
| A13 | Passed: current-revision submission and controlled close/post race; a posting ordered after close is rejected. |
| A14 | Passed: expense215000/surplus85000, full reversal180000/120000, second reversal rejected, original and correction retained. |
| A15 | Passed on Android: registration survives separate process and syncs at zero balances; manager count7, unchanged savings; normalized duplicate review tested server-side. |
| A16 | Passed: real browser simulation/replay/assignment/resolution and API assertions, open counts1→2→1; transport labelled. |
| A17 | Passed: expired local lease prevents upload; known server401 immediately locks cache (also exercised by real reset on the final APK); same-actor reauth keeps intent; actor/dataset changes with pending work rejected. |
| A18 | Passed in API/controller layers: reset revokes sessions; old-dataset intent remains private and blocks silent actor/dataset replacement. Explicit review/reset remains available. |
| A19 | Passed: actual Android encrypted file rejects unkeyed SQLite; secure-storage keys; ordinary APK secret scan; local HTTP exceptions excluded from release source set. |
| A20 | Partial: English/Hindi, keyboard/200% widget layouts, native semantics, offline expanded help, grayscale and target viewport review completed. Actual TalkBack spoken-output check remains unexecuted: AOSP emulator has no TalkBack/TTS service and no physical phone is connected. Do not mark this acceptance gate passed. |
| A21 | Passed: network/503 retry keeps IDs, 401 blocks/locks, numeric/date Retry-After honoured, independent operations continue. |
| A22 | Passed: fictional-data, draft-help, simulation, unavailable audio and planned languages/providers labelled in UI and handoff. |
| A23 | Passed: participant financial writes, wrong group/member/loan/enterprise relationships and unauthorized reversal rejected. |
| A24 | Passed: accepted receipt reconciles before discard; missing ambiguous receipt refuses discard; reversed effective ledger remains correct. |
| A25 | Passed: parser/server bounds reject fractional/invalid/negative/overflow amounts, principal cap and reversal-effective totals verified; pending remains separate. |
| A26 | Passed with permitted audio exception: four bilingual bundled cards; no reviewed audio assets, no working-playback claim. |
| A27 | Passed local startup path: clean copied source, isolated PostgreSQL cluster, migration/seed/login and encrypted-client/API roundtrip; `evidence/clean-startup.txt` and `clean-native-roundtrip.txt`. Docker execution unavailable; Compose configuration validated. |

## Timing and device limits

Eight Android cache-initialization observations ranged from 658 to 1914 ms. One durable savings-save observation was 65 ms. The cache measurement excludes Android/Flutter engine startup; it must not be presented as full application launch latency. The initial debug cold activity launch was approximately 5 seconds. The AOT profile build reduced its initial launch to 4.14 seconds; observed cached activity launches included 2.80, 3.05 and 3.55 seconds; the final APK launch measured 2.46 seconds. The full cached-start target of ≤2 seconds was not met on this emulator. Actual profile launch measurements are retained separately. Those original implementation samples are historical. The redesign captures encountered emulator System UI ANRs during cold boot; an uncontrolled cold activity launch was 6.12s and a later post-install launch timed out during the OS stall. They are not a controlled benchmark; see `evidence/redesign-device-notes.md`. The target remains unmet and requires representative-device measurement. These samples describe an API36 ARM64 software-rendered emulator (two cores, about 2.5 GB RAM), not field-device guarantees.

## Remaining acceptance and explicit exceptions

Actual TalkBack speech needs an Android installation with TalkBack and a TTS engine, then a listener must verify amount/status pronunciation, focus order, forms and modal return focus in both languages. Native accessibility labels are inspected but are not a substitute for that spoken-output test. This is the remaining A20 customer acceptance blocker. Full cached-start performance is also an unmet P1 quality target on this emulator and requires investigation/verification on representative Android hardware.

Reviewed audio is unavailable, as explicitly permitted by the pack. Live AI/speech/official WhatsApp are optional P2 and disabled. Docker container execution was not possible here; the tested startup uses native PostgreSQL. Hindi terminology/help copy still needs participant/content-owner review before production rollout. No credentials, private local config, credential-bearing test APKs or browser session traces belong in the handoff archive.


## Remaining-gap follow-up (6 November 2026)

See [GAP_CLOSURE.md](GAP_CLOSURE.md) for current status. English/Hindi draft help now supports device-generated speech, with installed offline voices required on Android and explicit missing-voice errors. Reviewed audio recordings and five-language acceptance remain outstanding. Narrow/large-text page titles now wrap in scrollable content. Prior screenshot and finish-review evidence describes the earlier build.


## VengeanceUI adaptation — 6 November 2026

The current UI uses Flutter adaptations of VengeanceUI SpotlightNavbar, GlowBorderCard and ResearchBentoGrid.Panel, with MIT attribution. It replaces the prior forest visual direction while retaining the existing Flutter apps, data and workflows. See [design/VENGEANCE_UI.md](design/VENGEANCE_UI.md). Current screenshots and verification use the `vengeance` prefix. Earlier finish reviews and screenshots are historical. External acceptance gaps are unchanged.
