# Implemented Phase 1 candidate baseline

This is the engineering baseline implemented without an approved customer BRD. It is reviewable scope, not evidence of TUIF approval. The RFP names modules and broad outcomes; it does not specify a complete loan product, accounting policy, inventory system or report catalogue. The following choices prevent those rules from being silently invented.

| Module | Working baseline | Explicit boundary |
|---|---|---|
| Participant profiling | Create/profile edit, group association, language preference, livelihood/contact, duplicate review, version conflicts; participant identity bound to one member | Group transfer, deletion/retention and additional demographic fields need agreed rules and acceptance |
| SHG management | Create/edit groups, assign Sakhis, schedule meetings, attendance, revision-safe submission | No silent transfer of existing balances between groups; no claim of cluster/MEG/market rollout |
| SHG financial management | Integer-paise savings deposits, confirmed/pending passbooks, imported opening balances and loans, principal repayment cap, immutable reversals and audit; exactly-once retries | Principal-only model; loan origination/disbursement, withdrawals, interest, fees and maker/checker rules are not inferred from module names |
| Enterprise management | Onboarding/editing, member owner, business plan, sale/expense categories, opening balances, cash surplus and reversal | Cash surplus is not accounting profit; inventory, receivables and taxes are outside this candidate baseline |
| Smart Sakhi monitoring | Assigned groups/caseload, private member visits, coaching topics, follow-up dates/outcomes, support progression and manager snapshot reports | Indicators are recorded activities, not independently validated livelihood outcomes |
| Common assistance | Cited local help, optional model-selected help cards, reviewed text/voice navigation with role allowlist, conditional device TTS | No autonomous payments, open-ended financial advice, reviewed recordings or five-language acceptance claim |
| Programme administration | Manager/Sakhi/participant access mapping, assignment, disable/re-enable and immediate online session revocation; initial organisation bootstrap and reviewed opening import | Cognito users must already exist; no invitations, provider user creation or live tenant verification |

## Report catalogue

All reports use the currently confirmed server snapshot and carry a refresh timestamp. Group filtering applies before export. Money columns are integer paise. Export escapes quoted/multiline values and prefixes spreadsheet formula-like text. Pending device operations do not contribute to totals. Tables page through 50 rows; exports include the whole selected snapshot.

1. Member balances: member/group, confirmed savings, outstanding principal.
2. Meeting attendance: date/status and present/absent/unmarked counts.
3. Enterprise cash: owner/group, sales/expenses/cash surplus.
4. Sakhi visits: member/group/Sakhi, topic/status and next visit date; private notes excluded from exports.
5. Support progress: reference/member/group/status/assigned Sakhi and creation/resolution times.

These are snapshot reports, not interval cash-flow statements. Whole-dataset bootstrap remains a deliberate architecture limitation; the bounded local load probe measures its cost but does not certify a production population size.

## Acceptance boundaries

Working local implementations and automated checks can be completed without AWS. Customer approval of this baseline, source mapping reconciliation by the data owner, verified identity subjects, real-language review, audio consent/listening review, representative physical-device testing and participant UAT require external evidence. Keep these as acceptance entries, not fabricated engineering passes. User interfaces that collect real data must use an approved deployment and information-handling policy before production use.
