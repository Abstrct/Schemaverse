-- Schemaverse
-- Nuke Item v0.1
-- Created by Josh McDougall


INSERT INTO item VALUES('NUKE','Nuclear Weapon', 'explosions are fun'::TEXT, ' SELECT ITEM_NUKE(location_x, location_y);'::TEXT);

CREATE OR REPLACE FUNCTION ITEM_NUKE(hit_location_x integer, hit_location_y integer) RETURNS boolean AS $item_nuke$
DECLARE
	current_inventory 	integer;
	blast_radius 		integer;
	
	event_id	integer;
	patron		RECORD;
BEGIN
	--decide on how awesome the item is
	blast_radius := 100;

	--check to see if the user actually has it
	SELECT quantity INTO current_inventory FROM player_inventory WHERE GET_PLAYER_ID(SESSION_USER) AND item_name='NUKE';
	IF quantity > 0 THEN
		--revome the item from the inventory
		UPDATE player_inventory SET quantity=quantity-1 WHERE GET_PLAYER_ID(SESSION_USER) AND item_name='NUKE';
		
		--do what the item is suppose to do
		UPDATE ship SET future_health=0 WHERE 
			(location_x between (hit_location_x-blast_radius) and (hit_location_x+blast_radius)) 
				AND
			(location_y between (hit_location_y-blast_radius) and (hit_location_y+blast_radius)) 
		
		DELETE FROM planet WHERE 
			(location_x between (hit_location_x-blast_radius) and (hit_location_x+blast_radius)) 
				AND
			(location_y between (hit_location_y-blast_radius) and (hit_location_y+blast_radius)) 
		
		--tell everybody involved about it
		event_id = NEXTVAL('event_id_seq');
		INSERT INTO event(id, description, tic) VALUES(event_id, SESSION_USER || ' Attacked location (' || hit_location_x || ',' || hit_location_y || ') with a Nuclear Weapon causing damage to your ship'::TEXT, (SELECT last_value FROM tic_seq));
		INSERT INTO event_patron VALUES(event_id, GET_PLAYER_ID(SESSION_USER));
		FOR patron IN SELECT DISTINCT player_id FROM ship WHERE
			(location_x between (hit_location_x-blast_radius) and (hit_location_x+blast_radius)) 
				AND
			(location_y between (hit_location_y-blast_radius) and (hit_location_y+blast_radius)) 
			LOOP
			INSERT INTO event_patron VALUES(event_id, patron.player_id);
		END LOOP;
		
		--return true since it all worked out.
		RETURN 't';
		
	ELSE
		--tell them why they suck
		INSERT INTO error_log(player_id, error) VALUES(GET_PLAYER_ID(SESSION_USER), 'You do not currently have any nuclear bombs in your 
inventory'::TEXT);
		--and fail
		RETURN 'f';
	END IF;
	
END
$item_nuke$ LANGUAGE plpgsql SECURITY DEFINER;
