-- Deploy table-player_trophy
-- requires: table-player
-- requires: table-trophy

BEGIN;

CREATE TABLE player_trophy
(
  round integer NOT NULL,
  trophy_id integer NOT NULL,
  player_id integer NOT NULL,
  CONSTRAINT player_trophy_pkey PRIMARY KEY (round, trophy_id, player_id),
  CONSTRAINT player_trophy_player_id_fkey FOREIGN KEY (player_id)
      REFERENCES player (id) MATCH SIMPLE
      ON UPDATE NO ACTION ON DELETE NO ACTION,
  CONSTRAINT player_trophy_trophy_id_fkey FOREIGN KEY (trophy_id)
      REFERENCES trophy (id) MATCH SIMPLE
      ON UPDATE NO ACTION ON DELETE NO ACTION
)
WITH (
  OIDS=FALSE
);

COMMIT;
