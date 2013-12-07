-- Deploy function-read_event
-- requires: table-event
-- requires: table-action

BEGIN;


CREATE OR REPLACE FUNCTION read_event(read_event_id integer)
  RETURNS text AS
$BODY$
DECLARE
	full_text TEXT;
BEGIN
	-- Sometimes you just write some dirty code... 
	SELECT  
	replace(
	 replace(
	  replace(
	   replace(
	    replace(
	      replace(
	       replace(
	        replace(
	         replace(
	          replace(
	           replace(
	            replace(
	             replace(
	              replace(action.string,
	               '%toc', toc::TEXT),
	              '%player_id_1%', 	player_id_1::TEXT),
	             '%player_name_1%', COALESCE(GET_PLAYER_SYMBOL(player_id_1) || ' ','')||GET_PLAYER_USERNAME(player_id_1)),
	            '%player_id_2%', 	COALESCE(player_id_2::TEXT,'Unknown')),
	           '%player_name_2%', 	COALESCE(COALESCE(GET_PLAYER_SYMBOL(player_id_2) || ' ','')||GET_PLAYER_USERNAME(player_id_2),'Unknown')),
	          '%ship_id_1%', 	COALESCE(ship_id_1::TEXT,'Unknown')),
	         '%ship_id_2%', 	COALESCE(ship_id_2::TEXT,'Unknown')),
	        '%ship_name_1%', 	COALESCE(GET_SHIP_NAME(ship_id_1),'Unknown')),
	       '%ship_name_2%', 	COALESCE(GET_SHIP_NAME(ship_id_2),'Unknown')),
	      '%location%', 		COALESCE(location::TEXT,'Unknown')),
	    '%descriptor_numeric%', 	COALESCE(descriptor_numeric::TEXT,'Unknown')),
	   '%descriptor_string%', 	COALESCE(descriptor_string,'Unknown')),
	  '%referencing_id%', 		COALESCE(referencing_id::TEXT,'Unknown')),
	 '%planet_name%', 		COALESCE(GET_PLANET_NAME(referencing_id),'Unknown')
	) into full_text
	FROM my_events INNER JOIN action on my_events.action=action.name 
	WHERE my_events.id=read_event_id; 

        RETURN full_text;
END
$BODY$
  LANGUAGE plpgsql VOLATILE
  COST 100;

COMMIT;
