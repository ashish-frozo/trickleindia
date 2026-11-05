# Acceptance tests and demonstration

These are tests to implement and run against the application. The specification pack itself does not constitute a passed application test. Use fresh reset datasets for independent scenarios, record actual results, and keep all test records synthetic.

## Test matrix

| ID | Scenario and method | Pass condition |
| --- | --- | --- |
| A01 | Seed and real aggregate API | Six members, two groups, savings 480000 paise, principal 500000, enterprise surplus 120000; API and portal agree |
| A02 | Bootstrap as each actor | Sakhi gets only Udaan; Rani only her permitted records; manager both groups. Direct guessed-ID requests are denied |
| A03 | Disconnect Android, save ₹200 | One durable operation; confirmed savings 120000; pending savings 20000; clear Saved on this phone status |
| A04 | Force-stop Android, reopen | Same operationId/transactionId and payload recovered; no lost form commitment or duplicated pending amount |
| A05 | Restore connection | One accepted ledger entry; Rani 140000, Udaan 380000, total 500000; pending cleared atomically |
| A06 | Drop response after server commit; retry | One ledger entry, one financial effect; receipt replay or pull reconciles the pending overlay |
| A07 | Retry same ID with changed payload | OPERATION_ID_REUSED; original unchanged; no automatic client ID regeneration |
| A08 | Rapid double tap and reentrant sync triggers | One form intent produces one operation and one transaction; one upload worker runs |
| A09 | Second device and incremental cursor | Second authorised Android installation retrieves the accepted record; empty authorised pages still advance; page replay is harmless |
| A10 | Commit-order and bootstrap race | Barrier-controlled concurrent writes/bootstrap cannot skip a committed record; sync-clock lock serialises cursor assignment; atomic page apply survives interruption |
| A11 | Attendance/profile conflict and local re-edit | Two devices edit same version; first accepted; second shows server record and original intent. Repeated never-dispatched offline edits supersede locally without stale predecessor conflicts; uncertain delivery must reconcile first |
| A12 | Principal repayment and concurrency | ₹100 yields Rani190000/overall490000; concurrent repayments exceeding available principal cannot both succeed; principal stays ≥0 |
| A13 | Meeting submission race | Submission checks latest revision; a post racing with close either commits before final review or is rejected after close; closed meeting accepts no mobile posting |
| A14 | Enterprise expense and reversal | ₹350 yields expenses215000/surplus85000; full reversal restores180000/120000; second reversal rejected; audit keeps reason and both records |
| A15 | Offline registration | Draft survives restart; accepted new member has zero savings/no loan; total members7; duplicate-name/group review creates no second active record |
| A16 | Support and simulator | One simulated message creates one request; replay returns same reference; open count1→2→1 after resolution; assigned Sakhi sees progress; Simulation label persistent |
| A17 | Session expiry and actor switch | Expired lease locks cached records and blocks uploads; same-actor reauth preserves queue; different actor cannot access old actor's data; client role spoof fails |
| A18 | Reset during pending work | Old dataset upload blocked; pending intent retained for explicit review; confirmation shows discard count; stale sessions invalid |
| A19 | Native storage and logs | Unkeyed SQLite reader cannot read data; tokens/access codes absent from logs; secure-storage key used; debug HTTP exception absent from hosted release config |
| A20 | Hindi, accessibility and responsive layouts | Entire core flow localised; no placeholder keys/overflow at 200% text; TalkBack amounts/status intelligible; web controls keyboard reachable |
| A21 | Outage and retry backoff | Network/503 remains retryable with same ID; 401 blocks; validation failure remains actionable; failure on one independent operation does not stall unrelated work forever |
| A22 | Truthful capability states | Seed data, help cards, audio availability, simulation and any P2 live provider are correctly labelled in UI and handoff |
| A23 | Wrong relationship and role checks | Rani cannot post money; Sakhi cannot use Pragati IDs; enterprise/member and loan/member mismatches fail; reverse requires manager |
| A24 | Local discard after ambiguous send | Receipt reconciled before discard; accepted original is corrected by reversal; no accepted server amount disappears through local deletion |
| A25 | Money boundaries and effective ledger | Reject fractional paise/NaN/negative/overflow, verify principal cap, exclude reversed original exactly once, keep enterprise pending separate |
| A26 | Offline content | Bundled cards open offline; available reviewed clips play; absent/unreviewed audio is labelled and does not appear to be working audio |
| A27 | Fresh handoff run | Clean environment setup, migration, seed, login and core demo reproduced from RUNBOOK without manual database editing |

## Verification layers

Use pure domain tests for money, ledger reversal and scope rules. Use backend integration tests against real PostgreSQL for transaction rollback, unique keys, row locking, receipts and cursors. Use Flutter integration tests on Android for native encrypted persistence, interruption and pending reconciliation. Use browser-based integration tests or Flutter web-compatible testing for portal behaviour. Screenshots alone verify appearance, not backend effects.

For A10, explicitly control transaction timing with test barriers: hold writer A inside the locked transaction, start writer B, confirm B cannot allocate a later committed cursor ahead of A, then release A and verify both changes through pagination. Exercise bootstrap before and after commit. Do not rely on random timing or repeated sleeps to prove consistency.

For A06, provide a local-only injectable fault that commits the operation and closes the response before the client receives it. Check database counts and the device after recovery. For A04 use Android force-stop and normal reopen, not hot reload. For A09 use two independent installations/device stores; a second browser tab does not establish Android offline behaviour.

Record local save latency and cached-start latency on the stated device. The targets are ≤300 ms and ≤2 s respectively. Record sample count and observed results; failures trigger investigation, not fabricated guarantees. Do not attribute network latency to local persistence.

## Demonstration runbook

Prepare a seeded API, Android device/emulator and manager portal. Log in while connected. Keep the fictional-data label visible and ensure screen recording contains no access code or token.

1. **Context:** “This proposal demo follows a Smart Sakhi recording a group meeting. All records are fictional.” Show role and English/Hindi switch.
2. **Starting position:** Open Rani's passbook: confirmed savings ₹1,200. Show Udaan meeting.
3. **Offline capture:** Disconnect. Mark Rani present, enter ₹200, review details and confirm. Point out Saved on this phone and pending ₹200.
4. **Durability:** Force-stop and reopen. Show the retained entry and unchanged confirmed balance.
5. **Synchronisation:** Reconnect. Show Confirmed ₹1,400, pending zero. Refresh portal: total savings ₹5,000. Open the canonical entry/audit record.
6. **Operational depth:** Add ₹100 repayment and ₹350 enterprise expense. Show principal ₹1,900 and enterprise cash surplus ₹850. Submit the meeting after reviewing confirmed ₹300 cash received.
7. **Support:** Open the clearly labelled WhatsApp simulation. Choose the expense-help topic. Show the resulting real support request and manager resolution.
8. **Honest scope:** Display the capability sheet: working offline/sync, bilingual UI, simulated WhatsApp transport, illustrative help content, remaining languages and production integrations planned.

Aim for a focused demonstration. Keep registration, reversal and fault injection as optional evidence clips or reviewer drill-downs rather than crowding the core presentation. This is a presentation pacing suggestion, not an implementation waiver.

If a live demonstration fails, state the failure and use a previously recorded successful run with its date and configuration visible. A recording must not be represented as a current live system. Keep the diagnostic evidence for follow-up.

## Final quality gate

All P0/P1 tests should pass before presenting the pack's target scope as completed. Audio may be explicitly marked unavailable if no reviewed assets can be supplied; report that exception. P2 integrations may remain disabled. The agent's report must show test counts and each exception, including device or environment limitations. No production-readiness claim follows from demo acceptance.
