-- Deploy table-ship_flight_recorder
-- requires: table-ship

BEGIN;

CREATE TABLE ship_flight_recorder
(
  ship_id integer NOT NULL,
  tic integer NOT NULL,
  location_x integer,
  location_y integer,
  location point,
  player_id integer,
  CONSTRAINT ship_flight_recorder_pkey PRIMARY KEY (ship_id, tic),
  CONSTRAINT ship_flight_recorder_ship_id_fkey FOREIGN KEY (ship_id)
      REFERENCES ship (id) MATCH SIMPLE
      ON UPDATE NO ACTION ON DELETE CASCADE
);

COMMIT;
