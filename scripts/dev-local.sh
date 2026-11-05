#!/usr/bin/env bash
set -euo pipefail
project_dir="$(cd "$(dirname "$0")/.." && pwd)"
cd "$project_dir"
pg_bin="${PG_BIN:-$(pg_config --bindir)}"
if [[ ! -x "$pg_bin/postgres" ]] && command -v brew >/dev/null 2>&1; then
  pg_bin="$(brew --prefix postgresql@18)/bin"
fi
if [[ ! -x "$pg_bin/postgres" || ! -x "$pg_bin/initdb" ]]; then
  echo "Install the PostgreSQL 18 server or set PG_BIN to its bin directory." >&2
  exit 1
fi
pg_port="${POP_PG_PORT:-55432}"
pg_data="${POP_PG_DIR:-$project_dir/.local/pgdata}"
mkdir -p .local
if [[ ! -f ${pg_data}/PG_VERSION ]]; then
  "$pg_bin/initdb" -D "$pg_data" -A trust -E UTF8 --no-locale
fi
if ! "$pg_bin/pg_ctl" -D "$pg_data" status >/dev/null 2>&1; then
  "$pg_bin/pg_ctl" -D "$pg_data" -l "${pg_data}.log" -o "-p $pg_port -h 127.0.0.1" start
fi
if ! "$pg_bin/psql" -h 127.0.0.1 -p "$pg_port" -d postgres -Atc "SELECT 1 FROM pg_database WHERE datname='pop_demo'" | read -r _; then
  "$pg_bin/createdb" -h 127.0.0.1 -p "$pg_port" -T template0 -E UTF8 pop_demo
fi
node scripts/configure-local.mjs
set -a
source .env
set +a
node --input-type=module -e 'const u=new URL(process.env.DATABASE_URL);if(!["127.0.0.1","localhost"].includes(u.hostname)||process.env.DEMO_MODE!=="true")throw new Error("dev-local requires a local demo database");'
cd services/api
npm ci
npm run migrate
node --import tsx --input-type=module -e 'import {pool,seed} from "./src/db.ts"; try { if (!(await pool.query("SELECT id FROM datasets WHERE active")).rowCount) await seed(); } finally {await pool.end();}'
exec npm run dev
