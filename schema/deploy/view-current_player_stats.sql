-- Deploy view-current_player_stats

BEGIN;


CREATE OR REPLACE VIEW current_player_stats AS 
 SELECT player.id AS player_id, player.username, 
    COALESCE(against_player.damage_taken, 0::numeric) AS damage_taken, 
    COALESCE(for_player.damage_done, 0::numeric) AS damage_done, 
    COALESCE(for_player.planets_conquered, 0::bigint) AS planets_conquered, 
    COALESCE(against_player.planets_lost, 0::bigint) AS planets_lost, 
    COALESCE(for_player.ships_built, 0::bigint) AS ships_built, 
    COALESCE(for_player.ships_lost, 0::bigint) AS ships_lost, 
    COALESCE(for_player.ship_upgrades, 0::numeric) AS ship_upgrades, 
    COALESCE((( SELECT sum(r.location <-> r2.location)::bigint AS sum
           FROM ship_flight_recorder r, ship_flight_recorder r2, ship s
          WHERE s.player_id = player.id AND r.ship_id = s.id AND r2.ship_id = r.ship_id AND r2.tic = (r.tic + 1)))::numeric, 0::numeric) AS distance_travelled, 
    COALESCE(for_player.fuel_mined, 0::numeric) AS fuel_mined
   FROM player
   LEFT JOIN ( SELECT sum(
                CASE
                    WHEN event.action = 'ATTACK'::bpchar THEN event.descriptor_numeric
                    ELSE NULL::numeric
                END) AS damage_done, 
            count(
                CASE
                    WHEN event.action = 'CONQUER'::bpchar THEN COALESCE(event.descriptor_numeric, 0::numeric)
                    ELSE NULL::numeric
                END) AS planets_conquered, 
            count(
                CASE
                    WHEN event.action = 'BUY_SHIP'::bpchar THEN COALESCE(event.descriptor_numeric, 0::numeric)
                    ELSE NULL::numeric
                END) AS ships_built, 
            count(
                CASE
                    WHEN event.action = 'EXPLODE'::bpchar THEN COALESCE(event.descriptor_numeric, 0::numeric)
                    ELSE NULL::numeric
                END) AS ships_lost, 
            sum(
                CASE
                    WHEN event.action = 'UPGRADE_SHIP'::bpchar THEN event.descriptor_numeric
                    ELSE NULL::numeric
                END) AS ship_upgrades, 
            sum(
                CASE
                    WHEN event.action = 'MINE_SUCCESS'::bpchar THEN event.descriptor_numeric
                    ELSE NULL::numeric
                END) AS fuel_mined, 
            event.player_id_1
           FROM event event
          WHERE event.action = ANY (ARRAY['ATTACK'::bpchar, 'CONQUER'::bpchar, 'BUY_SHIP'::bpchar, 'EXPLODE'::bpchar, 'UPGRADE_SHIP'::bpchar, 'MINE_SUCCESS'::bpchar])
          GROUP BY event.player_id_1) for_player ON for_player.player_id_1 = player.id
   LEFT JOIN ( SELECT sum(
           CASE
               WHEN event.action = 'ATTACK'::bpchar THEN event.descriptor_numeric
               ELSE NULL::numeric
           END) AS damage_taken, 
       count(
           CASE
               WHEN event.action = 'CONQUER'::bpchar THEN COALESCE(event.descriptor_numeric, 0::numeric)
               ELSE NULL::numeric
           END) AS planets_lost, 
       event.player_id_2
      FROM event event
     WHERE event.action = ANY (ARRAY['ATTACK'::bpchar, 'CONQUER'::bpchar])
     GROUP BY event.player_id_2) against_player ON against_player.player_id_2 = player.id
  WHERE player.id <> 0;


COMMIT;
