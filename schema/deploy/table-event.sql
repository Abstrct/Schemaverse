-- Deploy table-event

BEGIN;

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

COMMIT;
