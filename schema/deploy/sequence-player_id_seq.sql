-- Deploy sequence-player_id_seq
-- requires: table-player

BEGIN;

CREATE SEQUENCE player_id_seq
  INCREMENT 1
  MINVALUE 1
  MAXVALUE 9223372036854775807
  START 1
  CACHE 1;

COMMIT;
