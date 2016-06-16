-- Deploy trigger-variable_insert
-- requires: table-variable

BEGIN;

CREATE OR REPLACE FUNCTION variable_insert()
  RETURNS trigger AS
$BODY$
        BEGIN
        IF (SELECT count(*) FROM variable WHERE player_id=0 and name=NEW.name) = 1 THEN
                RETURN OLD;
        ELSE
               RETURN NEW;
        END IF;
END $BODY$
  LANGUAGE plpgsql VOLATILE;


CREATE TRIGGER VARIABLE_INSERT BEFORE INSERT ON variable
  FOR EACH ROW EXECUTE PROCEDURE VARIABLE_INSERT();

COMMIT;
