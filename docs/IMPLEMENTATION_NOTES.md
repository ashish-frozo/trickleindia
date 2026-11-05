# PoP 2.0 implementation notes

The preserved specification is `PoP_2_Demo_Coding_Pack`. This is a synthetic proposal demonstration for local development and recording. Completion evidence and remaining acceptance limits are listed individually in `TEST_RESULTS.md`; compilation alone is not acceptance.

## Architecture and decisions

Flutter Android and Flutter web share `packages/domain` and `packages/ui`. The mobile app uses encrypted Drift/SQLite with a random secure-storage key per actor/dataset. The portal uses memory storage and requires an online service. Fastify/TypeScript uses PostgreSQL transactions for canonical data, authorization, receipts, a serial change clock and audit history. All money is integer paise. Business dates remain ISO dates independent of host timezone.

The database uses a constrained typed JSONB `records` envelope table instead of a physical table per domain entity. Identity/version/amount constraints, unique attendance relationships, reversal identities and support references are enforced in PostgreSQL. Domain relationships and permissions are checked inside the serialized mutation transaction. This is a bounded prototype decision; relational projections, database foreign keys and production migration strategy require review before rollout.

Native canonical records, cursor and outbox are stored together in one encrypted Drift state row. A transaction with WAL and synchronous FULL commits each local save and each received page/receipt atomically. This differs from the recommended separate native entity tables and suits this six-member fixture. It is not a production-scale storage recommendation. Startup refuses to fall back to plaintext when encrypted storage fails.

Queued operations retain their original operation/transaction IDs, payload hash, actor/subject, sequence and dispatch history. Local saves and network sync are serialized independently; rapid review confirmation has one form intent. Never-dispatched edits may supersede earlier edits. Ambiguous writes require receipt reconciliation before discard. Accepted financial effects can only be corrected through full reversal. Backoff includes jitter and honours both numeric/date Retry-After. Permission, dataset and lease checks run server-side; stale actor responses cannot populate a switched session.

PostgreSQL's sync-clock row is locked before each mutation's canonical changes and cursor allocation. Snapshot isolation pairs bootstrap content with its cursor. Changes scan raw pages before applying scope filters, so invisible events still advance a client's cursor. Receipt replay returns the original canonical result; changed payload reuse is rejected. Barrier-controlled tests cover commit ordering and close/post races. Local fault injection drops a real HTTP connection after commit.

## Experience and content

Design tokens are generated from the supplied canonical JSON. Noto Sans and Noto Sans Devanagari are bundled with OFL licensing. English/Hindi resources have matching keys; offline help cards are bundled draft instructional content. The language switch updates routed screens and the full Material locale. Layout checks cover large text, Hindi entry with keyboard, and repeated confirmation.

The WhatsApp surface is a local labelled simulation creating actual support records through the service. It sends no messages. Replay of a simulated message keeps its reference. Audio is explicitly unavailable because reviewed assets were not supplied; playback controls are not shown. Odia, Ho and Santhali, conversational AI, speech and official WhatsApp transport remain planned/P2. No live provider integration is claimed.

## Tested environment

macOS arm64; Node 24.11.1/npm 11.6.2, PostgreSQL 18.3, Flutter 3.47.9/Dart 3.13.7, Java 17.0.17. Android API 36 AOSP ARM64 emulator uses software graphics, 2 cores and approximately 2.5 GB guest RAM. The supplied local APK is an AOT profile build with loopback HTTP configured; hosted/release use requires HTTPS and distribution signing. Dependencies are pinned in lock files. No access code is embedded in the ordinary deliverable APK.

Docker Compose configuration was checked but container execution was unavailable because there is no running Docker daemon. Native PostgreSQL startup and an API/encrypted-client roundtrip were reproduced in an isolated clean source tree and separate cluster. Emulator timing samples describe this environment only, not a device performance guarantee.

## Operational boundary

Eight-hour opaque sessions are stored as hashes on the server. Demo access and reset endpoints are restricted to configured demo mode; reset and fault controls require their explicit flags. Pending work belongs to its actor/dataset. No public deployment, external message, account creation or production connection was performed. Production security review, AWS provisioning, monitoring, backups, final BRD, language/content approval and rollout sizing are separate work.

See `RUNBOOK.md` for startup, reset and recovery, `openapi.json` for the API and `THIRD_PARTY_NOTICES.md` for licensing.

## Screen composition deviations

Member details use a dedicated routed passbook page in the portal instead of a separate desktop drawer. This reuses the same scoped read journey on Android and web, with explicit Back navigation. The server remains authoritative; this is a presentation choice. The local AOT profile manifest permits HTTP only to loopback/emulator host names; its configuration is excluded from the hosted release source set.
