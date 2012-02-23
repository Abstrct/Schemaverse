-- The Schemaverse 
-- Trophy Creation Script
-- Created by Josh McDougall
--
-- Trophy Goal: Smaller Fleet Size than average

INSERT INTO trophy (name, description, weight, run_order, script_declarations, script ) 
VALUES(

-- Trophy Common Name
'The Annoyance' ,

-- Trophy Description
'The players fleet size is less than the average'::TEXT,

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
		player.id as player_id
	FROM 
		player,
		(SELECT player_round_stats.player_id,	
			ships_built-ships_lost as player_ships 
		FROM player_round_stats WHERE player_round_stats.round_id = _round_id) prs,
		(SELECT avg_ships_built-avg_ships_lost as avg_ships 
		FROM round_stats WHERE round_stats.round_id=_round_id) rs  
	WHERE 
		player.id=prs.player_id AND 
		prs.player_ships < rs.avg_ships

LOOP
		winner.round  := _round_id; 
		winner.trophy_id := this_trophy_id; 
		winner.player_id := players.player_id; 
		RETURN NEXT winner;
END LOOP;
'
);

