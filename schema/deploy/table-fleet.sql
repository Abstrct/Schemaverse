-- Deploy table-fleet
-- requires: table-player

BEGIN;


CREATE TABLE fleet
(
  id integer NOT NULL,
  player_id integer NOT NULL DEFAULT get_player_id("session_user"()),
  name character varying(50),
  script text DEFAULT 'Select 1;'::text,
  script_declarations text DEFAULT 'fakevar smallint;'::text,
  last_script_update_tic integer DEFAULT 0,
  enabled boolean NOT NULL DEFAULT false,
  runtime interval DEFAULT '00:00:00'::interval,
  CONSTRAINT fleet_pkey PRIMARY KEY (id),
  CONSTRAINT fleet_player_id_fkey FOREIGN KEY (player_id)
      REFERENCES player (id) MATCH SIMPLE
      ON UPDATE NO ACTION ON DELETE NO ACTION
);


COMMIT;
