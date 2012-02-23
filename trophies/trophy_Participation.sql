-- The Schemaverse 
-- Trophy Creation Script
-- Created by Josh McDougall
--
-- Trophy Goal: Participation

INSERT INTO trophy (name, description, weight, run_order, script_declarations, script ) 
VALUES(

-- Trophy Common Name
'The Participation Award' ,

-- Trophy Description
'Great work. You certainly signed up!'::TEXT,

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
winning_total bigint;
',
--BEGIN
'
winning_total := 0;

IF _round_id = this_round THEN 
	FOR players IN 
		SELECT 
			distinct player_id_1
		FROM 
			event 
	LOOP
		winner.round  := _round_id; 
		winner.trophy_id := this_trophy_id; 
		winner.player_id := players.player_id_1; 
		RETURN NEXT winner;
	END LOOP;
ELSE
	FOR players IN 
		SELECT 
			distinct player_id_1 
		FROM 
			event_archive 
		WHERE 
			round_id=_round_id
	LOOP
		winner.round  := _round_id; 
		winner.trophy_id := this_trophy_id; 
		winner.player_id := players.player_id_1; 
		RETURN NEXT winner;
	END LOOP;
END IF;
'
);

