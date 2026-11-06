# UI finish review packet

## User brief and confirmed direction

The user requested a substantial improvement to both app and web, explicitly delegated the design choice, and required the RFP to guide UI requirements. This is an implementation task, not a mockup-only task. The original functional demo remains authoritative for workflow/data truth. Read PRODUCT.md and RFP_UI_REQUIREMENTS.md.

## Direction contract

A refined programme workspace / field record, grounded programme-report direction 7, seed 28d8fe24. Forest navigation and mobile task/passbook focus; warm daylight canvas; real bundled Noto Sans and Noto Sans Devanagari in regular/semibold; quiet sage, distinct amber pending state, flat surfaces and precise aligned records. Operating tasks and native affordances take priority. No invented branding, people, metrics, historical activity or provider capabilities.

Phone: make meeting entry obvious; distinguish confirmed savings, pending amounts and principal. Desktop: compare actual groups and find follow-up work in the first viewport. Tablet: labelled records replace dense tables. Financial actions retain protected review and a single commit.

## Quality bar

- Field users can identify the next action; large labelled primary controls, predictable navigation, minimal typing and presets remain intact.
- Financial values and pending/accepted/failure states are truthful, legible and distinct without relying only on colour.
- Web uses its space deliberately: stable navigation, connected summary band, aligned group/member data, compact relevant filters and clear follow-up actions.
- English and Hindi are complete in this demo. Fonts are bundled. Keyboard, large text, offline state and modal return remain usable.
- The full RFP's Odia, Ho, Santhali and voice/audio requirements remain explicit production gaps. Do not imply TUIF approval, live AI/WhatsApp or completed TalkBack speech testing.

## Implementation and references

Primary runtime code: packages/ui/lib/pop_ui.dart, src/components.dart, src/theme.dart, src/workspace.dart. Canonical active tokens: packages/ui/assets/design_tokens.json. Shared logic/API/native persistence are unchanged. Original spec assets are retained.

Selected design references: .impeccable/mocks/mobile-home.png, member-passbook.png, programme-overview.png and their JSON sidecars. They are composition references selected under delegated authority. Their fictional transaction dates/history, incorrect group principal split, invented support text/times/status and generated leaf marks are explicitly excluded; actual controller/API data wins. Native system bars, Material controls, semantic widgets and responsive text are required.

The first batched review tightened the phone home composition, replaced custom navigation with keyboard-capable Material buttons, separated heading/filter semantics, grouped support actions and added explicit Devanagari fallback for the language control. The detector was run once: docs/evidence/redesign-detector.json (no findings). Round 1 screenshots are retained in output/redesign-round1; final screenshots are in output/redesign.

## Verification boundaries

Eight widget tests include English/Hindi at 200%, keyboard/modal/repeated confirmation, conflict review, group drill-down and first-viewport pending money. Twenty-three PostgreSQL/API regressions passed. Root analysis was clean before the final small UI batch; rerun evidence accompanies the delivery. Native ordinary APK offline/save/restart/sync proof is separate from screenshots. Actual TalkBack speech and the full <=2s cached launch remain open acceptance items from the original implementation. Review the screenshots and actual sources; report material findings and a disposition without claiming those acceptance items passed.
