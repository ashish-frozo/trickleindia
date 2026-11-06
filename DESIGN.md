---
name: "PoP 2.0"
description: "A refined programme workspace and field record"
colors:
  canvas: "#F5F7F2"
  surface: "#FFFFFF"
  primary: "#175C48"
  primaryTint: "#E8F0E7"
  text: "#18392F"
  muted: "#5A6D62"
  border: "#DCE5DC"
  success: "#24613C"
  warning: "#80500D"
  error: "#A12B32"
  accent: "#B47C25"
  onPrimary: "#FFFFFF"
  successTint: "#EDF6EE"
  warningTint: "#FFF2D9"
  errorTint: "#FCEEF0"
  forest: "#123F36"
  forestMuted: "#C1D5C9"
  outline: "#74877A"
  surfaceSoft: "#EFF3EC"
typography:
  display:
    fontFamily: "Noto Sans, Noto Sans Devanagari, sans-serif"
    fontSize: "36px"
    fontWeight: 600
    lineHeight: 1.15
    letterSpacing: "-1px"
  headline-large:
    fontFamily: "Noto Sans, Noto Sans Devanagari, sans-serif"
    fontSize: "32px"
    fontWeight: 600
    lineHeight: 1.2
    letterSpacing: "-0.7px"
  headline-medium:
    fontFamily: "Noto Sans, Noto Sans Devanagari, sans-serif"
    fontSize: "28px"
    fontWeight: 600
    lineHeight: 1.25
    letterSpacing: "-0.5px"
  headline-small:
    fontFamily: "Noto Sans, Noto Sans Devanagari, sans-serif"
    fontSize: "24px"
    fontWeight: 600
    lineHeight: 1.3
    letterSpacing: "-0.4px"
  title:
    fontFamily: "Noto Sans, Noto Sans Devanagari, sans-serif"
    fontSize: "22px"
    fontWeight: 600
    lineHeight: 1.3
    letterSpacing: "-0.3px"
  mobile-title:
    fontFamily: "Noto Sans, Noto Sans Devanagari, sans-serif"
    fontSize: "18px"
    fontWeight: 600
    lineHeight: 1.35
    letterSpacing: "0px"
  portal-title:
    fontFamily: "Noto Sans, Noto Sans Devanagari, sans-serif"
    fontSize: "16px"
    fontWeight: 600
    lineHeight: 1.35
    letterSpacing: "0px"
  body:
    fontFamily: "Noto Sans, Noto Sans Devanagari, sans-serif"
    fontSize: "17px"
    fontWeight: 400
    lineHeight: 1.45
    letterSpacing: "0px"
  portal-body:
    fontFamily: "Noto Sans, Noto Sans Devanagari, sans-serif"
    fontSize: "14px"
    fontWeight: 400
    lineHeight: 1.45
    letterSpacing: "0px"
  body-small:
    fontFamily: "Noto Sans, Noto Sans Devanagari, sans-serif"
    fontSize: "14px"
    fontWeight: 400
    lineHeight: 1.45
    letterSpacing: "0px"
  portal-body-small:
    fontFamily: "Noto Sans, Noto Sans Devanagari, sans-serif"
    fontSize: "12px"
    fontWeight: 400
    lineHeight: 1.45
    letterSpacing: "0px"
  label:
    fontFamily: "Noto Sans, Noto Sans Devanagari, sans-serif"
    fontSize: "17px"
    fontWeight: 600
    lineHeight: 1.3
    letterSpacing: "0px"
  portal-label:
    fontFamily: "Noto Sans, Noto Sans Devanagari, sans-serif"
    fontSize: "14px"
    fontWeight: 600
    lineHeight: 1.3
    letterSpacing: "0px"
  amount:
    fontFamily: "Noto Sans, Noto Sans Devanagari, sans-serif"
    fontSize: "32px"
    fontWeight: 600
    lineHeight: 1.2
    letterSpacing: "-0.6px"
rounded:
  status: "8px"
  chip: "10px"
  button: "12px"
  card: "16px"
  sheet: "24px"
spacing:
  unit: "4px"
  page: "20px"
  card: "20px"
  rowGap: "12px"
  sectionGap: "24px"
components:
  button-primary:
    backgroundColor: "{colors.primary}"
    textColor: "{colors.onPrimary}"
    typography: "{typography.label}"
    rounded: "{rounded.button}"
    padding: "14px 20px"
  button-outline:
    textColor: "{colors.primary}"
    rounded: "{rounded.button}"
    padding: "12px 16px"
  button-text:
    textColor: "{colors.primary}"
    rounded: "{rounded.button}"
    padding: "10px 12px"
  input:
    backgroundColor: "{colors.surface}"
    textColor: "{colors.text}"
    rounded: "{rounded.button}"
    padding: "16px"
  surface-card:
    backgroundColor: "{colors.surface}"
    rounded: "{rounded.card}"
    padding: "20px"
  status-pending:
    backgroundColor: "{colors.warningTint}"
    textColor: "{colors.warning}"
    rounded: "{rounded.status}"
    padding: "6px 10px"
  navigation-selected:
    backgroundColor: "{colors.primaryTint}"
    textColor: "{colors.primary}"
    rounded: "{rounded.button}"
  review:
    backgroundColor: "{colors.surface}"
    rounded: "{rounded.sheet}"
---

# Design System: PoP 2.0

## Overview

**Creative North Star: "The Programme Workspace and Field Record"**

The programme workspace and field record is calm, grounded and exact. Deep forest anchors navigation and important task or balance panels; a warm daylight canvas, white records and quiet sage keep the work legible. Amber identifies waiting money with words and icons.

The same visual language serves different densities: generous field controls on Android and compact aligned programme records on web. Bundled English and Devanagari lettering, initials and semantic Material controls carry the identity. The shipped system uses no production raster imagery, generated texture or decorative leaf mark.

**Key Characteristics:**

- Forest anchors and daylight records.
- Role-specific density with scalable bilingual typography.
- Confirmed money, pending money and principal remain distinct.
- Flat surfaces, precise alignment and labelled native controls.

This document records the finished build. Colour and spacing primitives come from `packages/ui/assets/design_tokens.json` and its generated Dart tokens; effective type, shape and component values come from `packages/ui/lib/src/theme.dart`, `components.dart` and `workspace.dart`. Flutter logical pixels are represented as px for portable tokens. Runtime theme values take precedence over the JSON file's advisory typography entries. Original supplied specification tokens remain preserved separately.

## Colors

Forest and sage establish the operational palette; amber and red communicate explicit state rather than decoration.

### Primary

- **Programme Green** (`primary`): filled actions, active labels, icons and input focus.
- **Deep Forest** (`forest`): programme navigation, meeting and confirmed-balance panels; white text carries the focal information.
- **Quiet Sage** (`primaryTint`): selected navigation, initials, disclosure and accepted-status grounds.

### Secondary

- **Decorative Ochre** (`accent`): restrained secondary accent; never the only text or control boundary.
- **Waiting Amber** (`warning`, `warningTint`): pending money and planned/unavailable-state badges, always with a label.
- **Correction Red** (`error`, `errorTint`): errors and recovery feedback.
- **Accepted Green** (`success`, `successTint`): available semantic success roles; ordinary accepted chips use Programme Green and Quiet Sage.

### Neutral

- **Daylight Canvas** (`canvas`), **White Record** (`surface`) and **Soft Sage Surface** (`surfaceSoft`) distinguish page, record and secondary regions.
- **Forest Ink** (`text`) and **Muted Field Ink** (`muted`) separate primary reading from metadata.
- **Pale Separator** (`border`) divides records; **Control Outline** (`outline`) supplies the stronger interactive boundary.
- **Forest Secondary Text** (`forestMuted`) supports inverse contexts; `onPrimary` supplies white action text.

**The Separate Money Rule.** Show confirmed savings, pending amounts and principal as separately labelled values; pending never silently joins the confirmed balance.

## Typography

**Display and Body Font:** bundled Noto Sans for English and Noto Sans Devanagari for Hindi. Both have actual regular (400) and semibold (600) font files. Hindi changes the primary family, with the other bundled family available as fallback. There is no download-dependent font startup.

The upright sans hierarchy gives names, actions and money clear authority. Runtime theme display/headline roles step down through 36, 32, 28 and 24; 22 is the shared section-title role. Mobile body and major action labels are larger than portal equivalents. Body-large has a roomier 1.5 line-height; the regular body role uses the frontmatter value. Portal small metadata uses the smaller dedicated role. Avoid treating every available theme role as a demand for another heading.

Financial amounts use semibold tabular figures. MoneyAmount scales down within constrained width, exposes a semantic value and uses right alignment in records. The amount token is its default; contexts choose smaller sizes when needed. English/Hindi labels and ordinary paragraphs remain scalable and wrap.

**The Script Continuity Rule.** Use the bundled Noto families for English and Hindi, including language controls; allow labels and rows to grow with text scale.

## Layout

The rhythm uses the frontmatter spacing scale, with 20px page/card padding, 12px row gaps and 24px section gaps. Ordinary cards also leave 16px below them. The main content is bounded to 1280px. Android respects safe areas and native system bars; mobile bottom navigation and the passbook record action remain distinct from the scrolling content.

Authenticated programme managers enter the web workspace from 720px viewport width. Its forest rail is 88px below 1100px and a labelled 232px sidebar at or above 1100px. Login adds its separate welcome panel from 900px. These are distinct composition thresholds, not universal device classes.

The programme summary is a connected band, with four columns from 900px available content width, two from 480px, and one below. Group comparison becomes a table only from 850px available width and at text scale no greater than 1.35; narrower or enlarged layouts use labelled records including savings, principal and accepted date. Other sections choose their own available-width thresholds. At enlarged text, review labels stack above values rather than squeezing a two-column row. Scrolling is a valid response to large text; essential financial labels must survive it.

## Elevation & Depth

The everyday surface model is flat: SurfaceCard and app bars use zero elevation, disabled surface tint, fine pale separators and white/sage/forest tonal planes. Native Material dialogs and floating snackbars retain their framework interruption behavior. The build defines no custom shadow vocabulary or custom animation grammar; do not promote the token JSON's unused duration suggestions into a runtime motion contract.

**The Flat Record Rule.** Routine records use tonal surfaces and fine separators at zero elevation. Reserve modal depth for actual interruption and review.

## Shapes

Soft rectangular controls, broader record corners and generous modal corners form a consistent family. Use the frontmatter radius roles: status badges are tighter than buttons, cards are softer, and review dialogs are softest. Initial avatars are circles. One-pixel pale borders separate records; focused inputs use a two-pixel Programme Green stroke. The pale border is decorative; interactive fields use Control Outline.

## Components

### Buttons

Broad, labelled and predictable. Filled buttons use Programme Green with white text and a 56px mobile or 48px portal minimum height. Outlined and text variants keep 48px minimum targets. The meeting panel uses a broad white action against forest. Material supplies hover, pressed, focus and disabled behavior; retain its state affordances and keyboard activation. Heights are minima, not clipping boxes.

### Chips

StatusChip combines text with a check/clock icon and a compact sage or amber background. Its icon is 17px and its label uses the platform label-medium role at regular weight. Themed choice chips are a separate selectable control with the chip radius; status badges are not simulated interactive chips.

### Cards / Containers

SurfaceCard is white, bordered, clipped and flat, with the canonical padding and card radius. Forest task/balance panels omit the pale border. Connected metrics share one enclosing surface and internal dividers rather than becoming a grid of unrelated floating cards.

### Inputs / Fields

White filled outlined fields use comfortable 16px padding, a strong neutral outline and a two-pixel green focus border. Errors use Correction Red. Presets, selections and dropdowns precede typing where the working flow supports them. Preserve entered values during validation and language changes.

### Navigation

Phone NavigationBar uses a white surface, sage selected indicator and icons paired with labels. The portal uses real Material TextButtons in a forest sidebar/rail; selected state is sage with dark text and semantic selection. Compact rail labels remain present. Language switching is a labelled text-and-icon control with explicit Devanagari family coverage.

### Money, sync and protected review

Passbook identity and confirmed balance share a forest panel; pending money has a separate amber strip, and principal is independently labelled. TransactionRow aligns tabular money right, with date, subject and textual status beside an icon. SyncStatusBar is a semantic live region with a labelled refresh affordance. ReviewSheet presents the member, entry type, amount and date before commit; it is scrollable and guards repeated confirmation. Keep cancellation and modal return predictable.

## Do's and Don'ts

### Do:

- **Do** preserve the real API/controller records and the visible proposal-demo disclosure.
- **Do** pair status colour with an icon and explicit text.
- **Do** keep touch controls at least 48px and mobile primary buttons at least 56px, growing for text.
- **Do** retain all financial labels when tables become stacked records.
- **Do** use initials and semantic Material icons with readable labels.

### Don't:

- **Don't** fabricate programme metrics, historical activity, session identity or financial totals.
- **Don't** use pale decorative borders as the sole interactive boundary.
- **Don't** replace semantic text or controls with image typography, generated textures or leaf marks.
- **Don't** imply that planned languages, audio, live AI or external WhatsApp are available.
- **Don't** describe this proposal as TUIF approval or completed production accessibility acceptance.

The full RFP additionally requires Odia, Ho, Santhali and voice/audio support. These remain explicit gaps. Actual TalkBack speech and the full cached-start target also remain open acceptance items. The sidecar's HTML/CSS examples are portable visual translations of Flutter components, not replacements for their runtime semantics or accessibility validation.


## Remaining-gap follow-up (6 November 2026)

See [GAP_CLOSURE.md](docs/GAP_CLOSURE.md) for current status. English/Hindi draft help now supports device-generated speech, with installed offline voices required on Android and explicit missing-voice errors. Reviewed audio recordings and five-language acceptance remain outstanding. Narrow/large-text page titles now wrap in scrollable content. Prior screenshot and finish-review evidence describes the earlier build.
