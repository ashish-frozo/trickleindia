# Capability and acceptance matrix

**Current non-AWS implementation and verification:** [NON_AWS_COMPLETION.md](NON_AWS_COMPLETION.md). Earlier dated results below are historical and do not certify newer binaries.

| Capability | Delivered state | Verification |
|---|---|---|
| Restricted demo identities | Working | Opaque leases, server scopes/roles, guessed-ID denial, immediate known-revocation lock |
| Canonical ledger and reporting | Working | Real PostgreSQL, integer paise, deterministic fixture and sequential financial checkpoints |
| Android encrypted cache/outbox | Working | Actual Android file rejects unkeyed SQLite; secure-storage keys; atomic state transactions |
| Offline save and process termination | Working | Real route interruption, force-stop, identical IDs/payload/hash recovered |
| Retry/receipts/cursors | Working | Android lost response after commit; one effect; PostgreSQL controlled ordering barrier; backoff and invisible pages |
| Second Android installation | Working | Separate Android user profile begins empty and retrieves accepted contribution |
| Attendance/profile conflict review | Working | Server winner returned, original retained, replacement linked/versioned, widget test |
| Principal repayment/meeting submission | Working | Correct arithmetic, principal cap, current revision and controlled close/post race |
| Enterprise sale/expense/reversal | Working | Type-specific entry and full correction with reason/history; repeated reversal denied |
| Offline registration/duplicate review | Working | Android restart/sync, zero balances, seven members, normalized duplicate denial |
| Support assignment/progress/resolution | Working | Real support records, required resolution note, browser workflow and audit |
| WhatsApp transport | Simulation | No messages sent; creates real demo support requests; replay keeps reference |
| English/Hindi UI | Working draft copy | Matching 260 resource keys, bundled fonts, target viewports, 200%/keyboard widget checks |
| Accessibility | Partially verified | Contrast, native semantics, keyboard and large text checked; actual TalkBack speech remains A20 blocker |
| Offline help | Versioned draft content | Bundled fallback, atomic cached updates and manager editor; no language approval claim |
| Audio | Conditional device speech | Matching installed voice required; no reviewed recordings or audible field acceptance |
| Odia/Ho/Santhali | Planned | No working-language claim |
| Live AI / voice navigation / official WhatsApp | Not implemented | Optional integrations in the demo pack; RFP AI baseline remains open |
| Local startup | Working | Clean copied source/isolated PostgreSQL/API/encrypted-client reproduction |
| Container startup | Configuration only | Compose validated; no running Docker daemon to execute containers |
| Customer artifacts | Local review package | APK, web build, source, evidence, screenshots, recordings and runbook; see delivery README |

The remaining A20 spoken-output check prevents claiming full customer acceptance. Production deployment, content/terminology approval and operational hardening remain separate from this proposal demo.

## 6 November 2026 implementation follow-up

See [REQUIREMENTS_CLOSURE.md](REQUIREMENTS_CLOSURE.md) for current changes and evidence. Added group/meeting/enterprise administration, ordinary profile editing, scoped Sakhi visits, confirmed-balance CSV, content editing, audit paging and retained form drafts. Cognito/PKCE code and local verification are present; live identity deployment is untested. Historical native evidence above predates this revision. The full RFP is not complete.
