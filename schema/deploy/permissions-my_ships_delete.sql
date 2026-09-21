-- Deploy permissions-my_ships_delete
-- requires: view-my_ships
--
-- my_ships has always had an ON DELETE rule that marks the ship destroyed,
-- but players were never granted DELETE on the view.

BEGIN;

GRANT DELETE ON my_ships TO players;

COMMIT;
