-- Deploy view-player_round_stats

BEGIN;

CREATE TABLE player_round_stats
(
  player_id integer NOT NULL,
  round_id integer NOT NULL,
  damage_taken bigint NOT NULL DEFAULT 0,
  damage_done bigint NOT NULL DEFAULT 0,
  planets_conquered smallint NOT NULL DEFAULT 0,
  planets_lost smallint NOT NULL DEFAULT 0,
  ships_built smallint NOT NULL DEFAULT 0,
  ships_lost smallint NOT NULL DEFAULT 0,
  ship_upgrades integer NOT NULL DEFAULT 0,
  fuel_mined bigint NOT NULL DEFAULT 0,
  trophy_score smallint NOT NULL DEFAULT 0,
  last_updated timestamp without time zone NOT NULL DEFAULT now(),
  distance_travelled bigint NOT NULL DEFAULT 0,
  CONSTRAINT pk_player_round_stats PRIMARY KEY (player_id, round_id)
)
WITH (
  OIDS=FALSE
);

COMMIT;
