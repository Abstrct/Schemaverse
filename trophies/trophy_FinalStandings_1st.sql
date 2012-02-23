-- The Schemaverse 
-- Trophy Creation Script
-- Created by Josh McDougall
--
-- Trophy Goal: Final Standings - First Place

INSERT INTO trophy (name, description, weight, run_order, script_declarations, script ) 
VALUES(

-- Trophy Common Name
'Schema Supremacy' ,

-- Trophy Description
'Round champion. All hail your Schemaverse overlord'::TEXT,

-- Weight
-- This is the amount of points the trophy is worth. Can be any value between -32768 to +32767
0,

-- Run Order
-- This is the order the trophy will be calculated in (In ascending order). 
-- Unless the trophy relies on the amount of other trophies won, this should likely be 0
999, 

-- Trophy Script Definition
-- DECLARE
'
players RECORD; 
winning_total bigint;
',
--BEGIN
'
winning_total := 0;
FOR players IN 
	SELECT 
		player_trophy.player_id,
		sum(trophy.weight) as total 
	FROM 
		player_trophy, trophy 
	WHERE 
		player_trophy.round=_round_id
		AND player_trophy.trophy_id=trophy.id
	GROUP BY player_trophy.player_id
	ORDER BY total DESC
LOOP
	IF winning_total = 0 OR winning_total = players.total THEN
		winning_total := players.total; 
		winner.round  := _round_id; 
		winner.trophy_id := this_trophy_id; 
		winner.player_id := players.player_id; 
		RETURN NEXT winner;
	ELSE 
		RETURN;
	END IF;
END LOOP;

'
);

