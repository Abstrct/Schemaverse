-- Deploy view-trophy_case
-- requires: table-player
-- requires: table-trophy

BEGIN;

CREATE OR REPLACE VIEW trophy_case AS 
 SELECT player_trophy.player_id, 
    get_player_username(player_trophy.player_id) AS username, 
    trophy.name AS trophy, count(player_trophy.trophy_id) AS times_awarded, 
    ( SELECT t.round
           FROM player_trophy t
          WHERE t.trophy_id = player_trophy.trophy_id AND t.player_id = player_trophy.player_id
          ORDER BY t.round DESC
         LIMIT 1) AS last_round_won
   FROM trophy, player_trophy
  WHERE trophy.id = player_trophy.trophy_id
  GROUP BY player_trophy.trophy_id, trophy.name, player_trophy.player_id;

COMMIT;
