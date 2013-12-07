-- Deploy data-schemaverse_player
-- requires: table-player

BEGIN;

INSERT INTO player(id, username, password, fuel_reserve, balance) VALUES(0,'schemaverse','nopass',100000,100000); 

COMMIT;
