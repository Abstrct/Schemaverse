-- Verify type-trophy_winner

BEGIN;

SELECT 1/count(*) FROM pg_type WHERE typname = 'trophy_winner';

ROLLBACK;
