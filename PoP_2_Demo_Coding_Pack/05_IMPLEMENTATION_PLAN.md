# Ordered implementation plan

Complete vertical slices in this order. Each gate requires evidence. Do not start with all screens populated from disconnected hard-coded lists. Establish the real data path, then extend it using the same components and contracts.

## WP0 — Inspect and establish the toolchain

Read this pack, inspect existing files, and preserve unrelated work. Verify Flutter/Android tooling, Node.js and Docker availability. Choose supported stable versions through official documentation, pin dependencies and commit lockfiles. Record the exact toolchain and licence notices. Create the repository layout from the architecture document, environment examples, API/PostgreSQL Compose setup, and a single documented development startup procedure.

Gate: API readiness works against migrated PostgreSQL, Flutter mobile and web shells render, and a clean-checkout engineer can reproduce setup. If Android SDK or emulator access is unavailable, continue independently on server/web and list the exact missing prerequisite. A web-only result does not satisfy the Android offline gate.

## WP1 — Seed, contracts and authoritative arithmetic

Implement migrations for actors, assignments, records, ledger, receipts, audit and sync clock. Import assets/demo_seed.json through a repeatable seed command. Implement demo sessions and role-scoped bootstrap. Add pure aggregate functions or tested SQL views with one documented definition for each metric. Implement the canonical mutation schema and OpenAPI document.

Gate: the reset checkpoint is exactly six members, two groups, ₹4,800 savings, ₹5,000 outstanding principal and ₹1,200 enterprise cash surplus. Participant/Sakhi scope tests reject cross-group and cross-member access. A reset produces a new dataset ID and revokes prior sessions.

## WP2 — UI foundation and first real read journey

Import tokens and ARB resources; bundle fonts with licences. Implement shared components and responsive shells. Build M01–M04 and W01–W02 against real API/local repositories. Add every status state listed in the UI specification. Install the authorised bootstrap snapshot into an encrypted local database and verify restart access within the lease.

Gate: English and Hindi screenshots at target sizes; no hard-coded final financial cards; participant identity remains distinct from the active Sakhi. Verify encryption using an unkeyed reader and test scope after role switch.

## WP3 — Core offline savings and synchronisation

Build meeting attendance, the financial entry/review sheet and sync centre (M05–M07). Persist an outbox and pending overlay in one local transaction. Implement transaction.post, receipt replay, version-aware canonical upserts, bootstrap cursor, incremental pulls, backoff and foreground recovery. Add local-development fault controls for lose response after commit, temporary API failure and deterministic conflict setup. Keep fault controls restricted to test/demo mode.

Gate: run A01–A10 in the acceptance document. Capture the actual device in airplane mode or with API connectivity blocked. Force-stop/reopen while pending. Restore connection and show the same entry once in the passbook and portal. Test the encrypted native database, not just an in-memory replacement.

## WP4 — Complete the operational workflows

Add principal repayment, meeting finalisation, registration duplicate review, enterprise entries and manager reversal. Implement M08, M11, W03 and W05 with real records. Registration starts with zero balances. Use type-specific validation so enterprise entries do not require a meeting. Keep submission/reversal online and preserve ledger history.

Gate: every checkpoint in the seed fixture passes. Run race tests for repayment and meeting closure. Confirm stale attendance/profile changes require review. Verify a submitted meeting rejects further mobile postings and a manager correction remains traceable.

## WP5 — Support, content and WhatsApp demonstration

Build M09–M10, W04, W06 and X01. Bundle bilingual help cards, create/review audio assets if possible, and expose their availability truthfully. Build the local WhatsApp chat simulator against the shared support API, including duplicate simulated-event handling and assigned Sakhi work queue updates. Do not introduce external account setup into this gate.

Gate: the simulated chat creates one request, replay creates no duplicate, manager resolves it with a note, and Sakhi sees its canonical status. Help works without connectivity. Content approval state, audio state and live/simulated/planned integration state are visible.

## WP6 — Visual refinement and field usability

Use the screen inventory to review layouts at all target sizes. Complete localisation, text scaling, TalkBack labels, keyboard portal navigation, focus states, empty/error views and status announcements. Review every amount for tabular alignment and every pending/confirmed distinction for understandable language. Apply the visual quality rubric and fix all scores below the acceptance floor.

Gate: visual score at least 34/40, no dimension below 3/5; no clipping at 200% text; primary actions reachable; no status communicated only by colour; no misleading demo capability claims. Store screenshots named by screen ID, locale and viewport.

## WP7 — Reproducible handoff

Run the complete acceptance suite. Build the APK and Flutter web release, record the core demonstration, and create a clean-reset presentation path. Produce IMPLEMENTATION_NOTES.md, TEST_RESULTS.md, CAPABILITY_MATRIX.md and RUNBOOK.md in the application docs directory. Package the requested outputs; do not include database secrets, signing secrets, access codes or real participant data.

Gate: another engineer can follow RUNBOOK.md, reset, authenticate, run the offline savings journey and reproduce the numeric checkpoints. Include evidence paths and actual command results. Explicitly mark tests not run.

## Optional WP8 — P2 integrations

Attempt only after P0/P1 gates pass and the appropriate credentials and test authorisation exist. Add a live speech draft and/or grounded help adapter behind feature flags. An official WhatsApp test integration needs a dedicated test setup and approved recipients. Review current official provider documentation and commercial conditions before committing to production behaviour. Keep the simulator available for a reliable recording.

Gate: tests in the content/integrations document pass, the capability matrix identifies provider/model/configuration, and each live feature has a graceful disabled/offline state. The core offline demo does not depend on provider availability.

## Required handoff contents

| Output | Required evidence |
| --- | --- |
| Source and setup | Locked dependencies, migrations, synthetic seed, Compose, env example and executable startup commands |
| Native app | Android APK, build type, Android version/device used, tested encrypted database configuration |
| Web portal | Release build, local serve instructions, browser/version used |
| Contract | OpenAPI schemas, operation/error types, fixture import documentation |
| Test report | Test IDs, pass/fail/not-run, commands, actual evidence files, known limitations |
| Visual evidence | Core Android English/Hindi and portal screenshots; score rubric and fixes |
| Demonstration | Short recording, reset script, presentation sequence and capability slide |
| Operations | Backup/reset distinction, migration instructions, local demo access setup, security mode flags |
| Ownership | Source/licence notices, proposed production dependencies, changes from this pack |

Estimate work only after WP0 establishes the environment and team capacity. Do not imply a complete production platform can be delivered by the proposal deadline. Preserve the bid submission deadline as an independent milestone.
