-- Revert schemaverse:function-get_player_symbol from pg

BEGIN;

DROP FUNCTION get_player_symbol(integer);
DROP FUNCTION get_player_symbol(name);

COMMIT;
