-- The Schemaverse 
-- Trophy Creation Script
-- Created by Josh McDougall
--
-- Trophy Goal: Maintained control over more than the average number of planets

INSERT INTO trophy (name, description, weight, run_order, script_declarations, script ) 
VALUES(

-- Trophy Common Name
'Solid Leadership' ,

-- Trophy Description
'Had an empire at least larger than average during the round'::TEXT,

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
FOR players IN 
	SELECT 
		player.id as player_id
	FROM 
		player,
		(SELECT player_round_stats.player_id,	
			CASE WHEN player_round_stats.planets_lost = 0 THEN player_round_stats.planets_conquered 
				ELSE (player_round_stats.planets_conquered / player_round_stats.planets_lost) END as player_planets 
		FROM player_round_stats WHERE player_round_stats.round_id = _round_id) prs,
		(SELECT CASE WHEN round_stats.avg_planets_lost = 0 THEN round_stats.avg_planets_conquered
			 ELSE (round_stats.avg_planets_conquered/round_stats.avg_planets_lost) END as avg_planets
		FROM round_stats WHERE round_stats.round_id=_round_id) rs  
	WHERE 
		player.id=prs.player_id AND 
		prs.player_planets > rs.avg_planets 

LOOP
		winner.round  := _round_id; 
		winner.trophy_id := this_trophy_id; 
		winner.player_id := players.player_id; 
		RETURN NEXT winner;
END LOOP;
'
);

