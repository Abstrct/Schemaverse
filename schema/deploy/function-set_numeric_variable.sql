-- Deploy function-set_numeric_variable
-- requires: view-public_variable

BEGIN;

CREATE OR REPLACE FUNCTION SET_NUMERIC_VARIABLE(variable_name character varying, new_value integer) RETURNS integer AS $set_numeric_variable$
BEGIN
	SET search_path to public;
	IF (SELECT count(*) FROM variable WHERE name=variable_name AND player_id=GET_PLAYER_ID(SESSION_USER)) = 1 THEN
		UPDATE variable SET numeric_value=new_value WHERE  name=variable_name AND player_id=GET_PLAYER_ID(SESSION_USER);
	ELSEIF (SELECT count(*) FROM variable WHERE name=variable_name AND player_id=0) = 1 THEN
		EXECUTE 'NOTIFY ' || get_player_error_channel() ||', ''Cannot update a system variable'';';
	ELSE 
		INSERT INTO variable VALUES(variable_name,'f',new_value,'','',GET_PLAYER_ID(SESSION_USER));
	END IF;
	RETURN new_value; 
END $set_numeric_variable$ SECURITY definer LANGUAGE plpgsql ;

COMMIT;
