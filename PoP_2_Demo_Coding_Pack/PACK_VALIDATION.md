# Specification pack validation

Prepared 2026-11-05. These checks validate the documents and assets. Application code, Android behaviour, API runtime, rendered UI, native encryption, actual audio and end-to-end tests have not been implemented or executed by this document-generation task.

**Result: 28 specification checks passed.**

## Checks

- All five JSON/ARB assets parse as UTF-8 JSON
- 126 English/Hindi message keys match
- English/Hindi placeholder metadata match
- Placeholder present: en/@greeting/name
- Placeholder present: en/@assignedTo/name
- Placeholder present: en/@requestRecorded/reference
- Placeholder present: en/@pendingCount/count
- Placeholder present: hi/@greeting/name
- Placeholder present: hi/@assignedTo/name
- Placeholder present: hi/@requestRecorded/reference
- Placeholder present: hi/@pendingCount/count
- Fixture record UUIDs are unique and valid
- Every fixture record uses the dataset template ID
- Fixture foreign keys resolve
- Opening fixture sizes: 6 members, 2 groups, 1 enterprise, 1 open support request
- Opening savings total 480000 paise
- Opening loan principal total 500000 paise
- Udaan opening savings 360000 paise
- Accepted savings checkpoint: Rani140000, Udaan380000, all500000
- Repayment checkpoint: Rani190000, all490000, meeting cash30000
- Enterprise checkpoint: expenses215000, cash surplus85000
- Full expense reversal restores expenses180000 and surplus120000
- Support lifecycle expectations are 1 to 2 to 1
- Help content has four bilingual draft cards and no fabricated audio paths
- All nine intended text colour pairs exceed 4.5:1 contrast
- All Markdown relative links resolve and fenced blocks are balanced
- 18 unique screen IDs are specified
- 27 unique application acceptance scenarios are specified

## Calculated colour contrast

| Token pair | Ratio |
| --- | ---: |
| onPrimary/primary | 7.80:1 |
| text/canvas | 12.67:1 |
| text/surface | 13.52:1 |
| muted/canvas | 5.89:1 |
| muted/surface | 6.28:1 |
| primary/primaryTint | 6.87:1 |
| success/successTint | 6.67:1 |
| warning/warningTint | 6.12:1 |
| error/errorTint | 6.41:1 |

Rendered controls, focus boundaries, overlays and disabled states still require application visual QA. The pale Border and Accent tokens are decorative; they are not approved as text or sole interactive boundaries.

## Remaining review

- Hindi copy and instructional content need fluent review and TUIF terminology validation.
- Audio assets are not supplied; availability is explicitly false/null.
- Provider setup, live messaging and production platform decisions remain outside the required demo build.
- The coding agent must run the 27 acceptance scenarios and report actual results.
