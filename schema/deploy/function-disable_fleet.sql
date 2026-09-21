-- Deploy function-disable_fleet
-- requires: function-disable_fleet@v1.0
--
-- Rework: players have no UPDATE on the fleet table, so as a SECURITY INVOKER
-- function this only ever worked for the owner. Make it SECURITY DEFINER with
-- an ownership check keyed on SESSION_USER (CURRENT_USER is always the owner
-- inside a definer function, so the old CURRENT_USER test would have let any
-- player disable any fleet).

BEGIN;

CREATE OR REPLACE FUNCTION disable_fleet(fleet_id integer)
  RETURNS boolean AS
$BODY$
BEGIN
	IF SESSION_USER = 'schemaverse' THEN
		UPDATE fleet SET enabled='f' WHERE id=fleet_id;
	ELSE
		UPDATE fleet SET enabled='f' WHERE id=fleet_id AND player_id=GET_PLAYER_ID(SESSION_USER);
	END IF;
	RETURN FOUND;
END $BODY$
  LANGUAGE plpgsql VOLATILE SECURITY DEFINER
  SET search_path = public, pg_temp
  COST 100;

COMMIT;
