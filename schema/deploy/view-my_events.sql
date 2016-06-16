-- Deploy view-my_events
-- requires: table-event
-- requires: table-player

BEGIN;

CREATE OR REPLACE VIEW my_events AS 
 SELECT event.id, event.action, event.player_id_1, event.ship_id_1, 
    event.player_id_2, event.ship_id_2, event.referencing_id, 
    event.descriptor_numeric, event.descriptor_string, event.location, 
    event.public, event.tic, event.toc
   FROM event
  WHERE 
	( 
		get_player_id("session_user"()) = event.player_id_1 
		OR get_player_id("session_user"()) = event.player_id_2 
		OR event.public = true 
	)
	AND event.tic < (( SELECT tic_seq.last_value FROM tic_seq));

COMMIT;
