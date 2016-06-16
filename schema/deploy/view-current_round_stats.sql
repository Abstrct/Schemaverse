-- Deploy view-current_round_stats

BEGIN;


CREATE OR REPLACE VIEW current_round_stats AS 
 SELECT round.round_id, 
    COALESCE(avg(
        CASE
            WHEN against_player.action = 'ATTACK'::bpchar THEN COALESCE(against_player.sum, 0::numeric)
            ELSE NULL::numeric
        END), 0::numeric)::integer AS avg_damage_taken, 
    COALESCE(avg(
        CASE
            WHEN for_player.action = 'ATTACK'::bpchar THEN COALESCE(for_player.sum, 0::numeric)
            ELSE NULL::numeric
        END), 0::numeric)::integer AS avg_damage_done, 
    COALESCE(avg(
        CASE
            WHEN for_player.action = 'CONQUER'::bpchar THEN COALESCE(for_player.count, 0::bigint)
            ELSE NULL::bigint
        END), 0::numeric)::integer AS avg_planets_conquered, 
    COALESCE(avg(
        CASE
            WHEN against_player.action = 'CONQUER'::bpchar THEN COALESCE(against_player.count, 0::bigint)
            ELSE NULL::bigint
        END), 0::numeric)::integer AS avg_planets_lost, 
    COALESCE(avg(
        CASE
            WHEN for_player.action = 'BUY_SHIP'::bpchar THEN COALESCE(for_player.count, 0::bigint)
            ELSE NULL::bigint
        END), 0::numeric)::integer AS avg_ships_built, 
    COALESCE(avg(
        CASE
            WHEN for_player.action = 'EXPLODE'::bpchar THEN COALESCE(for_player.count, 0::bigint)
            ELSE NULL::bigint
        END), 0::numeric)::integer AS avg_ships_lost, 
    COALESCE(avg(
        CASE
            WHEN for_player.action = 'UPGRADE_SHIP'::bpchar THEN COALESCE(for_player.sum, 0::numeric)
            ELSE NULL::numeric
        END), 0::numeric)::bigint AS avg_ship_upgrades, 
    COALESCE(avg(
        CASE
            WHEN for_player.action = 'MINE_SUCCESS'::bpchar THEN COALESCE(for_player.sum, 0::numeric)
            ELSE NULL::numeric
        END), 0::numeric)::bigint AS avg_fuel_mined, 
    ( SELECT avg(prs.distance_travelled) AS avg
           FROM player_round_stats prs
          WHERE prs.round_id = round.round_id) AS avg_distance_travelled
   FROM ( SELECT round_seq.last_value AS round_id
           FROM round_seq) round
   LEFT JOIN ( SELECT ( SELECT round_seq.last_value AS round_id
                   FROM round_seq) AS round_id, 
            event.action, 
                CASE
                    WHEN event.action = ANY (ARRAY['ATTACK'::bpchar, 'UPGRADE_SHIP'::bpchar, 'MINE_SUCCESS'::bpchar]) THEN sum(COALESCE(event.descriptor_numeric, 0::numeric))
                    ELSE NULL::numeric
                END AS sum, 
                CASE
                    WHEN event.action = ANY (ARRAY['BUY_SHIP'::bpchar, 'EXPLODE'::bpchar, 'CONQUER'::bpchar]) THEN count(*)
                    ELSE NULL::bigint
                END AS count
           FROM event event
          WHERE event.action = ANY (ARRAY['ATTACK'::bpchar, 'CONQUER'::bpchar, 'BUY_SHIP'::bpchar, 'EXPLODE'::bpchar, 'UPGRADE_SHIP'::bpchar, 'MINE_SUCCESS'::bpchar])
          GROUP BY event.player_id_1, event.action) for_player ON for_player.round_id = round.round_id
   LEFT JOIN ( SELECT ( SELECT round_seq.last_value AS round_id
              FROM round_seq) AS round_id, 
       event.action, 
           CASE
               WHEN event.action = 'ATTACK'::bpchar THEN sum(COALESCE(event.descriptor_numeric, 0::numeric))
               ELSE NULL::numeric
           END AS sum, 
           CASE
               WHEN event.action = 'CONQUER'::bpchar THEN count(*)
               ELSE NULL::bigint
           END AS count
      FROM event event
     WHERE event.action = ANY (ARRAY['ATTACK'::bpchar, 'CONQUER'::bpchar])
     GROUP BY event.player_id_2, event.action) against_player ON against_player.round_id = round.round_id
  GROUP BY round.round_id;

COMMIT;
