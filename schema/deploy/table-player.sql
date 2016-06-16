-- Deploy table-player

BEGIN;

CREATE TABLE player
(
  id integer NOT NULL,
  username character varying NOT NULL,
  password character(40) NOT NULL,
  created timestamp without time zone NOT NULL DEFAULT now(),
  balance bigint NOT NULL DEFAULT (10000)::numeric,
  fuel_reserve bigint DEFAULT 1000,
  error_channel character(10) NOT NULL DEFAULT lower((generate_string(10))::text),
  starting_fleet integer,
  symbol character(1),
  rgb character(6),
  CONSTRAINT player_pkey PRIMARY KEY (id),
  CONSTRAINT player_username_key UNIQUE (username),
  CONSTRAINT unq_symbol UNIQUE (symbol, rgb),
  CONSTRAINT ck_balance CHECK (balance::numeric >= 0::numeric),
  CONSTRAINT ck_fuel_reserve CHECK (fuel_reserve >= 0)
)
WITH (
  OIDS=FALSE
);

COMMIT;
