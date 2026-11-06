# Organisation bootstrap, staff identities and opening-data import

This is a local, provider-independent implementation. It does not create Cognito users, send invitations, verify real client records, migrate an AWS environment, or establish RFP acceptance. An operator must create/verify the actual Cognito pool and subjects separately. Roles and assignments always come from this database, never token group claims.

## First production bootstrap

Run database migrations first. Keep the bootstrap JSON private, then run:

```sh
DEMO_MODE=false npm --prefix services/api run bootstrap:production -- /private/bootstrap.json
```

```json
{
  "businessDate": "2026-11-06",
  "displayName": "Initial manager",
  "mapping": {
    "issuer": "https://cognito-idp.ap-south-1.amazonaws.com/REAL_POOL_ID",
    "subject": "actual-cognito-subject"
  },
  "confirmation": "INITIALIZE EMPTY PRODUCTION"
}
```

Use the operator's explicitly configured `DATABASE_URL`; the command does not discover or connect to production automatically. It requires `DEMO_MODE=false`, refuses **any existing dataset**, uses the same advisory lock as dataset creation/reset, and atomically creates one dataset, clock, manager, identity mapping and audit event. It inserts no groups, members, financial balances or fictional people. It is deliberately not an HTTP endpoint. A repeated bootstrap refuses instead of resetting data. `businessDate` is an explicit organisation setting, not the source-import cutoff date.

## Staff administration

Manager session required. `GET /v1/staff` returns `{staff:[{actor,issuer,subject,enabled,groupIds}]}`. Staff comprises managers and Sakhis; participant identity administration is outside this endpoint.

`POST /v1/staff` creates or replaces a staff definition:

```json
{
  "datasetId": "dataset-uuid",
  "operationId": "unique-operation-uuid",
  "actorId": "stable-actor-uuid",
  "expectedVersion": 0,
  "displayName": "Staff name",
  "role": "sakhi",
  "enabled": true,
  "groupIds": [],
  "mapping": {"issuer": "https://cognito-idp.ap-south-1.amazonaws.com/REAL_POOL_ID", "subject": "actual-subject"},
  "revokeSessions": true
}
```

UUID placeholders must be replaced by actual UUIDs. `expectedVersion:0` creates; updates require the actor's exact current version. Use `enabled:false` to disable and `true` to re-enable. Use the same endpoint with the current definition and version to revoke sessions. Every successful write increments the version and revokes all that actor's sessions, even if only the display name changes. `revokeSessions` can only be true (defaults true). Changing group scope therefore requires signing in and a fresh bootstrap, preventing continued use of old scope through existing sessions. Offline devices cannot learn revocation until reconnecting; existing offline expiry remains in effect.

Manager assignments must be empty; Sakhi group IDs must be unique and exist. Identity mappings are unique per dataset. Last enabled manager removal/demotion is rejected. A manager cannot disable/demote themselves or replace their own mapped subject. Display-name edits and explicit session revocation for self are allowed and require reauthentication afterward. Unknown fields, unsupported roles and invalid payloads are rejected. Transactions serialize against normal mutations and identity-session issuance. Staff changes create audit and sync events. Staff response: `{actor,records,groupIds,changeCursor,replayed}`. A replay with identical operation ID and payload returns its receipt; changed content gives `OPERATION_ID_REUSED`. If the actor editing themselves revoked their own session, obtain a new session before retrying.

Operator wrapper uses the same authorization and auditing, replacing the former direct SQL provisioning path:

```sh
DEMO_MODE=false POP_SESSION_TOKEN=... npm --prefix services/api run identity:provision -- /private/staff-envelope.json
```

## Structured opening-data import

This imports already transformed structured JSON, independently of whether its source was CSV, a spreadsheet or another database. No unreviewed CSV parser or guessed column mapping is included. Convert and review source data first. Import is restricted to a dataset containing **only actors**, with zero groups, members, loans, enterprises, meetings, transactions, attendance, support requests or visits. Provision Sakhis with empty group assignments first. Imported groups each require at least one valid Sakhi assignment. Import never merges into or overwrites financial records.

`POST /v1/imports/dry-run` takes `{datasetId,payload}`. Payload schema:

- `formatVersion`: exactly `1`; `source`: nonempty provenance label (max 280); `asOfDate`: ISO date of opening balances.
- `groups`: `{id,code,displayName,villageLabel}` (max 500).
- `members`: `{id,groupId,displayName,preferredLanguage,livelihoodCategory,contact?,openingSavingsPaise}` (max 5000). Language: `en|hi|or|hoc|sat`; contact defaults null.
- `loans`: `{id,memberId,openingPrincipalPaise}` (max 5000).
- `enterprises`: `{id,memberId,name,businessPlan?,openingCashSalesPaise,openingCashExpensesPaise}` (max 5000). Business plan defaults empty.
- `assignments`: `{actorId,groupId}` (max 5000).

All arrays are required. IDs are UUIDs, unique across imported entities. Codes are unique; duplicate normalized member names within a group require source review and are rejected. References must resolve within the payload; assignments require an existing enabled Sakhi actor. Opening amounts are integer paise between zero and 100,000,000, never floats or rupees. HTTP bodies retain the API's 512 KiB limit; oversized migrations need explicit future batching design, not partial uploads.

Dry run changes nothing and returns `{valid,errors,reviewedHash,counts,totals}`. Structural schema failures return `INVALID_PAYLOAD`; relational/duplicate findings appear in `errors`. Totals cover savings, loan principal, enterprise cash sales and expenses in paise. Compare these totals and counts against the independently reviewed source register before committing.

`POST /v1/imports/commit` takes the same `{datasetId,payload}` plus `operationId` and the exact `reviewedHash` returned by dry run. The hash binds the normalized complete payload and dataset, including provenance. Commit revalidates the current database under the writer lock, creates rows/assignments, records source/date/operation provenance, publishes a sync event, and writes the receipt/audit atomically. A stale or modified payload fails. Identical concurrent retries have one effect; a changed payload using the same operation ID fails. A replay after rollback reports `rolledBack:true` and never imports again. A new reviewed import requires a new operation ID.

`POST /v1/imports/rollback` takes `{datasetId,operationId,importOperationId,reviewedHash}`. Rollback is deliberately conservative: the entire non-actor dataset and all assignments must exactly match the import, and **no later sync change** may exist. Edited rows, later meetings/transactions/support/visits or staff changes reject with `IMPORT_IN_USE`. It atomically removes only that initial imported domain dataset, retains provenance/receipts/audit, and revokes every session so clients must sign in and bootstrap; sync does not expose deletion tombstones. It does not reverse real-world payments. A second rollback after signing in reports replayed success.

CLI equivalents accept the same envelopes and require an authenticated manager token:

```sh
DEMO_MODE=false POP_SESSION_TOKEN=... npm --prefix services/api run data:import -- dry-run /private/dry-run.json
DEMO_MODE=false POP_SESSION_TOKEN=... npm --prefix services/api run data:import -- commit /private/commit.json
DEMO_MODE=false POP_SESSION_TOKEN=... npm --prefix services/api run data:import -- rollback /private/rollback.json
```

The OpenAPI document contains exact request schemas. All changes use existing structured error envelopes. Key conflict codes: `DATASET_EXISTS`, `DATASET_MISMATCH`, `VERSION_CONFLICT`, `IDENTITY_EXISTS`, `LAST_MANAGER`, `SELF_LOCKOUT`, `OPERATION_ID_REUSED`, `REVIEW_HASH_MISMATCH`, `IMPORT_INVALID`, `IMPORT_IN_USE`.

## Validation

PostgreSQL tests use a dedicated disposable database and serial execution. They truncate its dataset tables; never point them at production. Tests cover empty bootstrap refusal/audit, strict schemas and role checks, identity uniqueness, expected versions and retry receipts, manager lockout prevention, disabling/re-enabling/remapping identities, session revocation, migration validation/reconciliation, concurrent commit idempotency, no overwrite, safe rollback and rejection after edits. Existing API scope, ledger, response-loss, reset and Cognito signature-verification tests remain applicable. No real provider calls or real client data are used.
