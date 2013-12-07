-- Deploy table-ship_control
-- requires: table-ship

BEGIN;

CREATE TABLE ship_control
(
  ship_id integer NOT NULL,
  speed integer NOT NULL DEFAULT 0,
  direction integer NOT NULL DEFAULT 0,
  destination_x integer,
  destination_y integer,
  repair_priority integer DEFAULT 0,
  action character(30),
  action_target_id integer,
  destination point,
  target_speed integer,
  target_direction integer,
  player_id integer,
  CONSTRAINT ship_control_pkey PRIMARY KEY (ship_id),
  CONSTRAINT ship_control_player_id FOREIGN KEY (player_id)
      REFERENCES player (id) MATCH SIMPLE
      ON UPDATE CASCADE ON DELETE CASCADE,
  CONSTRAINT ship_control_ship_id_fkey FOREIGN KEY (ship_id)
      REFERENCES ship (id) MATCH SIMPLE
      ON UPDATE NO ACTION ON DELETE CASCADE,
  CONSTRAINT ch_action CHECK (action = ANY (ARRAY['REPAIR'::bpchar, 'ATTACK'::bpchar, 'MINE'::bpchar])),
  CONSTRAINT ship_control_direction_check CHECK (0 <= direction AND direction <= 360)
);

COMMIT;
