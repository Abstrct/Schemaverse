-- The Schemaverse 
-- Trophy Creation Script
-- Created by Josh McDougall
--
-- Trophy Goal:  Below Average Upgrades

INSERT INTO trophy (name, description, weight, run_order, script_declarations, script ) 
VALUES(

-- Trophy Common Name
'Penny Pincher' ,

-- Trophy Description
'Could not provide their fleet with the equipment they need'::TEXT,

-- Weight
-- This is the amount of points the trophy is worth. Can be any value between -32768 to +32767
-500,

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
		player_round_stats.ship_upgrades < round_stats.avg_ship_upgrades
LOOP
		winner.round  := _round_id; 
		winner.trophy_id := this_trophy_id; 
		winner.player_id := players.player_id; 
		RETURN NEXT winner;
END LOOP;
'
);

