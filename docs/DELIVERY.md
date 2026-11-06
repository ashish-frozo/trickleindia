# PoP 2.0 local review package

Current UI: blue/white structural redesign. See [BLUEPRINT_UI.md](design/BLUEPRINT_UI.md). `output/blueprint` contains the latest previews; the earlier olive/lime `vengeance` direction was rejected.

The package contains the implemented Flutter Android app and web portal, Node/TypeScript API, PostgreSQL migrations, pinned source/dependencies, test evidence, screenshots and recordings. All records are fictional.

Files in `delivery/`:

- `pop-2-demo-arm64.apk`: ordinary AOT profile APK, Android API26+, ARM64, development signing, no embedded access code. API configured to `http://127.0.0.1:3000`; use `adb reverse tcp:3000 tcp:3000` with the local service. Local HTTP is restricted to loopback/emulator host names in this profile build. Production release requires HTTPS/signing.
- `pop-2-web.zip`: release Flutter web build including renderer, fonts and notices; serve on `http://localhost:8080` with the API running.
- `pop-2-source.zip`: application/source, original specification pack, migrations, dependency locks, scripts and documentation. Local secrets, SDKs, dependencies, caches and test APKs are excluded.
- `pop-2-evidence.zip`: Android/web screenshots, main offline journey recording, portal support recording and verification logs.
- `SHA256SUMS`: artifact integrity checks.

Unpack source, install the tested toolchain and follow `docs/RUNBOOK.md`. `scripts/dev-local.sh` prepares the isolated local database and access configuration. Never publish `.local/demo-access-code` or `.env`. The binary and web build contain no service credentials; each user must log in with the separately generated local code.

Historical forest-design screenshots and native reconciliation proof are in `output/redesign` and `docs/evidence/redesign-*`. The preserved recordings show the earlier interface and remain functional evidence, rather than previews of the redesigned appearance. The core recording is edited across actual capture segments for pacing and demonstrates the real server-backed ₹200 offline savings flow, force-stop/reopen and once-only synchronization. The portal recording demonstrates simulation creating a real support request, replay and resolution. Audio is unavailable; the pack explicitly permits that exception. Live AI, speech and official WhatsApp transport are optional P2 and disabled; the chat is visibly a simulation and sends no messages.

Acceptance is not fully signed off. The AOSP emulator has no TalkBack/TTS service, so actual English/Hindi spoken-output verification remains A20's blocker. The software-rendered emulator also exceeds the two-second full cached-start target; cache initialization and durable save are within their measured targets. Retain those limits in customer review and rerun speech/startup checks on a representative physical Android phone. See `docs/TEST_RESULTS.md` for exact coverage, timings and exceptions. Container execution was unavailable, while native PostgreSQL startup was reproduced in a clean source tree.

No public deployment or production integration was performed. This package is for local proposal review.

## Remaining-gap follow-up (6 November 2026)

See [GAP_CLOSURE.md](GAP_CLOSURE.md) for current status. English/Hindi draft help now supports device-generated speech, with installed offline voices required on Android and explicit missing-voice errors. Reviewed audio recordings and five-language acceptance remain outstanding. Narrow/large-text page titles now wrap in scrollable content. Prior screenshot and finish-review evidence describes the earlier build.

## Historical VengeanceUI adaptation — 6 November 2026

The preceding UI revision used Flutter adaptations of VengeanceUI SpotlightNavbar, GlowBorderCard and ResearchBentoGrid.Panel, with MIT attribution. It replaces the prior forest visual direction while retaining the existing Flutter apps, data and workflows. See [design/VENGEANCE_UI.md](design/VENGEANCE_UI.md). That revision’s screenshots and verification use the `vengeance` prefix; current evidence uses `blueprint`. Earlier finish reviews and screenshots are historical. External acceptance gaps are unchanged.
