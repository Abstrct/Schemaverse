-- Schemaverse
-- Big Screen Improvement Item v0.1
-- Created by Josh McDougall

INSERT INTO item VALUES('BIG_SCREEN_IMPROVEMENT','A big new screen', 'Increases the range of a ship'::TEXT, ' SELECT 
ITEM_BIG_SCREEN_IMPROVEMENT(ship_id);'::TEXT);

CREATE OR REPLACE FUNCTION ITEM_BIG_SCREEN_IMPROVEMENT(ship_id integer) RETURNS boolean AS $item_big_screen_improvement$
DECLARE
	current_inventory 	integer;
	improvement_amount	integer;
	
	event_id	integer;
BEGIN
	--decide on how awesome the item is
	improvement_amount := 50;

	--check to see if the user actually has it	
	SELECT quantity INTO current_inventory FROM player_inventory WHERE GET_PLAYER_ID(SESSION_USER) AND item_name='BIG_SCREEN_IMPROVEMENT';
	IF quantity > 0 THEN
		--revome the item from the inventory
		UPDATE player_inventory SET quantity=quantity-1 WHERE GET_PLAYER_ID(SESSION_USER) AND item_name='BIG_SCREEN_IMPROVEMENT';
		
		--do what the item is suppose to do
		UPDATE ship SET range=range+improvement_amount WHERE id=ship_id;
		
		--tell everybody involved about it
		event_id = NEXTVAL('event_id_seq');
		INSERT INTO event(id, description, tic) VALUES(event_id, SESSION_USER || ' upgraded his ships range by'|| improvement_amount::TEXT, (SELECT last_value FROM tic_seq));
		INSERT INTO event_patron VALUES(event_id, GET_PLAYER_ID(SESSION_USER));
		
		
		--return true since it all worked out. 
		RETURN 't';
		
	ELSE
		--tell them why they suck
		INSERT INTO error_log(player_id, error) VALUES(GET_PLAYER_ID(SESSION_USER), 'You do not currently have any big screens in your inventory 
:('::TEXT);
		--and fail
		RETURN 'f';
	END IF;
	
END
$item_big_screen_improvement$ LANGUAGE plpgsql SECURITY DEFINER;
