CREATE TABLE IF NOT EXISTS migrations (version integer PRIMARY KEY, applied_at timestamptz NOT NULL DEFAULT now());
CREATE TABLE datasets (id uuid PRIMARY KEY, business_date date NOT NULL, schema_version integer NOT NULL, active boolean NOT NULL DEFAULT true, created_at timestamptz NOT NULL DEFAULT now());
CREATE UNIQUE INDEX one_active_dataset ON datasets(active) WHERE active;
CREATE TABLE sync_clock (dataset_id uuid PRIMARY KEY REFERENCES datasets(id), cursor bigint NOT NULL DEFAULT 0 CHECK(cursor >= 0), support_counter integer NOT NULL DEFAULT 1);
-- Typed envelopes retain the canonical API shape. All changes pass through the
-- serialized domain transaction; SQL also enforces natural identities below.
CREATE TABLE records (
 dataset_id uuid NOT NULL REFERENCES datasets(id), entity_type text NOT NULL,
 id uuid NOT NULL, body jsonb NOT NULL,
 PRIMARY KEY(dataset_id,entity_type,id),
 CHECK(entity_type IN ('actors','groups','members','loans','enterprises','meetings','attendance','transactions','supportRequests')),
 CHECK(body->>'id'=id::text AND body->>'datasetId'=dataset_id::text),
 CHECK((body->>'version')::integer >= 1),
 CHECK(entity_type <> 'transactions' OR ((body->>'amountPaise')::numeric BETWEEN 1 AND 100000000 AND (body->>'amountPaise')::numeric = trunc((body->>'amountPaise')::numeric)))
);
CREATE UNIQUE INDEX group_codes ON records(dataset_id,(body->>'code')) WHERE entity_type='groups';
CREATE UNIQUE INDEX attendance_identity ON records(dataset_id,(body->>'meetingId'),(body->>'memberId')) WHERE entity_type='attendance';
CREATE UNIQUE INDEX reversal_identity ON records(dataset_id,(body->>'originalTransactionId')) WHERE entity_type='transactions' AND body->>'type'='reversal';
CREATE UNIQUE INDEX support_reference ON records(dataset_id,(body->>'reference')) WHERE entity_type='supportRequests';
CREATE TABLE actor_groups(dataset_id uuid REFERENCES datasets(id), actor_id uuid NOT NULL, group_id uuid NOT NULL, PRIMARY KEY(dataset_id,actor_id,group_id));
CREATE TABLE sessions(token_hash text PRIMARY KEY, dataset_id uuid NOT NULL REFERENCES datasets(id), actor_id uuid NOT NULL, expires_at timestamptz NOT NULL);
CREATE TABLE operation_receipts(dataset_id uuid REFERENCES datasets(id), actor_id uuid NOT NULL, operation_id uuid NOT NULL, payload_hash text NOT NULL, result jsonb NOT NULL, PRIMARY KEY(dataset_id,actor_id,operation_id));
CREATE TABLE change_events(dataset_id uuid REFERENCES datasets(id), cursor bigint NOT NULL, records jsonb NOT NULL, PRIMARY KEY(dataset_id,cursor));
CREATE TABLE audit_events(id uuid PRIMARY KEY, dataset_id uuid REFERENCES datasets(id), actor_id uuid NOT NULL, operation_id uuid NOT NULL, body jsonb NOT NULL);
CREATE TABLE simulation_receipts(dataset_id uuid REFERENCES datasets(id), message_id uuid NOT NULL, payload_hash text NOT NULL, result jsonb NOT NULL, PRIMARY KEY(dataset_id,message_id));
INSERT INTO migrations(version) VALUES (1);
