-- Deploy table-my_query_store
-- requires: table-player
--
-- Saved queries for the web console, and the first table in the game guarded
-- by row level security instead of a my_* view. Players read and write the
-- table directly; the policy limits every statement to their own rows.

BEGIN;

CREATE TABLE my_query_store (
	id          integer GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
	player_id   integer NOT NULL DEFAULT get_player_id(SESSION_USER) REFERENCES player(id),
	name        character varying(80) NOT NULL,
	query_text  text NOT NULL,
	created     timestamptz NOT NULL DEFAULT now(),
	updated     timestamptz NOT NULL DEFAULT now(),
	CONSTRAINT my_query_store_player_name_key UNIQUE (player_id, name)
);

ALTER TABLE my_query_store ENABLE ROW LEVEL SECURITY;

CREATE POLICY own_queries ON my_query_store
	FOR ALL TO players
	USING (player_id = get_player_id(SESSION_USER))
	WITH CHECK (player_id = get_player_id(SESSION_USER));

GRANT SELECT, INSERT, UPDATE, DELETE ON my_query_store TO players;

COMMIT;
