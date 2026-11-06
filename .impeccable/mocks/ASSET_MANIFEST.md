# Operating-screen asset manifest

Reviewed PRODUCT.md, docs/design/RFP_UI_REQUIREMENTS.md, IMPLEMENTATION_INVENTORY.md and all three selected PNG references: mobile-home.png, member-passbook.png and programme-overview.png.

## Medium decision

No production raster imagery is required. These are operational, data-driven screens. Build the forest panels, warm canvas, separators, buttons, status strips, initials, tables and text as semantic Flutter widgets. Use bundled Material icons with visible text labels. This preserves translation, text scaling, focus, screen-reader semantics and live financial values. No decorative imagery needs production or generation.

| Reference ingredient | Production medium |
|---|---|
| PoP2.0 name | Text; no invented brand mark |
| Person identity | Actual display name and text initials |
| Navigation, meeting, finance, support and sync symbols | Material icons plus labels |
| Backgrounds, surfaces and status treatments | Flat Flutter theme colours, borders and layout |
| Programme comparison and financial summaries | Semantic text, rows and tables populated by real controller/API values |
| Activity/history or any future chart | Actual records and accessible Flutter presentation; no reference-image content |

## Required bundled fonts

All four font files already exist in packages/ui/assets/fonts and are recognized as TrueType files. Keep the bundled OFL.txt licence.

| Family | Weight | File | Current declaration |
|---|---|---|---|
| NotoSans | 400 | NotoSans-Regular.ttf | Present |
| NotoSans | 600 | NotoSans-SemiBold.ttf | Missing from packages/ui/pubspec.yaml |
| NotoSansDevanagari | 400 | NotoSansDevanagari-Regular.ttf | Present |
| NotoSansDevanagari | 600 | NotoSansDevanagari-SemiBold.ttf | Missing from packages/ui/pubspec.yaml |

Declare the semibold files at weight 600 in their respective existing families; explicitly declare regular at 400 for clarity. Verify both scripts offline on mobile and web after wiring. The missing item is font registration, not a missing binary. Material icons are already enabled by uses-material-design.

## Integrity and missing inputs

- The reference PNGs are design evidence only. Never ship them as screen backgrounds, extract their icons, or copy their textured/shadowed lettering into production.
- The generated leaf marks are not approved TUIF or PoP2.0 assets. Omit them; use the semantic product name until approved branding is supplied.
- Generated names, greeting/session identity, dates, timestamps, sample transaction history, totals, principal allocations, support descriptions and any chart values are not authoritative. Use existing records, fixture-backed state and honest empty states. In particular, exclude the passbook's invented January transaction and the portal's invented update times, support text and principal split.
- No participant photography, approved logo or reviewed speech recordings were supplied. None blocks these three screen compositions. Audio must retain its actual unavailable/planned state. Additional language/script font coverage and reviewed content remain future scope; these four fonts do not establish five-language support.
- No missing production image asset was identified. Font binaries are present; provenance beyond the bundled font files and licence was not independently audited in this pass.

This producer pass changes this manifest only; application source and font declarations are left to implementation.

## Implementation closure — 6 November 2026

Both regular (400) and semibold (600) files are now registered in packages/ui/pubspec.yaml for NotoSans and NotoSansDevanagari. The table above records the initial asset-review state. The built English/Hindi screens use the bundled fonts; the language control explicitly requests Devanagari when offering Hindi, including on the initial English web screen. No production raster imagery or generated mark was added.
