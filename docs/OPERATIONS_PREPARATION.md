# Operations preparation — 6 November 2026

The user confirmed that no TUIF AWS environment, approved repository or acceptance contact is available. Continue using synthetic local data. No cloud resources have been created, no production identity tenant has been contacted, and no production acceptance is claimed.

## Identity configuration

Cognito is the implemented candidate, subject to organisational selection. The API verifies access-token signature, issuer, application client, token type and expiry using `aws-jwt-verify`. Roles and group assignments come from PostgreSQL identity mappings; caller-provided roles are never authoritative. The returned opaque session expires no later than the verified access token. EN/HI demo sign-in remains the default.

Set `DEMO_MODE=false`, `ALLOW_DEMO_RESET=false`, `ALLOW_DEMO_FAULTS=false`, and set `COGNITO_USER_POOL_ID`, `COGNITO_CLIENT_ID`, `COGNITO_DOMAIN`, `AUTH_REDIRECT_URI` in the private API environment. The browser callback must be HTTPS on the portal origin. Register `com.frozo.pop:/oauthredirect` for Android. Use a public application client without a secret and code flow with PKCE. Build clients with `--dart-define=AUTH_MODE=cognito` and an HTTPS `API_URL`. Browser callback completion currently requires pressing Sign in after returning to the app. Live provider and device callback testing remain outstanding.

Run `npm --prefix services/api run identity:provision -- /private/path/identity.json` with an operator database connection. The JSON contains issuer, subject, displayName, role, optional memberId and groupIds. Participant identities require an existing member. A Sakhi's assigned groups must exist. Never commit mapping input files. This command does not bootstrap a production organisation or migrate real member data; those workflows require a separate, reviewed migration. Disabling a mapping prevents new sign-ins. Revoke existing sessions explicitly by actor ID in the same operator transaction; mapping disable alone does not invalidate sessions already issued.

Sources: [AWS verification guidance](https://docs.aws.amazon.com/cognito/latest/developerguide/amazon-cognito-user-pools-using-tokens-verifying-a-jwt.html), [official verifier](https://github.com/awslabs/aws-jwt-verify/blob/main/README.md), [Flutter AppAuth](https://pub.dev/packages/flutter_appauth).

## Release and rollback

1. Use an approved source revision and run API, domain, UI, analysis and platform builds. Save logs with that revision.
2. Configure Android signing in private `apps/mobile/android/key.properties` with storeFile, storePassword, keyAlias and keyPassword. Release tasks fail without it. Profile APKs remain development artifacts. Keep the keystore and properties outside source archives.
3. Take a database backup and successfully restore it to a disposable database before migration. Migrations 002–004 are additive except for extending the entity check constraint. They do not delete demo records.
4. Deploy migrations before new API/client code. `/readyz` requires migration 4 and an active dataset. `/healthz` is process liveness only.
5. For rollback, stop writers and retain the failing build and logs. Roll back the application only after compatibility testing against the migrated database. Do not delete ledger records or blindly reverse migrations. If a database restore is necessary, reconcile all writes since the backup before switching traffic.

## Backup and isolated restore

Use a private output directory on encrypted storage; dumps contain personal and financial information when used with real data. `scripts/database-backup.sh` refuses to overwrite existing files and uses restrictive output permissions. Set `DATABASE_URL` privately, then run `scripts/database-backup.sh /private/path/backup.dump`.

Create an empty disposable database, set `RESTORE_DATABASE_URL`, then run `scripts/database-restore-drill.sh /private/path/backup.dump`. The script refuses any target containing public tables, restores transactionally, and prints migration versions and record counts. It never drops a database. The URL is expanded into PostgreSQL environment variables, not included in process arguments. Unsupported connection URL options fail explicitly.

A local test-database archive was restored successfully on 6 November 2026. This establishes local tooling functionality, not AWS recovery objectives. Retention, recovery time, recovery point, encryption key custody and disaster-region decisions remain to be set and exercised in the eventual environment.

## Proposed AWS topology — not provisioned

Use a separate staging environment, HTTPS portal distribution, private API tasks behind an HTTPS load balancer, private PostgreSQL, managed secrets, bounded log retention and least-privilege deployment roles. Avoid exposing database ports publicly. Start with a fixed small task count and scale only against measured latency and database-lock contention. The current global sync-clock lock and whole-dataset bootstrap need representative-volume load tests before sizing.

The infrastructure bill depends on region, availability requirements, concurrent users, database size, outbound traffic, backups, identity activity and AI/audio usage. No account-specific estimate, infrastructure-as-code validation or capacity guarantee has been completed. Keep a cost worksheet for compute hours, database hours/storage/I/O, load balancer hours/traffic, CDN/storage/requests, secrets/logs/backups, identity users, and any model or speech calls; multiply usage by current account-region rates when the environment is selected.

## Support preparation

For each incident record severity, observed time, affected roles/devices, application revision, request/operation ID, reproducible steps and resolution. Exclude tokens and personal data from tickets. Financial incidents require preserving the immutable operation ID and checking server acknowledgement before retry or correction. Use an authorised reversal for a confirmed wrong amount.

Proposed triage: unavailable service or suspected duplicated ledger effect is critical; blocked role/workflow is high; a workaround or cosmetic issue is normal. Response times, support hours, ownership, warranty and escalation contacts are proposals to agree, not contractual promises. Training and UAT instructions are in USER_TRAINING.md.
