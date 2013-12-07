-- Deploy table-ship
-- requires: table-player

BEGIN;


CREATE TABLE ship
(
  id integer NOT NULL,
  player_id integer NOT NULL DEFAULT get_player_id(SESSION_USER),
  fleet_id integer,
  name character varying,
  last_action_tic integer DEFAULT 0,
  last_move_tic integer DEFAULT 0,
  last_living_tic integer DEFAULT 0,
  current_health integer NOT NULL DEFAULT 100,
  max_health integer NOT NULL DEFAULT 100,
  future_health integer DEFAULT 100,
  current_fuel integer NOT NULL DEFAULT 1100,
  max_fuel integer NOT NULL DEFAULT 1100,
  max_speed integer NOT NULL DEFAULT 1000,
  range integer NOT NULL DEFAULT 300,
  attack integer NOT NULL DEFAULT 5,
  defense integer NOT NULL DEFAULT 5,
  engineering integer NOT NULL DEFAULT 5,
  prospecting integer NOT NULL DEFAULT 5,
  location_x integer NOT NULL DEFAULT 0,
  location_y integer NOT NULL DEFAULT 0,
  destroyed boolean NOT NULL DEFAULT false,
  location point,
  CONSTRAINT ship_pkey PRIMARY KEY (id),
  CONSTRAINT ship_player_id_fkey FOREIGN KEY (player_id)
      REFERENCES player (id) MATCH SIMPLE
      ON UPDATE NO ACTION ON DELETE NO ACTION,
  CONSTRAINT ship_check CHECK (current_health <= max_health),
  CONSTRAINT ship_check1 CHECK (current_fuel <= max_fuel)
);

COMMIT;
