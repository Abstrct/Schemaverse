-- Deploy function-upgrade
-- requires: table-ship
-- requires: table-player
-- requires: function-charge

BEGIN;


CREATE OR REPLACE FUNCTION upgrade(reference_id integer, code character varying, quantity integer)
  RETURNS boolean AS
$BODY$
DECLARE 

	ship_value integer;
	
BEGIN
	SET search_path to public;
	IF code = 'SHIP' THEN
		EXECUTE 'NOTIFY ' || get_player_error_channel() ||', ''You cant upgrade ship into ship..Try to insert in my_ships'';';
		RETURN FALSE;
	END IF;
	IF code = 'FLEET_RUNTIME' THEN

		IF (SELECT sum(runtime) FROM fleet WHERE player_id=GET_PLAYER_ID(SESSION_USER)) > '0 minutes'::interval THEN
			IF NOT CHARGE(code, quantity) THEN
				EXECUTE 'NOTIFY ' || get_player_error_channel() ||', ''Not enough funds to increase fleet runtime'';';
				RETURN FALSE;
			END IF;
		ELSEIF quantity > 1 THEN
			IF NOT CHARGE(code, quantity-1) THEN
				EXECUTE 'NOTIFY ' || get_player_error_channel() ||', ''Not enough funds to increase fleet runtime'';';
				RETURN FALSE;
			END IF;
		END IF;
	
		UPDATE fleet SET runtime=runtime + (quantity || ' minute')::interval where id=reference_id;

		INSERT INTO event(action, player_id_1, referencing_id, public, tic)
			VALUES('FLEET',GET_PLAYER_ID(SESSION_USER), reference_id , 'f',(SELECT last_value FROM tic_seq));
		RETURN TRUE;

	END IF;

	IF code = 'REFUEL' THEN
		EXECUTE 'NOTIFY ' || get_player_error_channel() ||', ''Please use REFUEL_SHIP(ship_id) to refuel a ship now.'';';
		RETURN FALSE;

	END IF;


	IF code = 'RANGE' THEN
		SELECT range INTO ship_value FROM ship WHERE id=reference_id;
		IF (ship_value + quantity) > GET_NUMERIC_VARIABLE('MAX_SHIP_RANGE') THEN
			EXECUTE 'NOTIFY ' || get_player_error_channel() ||', ''The range of a ship cannot exceed the MAX_SHIP_RANGE system value of '|| GET_NUMERIC_VARIABLE('MAX_SHIP_RANGE')||''';';
			RETURN FALSE;
		ELSE
			IF NOT CHARGE(code, quantity) THEN
				EXECUTE 'NOTIFY ' || get_player_error_channel() ||', ''Not enough funds to perform upgrade'';';
				RETURN FALSE;
			END IF;			
			UPDATE ship SET range=(range+quantity) WHERE id=reference_id ;
		END IF;
	ELSEIF code = 'MAX_SPEED' THEN
		SELECT max_speed INTO ship_value FROM ship WHERE id=reference_id;
		IF (ship_value + quantity) > GET_NUMERIC_VARIABLE('MAX_SHIP_SPEED') THEN
			EXECUTE 'NOTIFY ' || get_player_error_channel() ||', ''The max speed of a ship cannot exceed the MAX_SHIP_SPEED system value of '|| GET_NUMERIC_VARIABLE('MAX_SHIP_SPEED')||''';';
			RETURN FALSE;
		ELSE
			IF NOT CHARGE(code, quantity) THEN
				EXECUTE 'NOTIFY ' || get_player_error_channel() ||', ''Not enough funds to perform upgrade'';';
				RETURN FALSE;
			END IF;			
			UPDATE ship SET max_speed=(max_speed+quantity) WHERE id=reference_id ;
		END IF;
	ELSEIF code = 'MAX_HEALTH' THEN
		SELECT max_health INTO ship_value FROM ship WHERE id=reference_id;
		IF (ship_value + quantity) > GET_NUMERIC_VARIABLE('MAX_SHIP_HEALTH') THEN
			EXECUTE 'NOTIFY ' || get_player_error_channel() ||', ''The max health of a ship cannot exceed the MAX_SHIP_HEALTH system value of '|| GET_NUMERIC_VARIABLE('MAX_SHIP_HEALTH')||''';';
			RETURN FALSE;
		ELSE
			IF NOT CHARGE(code, quantity) THEN
				EXECUTE 'NOTIFY ' || get_player_error_channel() ||', ''Not enough funds to perform upgrade'';';
				RETURN FALSE;
			END IF;	
			UPDATE ship SET max_health=(max_health+quantity) WHERE id=reference_id ;
		END IF;
	ELSEIF code = 'MAX_FUEL' THEN
		SELECT max_fuel INTO ship_value FROM ship WHERE id=reference_id;
		IF (ship_value + quantity) > GET_NUMERIC_VARIABLE('MAX_SHIP_FUEL') THEN
			EXECUTE 'NOTIFY ' || get_player_error_channel() ||', ''The max fuel of a ship cannot exceed the MAX_SHIP_FUEL system value of '|| GET_NUMERIC_VARIABLE('MAX_SHIP_FUEL')||''';';
			RETURN FALSE;
		ELSE
			IF NOT CHARGE(code, quantity) THEN
				EXECUTE 'NOTIFY ' || get_player_error_channel() ||', ''Not enough funds to perform upgrade'';';
				RETURN FALSE;
			END IF;	
			UPDATE ship SET max_fuel=(max_fuel+quantity) WHERE id=reference_id ;
		END IF;
	ELSE
		SELECT (attack+defense+prospecting+engineering) INTO ship_value FROM ship WHERE id=reference_id;
		IF (ship_value + quantity) > GET_NUMERIC_VARIABLE('MAX_SHIP_SKILL') THEN
			EXECUTE 'NOTIFY ' || get_player_error_channel() ||', ''The total skill of a ship cannot exceed the MAX_SHIP_SKILL system value of '|| GET_NUMERIC_VARIABLE('MAX_SHIP_SKILL')||''';';
			RETURN FALSE;
		ELSE
			IF NOT CHARGE(code, quantity) THEN
				EXECUTE 'NOTIFY ' || get_player_error_channel() ||', ''Not enough funds to perform upgrade'';';
				RETURN FALSE;
			END IF;		
			IF code = 'ATTACK' THEN
				UPDATE ship SET attack=(attack+quantity) WHERE id=reference_id ;
			ELSEIF code = 'DEFENSE' THEN
				UPDATE ship SET defense=(defense+quantity) WHERE id=reference_id ;
			ELSEIF code = 'PROSPECTING' THEN
				UPDATE ship SET prospecting=(prospecting+quantity) WHERE id=reference_id ;
			ELSEIF code = 'ENGINEERING' THEN
				UPDATE ship SET engineering=(engineering+quantity) WHERE id=reference_id ;	
			END IF;
		END IF;
	
	END IF;	

	INSERT INTO event(action, player_id_1, ship_id_1, descriptor_numeric,descriptor_string, public, tic)
	VALUES('UPGRADE_SHIP',GET_PLAYER_ID(SESSION_USER), reference_id , quantity, code, 'f',(SELECT last_value FROM tic_seq));

	RETURN TRUE;
END 
$BODY$
  LANGUAGE plpgsql VOLATILE SECURITY DEFINER
  COST 100;
COMMIT;
