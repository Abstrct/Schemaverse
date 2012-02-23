-- The Schemaverse 
-- Trophy Creation Script
-- Created by Josh McDougall
--
-- Trophy Goal:  Distance Covered is below average

INSERT INTO trophy (name, description, weight, run_order, script_declarations, script ) 
VALUES(

-- Trophy Common Name
'Fuel Conservationist' ,

-- Trophy Description
'Covered less distance than the average of all players in the round'::TEXT,

-- Weight
-- This is the amount of points the trophy is worth. Can be any value between -32768 to +32767
-50,

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
FOR players IN 
	SELECT 
		player_round_stats.player_id
	FROM 
		player_round_stats, round_stats 
	WHERE 
		player_round_stats.round_id = _round_id
		AND
		round_stats.round_id = _round_id
		AND
		player_round_stats.distance_travelled < round_stats.avg_distance_travelled
LOOP
		winner.round  := _round_id; 
		winner.trophy_id := this_trophy_id; 
		winner.player_id := players.player_id; 
		RETURN NEXT winner;
END LOOP;
'
);

