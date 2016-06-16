-- Deploy function-get_numeric_variable
-- requires: view-public_variable

BEGIN;

CREATE OR REPLACE FUNCTION GET_NUMERIC_VARIABLE(variable_name character varying) RETURNS integer AS $get_numeric_variable$
DECLARE
	value integer;
BEGIN
	IF CURRENT_USER = 'schemaverse' THEN
		SELECT numeric_value INTO value FROM variable WHERE name = variable_name and player_id=0;
	ELSE 
		SELECT numeric_value INTO value FROM public_variable WHERE name = variable_name;
	END IF;
	RETURN value; 
END $get_numeric_variable$  LANGUAGE plpgsql;

COMMIT;
