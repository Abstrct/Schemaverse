-- Revert event-partitioned
-- Restores the flat event table (with its foreign keys to ship), the
-- id_dealer trigger, the original views, and the RLS policy from rls-policies.

BEGIN;

DROP MATERIALIZED VIEW player_stats;
DROP VIEW current_round_stats;
DROP VIEW current_player_stats;
DROP VIEW my_events;
DROP VIEW event_archive;

ALTER TABLE event RENAME TO event_partitioned;
ALTER INDEX event_pkey RENAME TO event_partitioned_pkey;
ALTER INDEX event_player RENAME TO event_partitioned_player;
ALTER INDEX event_toc_index RENAME TO event_partitioned_toc_index;

CREATE TABLE event
(
  id integer NOT NULL,
  action character(30) NOT NULL,
  player_id_1 integer,
  ship_id_1 integer,
  player_id_2 integer,
  ship_id_2 integer,
  referencing_id integer,
  descriptor_numeric numeric,
  descriptor_string character varying,
  location_x integer,
  location_y integer,
  public boolean DEFAULT false,
  tic integer NOT NULL,
  toc timestamp without time zone NOT NULL DEFAULT now(),
  location point,
  CONSTRAINT event_pkey PRIMARY KEY (id),
  CONSTRAINT event_action_fkey FOREIGN KEY (action)
      REFERENCES action (name) MATCH SIMPLE
      ON UPDATE NO ACTION ON DELETE NO ACTION,
  CONSTRAINT event_player_id_1_fkey FOREIGN KEY (player_id_1)
      REFERENCES player (id) MATCH SIMPLE
      ON UPDATE NO ACTION ON DELETE NO ACTION,
  CONSTRAINT event_player_id_2_fkey FOREIGN KEY (player_id_2)
      REFERENCES player (id) MATCH SIMPLE
      ON UPDATE NO ACTION ON DELETE NO ACTION,
  CONSTRAINT event_ship_id_1_fkey FOREIGN KEY (ship_id_1)
      REFERENCES ship (id) MATCH SIMPLE
      ON UPDATE NO ACTION ON DELETE NO ACTION,
  CONSTRAINT event_ship_id_2_fkey FOREIGN KEY (ship_id_2)
      REFERENCES ship (id) MATCH SIMPLE
      ON UPDATE NO ACTION ON DELETE NO ACTION
);


INSERT INTO event (id, action, player_id_1, ship_id_1, player_id_2, ship_id_2, referencing_id, descriptor_numeric, descriptor_string, location_x, location_y, public, tic, toc, location) SELECT id, action, player_id_1, ship_id_1, player_id_2, ship_id_2, referencing_id, descriptor_numeric, descriptor_string, location_x, location_y, public, tic, toc, location FROM event_partitioned WHERE round_id = current_round();
DROP TABLE event_partitioned;

CREATE INDEX event_toc_index ON event USING btree (toc);
CREATE INDEX event_player ON event USING btree (player_id_1);
CREATE TRIGGER EVENT_ID_DEALER BEFORE INSERT OR UPDATE ON event FOR EACH ROW EXECUTE PROCEDURE ID_DEALER();
SELECT setval('event_id_seq', COALESCE((SELECT max(id) FROM event), 0) + 1, false);

ALTER TABLE event ENABLE ROW LEVEL SECURITY;
CREATE POLICY event_visible ON event FOR SELECT TO players
	USING (public OR player_id_1 = get_player_id(SESSION_USER) OR player_id_2 = get_player_id(SESSION_USER));
GRANT SELECT ON event TO players;

CREATE OR REPLACE VIEW my_events AS 
 SELECT event.id, event.action, event.player_id_1, event.ship_id_1, 
    event.player_id_2, event.ship_id_2, event.referencing_id, 
    event.descriptor_numeric, event.descriptor_string, event.location, 
    event.public, event.tic, event.toc
   FROM event
  WHERE 
	( 
		get_player_id("session_user"()) = event.player_id_1 
		OR get_player_id("session_user"()) = event.player_id_2 
		OR event.public = true 
	)
	AND event.tic < (( SELECT tic_seq.last_value FROM tic_seq));
ALTER VIEW my_events SET (security_invoker = true);
GRANT SELECT ON my_events TO players;

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
GRANT SELECT ON current_player_stats TO players;

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
GRANT SELECT ON current_round_stats TO players;

CREATE MATERIALIZED VIEW player_stats AS
	SELECT s.*, now() AS refreshed FROM current_player_stats s;
CREATE UNIQUE INDEX player_stats_player_id_idx ON player_stats (player_id);
GRANT SELECT ON player_stats TO players;

COMMIT;
