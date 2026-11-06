ALTER TABLE records DROP CONSTRAINT records_entity_type_check;
ALTER TABLE records ADD CONSTRAINT records_entity_type_check CHECK(entity_type IN ('actors','groups','members','loans','enterprises','meetings','attendance','transactions','supportRequests','sakhiVisits'));
INSERT INTO migrations(version) VALUES(2);
