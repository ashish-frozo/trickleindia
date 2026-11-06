# PoP 2.0 design system

Current direction: VengeanceUI adapted to Flutter, 6 November 2026. Requested by the user after reviewing the previous forest interface. Implementation and upstream provenance: [VENGEANCE_UI.md](docs/design/VENGEANCE_UI.md).

## Visual character

Ink and ivory with restrained lime highlights. Floating navigation, layered card surfaces, a contrasting savings tile and generous numerical hierarchy make the programme workspace distinct from the mobile task flow. Concentric lines and linked rings are decorative community motifs, never charts or implied programme facts.

## Tokens

The canonical values are in `packages/ui/assets/design_tokens.json`; run `node scripts/generate-tokens.mjs` after changes. Core colours: ivory canvas `#F4F4EF`, ink text `#20241D`, dark feature panels `#20251D`, primary `#343F28`, muted text `#60665A`, lime accent `#D7F56B`, pale borders `#DDE0D5`. Lime is an accent on dark surfaces, not body text on white. Pending, accepted and error retain their labelled amber, green and red states.

Bundled Noto Sans and Noto Sans Devanagari, regular and semibold, remain semantic, selectable/rendered text. Mobile body 17px, portal body 14px; display typography grows from 28–42px by context. Labels wrap at increased text scales. Never encode content in screenshots or rely on remote fonts.

## Components

`VengeanceSurface`: clipped Material panel, conic edge, radial dark-panel illumination, concentric line detail and subtle depth. Hover changes stop when interaction ends. `SurfaceCard` wraps this shared primitive.

`VengeanceNavigation`: SpotlightNavbar adaptation using accessible native TextButtons. Programme navigation occupies a floating light rail; mobile destinations form a rounded dock. Active destinations have ink fill and lime icons. All destinations have visible labels, selected semantics and keyboard activation. The mobile dock hides while the keyboard is open.

Programme metrics use four independently framed tiles; confirmed savings gets the dark emphasis. All amounts/counts come from the actual scoped API data. Group tables, tablet principal values and support actions are preserved. Mobile home foregrounds the meeting, passbooks distinguish confirmed and pending money, and the fixed financial action still opens a protected review.

The welcome panel includes linked rings, large typography and three capability rows. There are no invented testimonials, participant portraits or fictional trend charts.

## Interaction and accessibility

Hover/focus transitions last 220ms and become zero-duration when reduced motion is requested. No continuous shader loop, autoplay carousel, backdrop blur or 3D dependency. Native financial forms, offline save, conflict resolution, once-only confirmation and role restrictions remain unchanged. Controls have at least 48px targets; Hindi/English and 200% scaling are checked.

## Provenance and acceptance

VengeanceUI MIT notice is bundled and exposed through open-source notices. This is a Flutter adaptation of selected component implementations, not an installed React dependency. The earlier independent forest-design finish review and generated comps remain historical artifacts, not approval of this new direction. Current verification/screenshots use the `vengeance-` prefix. External language, speech, participant acceptance and performance gaps remain as described in [GAP_CLOSURE.md](docs/GAP_CLOSURE.md).
