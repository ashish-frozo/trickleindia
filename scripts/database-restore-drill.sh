#!/usr/bin/env bash
# Refuses non-empty targets. Never restores over an existing dataset.
set -euo pipefail
script_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
: "${RESTORE_DATABASE_URL:?Set a disposable empty restore database URL}"
backup_path="${1:?Usage: database-restore-drill.sh backup.dump}"
export PGDATABASE="$RESTORE_DATABASE_URL"
tables="$(python3 "$script_dir/pg-private.py" psql -X -A -t -v ON_ERROR_STOP=1 -c "SELECT count(*) FROM pg_tables WHERE schemaname='public'")"
[[ "$tables" == '0' ]] || { echo 'Restore target is not empty; refusing to continue' >&2; exit 1; }
python3 "$script_dir/pg-private.py" pg_restore --exit-on-error --single-transaction --no-owner --no-acl --dbname='' "$backup_path"
python3 "$script_dir/pg-private.py" psql -X -v ON_ERROR_STOP=1 -c 'SELECT version FROM migrations ORDER BY version' -c 'SELECT entity_type,count(*) FROM records GROUP BY entity_type ORDER BY entity_type'
printf 'Restore completed in isolated target. Verify application workflows before any cutover.\n'
