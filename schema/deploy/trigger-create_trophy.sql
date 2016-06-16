-- Deploy trigger-create_trophy
-- requires: table-trophy

BEGIN;

CREATE OR REPLACE FUNCTION create_trophy()
  RETURNS trigger AS
$BODY$
BEGIN
     
	NEW.approved 	:= 'f';
	NEW.creator 	:= GET_PLAYER_ID(SESSION_USER);
	NEW.round_started := 0;

       RETURN NEW;
END
$BODY$
  LANGUAGE plpgsql VOLATILE
  COST 100;



CREATE TRIGGER create_trophy
  BEFORE INSERT
  ON trophy
  FOR EACH ROW
  EXECUTE PROCEDURE create_trophy();

COMMIT;
