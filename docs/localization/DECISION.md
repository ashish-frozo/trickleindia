# Language and speech implementation decision — 6 November 2026

Use Odia script for Odia (`or-Orya-IN`), Warang Citi for Ho (`hoc-Wara-IN`) and Ol Chiki for Santhali (`sat-Olck-IN`) as the first candidate scripts. Preserve script-specific locale identifiers so a regional alternative can be added after field review. These are researched defaults, not claims that every participant reads these scripts.

Evidence:
- CIIL/NCERT's [Santali–Odia primer](https://www.ciil.org/primers/Santali-Odia_Primer.pdf) explicitly teaches Ol Chiki, including adult literacy.
- The O Foundation's [Ho resources](https://theofdn.org/oer/ho/) describe Warang Citi and acknowledge Devanagari, Odia, Bengali and Latin usage.
- [Unicode 17](https://www.unicode.org/versions/Unicode17.0.0/UnicodeStandard-17.0.pdf) documents the distinct scripts. Script support is not translation support.
- [Bhashini's model catalogue](https://dibd-bhashini.gitbook.io/bhashini-apis/available-models-for-usage) lists IIIT Hyderabad translation for Ho and Santali. Its IIT Madras Santali speech entry specifies Devanagari, while no Ho TTS entry is listed. Do not pass Ol Chiki to a Devanagari-only speech model, assume generic Hindi speech works for Ho, or equate a model listing with tested quality.

The best rollout is bundled, reviewed UI/help translations and recorded prompts, fully available offline. Machine translation can supply review drafts; it must not run at financial entry time or silently substitute another language. No Bhashini credentials, fluent reviewer or field review evidence is supplied in this workspace. Do not manufacture Ho/Santhali strings or mark English fallback as support.

The adjacent CSV worksheets contain every current UI message plus every help title, step and audio script. `scripts/localization-review.py export` regenerates them. `validate` rejects missing/duplicate keys, stale English sources, empty translations and missing reviewer/status. A language specialist should review money, principal, pending/confirmed, reversal, conflict and consent wording in context. After that, bundle script fonts, integrate full Material localizations, check glyph coverage and layout at 200%, record prompts with permission, and conduct participant task tests. This is outstanding work, not an accepted language release.

Current implementation provides device-generated reading of bundled English/Hindi help with stop, lifecycle cancellation, error recovery and installed offline Android voice selection. Browser speech uses the browser/device voice service and is not promised offline. No microphone or financial data is sent by this feature. This is distinct from reviewed recordings, voice-command navigation and TalkBack spoken acceptance.
