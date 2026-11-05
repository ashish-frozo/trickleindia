# Visual and accessibility review

Internal review, 5 November 2026. This is an engineering/design review, not participant usability or language approval.

| Dimension | Score / 5 | Evidence |
|---|---:|---|
| Hierarchy | 5 | Single primary meeting action; prominent confirmed amounts; separate pending state |
| Spacing | 4 | Consistent cards, 20px page gutters, scrollable small/large-text layouts |
| Typography | 5 | Bundled Noto Latin/Devanagari; no missing glyphs in inspected screens |
| Contrast | 5 | Nine checked text/background pairs, minimum 5.89:1; grayscale portal remains understandable |
| Bilingual layout | 4 | Native English/Hindi core and Hindi keyboard/review; 170 matching keys; terminology remains draft |
| State clarity | 5 | Fictional-data banner, pending vs confirmed amounts, outage reason, simulation and audio states |
| Responsive behaviour | 4 | Android logical360×800/390×844, portal768×1024/1440×1000, 200% widget/native checks |
| Consistency | 4 | Shared tokens/components; status words/icons agree across app, portal and queue |
| Total | 36 / 40 | Meets internal34/40 floor; no dimension below3 |

Screenshots are in `output/android` and `output/playwright`, named with screen, locale and logical viewport. Native PNGs are captured at device-pixel resolution (3x logical size). Screenshots are actual rendered app/browser captures; no missing UI was fabricated. The main Android recording joins actual capture segments for pacing; `docs/evidence/android/recording-edits.json` identifies cuts. It shows a real disconnected API, durable save, force-stop, retained operation and once-only acceptance. The server independently verifies the same operation and balances in `main-server-proof.json`.

Fixed during review: amount/review controller lifetime, repeated confirmation, narrow sync-bar/dropdown sizing, routed language-switch updates, Android login safe area, expired-session cache lock/reset recovery, and explicit current/proposed profile-conflict comparisons. The final independent code review's one important finding was corrected and covered by a red/green widget regression. No remaining critical financial finding was reported.

Actual browser keyboard verification tabs through language, refresh, sign out, sync and navigation, then activates Support using Enter. Chrome reduced-motion mode and achromatopsia emulation were used; no page errors were reported. Native Android animations were disabled; Hindi at200% and offline expanded help were captured. Large-text views intentionally scroll so actions/content remain reachable.

Actual TalkBack speech/focus/modal return still needs a phone or Android image with TalkBack/TTS; native semantics inspection does not establish spoken correctness. Full cached activity start exceeded the2s target on this software-rendered emulator, despite encrypted-cache initialization staying under2s in eight observations. Both limits remain explicit in `TEST_RESULTS.md` and the delivery README.
