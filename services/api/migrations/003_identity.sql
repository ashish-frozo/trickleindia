CREATE TABLE external_identities (
 dataset_id uuid NOT NULL REFERENCES datasets(id),
 issuer text NOT NULL CHECK (issuer LIKE 'https://%'),
 subject text NOT NULL,
 actor_id uuid NOT NULL,
 enabled boolean NOT NULL DEFAULT true,
 PRIMARY KEY(dataset_id,issuer,subject)
);
CREATE INDEX external_identity_actor ON external_identities(dataset_id,actor_id);
INSERT INTO migrations(version) VALUES(3);
