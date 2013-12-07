-- Deploy table-action

BEGIN;


CREATE TABLE action
(
  name character(30) NOT NULL,
  string text NOT NULL,
  bitname bit(6) NOT NULL,
  CONSTRAINT action_pkey PRIMARY KEY (name),
  CONSTRAINT action_bitname_un UNIQUE (bitname)
);


COPY action (name, string, bitname) FROM stdin;
BUY_SHIP                      	(#%player_id_1%)%player_name_1% has purchased a new ship (#%ship_id_1%)%ship_name_1% and sent it to location %location%	000001
ATTACK                        	(#%player_id_1%)%player_name_1%'s ship (#%ship_id_1%)%ship_name_1% has attacked (#%player_id_2%)%player_name_2%'s ship (#%ship_id_2%)%ship_name_2% causing %descriptor_numeric% of damage	000000
CONQUER                       	(#%player_id_1%)%player_name_1% has conquered (#%referencing_id%)%planet_name% from (#%player_id_2%)%player_name_2%	000010
EXPLODE                       	(#%player_id_1%)%player_name_1%'s ship (#%ship_id_1%)%ship_name_1% has been destroyed	000011
MINE_FAIL                     	(#%player_id_1%)%player_name_1%'s ship (#%ship_id_1%)%ship_name_1% has failed to mine the planet (#%referencing_id%)%planet_name%	000110
MINE_SUCCESS                  	(#%player_id_1%)%player_name_1%'s ship (#%ship_id_1%)%ship_name_1% has successfully mined %descriptor_numeric% fuel from the planet (#%referencing_id%)%planet_name%	000111
REFUEL_SHIP                   	(#%player_id_1%)%player_name_1% has refueled the ship (#%ship_id_1%)%ship_name_1% +%descriptor_numeric%	001000
REPAIR                        	(#%player_id_1%)%player_name_1%'s ship (#%ship_id_1%)%ship_name_1% has repaired (#%ship_id_2%)%ship_name_2% by %descriptor_numeric%	001001
UPGRADE_SHIP                  	(#%player_id_1%)%player_name_1% has upgraded the %descriptor_string% on ship (#%ship_id_1%)%ship_name_1% +%descriptor_numeric%	010010
TIC                           	A new Tic has begun at %toc%	010101
FLEET                         	(#%player_id_1%)%player_name_1%'s new fleet (#%referencing_id%) has been upgraded	000101
FLEET_FAIL                    	(#%player_id_1%)%player_name_1%'s fleet #%referencing_id% encountered an issue during execution and was terminated. The error logged was: %descriptor_string%	010100
FLEET_SUCCESS                 	(#%player_id_1%)%player_name_1%'s fleet #%referencing_id% completed successfully. Execution took: %descriptor_string%	010011
\.

COMMIT;
