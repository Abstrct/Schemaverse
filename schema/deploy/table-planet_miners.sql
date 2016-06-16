-- Deploy table-planet_miners
-- requires: table-planet

BEGIN;


CREATE TABLE planet_miners
(
  planet_id integer NOT NULL,
  ship_id integer NOT NULL,
  CONSTRAINT planet_miners_pkey PRIMARY KEY (planet_id, ship_id),
  CONSTRAINT planet_miners_planet_id_fkey FOREIGN KEY (planet_id)
      REFERENCES planet (id) MATCH SIMPLE
      ON UPDATE NO ACTION ON DELETE CASCADE,
  CONSTRAINT planet_miners_ship_id_fkey FOREIGN KEY (ship_id)
      REFERENCES ship (id) MATCH SIMPLE
      ON UPDATE NO ACTION ON DELETE NO ACTION
)
WITH (
  OIDS=FALSE
);

COMMIT;
