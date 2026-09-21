-- Deploy function-register_player
-- requires: function-register_player@v1.3
-- requires: data-gameplay_variables
-- requires: player-joined_tic
--
-- Rework: stamps joined_tic and applies the LATE_JOIN_STIPEND / LATE_JOIN_FUEL
-- levers. The registrar role already exists from the first version.

BEGIN;

CREATE OR REPLACE FUNCTION register_player(p_username text, p_password text)
  RETURNS integer AS
$BODY$
DECLARE
	new_id integer;
	progress numeric;
BEGIN
	IF p_username !~ '^[a-z][a-z0-9_]{1,30}$' THEN
		RAISE EXCEPTION 'username must be 2-31 characters of a-z, 0-9 and _, starting with a letter';
	END IF;
	IF p_username IN ('schemaverse', 'registrar', 'players', 'postgres', 'public')
	   OR EXISTS (SELECT 1 FROM pg_roles WHERE rolname = p_username)
	   OR EXISTS (SELECT 1 FROM player WHERE username = p_username) THEN
		RAISE EXCEPTION 'username % is taken', p_username;
	END IF;
	IF length(p_password) < 8 THEN
		RAISE EXCEPTION 'password must be at least 8 characters';
	END IF;

	EXECUTE format('CREATE ROLE %I WITH LOGIN NOSUPERUSER NOCREATEDB NOCREATEROLE INHERIT PASSWORD %L IN ROLE players',
	               p_username, p_password);

	-- How far along the round is, 0..1, for the late-join stipend.
	progress := LEAST(1, GREATEST(0,
		EXTRACT(epoch FROM (now() - GET_CHAR_VARIABLE('ROUND_START_DATE')::date))
		/ NULLIF(EXTRACT(epoch FROM GET_CHAR_VARIABLE('ROUND_LENGTH')::interval), 0)));

	INSERT INTO player(username, balance, fuel_reserve, joined_tic)
		VALUES (p_username,
		        10000  + round(GET_NUMERIC_VARIABLE('LATE_JOIN_STIPEND') * COALESCE(progress, 0)),
		        100000 + round(GET_NUMERIC_VARIABLE('LATE_JOIN_FUEL') * COALESCE(progress, 0)),
		        current_tic())
		RETURNING id INTO new_id;

	RETURN new_id;
END
$BODY$
  LANGUAGE plpgsql VOLATILE SECURITY DEFINER
  SET search_path = public, pg_temp;

REVOKE ALL ON FUNCTION register_player(text, text) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION register_player(text, text) TO registrar;

COMMIT;
