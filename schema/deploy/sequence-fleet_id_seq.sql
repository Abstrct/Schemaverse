-- Deploy sequence-fleet_id_seq
-- requires: table-fleet

BEGIN;

CREATE SEQUENCE fleet_id_seq
  INCREMENT 1
  MINVALUE 1
  MAXVALUE 9223372036854775807
  START 1
  CACHE 1;

COMMIT;
