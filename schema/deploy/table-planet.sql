-- Deploy table-planet
-- requires: table-player

BEGIN;

CREATE TABLE planet
(
  id integer NOT NULL,
  name character varying,
  fuel integer NOT NULL DEFAULT (random() * (100000)::double precision),
  mine_limit integer NOT NULL DEFAULT (random() * (100)::double precision),
  difficulty integer NOT NULL DEFAULT (random() * (10)::double precision),
  location_x integer NOT NULL DEFAULT random(),
  location_y integer NOT NULL DEFAULT random(),
  conqueror_id integer,
  location point,
  CONSTRAINT planet_pkey PRIMARY KEY (id),
  CONSTRAINT planet_conqueror_id_fkey FOREIGN KEY (conqueror_id)
      REFERENCES player (id) MATCH SIMPLE
      ON UPDATE NO ACTION ON DELETE NO ACTION
)
WITH (
  OIDS=FALSE
);

COMMIT;
