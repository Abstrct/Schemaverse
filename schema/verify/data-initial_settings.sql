-- Verify data-initial_settings

BEGIN;

SELECT 1/count(*) FROM variable WHERE name = 'UNIVERSE_CREATOR' AND player_id = 0;

ROLLBACK;
