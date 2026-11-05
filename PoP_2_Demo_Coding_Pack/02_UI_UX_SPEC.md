# PoP 2.0 interface and interaction specification

## Visual direction

Create a calm, contemporary tool that feels trustworthy in a village meeting and precise in a programme office. Use warm off-white surfaces, deep teal actions, generous whitespace, clear Devanagari typography, and restrained illustration. The participant experience should feel welcoming. Staff views should make follow-up work and record status easy to scan.

This is a proposed visual identity. Use PoP 2.0 as a text wordmark, accompanied by Proposal demo. Brand assets supplied later can replace the wordmark through a single theme configuration.

## Design tokens

The machine-readable source is [assets/design_tokens.json](assets/design_tokens.json). Use one shared Flutter theme package for mobile and web.

| Token | Value | Intended use |
| --- | --- | --- |
| Canvas | #F7F8F4 | Main background |
| Surface | #FFFFFF | Cards, sheets, dialogs |
| Primary | #175C53 | Main actions and selected navigation |
| Primary tint | #E8F3EF | Selected rows and soft emphasis |
| Text | #18332F | Headings, figures, main copy |
| Muted text | #52645E | Supporting copy |
| Border | #D9E3DD | Card edges and separators |
| Success | #24613C | Confirmed state text and icon |
| Warning | #83510A | Pending state text and icon |
| Error | #A12B32 | Failed state text and icon |
| Accent | #C58B39 | Small decorative highlights |

Set buttons to white text on Primary. Use Accent for small decorative marks. Status components use a coloured icon, a text label, and a pale background so meaning is available without colour perception. Verify rendered contrast, including disabled and selected controls.

Typography uses bundled Noto Sans for English and Noto Sans Devanagari for Hindi, with their licence notices retained. If these cannot be bundled during a build, record the fallback and check every screenshot for glyph coverage. App-start font downloads introduce an avoidable connectivity dependency.

| Style | Mobile size / line height | Weight |
| --- | --- | --- |
| Screen title | 26 / 34 logical pixels | 600 |
| Section title | 20 / 28 | 600 |
| Body | 17 / 26 | 400 |
| Button | 17 / 24 | 600 |
| Supporting label | 14 / 21 | 500 |
| Amount | 32 / 40 | 600, tabular numerals when available |

Use a 4-point spacing scale. Default page padding is 20, card padding 20, row gap 12, and section gap 24. Cards use 16-pixel radii, buttons 14, and sheets 24. Primary buttons are at least 56 high. Icon controls and other touch targets are at least 48 by 48. Hindi copy may wrap and grow vertically.

## Composition rules

- Show one prominent next action per task screen.
- Keep money values and the selected member visible together during entry and confirmation.
- Pair icons with text. Use consistent rounded line icons from one locally bundled family.
- Use initials or simple fictional avatars for people. Decorative assets should preserve bandwidth and attention for the task.
- Align financial columns on the right in web tables. Show dates in one agreed format, such as 05 Nov 2026.
- Mobile navigation has Home, Groups, Work, and Help. Participant mode has Home, Passbook, Enterprise, and Help.
- Pending sync appears as a compact persistent status row. It must remain visible after transient snackbars disappear.
- Motion lasts 150–220 ms and supports reduced-motion settings. Use gentle state transitions and a short confirmation check animation.
- Preserve user input while changing language, navigating back, or recovering from a failed request.
- Use a maximum content width of 1,280 on the portal. At narrow widths convert detail tables to labelled stacked rows.

## Screen inventory

| ID | Screen | Required content and behaviour |
| --- | --- | --- |
| M01 | Demo entry | Project title, fictional-data notice, English/Hindi control, three persona cards, configured access-code input, and download progress |
| M02 | Home | Sakhi greeting, today's meeting, outstanding work, sync status, and a single primary Open meeting action |
| M03 | Groups and members | Assigned SHGs, member counts, search, member names and savings summary, Add member in Sakhi mode |
| M04 | Member profile and passbook | Identity, group, confirmed savings, pending savings separately, principal outstanding, dated transaction rows |
| M05 | Meeting workspace | Attendance, member rows, savings and repayment entry actions, totals, local save status, and online Submit meeting |
| M06 | Amount entry and review | Type, member, large amount field, preset amounts, date, note, review sheet, and explicit confirmation |
| M07 | Sync centre | Pending/syncing/confirmed/needs-attention sections, last server contact, per-item reason, retry, and conflict resolution |
| M08 | Enterprise | Demo-period sales, expenses, cash surplus, activity rows, Record sale and Record expense |
| M09 | Work and request detail | Assigned requests, status changes, resolution notes, and clear origin badge |
| M10 | Help | Topic cards, offline content status, optional audio buttons, and request support |
| M11 | Member registration | Name, group, preferred language, livelihood, optional contact, review, and draft/confirmed status |
| W01 | Programme overview | Sample member count, confirmed savings, principal outstanding, open support requests, group freshness, and recent activity |
| W02 | Groups and member detail | Two-group list, filters, member passbook drawer, and scoped financial history |
| W03 | Meeting review | Attendance, received amounts, submission status, and version-conflict explanation |
| W04 | Support queue | Status and owner filters, request detail, activity trail, reassignment and resolution |
| W05 | Audit and sync activity | Actor, subject, action, event/received timestamps, operation reference, and correction links |
| W06 | Demo controls and capability sheet | Dataset revision, service availability, reset instructions, simulation labels, fault controls restricted to demo mode |
| X01 | WhatsApp simulation | Familiar chat layout, persistent Simulation label, fictional contact, help choices, request reference, and resulting support state |

M06 contains the amount form and review state within one route. M04 uses a profile header and passbook section within one route. Avoid creating separate routes for every small state.

## Four screen compositions to implement precisely

### Mobile Home

Use a 390 × 844 reference canvas, then verify at 360 × 800 and with enlarged text. Place the small PoP 2.0 wordmark and language switch in the top row. Below it, show Hello, Kavita and the demo date. The largest card contains Udaan SHG meeting, the sample village label, and the Open meeting action. A narrow sync card follows. Two compact work cards show Pending requests and Recent activity. Bottom navigation sits above the safe area.

Use the meeting as the main visual anchor. Counts come from data. Offline state changes the sync card text and icon while the meeting remains usable.

### Member passbook

Top row has Back, Member passbook, and an accessible help action. Show Rani's initials, full name, and group. Place Confirmed savings above a large ₹1,200. A separate pale amber strip reads ₹200 waiting to sync after an offline contribution. A second card shows Loan principal outstanding. Below, group transactions by business date, with amount, type, and status on each row. The primary action for Sakhi is Record entry. Participant mode presents read access and Request help.

When the accepted transaction arrives, the confirmed total changes to ₹1,400 and the pending strip disappears. Use a short status transition. A rejected entry retains an actionable explanation in the passbook and sync centre.

### Amount entry and confirmation

Keep Rani and Udaan SHG visible above the numeric amount. Use the system numeric keyboard, a large rupee prefix, and presets ₹50, ₹100, ₹200. Parse up to two fractional digits using decimal-string logic. Review displays a four-row summary for Member, Type, Amount, and Date. The confirmation action reads Save contribution. During the local database transaction, lock the action against repeat taps. On completion show Saved on this phone or Confirmed, according to actual state.

On validation failure keep the value and show a correction beside the field. On an API outage, local capture remains available within the valid offline lease.

### Programme overview

Use a 1,440 × 1,000 reference viewport. A 240-pixel sidebar holds Overview, Groups, Meetings, Support, and Activity. The top bar shows Demo programme, filters, language, and authenticated identity. Four metric cards show member count, confirmed savings, principal outstanding, and open requests. The next row contains a group table with last received times and a support queue preview. A recent activity timeline completes the page.

Every metric is calculated from the server dataset. Display Last refreshed and a Refresh control. During an outage retain the prior values with Data may be out of date. Clear them when identity changes. Clicking a card applies a relevant filter or opens its supporting records.

## Reusable components

Implement AppScaffold, DemoBanner, LanguageSwitcher, SyncStatusBar, MemberRow, MoneyAmount, TransactionRow, StatusChip, HelpAudioButton, ReviewSheet, MetricCard, EmptyState, ErrorState, and CapabilityBadge. Share visual primitives and formatting. Keep the participant and staff page layouts distinct.

Each async component supports loading, loaded, empty, and failed states. Loading indicators have text when a user action is blocked. Errors explain what happened and the next available action. Destructive demo reset requires a typed confirmation and pending-data warning.

## Language and audio

Use the supplied ARB strings as the initial vocabulary. Labels are drafted for the demo and require field review before production. Language switching must preserve form data and route. Currency values retain the same numeric meaning. System dialogs, errors, dates, and plural forms follow the selected locale.

Audio controls play only on tap and offer replay and stop. Provide a transcript. If a validated audio asset is missing, hide playback and show the help text with Audio pending in the capability sheet. A visible microphone indicates actual capture or an explicitly labelled simulation.

## Accessibility and responsive acceptance

Verify screen-reader labels for actions, transaction types, amounts, and status. Provide logical focus order and visible keyboard focus on web. Test at 200% text scaling, with the keyboard open, and in grayscale. Status changes should have polite semantic announcements. Confirm that every money amount remains fully visible and that long Hindi labels wrap without clipping.

Document measured contrast for token pairs and inspect screenshots at 360 × 800, 390 × 844, 768 × 1,024, and 1,440 × 1,000. Test reference devices with reduced motion. Apply these checks before decorative polish.

## Visual review rubric

Score hierarchy, spacing, typography, contrast, bilingual layout, state clarity, responsive behaviour, and consistency from 0–5 each. Reach at least 34/40 and fix every score below 3. This is an internal design review score. Participant usability still needs direct testing.
