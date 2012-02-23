-- The Schemaverse 
-- Trophy Creation Script
-- Created by Josh McDougall
--
-- Trophy Goal: First Blood

INSERT INTO trophy (name, description, weight, run_order, script_declarations, script ) 
VALUES(

-- Trophy Common Name
'First Blood' ,

-- Trophy Description
'First attack of the round!'::TEXT,

-- Weight
-- This is the amount of points the trophy is worth. Can be any value between -32768 to +32767
100,

-- Run Order
-- This is the order the trophy will be calculated in (In ascending order). 
-- Unless the trophy relies on the amount of other trophies won, this should likely be 0
0, 

-- Trophy Script Definition
-- DECLARE
'
players RECORD; 
',
--BEGIN
'

IF _round_id = this_round THEN
	FOR players IN 
		SELECT 
			player_id_1 
		FROM 
			event 
		WHERE 
			action=''ATTACK'' 
		ORDER BY id ASC LIMIT 1
	LOOP
		winner.round := this_round; 
		winner.trophy_id := this_trophy_id; 
		winner.player_id := players.player_id_1; 
		RETURN NEXT winner;
	END LOOP;
ELSE
	FOR players IN 
		SELECT 
			player_id_1 
		FROM 
			event_archive 
		WHERE 
			action=''ATTACK''
			AND round_id=_round_id 
		ORDER BY event_id ASC LIMIT 1
	LOOP
		winner.round := _round_id; 
		winner.trophy_id := this_trophy_id; 
		winner.player_id := players.player_id_1; 
		RETURN NEXT winner;
	END LOOP;

END IF;
'
);

