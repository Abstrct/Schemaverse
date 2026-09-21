-- Deploy data-trophies
-- requires: table-trophy
-- requires: trigger-trophy_script_update
-- requires: event-partitioned
--
-- The 29 classic trophies from trophies/, owned by the house (player 0). The
-- trophy_script_update trigger was created disabled in 2013 and never
-- re-enabled, so approving a trophy never compiled its function. It is enabled
-- here and stays enabled: players may still INSERT proposals, and the owner
-- approves them with UPDATE trophy SET approved = true.
--
-- Generated from trophies/*.sql; edit those and regenerate rather than this.

BEGIN;

-- trophy_AverageAttackVSDamageRatio.sql
-- The Schemaverse 
-- Trophy Creation Script
-- Created by Josh McDougall
--
-- Trophy Goal: Higher Attack/Damage ratio than average

INSERT INTO trophy (creator, approved, round_started, name, description, weight, run_order, script_declarations, script)
VALUES(0, false, 0,

-- Trophy Common Name
'Honourable Combat Performance' ,

-- Trophy Description
'The players Attack done VS Damage Taken ratio is greater than the average'::TEXT,

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
			CASE WHEN player_round_stats.damage_taken = 0 THEN player_round_stats.damage_done 
				ELSE (player_round_stats.damage_done / player_round_stats.damage_taken) END as player_damage 
		FROM player_round_stats WHERE player_round_stats.round_id = _round_id) prs,
		(SELECT CASE WHEN round_stats.avg_damage_taken = 0 THEN round_stats.avg_damage_done
			 ELSE (round_stats.avg_damage_done/round_stats.avg_damage_taken) END as avg_damage 
		FROM round_stats WHERE round_stats.round_id=_round_id) rs  
	WHERE 
		player.id=prs.player_id AND 
		prs.player_damage > rs.avg_damage 

LOOP
		winner.round  := _round_id; 
		winner.trophy_id := this_trophy_id; 
		winner.player_id := players.player_id; 
		RETURN NEXT winner;
END LOOP;
'
);

-- trophy_AverageDamageDone.sql
-- The Schemaverse 
-- Trophy Creation Script
-- Created by Josh McDougall
--
-- Trophy Goal: Did more damage than the average

INSERT INTO trophy (creator, approved, round_started, name, description, weight, run_order, script_declarations, script)
VALUES(0, false, 0,

-- Trophy Common Name
'Acceptable Combat Performance' ,

-- Trophy Description
'Did better than the average attack of all players in the round'::TEXT,

-- Weight
-- This is the amount of points the trophy is worth. Can be any value between -32768 to +32767
50,

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
		player_round_stats.damage_done > round_stats.avg_damage_done
LOOP
		winner.round  := _round_id; 
		winner.trophy_id := this_trophy_id; 
		winner.player_id := players.player_id; 
		RETURN NEXT winner;
END LOOP;
'
);

-- trophy_AverageDistanceCovered.sql
-- The Schemaverse 
-- Trophy Creation Script
-- Created by Josh McDougall
--
-- Trophy Goal:  Distance Covered is greater than average

INSERT INTO trophy (creator, approved, round_started, name, description, weight, run_order, script_declarations, script)
VALUES(0, false, 0,

-- Trophy Common Name
'Scout' ,

-- Trophy Description
'Covered more distance than the average of all players in the round'::TEXT,

-- Weight
-- This is the amount of points the trophy is worth. Can be any value between -32768 to +32767
50,

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
		player_round_stats.distance_travelled > round_stats.avg_distance_travelled
LOOP
		winner.round  := _round_id; 
		winner.trophy_id := this_trophy_id; 
		winner.player_id := players.player_id; 
		RETURN NEXT winner;
END LOOP;
'
);

-- trophy_AverageFleetSize.sql
-- The Schemaverse 
-- Trophy Creation Script
-- Created by Josh McDougall
--
-- Trophy Goal: Larger Fleet Size than average

INSERT INTO trophy (creator, approved, round_started, name, description, weight, run_order, script_declarations, script)
VALUES(0, false, 0,

-- Trophy Common Name
'The Superpower' ,

-- Trophy Description
'The players fleet size is greater than the average'::TEXT,

-- Weight
-- This is the amount of points the trophy is worth. Can be any value between -32768 to +32767
50,

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
		prs.player_ships > rs.avg_ships

LOOP
		winner.round  := _round_id; 
		winner.trophy_id := this_trophy_id; 
		winner.player_id := players.player_id; 
		RETURN NEXT winner;
END LOOP;
'
);

-- trophy_AverageFuelMined.sql
-- The Schemaverse 
-- Trophy Creation Script
-- Created by Josh McDougall
--
-- Trophy Goal: Did more fuel mining than the average

INSERT INTO trophy (creator, approved, round_started, name, description, weight, run_order, script_declarations, script)
VALUES(0, false, 0,

-- Trophy Common Name
'Big Petroleum' ,

-- Trophy Description
'Did better than the average mining of all players in the round'::TEXT,

-- Weight
-- This is the amount of points the trophy is worth. Can be any value between -32768 to +32767
50,

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
		player_round_stats.fuel_mined > round_stats.avg_fuel_mined
LOOP
		winner.round  := _round_id; 
		winner.trophy_id := this_trophy_id; 
		winner.player_id := players.player_id; 
		RETURN NEXT winner;
END LOOP;
'
);

-- trophy_AveragePlanetsMaintained.sql
-- The Schemaverse 
-- Trophy Creation Script
-- Created by Josh McDougall
--
-- Trophy Goal: Maintained control over more than the average number of planets

INSERT INTO trophy (creator, approved, round_started, name, description, weight, run_order, script_declarations, script)
VALUES(0, false, 0,

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

-- trophy_BelowAverageAttackVSDamageRatio.sql
-- The Schemaverse 
-- Trophy Creation Script
-- Created by Josh McDougall
--
-- Trophy Goal: Below Attack/Damage ratio average

INSERT INTO trophy (creator, approved, round_started, name, description, weight, run_order, script_declarations, script)
VALUES(0, false, 0,

-- Trophy Common Name
'Crap Combat Performance' ,

-- Trophy Description
'The players Attack done VS Damage Taken ratio is lower than the average'::TEXT,

-- Weight
-- This is the amount of points the trophy is worth. Can be any value between -32768 to +32767
-100,

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
			CASE WHEN player_round_stats.damage_taken = 0 THEN player_round_stats.damage_done 
				ELSE (player_round_stats.damage_done / player_round_stats.damage_taken) END as player_damage 
		FROM player_round_stats WHERE player_round_stats.round_id = _round_id) prs,
		(SELECT CASE WHEN round_stats.avg_damage_taken = 0 THEN round_stats.avg_damage_done
			 ELSE (round_stats.avg_damage_done/round_stats.avg_damage_taken) END as avg_damage 
		FROM round_stats WHERE round_stats.round_id=_round_id) rs  
	WHERE 
		player.id=prs.player_id AND 
		prs.player_damage < rs.avg_damage 

LOOP
		winner.round  := _round_id; 
		winner.trophy_id := this_trophy_id; 
		winner.player_id := players.player_id; 
		RETURN NEXT winner;
END LOOP;
'
);

-- trophy_BelowAverageDamageDone.sql
-- The Schemaverse 
-- Trophy Creation Script
-- Created by Josh McDougall
--
-- Trophy Goal: Did less damage than the average

INSERT INTO trophy (creator, approved, round_started, name, description, weight, run_order, script_declarations, script)
VALUES(0, false, 0,

-- Trophy Common Name
'Unacceptable Combat Performance' ,

-- Trophy Description
'Did worse than the average attack of all players in the round'::TEXT,

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
		player_round_stats.damage_done < round_stats.avg_damage_done
LOOP
		winner.round  :=  _round_id; 
		winner.trophy_id := this_trophy_id; 
		winner.player_id := players.player_id; 
		RETURN NEXT winner;
END LOOP;
'
);

-- trophy_BelowAverageDistanceCovered.sql
-- The Schemaverse 
-- Trophy Creation Script
-- Created by Josh McDougall
--
-- Trophy Goal:  Distance Covered is below average

INSERT INTO trophy (creator, approved, round_started, name, description, weight, run_order, script_declarations, script)
VALUES(0, false, 0,

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

-- trophy_BelowAverageFleetSize.sql
-- The Schemaverse 
-- Trophy Creation Script
-- Created by Josh McDougall
--
-- Trophy Goal: Smaller Fleet Size than average

INSERT INTO trophy (creator, approved, round_started, name, description, weight, run_order, script_declarations, script)
VALUES(0, false, 0,

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

-- trophy_BelowAverageFuelMined.sql
-- The Schemaverse 
-- Trophy Creation Script
-- Created by Josh McDougall
--
-- Trophy Goal: Did less fuel mining than the average

INSERT INTO trophy (creator, approved, round_started, name, description, weight, run_order, script_declarations, script)
VALUES(0, false, 0,

-- Trophy Common Name
'Corner Gas' ,

-- Trophy Description
'Did worse than the average mining of all players in the round'::TEXT,

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
		player_round_stats.fuel_mined < round_stats.avg_fuel_mined
LOOP
		winner.round  := _round_id; 
		winner.trophy_id := this_trophy_id; 
		winner.player_id := players.player_id; 
		RETURN NEXT winner;
END LOOP;
'
);

-- trophy_BelowAverageUpgrades.sql
-- The Schemaverse 
-- Trophy Creation Script
-- Created by Josh McDougall
--
-- Trophy Goal:  Below Average Upgrades

INSERT INTO trophy (creator, approved, round_started, name, description, weight, run_order, script_declarations, script)
VALUES(0, false, 0,

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

-- trophy_FinalStandings_1st.sql
-- The Schemaverse 
-- Trophy Creation Script
-- Created by Josh McDougall
--
-- Trophy Goal: Final Standings - First Place

INSERT INTO trophy (creator, approved, round_started, name, description, weight, run_order, script_declarations, script)
VALUES(0, false, 0,

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

-- trophy_FirstBlood.sql
-- The Schemaverse 
-- Trophy Creation Script
-- Created by Josh McDougall
--
-- Trophy Goal: First Blood

INSERT INTO trophy (creator, approved, round_started, name, description, weight, run_order, script_declarations, script)
VALUES(0, false, 0,

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

-- trophy_LeastConqueredPlanets.sql
-- The Schemaverse 
-- Trophy Creation Script
-- Created by Josh McDougall
--
-- Trophy Goal: Least Planets Conquered

INSERT INTO trophy (creator, approved, round_started, name, description, weight, run_order, script_declarations, script)
VALUES(0, false, 0,

-- Trophy Common Name
'No place like Home' ,

-- Trophy Description
'This player conquered the least amount of planets during the round'::TEXT,

-- Weight
-- This is the amount of points the trophy is worth. Can be any value between -32768 to +32767
-100,

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

FOR players IN 
	SELECT 
		player_id, 
		planets_conquered as total
	FROM 
		player_round_stats 
	WHERE 
		round_id=_round_id
	ORDER BY total ASC 
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

-- trophy_LeastDamageDone.sql
-- The Schemaverse 
-- Trophy Creation Script
-- Created by Josh McDougall
--
-- Trophy Goal: Least Damage Done

INSERT INTO trophy (creator, approved, round_started, name, description, weight, run_order, script_declarations, script)
VALUES(0, false, 0,

-- Trophy Common Name
'The Peacekeeper' ,

-- Trophy Description
'Maybe you should invest in defense.. or maybe you did already... This goes to the player who dealt the least damage throughout the round.'::TEXT,

-- Weight
-- This is the amount of points the trophy is worth. Can be any value between -32768 to +32767
-100,

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

FOR players IN 
	SELECT 
		player_id, 
		damage_done as total
	FROM 
		player_round_stats 
	WHERE 
		round_id=_round_id
	ORDER BY total ASC 
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

-- trophy_LeastDistanceCovered.sql
-- The Schemaverse 
-- Trophy Creation Script
-- Created by Josh McDougall
--
-- Trophy Goal: Least Distance Covered

INSERT INTO trophy (creator, approved, round_started, name, description, weight, run_order, script_declarations, script)
VALUES(0, false, 0,

-- Trophy Common Name
'Hermit' ,

-- Trophy Description
'This player travelled the least distance overall in a round.'::TEXT,

-- Weight
-- This is the amount of points the trophy is worth. Can be any value between -32768 to +32767
-200,

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

FOR players IN 
	SELECT 
		player_id, 
		distance_travelled as total
	FROM 
		player_round_stats 
	WHERE 
		round_id=_round_id
	ORDER BY total ASC 
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

-- trophy_LeastFuelMined.sql
-- The Schemaverse 
-- Trophy Creation Script
-- Created by Josh McDougall
--
-- Trophy Goal: Least Fuel Mined

INSERT INTO trophy (creator, approved, round_started, name, description, weight, run_order, script_declarations, script)
VALUES(0, false, 0,

-- Trophy Common Name
'Greenpeace' ,

-- Trophy Description
'This goes to the player who mined the least fuel throughout the round.'::TEXT,

-- Weight
-- This is the amount of points the trophy is worth. Can be any value between -32768 to +32767
-100,

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

FOR players IN 
	SELECT 
		player_id, 
		fuel_mined as total
	FROM 
		player_round_stats 
	WHERE 
		round_id=_round_id
	ORDER BY total ASC 
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

-- trophy_LeastShips.sql
-- The Schemaverse 
-- Trophy Creation Script
-- Created by Josh McDougall
--
-- Trophy Goal: Least Ships

INSERT INTO trophy (creator, approved, round_started, name, description, weight, run_order, script_declarations, script)
VALUES(0, false, 0,

-- Trophy Common Name
'Least Ships' ,

-- Trophy Description
'This player had the smallest fleet of ships in a round'::TEXT,

-- Weight
-- This is the amount of points the trophy is worth. Can be any value between -32768 to +32767
-100,

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

FOR players IN 
	SELECT 
		player_id, 
		ships_built-ships_lost as total
	FROM 
		player_round_stats 
	WHERE 
		round_id=_round_id
	ORDER BY total ASC 
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

-- trophy_MostConqueredPlanets.sql
-- The Schemaverse 
-- Trophy Creation Script
-- Created by Josh McDougall
--
-- Trophy Goal: Most Planets Conquered

INSERT INTO trophy (creator, approved, round_started, name, description, weight, run_order, script_declarations, script)
VALUES(0, false, 0,

-- Trophy Common Name
'Greatest Empire' ,

-- Trophy Description
'This player conquered the most amount of planets during the round'::TEXT,

-- Weight
-- This is the amount of points the trophy is worth. Can be any value between -32768 to +32767
200,

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

FOR players IN 
	SELECT 
		player_id, 
		planets_conquered as total
	FROM 
		player_round_stats 
	WHERE 
		round_id=_round_id
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

-- trophy_MostDamageDone.sql
-- The Schemaverse 
-- Trophy Creation Script
-- Created by Josh McDougall
--
-- Trophy Goal: Most Damage Done

INSERT INTO trophy (creator, approved, round_started, name, description, weight, run_order, script_declarations, script)
VALUES(0, false, 0,

-- Trophy Common Name
'The Space Jerk' ,

-- Trophy Description
'You might get picked on after winning this trophy. This goes to the player who dealt the most damage throughout the round.'::TEXT,

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

FOR players IN 
	SELECT 
		player_id, 
		damage_done as total
	FROM 
		player_round_stats 
	WHERE 
		round_id=_round_id
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

-- trophy_MostDamageTaken.sql
-- The Schemaverse 
-- Trophy Creation Script
-- Created by Josh McDougall
--
-- Trophy Goal: Most Damage Taken

INSERT INTO trophy (creator, approved, round_started, name, description, weight, run_order, script_declarations, script)
VALUES(0, false, 0,

-- Trophy Common Name
'The Peacekeeper''s Sidekick' ,

-- Trophy Description
'Maybe you should invest in defense.. or maybe you did already... This goes to the player who took the most damage throughout the round.'::TEXT,

-- Weight
-- This is the amount of points the trophy is worth. Can be any value between -32768 to +32767
-100,

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

FOR players IN 
	SELECT 
		player_id, 
		damage_taken as total
	FROM 
		player_round_stats 
	WHERE 
		round_id=_round_id
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

-- trophy_MostDistanceCovered.sql
-- The Schemaverse 
-- Trophy Creation Script
-- Created by Josh McDougall
--
-- Trophy Goal: Most Distance Covered

INSERT INTO trophy (creator, approved, round_started, name, description, weight, run_order, script_declarations, script)
VALUES(0, false, 0,

-- Trophy Common Name
'Discoverer' ,

-- Trophy Description
'This player travelled the furthest distance overall in a round.'::TEXT,

-- Weight
-- This is the amount of points the trophy is worth. Can be any value between -32768 to +32767
200,

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

FOR players IN 
	SELECT 
		player_id, 
		distance_travelled as total
	FROM 
		player_round_stats 
	WHERE 
		round_id=_round_id
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

-- trophy_MostFuelMined.sql
-- The Schemaverse 
-- Trophy Creation Script
-- Created by Josh McDougall
--
-- Trophy Goal: Most Fuel Mined

INSERT INTO trophy (creator, approved, round_started, name, description, weight, run_order, script_declarations, script)
VALUES(0, false, 0,

-- Trophy Common Name
'Oil Tycoon' ,

-- Trophy Description
'This goes to the player who mined the most fuel throughout the round.'::TEXT,

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

FOR players IN 
	SELECT 
		player_id, 
		fuel_mined as total
	FROM 
		player_round_stats 
	WHERE 
		round_id=_round_id
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

-- trophy_MostPlanetsLost.sql
-- The Schemaverse 
-- Trophy Creation Script
-- Created by Josh McDougall
--
-- Trophy Goal: Most Planets Lost

INSERT INTO trophy (creator, approved, round_started, name, description, weight, run_order, script_declarations, script)
VALUES(0, false, 0,

-- Trophy Common Name
'Coward' ,

-- Trophy Description
'This player lost the most amount of planets to another during the round'::TEXT,

-- Weight
-- This is the amount of points the trophy is worth. Can be any value between -32768 to +32767
-100,

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

FOR players IN 
	SELECT 
		player_id, 
		planets_lost as total
	FROM 
		player_round_stats 
	WHERE 
		round_id=_round_id
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

-- trophy_MostPowerfulShips.sql
-- The Schemaverse 
-- Trophy Creation Script
-- Created by Josh McDougall
--
-- Trophy Goal: Most Powerful Ships

INSERT INTO trophy (creator, approved, round_started, name, description, weight, run_order, script_declarations, script)
VALUES(0, false, 0,

-- Trophy Common Name
'Size Matters' ,

-- Trophy Description
'This player had the most powerful fleet of ships in a round'::TEXT,

-- Weight
-- This is the amount of points the trophy is worth. Can be any value between -32768 to +32767
200,

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

FOR players IN 
	SELECT 
		player_id, 
		ship_upgrades as total
	FROM 
		player_round_stats 
	WHERE 
		round_id=_round_id
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

-- trophy_MostShips.sql
-- The Schemaverse 
-- Trophy Creation Script
-- Created by Josh McDougall
--
-- Trophy Goal: Most Ships

INSERT INTO trophy (creator, approved, round_started, name, description, weight, run_order, script_declarations, script)
VALUES(0, false, 0,

-- Trophy Common Name
'Largest Fleet' ,

-- Trophy Description
'This player had the largest fleet of ships in a round'::TEXT,

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

FOR players IN 
	SELECT 
		player_id, 
		ships_built-ships_lost as total
	FROM 
		player_round_stats 
	WHERE 
		round_id=_round_id
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

-- trophy_MostShipsDestroyed.sql
-- The Schemaverse 
-- Trophy Creation Script
-- Created by Josh McDougall
--
-- Trophy Goal: Most Ships Destroyed

INSERT INTO trophy (creator, approved, round_started, name, description, weight, run_order, script_declarations, script)
VALUES(0, false, 0,

-- Trophy Common Name
'Space Lemmings' ,

-- Trophy Description
'Had the most ships destroyed within a round'::TEXT,

-- Weight
-- This is the amount of points the trophy is worth. Can be any value between -32768 to +32767
-100,

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

FOR players IN 
	SELECT 
		player_id, 
		ships_lost as total
	FROM 
		player_round_stats 
	WHERE 
		round_id=_round_id
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

-- trophy_Participation.sql
-- The Schemaverse 
-- Trophy Creation Script
-- Created by Josh McDougall
--
-- Trophy Goal: Participation

INSERT INTO trophy (creator, approved, round_started, name, description, weight, run_order, script_declarations, script)
VALUES(0, false, 0,

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

ALTER TABLE trophy ENABLE TRIGGER trophy_script_update;

-- Approving compiles trophy_script_<id>(round) for each one.
UPDATE trophy SET approved = true WHERE creator = 0 AND NOT approved;

COMMIT;
