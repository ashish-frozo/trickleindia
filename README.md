# PoP 2.0 proposal demo

Current UI: blue/white structural redesign. See [BLUEPRINT_UI.md](docs/design/BLUEPRINT_UI.md). `output/blueprint` contains the latest previews; the earlier olive/lime `vengeance` direction was rejected.

Flutter Android field app, Flutter programme portal, Node.js/TypeScript API and PostgreSQL. All records are synthetic. The original requirements remain in `PoP_2_Demo_Coding_Pack`.

The app and portal use a shared blue-and-white design system with distinct field-task and programme-monitoring layouts. RFP traceability is in [UI requirements](docs/design/RFP_UI_REQUIREMENTS.md); the built design system is in [DESIGN.md](DESIGN.md).

The local review package is in `delivery/`. Implementation and automated/device evidence are available. The remaining acceptance gates are actual TalkBack spoken output and the full cached-start target; see `docs/TEST_RESULTS.md`.

## Start locally

Install Node 24.11.1, PostgreSQL 18, and Flutter 3.47.9. From this directory:

```sh
./scripts/dev-local.sh
```

The command starts a dedicated local PostgreSQL cluster on 127.0.0.1:55432, migrates, seeds only an empty database, generates ignored local access configuration when absent, and starts the API on port 3000. Existing active demo records are retained. Access code location: `.local/demo-access-code`.

In another terminal:

```sh
cd apps/portal
../../scripts/flutterw pub get --enforce-lockfile
../../scripts/flutterw build web --release --no-web-resources-cdn
cd ../..
python3 -m http.server 8080 --bind 127.0.0.1 --directory apps/portal/build/web
```

Open http://localhost:8080. Choose programme manager and enter the local access code.

For Android, start an ARM64 emulator or connect an Android device, then:

```sh
cd apps/mobile
../../scripts/flutterw pub get --enforce-lockfile
../../scripts/flutterw run --dart-define=API_URL=http://10.0.2.2:3000
```

Development HTTP is enabled in debug and restricted to local host names in the profile manifest. The emulator alias reaches the local API. Physical-device configuration requires an explicit route to the development host. Release builds require an HTTPS API URL.

## Verify

Create a separate UTF-8 PostgreSQL test database, then:

```sh
TEST_DATABASE_URL=postgresql://USER@127.0.0.1:55432/pop_test ./scripts/verify.sh
```

The database suite resets its selected database repeatedly. Use a dedicated test database. Native Android phases are documented in `scripts/android-core.sh`. Never package `.env`, `.local`, test APKs with injected access codes, or browser session traces.

Detailed setup, reset, limits and evidence: `docs/RUNBOOK.md`, `docs/IMPLEMENTATION_NOTES.md`, `docs/TEST_RESULTS.md`. API contract: `docs/openapi.json`.
