-- Deploy view-online_players

BEGIN;

CREATE VIEW online_players AS
	SELECT id, username FROM player
		WHERE username in (SELECT DISTINCT usename FROM pg_stat_activity);

COMMIT;
