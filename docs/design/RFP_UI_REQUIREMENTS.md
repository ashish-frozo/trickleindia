# RFP-to-interface design requirements

Source: [TUIF PoP2.0 RFP](../../RfpDocuments_6a117cf26110482d92618ed039e0786d.pdf), all 10 pages reviewed on 6 November 2026. The proposal-demo scope remains explicit; this document separates full RFP expectations from features actually available in the local demo.

| RFP reference | Requirement | Redesign decision | Current capability boundary |
|---|---|---|---|
| §2, page 1 | Simple day-to-day mobile operations; separate advanced programme portal | Phone home leads with the meeting and one next action. Portal uses a desktop navigation shell, aligned metrics, group table and follow-up feed. | Existing working workflows remain connected to the API. |
| §2,2.2, pages 1–2 | Women with limited digital literacy; limited reading/writing ability | Large labelled controls, readable typography, initials instead of fake photos, predictable navigation, concise task wording and clear confirmations. | Usability and terminology still require participant/UAT review. |
| §2.1, pages 1–2 | Enter/save/access offline; automatic sync; pending/success/failure visibility | Persistent compact sync status. Distinct pending strip beside confirmed financial values. Entry feedback and a clear recovery path. | Preserve encrypted native persistence, stable IDs and real server reconciliation. |
| §2.1, page 2 | Deduplication, consistency and conflict resolution | Keep repeated-submit guard and explicit current/proposed conflict comparisons; redesign presentation without changing mutation semantics. | Existing automated transaction/concurrency tests remain applicable. |
| §2.2, page 2 | English, Hindi, Odia, Ho and Santhali | Keep language selection obvious, keep English/Hindi complete and layouts flexible for Devanagari; show other languages as planned rather than working choices. | This demo implements two languages. Full five-language implementation remains a production scope gap. |
| §2.2, page 2 | Voice-assisted navigation and audio instructions | Contextual help remains findable and audio availability remains truthful. Do not put a decorative microphone in a primary action. | No reviewed audio/TTS/voice provider supplied; unavailable/planned is explicit. |
| §2.2, page 2 | Minimal manual entry, dropdowns and predefined choices | Prominent amount presets, relevant dropdowns, focused review sheets and preserved input during validation/language changes. | Preserve current entry and review behavior. |
| §3–5, pages 2–3 | Governance, enterprise and monitoring; roles/modules1–5 | Separate member, Sakhi and programme-team information density; registration, SHG, finance, enterprise and support stay reachable. | Do not invent cluster/market/AI analytics or historical trends. |
| §6.1, page 3 | Flutter mobile and web; Node.js; AWS; auth decision by TUIF | Redesign existing Flutter packages and shared components. | Local demo authentication/hosting remain distinct from the future production Cognito/Firebase/AWS decisions. |
| §6.3, pages 5–6 | Workflows, wireframes, offline/multilingual/accessibility; approved BRD alignment | Record screen compositions, responsive variants and design decisions; retain existing operational paths. | No approved final BRD/wireframes supplied; these are proposal-review designs, not TUIF approval. |
| §6.4,6.7, pages 6–7 | Module demonstrations, functional/regression checks and UAT | Re-run relevant widget/browser/Android checks and capture both platforms together; preserve functional evidence. | Actual TalkBack speech and field-device startup performance remain open acceptance checks. |

## Design success criteria

- A field user can identify the next meeting action without scanning a dashboard.
- A member can distinguish confirmed money, pending money and principal at a glance.
- A programme manager can compare actual groups and locate follow-up work in the first desktop viewport.
- Text/icon/status meaning remains clear without colour, with Hindi, large text, keyboard input and poor connectivity.
- No attractive control implies unavailable speech, a real WhatsApp connection, approved language content or fabricated reporting history.
