# PoP 2.0 — blue and white

Current specification: [BLUEPRINT_UI.md](docs/design/BLUEPRINT_UI.md). This revision follows explicit rejection of the earlier olive/lime palette and makes structural changes to both interfaces.

## Colour and type

White surfaces, pale cool-blue canvas (`#F5F7FC`), royal-blue actions (`#2456D6`), navy text (`#172B4D`) and muted slate (`#526582`). Peach is decorative only. Green, amber and red are reserved for labelled operational states. There are no olive/lime panels or ornamental rings.

Bundled Noto Sans / Noto Sans Devanagari 400/600, 17px mobile body and 14px portal body. Amounts use tabular figures. Preserve semantic text, native focus and text scaling. Avatar initials fit within their decorative circles at larger scales.

Canonical tokens: `packages/ui/assets/design_tokens.json`. Generated Dart: `scripts/generate-tokens.mjs`. Some existing internal names such as `forest` remain compatibility aliases for blue feature panels; they are not user-facing colour names.

## Layout

The programme portal has full-width top navigation. A prominent blue savings summary anchors the page beside three compact metrics. On wide screens, group records and actionable support sit alongside each other; activity follows. Narrow layouts stack these sections and preserve every principal/amount label.

The mobile home has a white meeting panel, blue action, compact savings/follow-up tiles and a group list. Its passbook puts identity on white and confirmed savings into a pale-blue inset, with pending amounts and outstanding principal clearly separate. Disclosure/status can scroll so they do not consume all space at 200% text. The bottom dock hides with the keyboard; financial confirmation remains protected.

## Components and motion

The shared surface/navigation primitives retain VengeanceUI-derived code and MIT attribution but now use simple borders, restrained shadows and flat focus states. Interaction transitions respect reduced motion. A static record-sheet illustration replaces the decorative rings on the welcome panel; it contains no implied business data.

## Verification and limits

Current evidence uses `blueprint` paths. Earlier `vengeance` images are the rejected direction, preserved for comparison. App widget previews render the real Flutter widgets with bundled fonts and synthetic fixtures; browser captures use the running API. These do not prove new physical-device, TalkBack or startup acceptance. Existing external requirements remain tracked in [GAP_CLOSURE.md](docs/GAP_CLOSURE.md).
