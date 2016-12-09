-- Deploy schemaverse:function-get_player_symbol to pg
-- requires: table-player

BEGIN;

CREATE OR REPLACE FUNCTION public.get_player_symbol(check_id integer)
 RETURNS character
 LANGUAGE sql
 STABLE SECURITY DEFINER
AS $function$
SELECT symbol FROM public.player WHERE id=$1;
$function$;


CREATE OR REPLACE FUNCTION public.get_player_symbol(check_username name)
 RETURNS character
 LANGUAGE sql
 STABLE SECURITY DEFINER
AS $function$
SELECT symbol FROM public.player WHERE username=$1;
$function$;

GRANT EXECUTE ON FUNCTION public.get_player_symbol(integer) TO players;
GRANT EXECUTE ON FUNCTION public.get_player_symbol(name) TO players;

COMMIT;
