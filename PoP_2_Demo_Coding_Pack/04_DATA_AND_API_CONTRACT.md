# Data and API contract

## Common conventions

Base path /v1. JSON uses camelCase, UTC ISO-8601 timestamps, ISO calendar dates for businessDate, UUID identifiers, and integer paise for money. Display dates in Asia/Kolkata. Never store a displayed currency string as a financial value. A positive entry amount is between 1 and 100,000,000 paise for this demo. Validate aggregate values as JavaScript safe integers before serialising. Return change cursors as decimal strings to avoid bigint precision loss.

Every domain record carries id, datasetId, version, createdAt, updatedAt and, when created by a mutation, originOperationId. Version starts at 1 and increments on a change. API responses include requestId. Authorisation derives from the bearer session; never accept an actor/role supplied in a mutation as authority. SQL queries are parameterised and scoped to dataset and permitted records.

## Entities

| Entity | Required domain fields and constraints |
| --- | --- |
| Dataset | id, businessDate, schemaVersion, createdAt; exactly one active dataset per demo environment |
| Actor | id, displayName, role: sakhi / participant / manager; participant memberId where relevant |
| ActorGroup | actorId, groupId; unique pair; manager may read all demo groups |
| Group | id, code, displayName, villageLabel; code unique in dataset |
| Member | id, groupId, displayName, preferredLanguage, livelihoodCategory, optional contact, openingSavingsPaise; active status; registration defaults opening savings to zero |
| Loan | id, memberId, openingPrincipalPaise; exactly one seeded loan at most per member; no loan creation UI |
| Enterprise | id, memberId, name, openingCashSalesPaise, openingCashExpensesPaise; one seeded enterprise |
| Meeting | id, groupId, businessDate, status: open / submitted, submittedAt, submittedBy; seeded meeting starts open |
| Attendance | id, meetingId, memberId, status: present / absent / unmarked; unique meeting/member pair; own version |
| Transaction | id, operationId, memberId, groupId, type, amountPaise, businessDate, createdByActorId; optional meetingId, loanId, enterpriseId, category, note (max 280 characters); reversal fields below |
| SupportRequest | id, reference, memberId, groupId, category, description, source: app / whatsapp_simulation, status: open / in_progress / resolved, assignedActorId, resolutionNote, resolvedAt |
| AuditEvent | id, actorId, action, entityType, entityId, operationId, changedFields, reason if required, clientCreatedAt if supplied, timestamp set by server; append only; client time is untrusted display context |
| OperationReceipt | datasetId, actorId, operationId, canonicalPayloadHash, acceptedResult; unique composite key |
| ChangeEvent | datasetId, cursor, entityType, entityId, record, originOperationId; committed in the domain transaction |
| DeviceSyncReport | actorId, deviceId, pendingCount, lastLocalSaveAt, reportedAt; optional telemetry; explicitly stale-capable |

The seed JSON is an import document, not the physical database schema. Its record code fields support human review and stable lookups. Convert fixture records through a seed command and normal migrations. Never use the JSON file as the running server database.

## Financial rules

Transaction types are savings_deposit, loan_principal_repayment, enterprise_sale, enterprise_expense, and reversal. The first two require an open meeting in the member's group. Enterprise entries require a matching enterprise and member; they have no meetingId. All original amounts are positive. A reversal references originalTransactionId, stores its positive amount and original type for audit, and sets original.reversedByTransactionId. One reversal per original, full amount, manager only, online, reason required. The original remains immutable except for its reversal link and version.

For calculations, effective originals are transactions without a reversedByTransactionId, excluding type reversal. Do not both remove an original and subtract its reversal. The opening balances are explicit seed balances, not invented historical transaction rows.

| Metric | Formula using effective originals |
| --- | --- |
| Confirmed member savings | openingSavingsPaise + savings_deposit |
| Outstanding principal | openingPrincipalPaise − loan_principal_repayment for that loan |
| Enterprise cash sales | openingCashSalesPaise + enterprise_sale |
| Enterprise cash expenses | openingCashExpensesPaise + enterprise_expense |
| Enterprise cash surplus | cash sales − cash expenses |
| Meeting cash received | savings_deposit + loan_principal_repayment linked to that meeting |

Savings withdrawals, interest, loan issuance and enterprise transfers are outside these formulas. Group and dashboard values sum the corresponding confirmed member values. Unsent operations never appear in server aggregates. Locally show pending totals by type; an enterprise pending expense must not inflate savings. A rejected, discarded or superseded intent contributes no pending financial amount. A conflict/blocked financial intent remains visibly unresolved and separate from confirmed balances.

## Canonical fixture checkpoints

| Checkpoint | Rani savings | All savings | Rani principal | All principal | Enterprise expenses / surplus |
| --- | ---: | ---: | ---: | ---: | ---: |
| Reset | ₹1,200 | ₹4,800 | ₹2,000 | ₹5,000 | ₹1,800 / ₹1,200 |
| Accept ₹200 savings | ₹1,400 | ₹5,000 | ₹2,000 | ₹5,000 | ₹1,800 / ₹1,200 |
| Accept ₹100 repayment | ₹1,400 | ₹5,000 | ₹1,900 | ₹4,900 | ₹1,800 / ₹1,200 |
| Accept ₹350 expense | ₹1,400 | ₹5,000 | ₹1,900 | ₹4,900 | ₹2,150 / ₹850 |
| Reverse that expense | ₹1,400 | ₹5,000 | ₹1,900 | ₹4,900 | ₹1,800 / ₹1,200 |

Six members, two groups, one enterprise and one open seeded support request exist on reset. A new WhatsApp simulated request increases open requests to two. Resolving that new request returns the open count to one. Completing registration increases members to seven without changing financial totals.

## Mutation envelope

POST /v1/mutations accepts one operation. This also serves online-only writes, which retain idempotency. The client sends the same complete envelope on retry.

```json
{
  "datasetId": "<active-dataset-uuid>",
  "operationId": "<generated-once-uuid>",
  "kind": "transaction.post",
  "clientCreatedAt": "2026-11-05T09:00:00Z",
  "payload": {
    "transactionId": "<generated-once-uuid>",
    "memberId": "<rani-uuid-from-seed>",
    "meetingId": "<udaan-meeting-uuid-from-seed>",
    "type": "savings_deposit",
    "amountPaise": 20000,
    "businessDate": "2026-11-05"
  }
}
```

Placeholders above illustrate the schema; use valid UUIDs at runtime. Canonical hash input includes datasetId, operationId, kind, clientCreatedAt and payload, using a consistent sorted-key canonical JSON function. Freeze these values after enqueue. The server computes its own hash. Reject unknown fields rather than silently ignoring fields that affect user intent.

Success is HTTP 200 with operationId, status: accepted, replayed: boolean, changeCursor, records: [{entityType, record}], and requestId. A replay returns the original receipt's records/cursor; it must not regress newer local versions. The client upserts only a newer or equal matching version and then pulls changes. Acknowledgement applies records and clears the pending overlay atomically.

| kind | Payload | Actor and rules |
| --- | --- | --- |
| member.create | memberId, groupId, displayName, preferredLanguage, livelihoodCategory, contact? | Sakhi assigned group; zero opening balances; duplicate check below |
| member.update | memberId, expectedVersion, allowed patch | Sakhi; name, preferredLanguage, livelihoodCategory, contact only; no balance/group edits |
| meeting.attendance_set | attendanceId, meetingId, memberId, status, expectedVersion | Sakhi, open assigned meeting; preseed unmarked rows have version 1; attendance change also increments meeting version |
| transaction.post | transactionId, memberId, type, amountPaise, businessDate, meetingId?/loanId?/enterpriseId?/category?/note? | Sakhi; type-specific relationships; repayment cannot exceed principal; enterprise category required |
| meeting.submit | meetingId, expectedVersion | Manager or assigned Sakhi; online; canonical attendance/amount review; requires at least one marked attendee and accepted transaction |
| transaction.reverse | transactionId for reversal, originalTransactionId, reason | Manager; online only; full original amount; cannot reverse a reversal or already reversed record |
| support.create | requestId, memberId, category, description | Participant for self, Sakhi assigned member, manager any; source fixed to app by server; assign group Sakhi |
| support.update | requestId, expectedVersion, status?, assignedActorId?, resolutionNote? | Manager can assign within group and change status; assigned Sakhi can progress/resolve; resolved requires nonempty note |

Member duplicate heuristic: trim/collapse whitespace, Unicode NFKC and casefold-equivalent normalisation for display name, compare within group. A matching active member produces POSSIBLE_DUPLICATE with candidate IDs/names authorised for the actor. Demo resolution offers use existing member or edit new draft and submit a new operation. Do not auto-merge and do not hard-block a production identity solely on a name match. Distinct people with identical names require a future supervised resolution design.

For a newly confirmed member, create unmarked attendance when first added to an open meeting through an explicit add-member action, with expectedVersion 0 for the new attendance row. This action cannot modify a submitted meeting. All supported locales may be stored as member preferences, but only English/Hindi UI are available in the demo. The preference form labels the other languages Planned and does not promise translated output.

Support state transitions: open → in_progress → resolved. Reopen is outside the prototype. A resolved request is read-only except audit inspection. The server generates a short reference such as DEMO-0002 through a database-safe counter. Two requests with identical text are valid when their operation identities differ.

## Endpoints

| Method and path | Response / behaviour |
| --- | --- |
| POST /v1/demo/session | Input actorCode, accessCode; output token, expiresAt, offlineUntil, actor, datasetId; configured demo mode only |
| GET /v1/bootstrap | Authorised snapshot: groups, members, loans, enterprises, meetings, attendance, transactions, support requests, content version, cursor, datasetId, serverTime |
| POST /v1/mutations | Envelope above; online-only kinds are never queued for offline execution |
| GET /v1/operations/{operationId}?datasetId=… | Receipt for this actor or 404 OPERATION_NOT_FOUND; dataset mismatch is 409, never interpreted as absent |
| GET /v1/changes?datasetId=…&after=…&limit=… | Authorised records, nextCursor, highWaterCursor, hasMore, datasetId; limit 1–500, default 100 |
| GET /v1/dashboard | Manager; confirmed metrics, open request count, asOf, datasetId; optional last-reported device telemetry separate |
| GET /v1/groups | Authorised groups and confirmed summaries |
| GET /v1/members/{id}/passbook | Member, openings, effective balances and transaction history including reversal markers |
| GET /v1/meetings/{id} | Attendance, current version, status, accepted totals and transaction history |
| GET /v1/enterprises/{id} | Confirmed sales, expenses, cash surplus and entries |
| GET /v1/support-requests | Scoped requests; manager may filter group/status |
| GET /v1/support-requests/{id} | Authorised request detail and its bounded status/assignment audit trail; participant self, assigned Sakhi or manager |
| GET /v1/audit-events | Manager, pagination; bounded metadata and correction reasons |
| GET /v1/content | Versioned bilingual demo help cards; bundled copy works without API |
| POST /v1/device-sync-reports | Optional; authenticated actor/device, bounded counts; server sets reportedAt |
| POST /v1/demo/whatsapp-events | Manager simulator only; simulatedMessageId, demoContactCode, topicCode; creates one real support request per simulated message |
| POST /v1/demo/reset | Local development only; manager session plus access code and literal confirmation RESET DEMO; recreate dataset, revoke sessions; reject if hosted reset disabled |
| GET /healthz and /readyz | Process liveness and database/migration readiness; no credentials or user data |

Portal detail screens can assemble data from these endpoints and bootstrap. Paginate list endpoints with bounded page sizes; do not expose arbitrary SQL/filter expressions. Include an OpenAPI file in the implementation that matches these contract decisions.

The simulator endpoint uses unique(datasetId, simulatedMessageId), derives Rani from the server-owned demo contact mapping, creates source whatsapp_simulation and returns the support reference plus a scripted acknowledgement. A duplicate event returns the existing result. A changed payload for the same ID returns OPERATION_ID_REUSED. It commits its receipt, domain record, audit and change event under the same sync-clock lock.

## Errors and recovery

Error body: {error: {code, messageKey, retryable, fieldErrors?, currentVersion?, currentRecord?}, requestId}. UI translates messageKey and never displays a raw stack trace. The server is authoritative for retryability. Keep definitive rejection separate from delivery uncertainty.

| HTTP | Code | Client action |
| --- | --- | --- |
| 400 | INVALID_PAYLOAD / INVALID_AMOUNT | Correct draft; rejected operation stays visible |
| 401 | SESSION_EXPIRED | Block worker, lock cached records after lease, reauthenticate same actor |
| 403 | FORBIDDEN | Explain restricted action; preserve receipt/error evidence |
| 404 | NOT_FOUND | Refresh scope; avoid revealing inaccessible record details |
| 409 | VERSION_CONFLICT | Show current record and original intent; user reviews before new operation |
| 409 | DATASET_MISMATCH | Block uploads; show unsent count and explicit demo reset action |
| 409 | OPERATION_ID_REUSED / TRANSACTION_ID_REUSED | Stop operation; implementation defect or changed replay; never auto-regenerate IDs |
| 409 | POSSIBLE_DUPLICATE | Offer authorised candidate review |
| 409 | MEETING_CLOSED / LOAN_BALANCE_EXCEEDED / ALREADY_REVERSED | Reject with current canonical facts; user corrects intent |
| 429 | RATE_LIMITED | Honour Retry-After with bounded backoff |
| 503 | TEMPORARILY_UNAVAILABLE | Retry same operation ID and payload |

Persist accepted receipts only in the required demo. A definitive failed operation is not automatically retried with edited content. Record validation failures in bounded diagnostic logs; optionally add a rejection audit without creating a financial record. A transport timeout remains ambiguous until receipt lookup or a same-ID replay resolves it.
