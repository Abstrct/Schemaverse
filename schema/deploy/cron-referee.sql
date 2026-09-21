-- Deploy cron-referee
-- requires: table-player
--
-- ref.pl polled pg_stat_activity every 30 seconds and cancelled any player
-- query older than a minute. Same rule, as a pg_cron job owned by the game
-- owner. Fleet-script sessions (application_name is the fleet id) are left to
-- the ticker, which enforces each fleet's own runtime.

BEGIN;

SELECT cron.schedule('referee', '30 seconds', $job$
	SELECT pg_notify(p.error_channel, 'The following query was canceled after 60 seconds: ' || left(a.query, 200)),
	       pg_cancel_backend(a.pid)
	  FROM pg_stat_activity a
	  JOIN player p ON p.username = a.usename
	 WHERE a.datname = current_database()
	   AND p.id > 0
	   AND a.state = 'active'
	   AND a.application_name !~ '^[0-9]+$'
	   AND now() - a.query_start > interval '60 seconds'
$job$);

COMMIT;
