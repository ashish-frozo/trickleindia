# Remaining-gap work — 6 November 2026

This follow-up does not supersede the prior UI finish review or claim full RFP acceptance.

## Implemented

- Long mobile titles move into the scrollable content at narrow widths or large text sizes. This fixes the Hindi passbook abbreviation without shrinking text or consuming fixed keyboard space.
- Bundled English/Hindi help now has real device-generated reading controls with stop, matching-language selection, lifecycle/route/language cancellation and visible failure states. Android selects an installed voice whose `network_required` flag is false. Web uses browser speech; offline availability is not guaranteed. Only bundled instruction text reaches the voice engine. No microphone permission or financial text is used.
- Encrypted Drift/SQLite work runs in a background isolate. SQLCipher detection, keying, WAL and FULL durability are preserved. Native semantics are enabled by Android accessibility demand instead of being forced for every session; browser semantics remain enabled for keyboard access.
- Complete, source-version-checked translation worksheets and a review validator are provided for all three missing languages. Research selects Odia, Warang Citi (Ho), and Ol Chiki (Santhali) as candidate scripts; see `localization/DECISION.md`.
- `scripts/measure-android-startup.py` records repeatable activity-launch samples without mislabelling them as physical-device acceptance.

## Still blocked on external evidence or content

| Requirement | What is still required |
|---|---|
| Odia, Ho and Santhali UI/help | Fluent translation and terminology review of the 217-entry worksheets; script/font integration and participant task tests. No English fallback is advertised as translation. |
| Reviewed recorded prompts and voice-assisted navigation | Content-owner review, native-speaker recordings and navigation usability testing. Device-generated help is available but does not satisfy these broader requirements by itself. |
| Actual TalkBack acceptance | An Android device with TalkBack and suitable installed speech voices, plus listening/focus/form validation. AOSP emulator has no such service; no physical phone is connected. |
| Full cached launch ≤2 seconds | Controlled measurements on representative field hardware. Background database work improves UI responsiveness; it does not prove a startup threshold. |
| Participant/UAT and Hindi terminology acceptance | Programme/content-owner and representative-participant review. |
| Production AWS, live providers and official WhatsApp | Approved BRD, deployment/account access, provider credentials and operational setup. The demo remains local and the chat transport remains explicitly simulated. |

The Docker CLI exists but its daemon is unavailable. The existing native PostgreSQL startup path remains tested. No external provider message was sent, production resource deployed, or synthetic review sign-off manufactured.

## Verification

- Eleven Flutter UI/speech tests pass, including 200% Hindi financial review and repeat-confirm protection, missing/network-only voices, matching Hindi offline voice selection, and stop/completion cancellation.
- Native encrypted-database reopen and unkeyed-reader rejection pass with the background executor.
- UI and mobile static analysis report no issues; 197 English/Hindi keys and nine contrast pairs pass.
- The real Chrome desktop/tablet regression checks pass. A separate browser test exercises the missing-voice state explicitly and does not claim audible playback.
- APK and self-contained web release builds are recorded in `docs/evidence/gaps-*-build.txt`. The TTS dependency emits a future Kotlin-plugin compatibility warning with the pinned Flutter version; current builds succeed.
- No physical Android device is connected. The booted AOSP image reports no enabled accessibility service and has no TalkBack/TTS packages. Cold launch encountered an Android **System UI** ANR; closing that OS dialog restored the app. That cold sample is not a controlled cached-start benchmark.

Latest rebuilt-APK cached activity samples: **4,099 ms, 3,163 ms and 2,640 ms** (`evidence/gaps-startup.json`). All exceed the 2,000 ms target. These are software-emulator measurements; no performance pass is claimed. The app recovered its prior encrypted session and data after install/restart. Native help displayed a speech-settings error when playback was attempted without a TTS engine, leaving text available.

The native 200% Hindi capture shows the full passbook title in the content area. It also revealed a clipped redundant toolbar wordmark; the final code removes that wordmark whenever the full title is relocated. The saved `before-header-cleanup` capture predates this last small correction; final layout tests are rerun.
