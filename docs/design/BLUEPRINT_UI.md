# Blue/white structural redesign

The user rejected the lime/olive palette and found the preceding changes insufficient. This revision changes both composition and colour; it does not claim that a component library alone solves design quality.

- Palette: white, cool pale blue canvas, royal blue actions, navy text. Peach is a small decorative accent. Lime, olive, conic borders and decorative rings are removed.
- Programme portal: full-width top navigation replaces the floating side rail. A dominant blue savings summary sits alongside three compact programme metrics. Group records and follow-up share the main workspace; recent financial activity follows. Counts and money remain real scoped API values.
- Mobile: a white meeting panel with a calendar icon, member/location line and blue action; two-column savings/follow-up tiles; a compact group list. The passbook separates member identity from a pale blue confirmed-balance inset. Pending funds and principal remain distinct. Decorative avatar initials fit at large text sizes.
- Mobile disclosure/status remain scrollable; the navigation dock hides with the keyboard. VengeanceUI-derived interaction primitives and MIT attribution remain, but their previous colours, edges and ring treatment are replaced.

Both clients retain the working Flutter/domain/storage/API architecture, English/Hindi, speech controls and financial confirmation guards. No illustrative financial charts or invented programme activity are introduced.

New evidence and previews use `blueprint` paths. The rejected `vengeance` screenshots remain available for a side-by-side comparison. Widget previews are renders of actual Flutter UI with bundled fonts and the original synthetic fixture; portal screenshots use the running API, which includes the previously accepted contribution. Neither establishes new native TalkBack or startup acceptance.

## Research rationale (6 November 2026)

The palette is a design hypothesis, not an empirically proven preference of this programme's participants. The sources below support legibility and interaction decisions; none establishes blue as the best colour for tribal women or SHG participants.

- [Microsoft Research, Designing Mobile Interfaces for Novice and Low-Literacy Users (2011)](https://www.microsoft.com/en-us/research/publication/designing-mobile-interfaces-for-novice-and-low-literacy-users/) reports substantial barriers with text interfaces and, in its mobile-banking study, highest task completion with a graphical interface. This supports keeping labelled icons, visible primary actions and speech assistance. Existing speech help is not a complete voice-guided workflow; reviewed local-language audio remains a delivery gap.
- [W3C minimum contrast](https://www.w3.org/WAI/WCAG21/Understanding/contrast-minimum) specifies 4.5:1 for normal text and 3:1 for large text. The current token checker passes all 12 checked pairs at 4.5:1 or greater. This checks those combinations, not every rendered screen or full WCAG conformance.
- [W3C use of colour](https://www.w3.org/WAI/WCAG22/Understanding/use-of-color.html) requires another means of conveying meaning. Confirmed, pending and error states retain words and icons; blue is an action/selection accent, not a financial status.
- [W3C enhanced target size](https://www.w3.org/WAI/WCAG22/Understanding/target-size-enhanced.html) recommends 44 by 44 CSS pixels, with stated exceptions, to improve operability. The design retains large mobile actions and native keyboard focus; larger targets and reflow matter more than decorative effects.

Practical choice: white reading surfaces, dark navy text, one saturated blue action colour and restrained status colours. Mobile prioritises a meeting and the participant's records; the portal supports denser staff review. Validate with actual participants using find-a-meeting, read-confirmed-versus-pending-savings and recover-from-offline tasks, in their preferred language and on field devices. Do not infer success from aesthetic preference, screenshots or automated tests alone.

## Local verification

UI/speech tests: 11 passed, one opt-in preview test skipped in the normal run. The opt-in preview run passed separately. Static analysis passed. Browser checks passed on desktop/tablet in English/Hindi, including group-scoped principal and keyboard navigation to Support, with no captured browser errors. Web release compiled. See `docs/evidence/blueprint-*` and `output/blueprint`. App images are Flutter widget renders, not new physical-device evidence. `output/review.html` compares the rejected and current layouts.

ARM64 Android profile build completed (33.6 MB); APK signature verification passed. No new emulator or physical-device run was performed for this revision. All six comparison images load and its three view selectors work.
