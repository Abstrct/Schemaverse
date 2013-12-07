-- Deploy trigger-create_ship
-- requires: table-ship

BEGIN;


CREATE OR REPLACE FUNCTION create_ship()
  RETURNS trigger AS
$BODY$
BEGIN
	--CHECK SHIP STATS
	NEW.current_health = 100; 
	NEW.max_health = 100;
	NEW.current_fuel = 100; 
	NEW.max_fuel = 100;
	NEW.max_speed = 1000;

	IF ((SELECT COUNT(*) FROM ship WHERE player_id=NEW.player_id AND NOT destroyed) > 2000 ) THEN
		EXECUTE 'NOTIFY ' || get_player_error_channel() ||', ''A player can only have 2000 ships in their fleet for this round'';';
		RETURN NULL;
	END IF; 

	IF (LEAST(NEW.attack, NEW.defense, NEW.engineering, NEW.prospecting) < 0 ) THEN
		EXECUTE 'NOTIFY ' || get_player_error_channel() ||', ''When creating a new ship, Attack Defense Engineering and Prospecting cannot be values lower than zero'';';
		RETURN NULL;
	END IF; 

	IF (NEW.attack + NEW.defense + NEW.engineering + NEW.prospecting) > 20 THEN
		EXECUTE 'NOTIFY ' || get_player_error_channel() ||', ''When creating a new ship, the following must be true (Attack + Defense + Engineering + Prospecting) > 20'';';
		RETURN NULL;
	END IF; 

	
	--Backwards compatibility
	IF NEW.location IS NULL THEN
		NEW.location := POINT(NEW.location_x, NEW.location_y);
	ELSE
		NEW.location_x := NEW.location[0];
		NEW.location_y := NEW.location[1];
	END IF;
	
	IF not exists (select 1 from planets p where p.location ~= NEW.location and p.conqueror_id = NEW.player_id) then
		SELECT location INTO NEW.location from planets where conqueror_id=NEW.player_id limit 1;
		NEW.location_x := NEW.location[0];
		NEW.location_y := NEW.location[1];
		EXECUTE 'NOTIFY ' || get_player_error_channel() ||', ''New ship MUST be created on a planet your player has conquered'';';
		--RETURN NULL;
	END IF;

	IF NEW.location is null THEN
		EXECUTE 'NOTIFY ' || get_player_error_channel() ||', ''Lost all your planets. Unable to create new ships.'';';
		RETURN NULL;
	END IF;
	--CHARGE ACCOUNT	
	IF NOT CHARGE('SHIP', 1) THEN 
		EXECUTE 'NOTIFY ' || get_player_error_channel() ||', ''Not enough funds to purchase ship'';';
		RETURN NULL;
	END IF;

	NEW.last_move_tic := (SELECT last_value FROM tic_seq); 


	RETURN NEW; 
END
$BODY$
  LANGUAGE plpgsql VOLATILE SECURITY DEFINER
  COST 100;

CREATE TRIGGER CREATE_SHIP BEFORE INSERT ON ship
  FOR EACH ROW EXECUTE PROCEDURE CREATE_SHIP(); 

COMMIT;
