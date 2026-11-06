#!/usr/bin/env bash
# Encrypted storage of the output is the operator's responsibility.
set -euo pipefail
script_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
: "${DATABASE_URL:?Set DATABASE_URL without placing credentials in command arguments}"
backup_path="${1:?Usage: database-backup.sh /private/path/backup.dump}"
[[ ! -e "$backup_path" ]] || { echo 'Refusing to overwrite an existing backup' >&2; exit 1; }
umask 077
export PGDATABASE="$DATABASE_URL"
python3 "$script_dir/pg-private.py" pg_dump --format=custom --no-owner --no-acl --file="$backup_path"
python3 "$script_dir/pg-private.py" pg_restore --list "$backup_path" >/dev/null
printf 'Backup created and archive index checked. A restore drill is still required.\n'
