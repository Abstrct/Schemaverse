-- Deploy table-round_stats

BEGIN;

CREATE TABLE round_stats
(
  round_id integer NOT NULL,
  avg_damage_taken integer,
  avg_damage_done integer,
  avg_planets_conquered integer,
  avg_planets_lost integer,
  avg_ships_built integer,
  avg_ships_lost integer,
  avg_ship_upgrades bigint,
  avg_fuel_mined bigint,
  avg_distance_travelled bigint,
  CONSTRAINT pk_round_stats PRIMARY KEY (round_id)
)
WITH (
  OIDS=FALSE
);
COMMIT;
