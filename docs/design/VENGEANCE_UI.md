# VengeanceUI integration

Requested by the user on 6 November 2026. Upstream: https://github.com/Ashutoshx7/VengeanceUI at commit `298075bd1b883fbcc7b25d8c9894b76a8d683161`.

This is a **Flutter adaptation**, not a React/npm dependency. Both delivered clients remain Flutter as specified in the RFP. The upstream implementation was read before adapting these components:

- `src/components/ui/spotlight-navbar.tsx`: active ambience, rounded navigation, hover and focus illumination. `VengeanceNavigation` uses native TextButtons, labelled destinations and keyboard activation. Its illumination follows the hovered/focused destination, not a continuously tracked mouse coordinate; vertical navigation serves the portal and a horizontal dock serves mobile.
- `src/components/ui/glow-border-card.tsx`: conic colour edge and inset layered surface. `VengeanceSurface` translates these into a Flutter SweepGradient, clipped Material surface and interaction-driven depth. Constant spinning and expensive backdrop blur are omitted for field-device performance.
- `src/components/ui/research-bento-grid.tsx`, `Panel`: framed pale panels, radial illumination, generous numerical hierarchy and contrasting dark feature cells. Programme metrics use actual API values, never the original component's fictional prices or promotional content.

Licence: upstream MIT copyright and permission notice are included in `packages/ui/assets/licenses/VengeanceUI-MIT.txt` and registered in both clients' open-source notices.

The visual direction is ink, ivory and restrained lime: a floating white programme rail, illuminated active selection, independent metric tiles with a dark savings focal card, layered passbooks, tactile cards, a compact mobile dock and a community-ring motif on the welcome panel. The rings are decorative and excluded from accessibility semantics. Existing bundled English/Hindi text/fonts, offline functionality, native encryption, financial guards, sync status and permissions remain unchanged.

Animations run only on interaction and honour Flutter's reduced-motion setting. No perpetual animation, 3D dependency, remote font or rasterized UI text is introduced. The library's original marketing copy, third-party logos and example business metrics are not used.

This direction replaces the previous forest programme-report visual finish. The earlier independent finish review is historical and does not certify this adaptation. Functional verification and screenshots for this version use the `vengeance-` evidence prefix. External acceptance gaps remain in `docs/GAP_CLOSURE.md`.

## Verification

Eleven UI/speech tests pass, including English/Hindi large text, financial confirmation, offline pending visibility, group scope and keyboard navigation. Static analysis reports no issues. All 197 bilingual UI keys resolve and tested text/background contrast pairs exceed 4.5:1. Real Chrome checks cover desktop/tablet English/Hindi, per-group principal values and Tab/Enter navigation.

The first keyboard test exposed a fixed mobile status/header area overflowing when the enlarged dock reduced available height. The fix moves mobile disclosure/status into the scrollable page and hides the dock when the keyboard is open. The original failing test is retained as `vengeance-keyboard-before-fix.txt`; the assertion was not weakened.

The final web build and signed ARM64 profile APK both succeeded. A first Android build ran out of local disk space; only task-generated build intermediates were cleared, then the build was repeated with a 1.5GB Gradle heap and two workers. Application behaviour is unchanged by that build-memory setting.

Mobile images named `*-widget-preview.png` are rendered from the actual Flutter widgets with bundled Noto/Material fonts and the original synthetic fixture, using `visual_preview_test.dart`. They are not Android-device screenshots or evidence of native TalkBack/performance acceptance. The fixture shows Rani ₹1,200; the running portal includes the earlier accepted ₹200 contribution and therefore shows aggregate savings ₹5,000. The preview run passes in English, Hindi and 200% text. Native visual capture was not repeated for this adaptation because of local disk constraints.
