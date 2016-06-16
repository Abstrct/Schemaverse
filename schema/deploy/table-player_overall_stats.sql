-- Deploy table-player_overall_stats

BEGIN;

CREATE TABLE player_overall_stats
(
  player_id integer NOT NULL,
  damage_taken bigint,
  damage_done bigint,
  planets_conquered integer,
  planets_lost integer,
  ships_built integer,
  ships_lost integer,
  ship_upgrades bigint,
  distance_travelled bigint,
  fuel_mined bigint,
  trophy_score integer,
  CONSTRAINT pk_player_overall_stats PRIMARY KEY (player_id)
)
WITH (
  OIDS=FALSE
);

COMMIT;
