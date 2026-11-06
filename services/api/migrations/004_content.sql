CREATE TABLE content_packs(dataset_id uuid NOT NULL REFERENCES datasets(id), revision integer NOT NULL CHECK(revision>0), body jsonb NOT NULL, published_by uuid NOT NULL, published_at timestamptz NOT NULL DEFAULT now(), PRIMARY KEY(dataset_id,revision));
INSERT INTO migrations(version) VALUES(4);
