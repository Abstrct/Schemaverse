-- Deploy sequence-ship_id_seq
-- requires: table-ship

BEGIN;

CREATE SEQUENCE ship_id_seq
  INCREMENT 1
  MINVALUE 1
  MAXVALUE 9223372036854775807
  START 1
  CACHE 1;

COMMIT;
