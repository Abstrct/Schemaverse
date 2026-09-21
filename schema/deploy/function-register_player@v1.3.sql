-- Deploy function-register_player
-- requires: table-player
-- requires: role-players
--
-- Registration used to be "INSERT INTO player" by the owner with a client-side
-- MD5 hash in player.password, which a trigger then pasted into CREATE ROLE.
-- Now: a definer function validates the name, creates the role with the
-- server hashing the password (scram-sha-256 on modern defaults), and inserts
-- the player row. The password never lands in a table.
--
-- The "registrar" role exists so a web front end or a classroom script can
-- register players without being the owner. It has no password until an
-- operator gives it one:  ALTER ROLE registrar PASSWORD '...';

BEGIN;

CREATE ROLE registrar WITH LOGIN NOSUPERUSER NOCREATEDB NOCREATEROLE NOINHERIT;

CREATE OR REPLACE FUNCTION register_player(p_username text, p_password text)
  RETURNS integer AS
$BODY$
DECLARE
	new_id integer;
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

	INSERT INTO player(username, balance, fuel_reserve) VALUES (p_username, 10000, 100000)
		RETURNING id INTO new_id;

	RETURN new_id;
END
$BODY$
  LANGUAGE plpgsql VOLATILE SECURITY DEFINER
  SET search_path = public, pg_temp;

REVOKE ALL ON FUNCTION register_player(text, text) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION register_player(text, text) TO registrar;

COMMIT;
