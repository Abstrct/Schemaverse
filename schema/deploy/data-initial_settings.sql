-- Deploy data-initial_settings
-- requires: table-variable

BEGIN;

INSERT INTO variable VALUES 
	('MINE_BASE_FUEL','f',15,'','This value is used as a multiplier for fuel discovered from all planets'::TEXT,0),
	('UNIVERSE_CREATOR','t',9702000,'','The answer which creates the universe'::TEXT,0), 
	('EXPLODED','f',3,'','After this many tics, a ship will explode. Cost of a base ship will be returned to the player'::TEXT,0),
	('MAX_SHIPS','f',1000,'','The max number of ships a player can control at any time. Destroyed ships do not count'::TEXT,0),
	('MAX_SHIP_SKILL','f',500,'','This is the total amount of skill a ship can have (attack + defense + engineering + prospecting)'::TEXT,0),
	('MAX_SHIP_RANGE','f',5000,'','This is the maximum range a ship can have'::TEXT,0),
	('MAX_SHIP_FUEL','f',200000,'','This is the maximum fuel a ship can have'::TEXT,0),
	('MAX_SHIP_SPEED','f',800000,'','This is the maximum speed a ship can travel'::TEXT,0),
	('MAX_SHIP_HEALTH','f',1000,'','This is the maximum health a ship can have'::TEXT,0),
	('ROUND_START_DATE','f',0,'1986-03-27','The day the round started.'::TEXT,0),
	('ROUND_LENGTH','f',0,'1 days','The length of time a round takes to complete'::TEXT,0),
	('DEFENSE_EFFICIENCY', 'f', 50, '', 'Used to calculate attack with defense'::TEXT,0);

COMMIT;
