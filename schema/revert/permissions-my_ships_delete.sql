-- Revert permissions-my_ships_delete

BEGIN;

REVOKE DELETE ON my_ships FROM players;

COMMIT;
