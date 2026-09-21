-- Deploy view-my_player
-- requires: table-player

BEGIN;

CREATE VIEW my_player AS 
	SELECT id, username, created, balance, fuel_reserve, password, error_channel, starting_fleet, symbol, rgb
	 FROM player WHERE username=SESSION_USER;


CREATE OR REPLACE RULE my_player_starting_fleet AS
    ON UPDATE TO my_player DO INSTEAD  
        UPDATE player SET starting_fleet = new.starting_fleet, symbol = new.symbol, rgb = new.rgb
             WHERE player.id = new.id;

COMMIT;
