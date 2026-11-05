# PoP 2.0 demonstration requirements

## Product purpose

Help a reviewer experience how a Smart Sakhi records group activity with limited connectivity and how a programme manager receives trustworthy information. The demo should establish engineering reliability, accessible interaction, and understanding of field workflows.

The commercial proposal remains a separate deliverable. This prototype provides evidence for its technical approach. It implements selected journeys from the five Phase 1 modules and illustrates the proposed help and communication experience.

## Actors and permissions

| Actor | Identity in fixture | Access |
| --- | --- | --- |
| Smart Sakhi | Kavita Rao | Udaan SHG and its four members, assigned enterprise, meeting capture, support follow-up |
| Participant | Rani Mahto | Own profile, passbook, enterprise summary, and help request creation. Read-only financial records |
| Programme manager | Arun Sen | Both sample SHGs, aggregate reporting, all demo support requests, and online correction workflow |

Identities and locations are fictional. The backend derives the role, actor ID, and assignment from the authenticated session. User-supplied role fields confer no authority. Actor identity and the member whose record changes are separate fields.

## Priorities

| ID | Priority | Capability | Completion condition |
| --- | --- | --- | --- |
| D01 | P0 | Restricted demo login and initial download | The Android app downloads only authorised records and can reopen within its offline session lease |
| D02 | P0 | SHG and member profiles | Seeded profiles and membership are accessible offline |
| D03 | P0 | Meeting attendance | Sakhi can save attendance locally and recover it after restart |
| D04 | P0 | Savings contribution | Enter, review, confirm, persist, retry, and synchronise one contribution |
| D05 | P0 | Member passbook | Confirmed savings and pending changes remain clearly distinguishable |
| D06 | P0 | Sync centre | Queue counts, status, retry, failure reasons, and conflict resolution are visible |
| D07 | P0 | Programme portal | Dashboard and group/member detail are derived from server records |
| D08 | P0 | English and Hindi UI | Main journey and system states are fully localised |
| D09 | P1 | Principal repayment | Record repayment against a seeded loan and enforce remaining-principal validation |
| D10 | P1 | Meeting submission | Online finalisation validates the current meeting revision and recorded totals |
| D11 | P1 | Enterprise cash entries | Record a sale or expense offline and show deterministic cash summaries |
| D12 | P1 | Participant registration | A short offline form creates a member draft and synchronises it with duplicate review |
| D13 | P1 | Smart Sakhi support | Create, assign, progress, and resolve a request in the portal |
| D14 | P1 | Help and audio guidance | Bundled topic cards work offline. Verified clips play offline when available |
| D15 | P1 | WhatsApp preview | Clearly labelled simulator creates a support request through the shared API |
| D16 | P1 | Correction and audit | Manager reverses an eligible financial entry online with a recorded reason |
| D17 | P2 | Live spoken expense draft | Provider-enabled speech creates an editable draft, followed by explicit save |
| D18 | P2 | Live knowledge assistant | Approved demo corpus, grounded response, source, and escalation behaviour |
| D19 | P2 | Official WhatsApp connection | Dedicated test account, permitted test recipients, inbound handling and idempotency |

P0 and P1 describe this prototype's release target. P2 completion must be recorded individually. Architecture for future languages is required, while Odia, Ho, and Santhali remain planned language work in the capability matrix.

## Core journey

1. Log in as Kavita while connected and download Udaan records.
2. Open the scheduled meeting and mark Rani present.
3. Disconnect the device from the API.
4. Choose Rani and enter a savings contribution of ₹200.
5. Review member, group, amount, meeting date, and entry type. Confirm once.
6. Show Saved on this phone and a pending contribution of ₹200. Confirmed savings remain ₹1,200.
7. Terminate and reopen the app. Recover the same transaction and queue state.
8. Restore connectivity. Upload the saved operation and download canonical results.
9. Show Rani's confirmed savings of ₹1,400 and zero pending amount.
10. Refresh the manager portal. Udaan savings are ₹3,800 and overall sample savings are ₹5,000.

Repeat an upload or lose its acknowledgement. The same operation must leave the same single financial effect. A successful HTTP request and business approval are separate concepts. This demo accepts valid ledger postings immediately on the server and labels their status Confirmed. It does not add a separate financial approval state.

## Secondary journeys

### Repayment and meeting completion

Record a ₹100 principal repayment for Rani. Her outstanding principal becomes ₹1,900. The meeting's cash received is ₹300 after the contribution and repayment. The manager portal shows overall outstanding principal of ₹4,900. Interest accrual, fees, loan disbursement, and rescheduling are outside this prototype's calculation model.

Submit the meeting only when connected and after all of its local operations are acknowledged. Display the server-confirmed attendance and ledger totals before finalisation. A stale revision produces a review step. A submitted meeting blocks additional mobile postings. An online manager reversal remains possible and is visible in audit history.

### Enterprise activity

Record a ₹350 Seeds expense for Rani's vegetable enterprise. Opening demo-period cash sales are ₹3,000 and cash expenses are ₹1,800. The resulting expenses are ₹2,150 and cash surplus is ₹850. Label this metric Cash surplus. Full profit accounting, inventory valuation, and receivables are future scope.

### Registration

Capture name, group, preferred language, and one livelihood category. Allow an optional contact field, empty by default. Save a draft offline. The new member receives zero opening savings and no loan. After confirmation, the member may participate in later entries. A possible name/group duplicate requires review and produces no new active member until resolved.

### Support request

The local WhatsApp preview uses a fictional contact mapped to Rani. She chooses Help recording an expense and receives a request reference. The manager sees a new request assigned to Kavita, moves it through In progress to Resolved, and records a resolution note. Real transport is labelled separately from simulated transport.

## Product boundaries

- Core records, local persistence, server sync, roles, reports, and support state changes run end to end.
- Help card retrieval is deterministic and labelled Demo help. Provider-backed generative responses receive their own visible label.
- Financial entry is performed by the Sakhi role. Participant mode provides read access and help creation.
- Demo authentication is an isolated mechanism. Production identity is selected by TUIF from the tender's options.
- The demo runs with a fixed business date of 2026-11-05. Event timestamps record actual execution time in UTC and display in IST.
- Browser portal requires connectivity for writes. Its last fetched data may remain visible with a stale indicator during an outage.
- Attachments, lending decisions, payments, biometric identity, GPS tracking, marketplace functions, predictive scoring, and bulk messaging are deferred.

## Success criteria

The core journey must run from a clean seed without manual database editing. No accepted transaction is duplicated by retries. A second device can retrieve accepted records. Cross-group access is rejected. Every screen has an intentional offline or error state. A reviewer can identify implemented, simulated, and planned capabilities from the UI and handoff.

Local responsiveness targets are engineering targets, measured on the documented test device. Aim for visible save confirmation within 300 ms and a first cached screen within 2 seconds on restart. Keep dashboard freshness explicit instead of promising a fixed network delivery time.
