-- Verify event-partitioned

BEGIN;

SELECT 1/count(*) FROM pg_class WHERE relname = 'event' AND relkind = 'p';
SELECT 1/count(*) FROM pg_attribute WHERE attrelid = 'event'::regclass AND attname = 'id' AND attidentity = 'a';
SELECT 1/count(*) FROM pg_views WHERE viewname = 'event_archive';
SELECT 1/count(*) FROM pg_views WHERE viewname = 'my_events' AND definition ~ 'current_round';
SELECT 1/count(*) FROM pg_matviews WHERE matviewname = 'player_stats';
SELECT 1/count(*) FROM pg_policies WHERE tablename = 'event' AND policyname = 'event_visible';
SELECT 1/(CASE WHEN to_regclass('event_round_' || current_round()) IS NOT NULL THEN 1 ELSE 0 END);

ROLLBACK;
