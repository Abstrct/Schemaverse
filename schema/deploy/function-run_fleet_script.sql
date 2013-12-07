-- Deploy function-run_fleet_script

BEGIN;

CREATE OR REPLACE FUNCTION run_fleet_script(id integer)
  RETURNS boolean AS
$BODY$
DECLARE
    this_fleet_script_start timestamptz;
BEGIN
    this_fleet_script_start := current_timestamp;
    BEGIN
        EXECUTE 'SELECT FLEET_SCRIPT_' || id || '()';
    EXCEPTION
	WHEN OTHERS OR QUERY_CANCELED THEN 
		PERFORM fleet_fail_event(id, SQLERRM);
		RETURN false;
    END;
    
    PERFORM fleet_success_event(id, ( timeofday()::timestamp - this_fleet_script_start )::interval) ;
    RETURN true;
END $BODY$
  LANGUAGE plpgsql VOLATILE
  COST 100;

COMMIT;
