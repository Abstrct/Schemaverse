-- Deploy table-variable
-- requires: table-player

BEGIN;

CREATE TABLE variable
(
	name character varying NOT NULL,
	private boolean,
	numeric_value integer,
	char_value character varying,
	description TEXT,
	player_id integer NOT NULL DEFAULT 0 REFERENCES player(id), 
  	CONSTRAINT pk_variable PRIMARY KEY (name, player_id)
);


COMMIT;
