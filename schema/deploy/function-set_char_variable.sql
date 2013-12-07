-- Deploy function-set_char_variable
-- requires: view-public_variable

BEGIN;


CREATE OR REPLACE FUNCTION SET_CHAR_VARIABLE(variable_name character varying, new_value character varying) RETURNS character varying AS 
$set_char_variable$
BEGIN
	SET search_path to public;
        IF (SELECT count(*) FROM variable WHERE name=variable_name AND player_id=GET_PLAYER_ID(SESSION_USER)) = 1 THEN
                UPDATE variable SET char_value=new_value WHERE  name=variable_name AND player_id=GET_PLAYER_ID(SESSION_USER);
        ELSEIF (SELECT count(*) FROM variable WHERE name=variable_name AND player_id=0) = 1 THEN
                EXECUTE 'NOTIFY ' || get_player_error_channel() ||', ''Cannot update a system variable'';';
        ELSE
                INSERT INTO variable VALUES(variable_name,'f',0,new_value,'',GET_PLAYER_ID(SESSION_USER));
        END IF;

        RETURN new_value;
END $set_char_variable$ SECURITY definer LANGUAGE plpgsql;

COMMIT;
