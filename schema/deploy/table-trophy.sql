-- Deploy table-trophy

BEGIN;


CREATE TABLE trophy
(
  id integer NOT NULL,
  name character varying,
  description text,
  picture_link text,
  script text,
  script_declarations text,
  creator integer NOT NULL,
  approved boolean DEFAULT false,
  round_started integer,
  weight smallint,
  run_order smallint,
  CONSTRAINT trophy_pkey PRIMARY KEY (id),
  CONSTRAINT trophy_creator_fkey FOREIGN KEY (creator)
      REFERENCES player (id) MATCH SIMPLE
      ON UPDATE NO ACTION ON DELETE NO ACTION
)
WITH (
  OIDS=FALSE
);


COMMIT;
