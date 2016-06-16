-- Deploy view-current_stats

BEGIN;


CREATE OR REPLACE VIEW current_stats AS 
 SELECT ( SELECT tic_seq.last_value
           FROM tic_seq) AS current_tic, 
    count(player.id) AS total_players, 
    ( SELECT count(online_players.id) AS count
           FROM online_players) AS online_players, 
    ( SELECT count(ship.id) AS count
           FROM ship) AS total_ships, 
    ceil(avg(( SELECT count(ship.id) AS count
           FROM ship
          WHERE ship.player_id = player.id
          GROUP BY ship.player_id))) AS avg_ships, 
    ( SELECT sum(player.fuel_reserve) AS sum
           FROM player
          WHERE player.id <> 0) AS total_fuel_reserves, 
    ceil(( SELECT avg(player.fuel_reserve) AS avg
           FROM player
          WHERE player.id <> 0)) AS avg_fuel_reserve, 
    ( SELECT sum(player.balance) AS sum
           FROM player
          WHERE player.id <> 0) AS total_currency, 
    ceil(( SELECT avg(player.balance) AS avg
           FROM player
          WHERE player.id <> 0)) AS avg_balance, 
    ( SELECT round_seq.last_value
           FROM round_seq) AS current_round
   FROM player;

COMMIT;
