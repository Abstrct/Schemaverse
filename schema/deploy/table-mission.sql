-- Deploy table-mission
-- requires: table-player
-- requires: table-event
--
-- Missions are the tutorial track: a row per goal, with a SQL check that the
-- game evaluates as the owner ($1 is the player id) and a reward. They exist
-- for psql players as much as for the web: my_missions shows them,
-- check_missions() claims them, and tic_close() checks everyone's every few
-- tics so nobody has to remember to.

BEGIN;

CREATE TABLE mission (
	id             integer GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
	code           text NOT NULL UNIQUE,
	title          text NOT NULL,
	description    text NOT NULL,
	hint           text,
	check_sql      text NOT NULL,
	reward_balance integer NOT NULL DEFAULT 0,
	reward_fuel    integer NOT NULL DEFAULT 0,
	sort           integer NOT NULL DEFAULT 0
);
COMMENT ON TABLE mission IS 'The tutorial track. check_sql is a boolean expression evaluated as the owner with $1 = player id.';
GRANT SELECT ON mission TO players;

CREATE TABLE mission_progress (
	player_id     integer NOT NULL REFERENCES player (id),
	mission_id    integer NOT NULL REFERENCES mission (id),
	round_id      integer NOT NULL DEFAULT current_round(),
	completed_tic integer NOT NULL,
	PRIMARY KEY (player_id, mission_id, round_id)
);
ALTER TABLE mission_progress ENABLE ROW LEVEL SECURITY;
CREATE POLICY mission_progress_own ON mission_progress FOR SELECT TO players USING (player_id = get_player_id(SESSION_USER));
GRANT SELECT ON mission_progress TO players;

INSERT INTO action (name, string, bitname)
	SELECT 'MISSION', '%player_name_1% completed the mission "%descriptor_string%"', (max(bitname::integer) + 1)::bit(6) FROM action;

CREATE VIEW my_missions WITH (security_invoker = true) AS
	SELECT m.id, m.code, m.title, m.description, m.hint, m.reward_balance, m.reward_fuel, m.sort, p.completed_tic
	  FROM mission m
	  LEFT JOIN mission_progress p ON p.mission_id = m.id AND p.player_id = get_player_id(SESSION_USER) AND p.round_id = current_round()
	 ORDER BY m.sort, m.id;
GRANT SELECT ON my_missions TO players;

-- Claim every mission the player has now met. Returns the ones completed by
-- this call. The owner may check any player; players check themselves.
CREATE OR REPLACE FUNCTION check_missions(p_player integer DEFAULT NULL) RETURNS SETOF mission AS
$BODY$
DECLARE
	target integer;
	m mission%ROWTYPE;
	ok boolean;
	channel text;
BEGIN
	IF SESSION_USER = 'schemaverse' AND p_player IS NOT NULL THEN
		target := p_player;
	ELSE
		target := get_player_id(SESSION_USER);
	END IF;
	IF target IS NULL OR target = 0 THEN RETURN; END IF;

	FOR m IN
		SELECT * FROM mission mi
		 WHERE NOT EXISTS (SELECT 1 FROM mission_progress p WHERE p.mission_id = mi.id AND p.player_id = target AND p.round_id = current_round())
		 ORDER BY sort, id
	LOOP
		BEGIN
			EXECUTE 'SELECT COALESCE((' || m.check_sql || '), false)' INTO ok USING target;
		EXCEPTION WHEN OTHERS THEN
			RAISE WARNING 'mission % check failed: %', m.code, SQLERRM;
			ok := false;
		END;
		IF ok THEN
			INSERT INTO mission_progress (player_id, mission_id, completed_tic) VALUES (target, m.id, current_tic());
			UPDATE player SET balance = balance + m.reward_balance, fuel_reserve = fuel_reserve + m.reward_fuel WHERE id = target;
			INSERT INTO event (action, player_id_1, descriptor_string, descriptor_numeric, public, tic)
				VALUES ('MISSION', target, m.title, m.reward_balance, false, current_tic());
			SELECT rtrim(error_channel) INTO channel FROM player WHERE id = target;
			PERFORM pg_notify(channel, format('Mission complete: %s (+%s balance, +%s fuel)', m.title, m.reward_balance, m.reward_fuel));
			RETURN NEXT m;
		END IF;
	END LOOP;
	RETURN;
END
$BODY$ LANGUAGE plpgsql VOLATILE SECURITY DEFINER SET search_path = public, pg_temp;
GRANT EXECUTE ON FUNCTION check_missions(integer) TO players;

CREATE OR REPLACE FUNCTION check_all_missions() RETURNS integer AS
$BODY$
DECLARE n integer := 0; p record;
BEGIN
	IF SESSION_USER <> 'schemaverse' THEN
		RAISE EXCEPTION 'check_all_missions() is for the game owner';
	END IF;
	FOR p IN SELECT id FROM player WHERE id > 0 LOOP
		n := n + (SELECT count(*) FROM check_missions(p.id));
	END LOOP;
	RETURN n;
END
$BODY$ LANGUAGE plpgsql VOLATILE SET search_path = public, pg_temp;
REVOKE ALL ON FUNCTION check_all_missions() FROM PUBLIC;

COMMIT;
