# Local demo runbook

Run from the `trickleup` project directory. All data is fictional. Tested on macOS arm64 with Node 24.11.1/npm 11.6.2, PostgreSQL 18.3, Flutter 3.47.9/Dart 3.13.7, Java 17 and Android API 36 ARM64. SDK and dependency versions are pinned; install Flutter separately or set `FLUTTER_BIN`.

## Start the service

Install Node 24 and PostgreSQL 18 server, then run:

```sh
./scripts/dev-local.sh
```

This starts a dedicated PostgreSQL cluster on loopback port 55432, creates a UTF-8 `pop_demo` database, installs locked API dependencies, migrates, seeds only an empty database and starts Fastify on port 3000. `PG_BIN`, `POP_PG_PORT` and `POP_PG_DIR` override local PostgreSQL paths. The local cluster uses loopback trust for this development workstation. Use password authentication for shared installations.

Configuration is generated in ignored `.env`. The random access code is in ignored `.local/demo-access-code`; only its SHA-256 digest is configured in the server. Never record or ship either file. `GET http://127.0.0.1:3000/readyz` must return ready. Choose Kavita (Smart Sakhi), Rani (member) or Arun (programme manager) and enter that code. Sessions expire after eight hours.

For an existing database instead, copy `.env.example`, configure a database URL and access-code digest, export those values and run `npm ci`, `npm run migrate`, `npm run seed`, then `npm run dev` from `services/api`. Seed creates a new active dataset and revokes existing sessions.

## Web portal

```sh
cd apps/portal
../../scripts/flutterw pub get --enforce-lockfile
../../scripts/flutterw build web --release --no-web-resources-cdn
cd ../..
python3 -m http.server 8080 --bind 127.0.0.1 --directory apps/portal/build/web
```

Open http://localhost:8080 and choose programme manager. The web build bundles its renderer/fonts; the portal requires the API and keeps its session in memory. Configure a different API with `--dart-define=API_URL=https://...` at build time; allow the exact portal origin in the API CORS configuration.

## Android

Use Android 8/API 26 or newer. The tested emulator is API 36 AOSP ARM64. For an emulator, build/run:

```sh
cd apps/mobile
../../scripts/flutterw pub get --enforce-lockfile
../../scripts/flutterw run --dart-define=API_URL=http://10.0.2.2:3000
```

To use the supplied local profile APK, install it with `adb install -r PATH_TO_APK`, run `adb reverse tcp:3000 tcp:3000`, and launch PoP 2.0. Its configured API is `http://127.0.0.1:3000`. Removing that reverse mapping genuinely interrupts the API route; restoring it reconnects. Do not switch to a different API after creating pending work. The development profile manifest permits HTTP only to loopback/emulator host names; release configuration requires HTTPS. The profile APK uses Android development signing and is for local proposal review.

## Main demonstration

Start from a fresh dataset. Log in Android as Kavita and portal as Arun while connected. Open Rani's passbook: confirmed savings ₹1,200. Disconnect the API route; mark attendance in the meeting, record ₹200 savings, review and save. Confirmed savings remains ₹1,200 with a separate ₹200 pending amount. Force-stop through Android settings or `adb shell am force-stop com.frozo.pop_mobile`; reopen normally and inspect the same pending entry. Reconnect and retry: Rani ₹1,400, Udaan ₹3,800 and manager total ₹5,000. Record ₹100 principal repayment (Rani principal ₹1,900, overall ₹4,900) and ₹350 enterprise expense (expenses ₹2,150, surplus ₹850). Meeting submission requires current confirmed attendance and entries; review ₹300 cash received. Manager can reverse the full expense with a reason, restoring expenses ₹1,800 and surplus ₹1,200.

Use the labelled WhatsApp simulation to create an expense-help request. Replay preserves its reference. Assign/resolve through support with a resolution note. The assigned Sakhi sees the same server record. Help cards are illustrative and bundled; reviewed audio is unavailable. Odia, Ho and Santhali and live AI/WhatsApp integrations are planned, not working providers.

## Reset, recovery and diagnostics

Manager capabilities includes reset when `ALLOW_DEMO_RESET=true`. It requires the access code and literal `RESET DEMO`, shows pending work consequences, creates a new dataset and invalidates old sessions. Review pending work before resetting. Old datasets remain diagnostic history; reset is not a backup. Use `pg_dump` before maintenance.

Retryable network failures retain IDs/payloads. Retry respects server `Retry-After`. Validation/conflict entries remain visible for review and replacement; a replacement has a new identity linked to its predecessor. Ambiguously sent entries require receipt reconciliation before discard. Accepted financial effects require a manager reversal. An expired session locks cached records; same-actor reauthentication retains that actor's pending work. Another actor cannot read it. Native storage errors show a retryable startup failure and never fall back to plaintext.

Fault controls require both demo mode and `ALLOW_DEMO_FAULTS=true`; the default generated configuration disables faults. They are for local verification only. Logs exclude access codes, session tokens and request bodies. `docs/openapi.json` describes the API.

## Reproduce checks

Create a separate UTF-8 database and run:

```sh
TEST_DATABASE_URL=postgresql://USER@127.0.0.1:55432/pop_test ./scripts/verify.sh
node scripts/check-assets.mjs
```

The API tests reset their selected database. Never point them at demo or production data. Android's four-process durable-state check is `scripts/android-core.sh`; it clears the test app, expects a freshly seeded demo and reads an ignored `.local/client-test.json` containing `DEMO_ACCESS_CODE`. That harness builds credential-bearing test APKs: rebuild the ordinary `lib/main.dart` APK without test defines before sharing. Real device logs and acceptance exceptions are in `docs/TEST_RESULTS.md`.

## Container alternative

Docker Compose is supplied for PostgreSQL/API. Set the database password, build the API, run migration and seed explicitly using `docker compose run --rm api npm run migrate` and `... npm run seed`, then start the API. Compose configuration was validated; container execution could not be tested because this workstation has no running Docker daemon. The native PostgreSQL startup path was reproduced in a separate clean source tree and isolated cluster.
