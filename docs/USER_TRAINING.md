# User training and acceptance worksheet

This guide covers the local proposal application with fictional records. English and Hindi copy is draft; Odia, Ho and Santhali preferences do not imply translated screens or reviewed speech.

## Sakhi practice

1. Sign in with the supplied private demo access code and Sakhi persona. Choose English or Hindi. Open the assigned group and member passbook.
2. Record savings: enter the amount and note; review member, group, type and date; confirm once. With connectivity unavailable, verify the item is pending and the confirmed total has not changed.
3. Close and reopen the app. The saved outbox entry must remain. Restore connectivity and sync. Verify one confirmed transaction and one corresponding balance increase. Never re-enter an uncertain payment as a new transaction.
4. Reopen an unfinished amount form to check draft recovery. A draft is not a saved financial operation. Resolve conflicts against the current server value; rejected entries require attention rather than repeated blind retries.
5. Add a member: select group, name, preference, livelihood and optional contact. Review every field. New members start with zero balances. Use Edit profile from the passbook for permitted changes.
6. Open Meetings, schedule a meeting, record attendance and submit after review. Submitted meetings cannot accept further financial postings.
7. Open enterprise records, record a sale or expense with the appropriate category, and check confirmed surplus. Business plans and enterprise details can be maintained through the enterprise form.
8. Open Work → Sakhi monitoring. Record a visit, topic, notes and optional follow-up date. Confirm a follow-up outcome when complete. Visits are scoped to authorised staff; participants do not receive staff visit notes.
9. Open Help, search a topic and expand its steps. Device speech works only when a matching voice is installed. Missing voice support is displayed. Reviewed recordings are not supplied. Open Help → voice/help assistance to type a question and view the matching source instructions. The optional remote-assistance checkbox requires consent and a configured provider; without one, local instructions remain available.

## Programme manager practice

Open groups to create or update a group and assign an available Sakhi. Open member records and enterprise details to review the operational data. Use savings totals to drill into their supporting records. In Activity, refresh, load more and retry failures.

Open Capabilities → Reports to filter confirmed member balances by group and download CSV on web (copy CSV on native). CSV money columns are integer paise. Pending device entries are excluded; review the refresh timestamp before use. Choose member balances, meeting attendance, enterprise cash, Sakhi visits or support progress. These are snapshot reports, not accounting statements. Tables display 50 rows at a time; exports include the full selected report.

Open Capabilities → Manage help content to select a help card and English/Hindi locale, edit title, one step per line and speech text, then publish a draft revision. Publication is manager-only and version checked. A failed or uncertain submission retries the frozen payload. Reopen the editor to start another edit. Published draft content is downloaded and retained for offline use; publication does not constitute language approval.

## Participant practice

Sign in as the participant persona. Confirm that only the assigned member's information is visible. Read confirmed and pending balances separately, browse help, and create a support request. Check that financial posting and staff visit information are unavailable.

## Acceptance record — complete during observed sessions

| Scenario | Expected evidence | Result / observer / device / date |
|---|---|---|
| Offline save and process restart | Same operation remains pending, then appears exactly once | Not yet entered |
| Expired session | No unauthorised write; retained data can be recovered safely | Not yet entered |
| Profile and registration | Correct assigned group and reviewed fields, no invented opening balance | Not yet entered |
| Conflict and correction | Current server state shown; reversal preserves audit trail | Not yet entered |
| Reports | Scope, timestamp and confirmed totals match canonical data | Not yet entered |
| Language and speech | Fluent reviewer validates text; participant understands spoken prompts | Not yet entered |
| Accessibility | Actual TalkBack reading order and task completion, 200% text | Not yet entered |
| Performance | Representative-device launch and durable-save timings | Not yet entered |

Record failures with the screen, expected/actual result and request or operation ID. Do not collect access codes, session tokens or unnecessary member information. No row above represents a completed human acceptance session.

## Voice navigation

Open Help → assistance. Type an exact screen command such as “open groups” or “रिपोर्ट”, or choose Use microphone. Read the microphone disclosure and confirm before recording. Recognition requires a matching installed device language; unsupported devices show an error and retain typed input. Review the recognized text, then press Open selected screen. Speaking never posts a payment or opens a screen automatically. Leaving the screen, changing language or backgrounding the app cancels recognition. TTS and recognition depend on device services; they are not reviewed recorded prompts.

## Access administration and opening import

Managers can open Capabilities → staff administration to map an existing provider subject to a manager, Sakhi or participant. Sakhis receive explicit groups; participants require an existing member. Review role and scope before saving. Saving revokes that identity’s sessions, including your own if you edit yourself. Last-manager and self-lockout protections reject unsafe changes. This screen does not create provider users or send invitations.

An opening import applies only to an empty organisation with actors already provisioned. Use the documented JSON format, run validation, reconcile displayed counts and integer-paise totals against the source register, and confirm the reviewed payload. Existing programme records cannot be overwritten by import. Preserve the operation ID and reviewed hash. Rollback is an operator action permitted only before any subsequent programme change. Practice against a disposable dataset; do not attempt import into the populated demo.
