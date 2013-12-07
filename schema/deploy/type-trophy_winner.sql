-- Deploy type-trophy_winner

BEGIN;

CREATE TYPE trophy_winner AS (round integer, trophy_id integer, player_id integer);

COMMIT;
