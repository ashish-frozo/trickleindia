#!/usr/bin/env bash
set -euo pipefail
project_dir="$(cd "$(dirname "$0")/.." && pwd)"
: "${TEST_DATABASE_URL:?Set TEST_DATABASE_URL to a dedicated PostgreSQL test database}"
cd "$project_dir/services/api"
npm ci
npm run build
DATABASE_URL="$TEST_DATABASE_URL" npm test
for package in domain ui; do
  cd "$project_dir/packages/$package"
  "$project_dir/scripts/flutterw" pub get --enforce-lockfile
  "$project_dir/scripts/flutterw" test
 done
cd "$project_dir/apps/mobile"
"$project_dir/scripts/flutterw" pub get --enforce-lockfile
"$project_dir/scripts/flutterw" test test/encryption_test.dart
cd "$project_dir"
"$project_dir/scripts/flutterw" analyze packages/domain packages/ui apps/mobile apps/portal
