#!/usr/bin/env python3
"""Run a PostgreSQL CLI with connection fields in environment, not argv."""
import os
import sys
from urllib.parse import urlsplit, unquote, parse_qsl

connection = urlsplit(os.environ['PGDATABASE'])
if connection.scheme not in ('postgres', 'postgresql'):
    raise SystemExit('A PostgreSQL URL is required')
env = dict(os.environ)
for key in ('PGDATABASE', 'DATABASE_URL', 'RESTORE_DATABASE_URL'):
    env.pop(key, None)
for key, value in {
    'PGHOST': connection.hostname,
    'PGPORT': str(connection.port or 5432),
    'PGUSER': unquote(connection.username or ''),
    'PGPASSWORD': unquote(connection.password or ''),
    'PGDATABASE': unquote(connection.path.lstrip('/')),
}.items():
    if value:
        env[key] = value
allowed = {'sslmode': 'PGSSLMODE', 'sslrootcert': 'PGSSLROOTCERT', 'connect_timeout': 'PGCONNECT_TIMEOUT'}
for key, value in parse_qsl(connection.query):
    if key not in allowed:
        raise SystemExit('Unsupported connection option: ' + key)
    env[allowed[key]] = value
if sys.argv[1] not in ('pg_dump', 'pg_restore', 'psql'):
    raise SystemExit('Unsupported PostgreSQL utility')
os.execvpe(sys.argv[1], sys.argv[1:], env)
