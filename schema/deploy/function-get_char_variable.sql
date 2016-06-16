-- Deploy function-get_char_variable
-- requires: view-public_variable

BEGIN;

CREATE OR REPLACE FUNCTION GET_CHAR_VARIABLE(variable_name character varying) RETURNS character varying AS $get_char_variable$
DECLARE
	value character varying;
BEGIN
	IF CURRENT_USER = 'schemaverse' THEN
		SELECT char_value INTO value FROM variable WHERE name = variable_name and player_id=0;
	ELSE
		SELECT char_value INTO value FROM public_variable WHERE name = variable_name;
	END IF;
	RETURN value; 
END $get_char_variable$  LANGUAGE plpgsql;

COMMIT;
