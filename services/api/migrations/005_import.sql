CREATE TABLE import_receipts (
 dataset_id uuid NOT NULL REFERENCES datasets(id), operation_id uuid NOT NULL,
 payload_hash text NOT NULL, result jsonb NOT NULL, rows jsonb NOT NULL,
 assignments jsonb NOT NULL, rolled_back boolean NOT NULL DEFAULT false,
 PRIMARY KEY(dataset_id,operation_id)
);
INSERT INTO migrations(version) VALUES(5);
