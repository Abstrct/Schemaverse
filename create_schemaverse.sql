-- Schemaverse 
-- Created by Josh McDougall
-- v1.2.3 - Making things usable
begin;
 
CREATE SEQUENCE round_seq
  INCREMENT 1
  MINVALUE 1
  MAXVALUE 9223372036854775807
  START 1
  CACHE 1;

CREATE SEQUENCE tic_seq
  INCREMENT 1
  MINVALUE 1
  MAXVALUE 9223372036854775807
  START 1
  CACHE 1;

CREATE TABLE variable
(
	name character varying NOT NULL,
	private boolean,
	numeric_value integer,
	char_value character varying,
	description TEXT,
	player_id integer NOT NULL DEFAULT 0, 
  	CONSTRAINT pk_variable PRIMARY KEY (name, player_id)
);

INSERT INTO variable VALUES 
	('MINE_BASE_FUEL','f',1,'','This value is used as a multiplier for fuel discovered from all planets'::TEXT,0),
	('UNIVERSE_CREATOR','t',9702000,'','The answer which creates the universe'::TEXT,0), 
	('EXPLODED','f',60,'','After this many tics, a ship will explode. Cost of a base ship will be returned to the player'::TEXT,0),
	('MAX_SHIP_SKILL','f',500,'','This is the total amount of skill a ship can have (attack + defense + engineering + prospecting)'::TEXT,0),
	('MAX_SHIP_RANGE','f',2000,'','This is the maximum range a ship can have'::TEXT,0),
	('MAX_SHIP_FUEL','f',16000,'','This is the maximum fuel a ship can have'::TEXT,0),
	('MAX_SHIP_SPEED','f',5000,'','This is the maximum speed a ship can travel'::TEXT,0),
	('MAX_SHIP_HEALTH','f',1000,'','This is the maximum health a ship can have'::TEXT,0),
	('ROUND_START_DATE','f',0,'1986-03-27','The day the round started.'::TEXT,0),
	('ROUND_LENGTH','f',0,'7 days','The length of time a round takes to complete'::TEXT,0),
	('DEFENSE_EFFICIENCY', 'f', 50, '', 'Used to calculate attack with defense'::TEXT,0);

CREATE TABLE price_list
(
	code character varying NOT NULL PRIMARY KEY,
	cost integer NOT NULL,
	description TEXT
);


INSERT INTO price_list VALUES
	('SHIP', 100000, 'HOLY CRAP. A NEW SHIP!'),
	('FLEET_RUNTIME', 10000000, 'Add one minute of runtime to a fleet script'),
	('MAX_HEALTH', 25, 'Increases a ships MAX_HEALTH by one'),
	('MAX_FUEL', 1, 'Increases a ships MAX_FUEL by one'),
	('MAX_SPEED', 1, 'Increases a ships MAX_SPEED by one'),
	('RANGE', 25, 'Increases a ships RANGE by one'),
	('ATTACK', 25,'Increases a ships ATTACK by one'),
	('DEFENSE', 25, 'Increases a ships DEFENSE by one'),
	('ENGINEERING', 25, 'Increases a ships ENGINEERING by one'),
	('PROSPECTING', 25, 'Increases a ships PROSPECTING by one');

--no mechanism for updating password yet...

CREATE OR REPLACE FUNCTION GENERATE_STRING(len integer) RETURNS CHARACTER VARYING AS $generate_string$
BEGIN
	RETURN array_to_string(ARRAY(SELECT chr((65 + round(random() * 25)) :: integer) FROM generate_series(1,len)), '');
END
$generate_string$ LANGUAGE plpgsql;

CREATE TABLE player
(
	id integer NOT NULL PRIMARY KEY,
	username character varying NOT NULL UNIQUE,
	password character(40) NOT NULL,			-- 'md5' + MD5(password+username) 
	created timestamp NOT NULL DEFAULT NOW(),
	balance numeric NOT NULL DEFAULT '10000',
	fuel_reserve integer NOT NULL DEFAULT '1000',
	error_channel CHARACTER(10) NOT NULL DEFAULT lower(generate_string(10)),
	starting_fleet integer,
	CONSTRAINT ck_balance CHECK (balance >= 0::numeric),
  	CONSTRAINT ck_fuel_reserve CHECK (fuel_reserve >= 0)
);


CREATE SEQUENCE player_id_seq
  INCREMENT 1
  MINVALUE 1
  MAXVALUE 9223372036854775807
  START 1
  CACHE 1;

INSERT INTO player(id, username, password, fuel_reserve, balance) VALUES(0,'schemaverse','nopass',100000,100000); 

CREATE VIEW my_player AS 
	SELECT id, username, created, balance, fuel_reserve, password, error_channel, starting_fleet
	 FROM player WHERE username=SESSION_USER;

ALTER TABLE variable ADD CONSTRAINT fk_variable_player_id FOREIGN KEY (player_id)
      REFERENCES player (id) MATCH SIMPLE; 

--Credit to xocolatl for optimizing this function
CREATE OR REPLACE FUNCTION GET_PLAYER_ID(check_username name) RETURNS integer AS $get_player_id$
SELECT id FROM player WHERE username=$1;
$get_player_id$ LANGUAGE sql STABLE SECURITY DEFINER;

CREATE VIEW public_variable AS SELECT * FROM variable WHERE (private='f' AND player_id=0) OR player_id=GET_PLAYER_ID(SESSION_USER);


CREATE OR REPLACE FUNCTION GET_NUMERIC_VARIABLE(variable_name character varying) RETURNS integer AS $get_numeric_variable$
DECLARE
	value integer;
BEGIN
	IF CURRENT_USER = 'schemaverse' THEN
		SELECT numeric_value INTO value FROM variable WHERE name = variable_name and player_id=0;
	ELSE 
		SELECT numeric_value INTO value FROM public_variable WHERE name = variable_name;
	END IF;
	RETURN value; 
END $get_numeric_variable$  LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION GET_CHAR_VARIABLE(variable_name character varying) RETURNS character varying AS $get_char_variable$
DECLARE
	value character varying;
BEGIN
	IF CURRENT_USER = 'schemaverse' THEN
		SELECT char_value INTO value FROM variable WHERE name = variable_name and player_id=0;
	ELSE
		SELECT char_value INTO value FROM public_variable WHERE name = variable_name;
	END IF;
	RETURN value; 
END $get_char_variable$  LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION SET_NUMERIC_VARIABLE(variable_name character varying, new_value integer) RETURNS integer AS $set_numeric_variable$
BEGIN
	IF (SELECT count(*) FROM variable WHERE name=variable_name AND player_id=GET_PLAYER_ID(SESSION_USER)) = 1 THEN
		UPDATE variable SET numeric_value=new_value WHERE  name=variable_name AND player_id=GET_PLAYER_ID(SESSION_USER);
	ELSEIF (SELECT count(*) FROM variable WHERE name=variable_name AND player_id=0) = 1 THEN
		EXECUTE 'NOTIFY ' || get_player_error_channel() ||', ''Cannot update a system variable'';';
	ELSE 
		INSERT INTO variable VALUES(variable_name,'f',new_value,'','',GET_PLAYER_ID(SESSION_USER));
	END IF;
	RETURN new_value; 
END $set_numeric_variable$ SECURITY definer LANGUAGE plpgsql ;

CREATE OR REPLACE FUNCTION SET_CHAR_VARIABLE(variable_name character varying, new_value character varying) RETURNS character varying AS 
$set_char_variable$
BEGIN
	IF (SELECT count(*) FROM variable WHERE name=variable_name AND player_id=GET_PLAYER_ID(SESSION_USER)) = 1 THEN
		UPDATE variable SET char_value=new_value WHERE  name=variable_name AND player_id=GET_PLAYER_ID(SESSION_USER);
	ELSEIF (SELECT count(*) FROM variable WHERE name=variable_name AND player_id=0) = 1 THEN
		EXECUTE 'NOTIFY ' || get_player_error_channel() ||', ''Cannot update a system variable'';';
	ELSE 
		INSERT INTO variable VALUES(variable_name,'f',0,new_value,'',GET_PLAYER_ID(SESSION_USER));
	END IF;
	RETURN new_value; 
END $set_char_variable$ SECURITY definer LANGUAGE plpgsql;



CREATE RULE public_variable_update AS ON UPDATE to public_variable
	DO INSTEAD UPDATE variable 
		SET 
			numeric_value=NEW.numeric_value,
			description=NEW.description 
		WHERE 
			name=NEW.name AND player_id=GET_PLAYER_ID(SESSION_USER);

CREATE RULE public_variable_insert AS ON INSERT to public_variable
	DO INSTEAD INSERT INTO variable(name, char_value, numeric_value, description, player_id) VALUES(
			NEW.name,
			NEW.char_value, 
			NEW.numeric_value,
			NEW.description,
			GET_PLAYER_ID(SESSION_USER));

CREATE RULE public_variable_delete AS ON DELETE to public_variable
	DO INSTEAD DELETE FROM variable 
		WHERE 
			name=OLD.name AND player_id=GET_PLAYER_ID(SESSION_USER);


CREATE OR REPLACE FUNCTION VARIABLE_INSERT() RETURNS trigger AS $variable_insert$
	BEGIN
	IF (SELECT count(*) FROM variable WHERE player_id=0 and name=NEW.name) = 1 THEN
		RETURN OLD;
	ELSE
	       RETURN NEW;
	END IF;
END $variable_insert$ LANGUAGE plpgsql;

CREATE TRIGGER VARIABLE_INSERT BEFORE INSERT ON variable
  FOR EACH ROW EXECUTE PROCEDURE VARIABLE_INSERT();



	--Needs a trigger to alter the user account. Don't feel like actually writing this right now. 
	--A bit worried it is a security risk unless the new password is checked thoroughly. Otherwise they could inject into the alter user statement 
	--CREATE RULE my_player AS ON UPDATE TO player 
	-- DO INSTEAD UPDATE player SET password=NEW.password WHERE username=SESSION_USER; ON UPDATE CASCADE ON DELETE CASCADE
	
CREATE RULE my_player_starting_fleet AS ON UPDATE to my_player
	DO INSTEAD UPDATE player SET starting_fleet=NEW.starting_fleet WHERE id=NEW.id;

CREATE VIEW online_players AS
	SELECT id, username FROM player
		WHERE username in (SELECT DISTINCT usename FROM pg_stat_activity);

CREATE OR REPLACE FUNCTION PLAYER_CREATION() RETURNS trigger AS $player_creation$
BEGIN
	execute 'CREATE ROLE ' || NEW.username || ' WITH LOGIN NOSUPERUSER NOCREATEDB NOCREATEROLE ENCRYPTED PASSWORD '''|| NEW.password ||'''  IN GROUP players'; 

	UPDATE planet SET conqueror_id=NEW.id, mine_limit=50, fuel=3000000, difficulty=10 
			WHERE planet.id = 
				(SELECT id FROM planet WHERE 
					( NOT CIRCLE(POINT(0,0),50000) ~ planet.location ) 
					AND conqueror_id is null ORDER BY RANDOM() LIMIT 1);
	RETURN NEW;
END
$player_creation$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE TRIGGER PLAYER_CREATION AFTER INSERT ON player
  FOR EACH ROW EXECUTE PROCEDURE PLAYER_CREATION(); 


CREATE OR REPLACE FUNCTION GET_PLAYER_USERNAME(check_player_id integer) RETURNS character varying AS $get_player_username$
SELECT username FROM player WHERE id=$1;
$get_player_username$  LANGUAGE sql STABLE SECURITY DEFINER;


CREATE OR REPLACE FUNCTION GET_PLAYER_ERROR_CHANNEL(player_name character varying default SESSION_USER) RETURNS character varying AS 
$get_player_error_channel$
DECLARE 
	found_error_channel character varying;
BEGIN
	IF CURRENT_USER = 'schemaverse' THEN
		SELECT error_channel INTO found_error_channel FROM player WHERE username=player_name;
        ELSE
		SELECT error_channel INTO found_error_channel FROM my_player LIMIT 1;
	END IF;
	RETURN found_error_channel;
END
$get_player_error_channel$ LANGUAGE plpgsql;

CREATE TABLE item
(
	system_name character varying NOT NULL PRIMARY KEY,
	name character varying NOT NULL,
	description TEXT,
	howto TEXT,
	persistent boolean NOT NULL DEFAULT 'f',
	script text,
	creator integer NOT NULL REFERENCES player(id),
        approved boolean default 'f',
        round_started integer
);

create or replace function random_point () returns point as $$
begin
	return point(random(), random());
end
$$ language plpgsql;

comment on function random_point () is 'Generate a random point';

CREATE TABLE item_location
(
	system_name character varying NOT NULL REFERENCES item(system_name),
	location point not null default random_point()
);


CREATE OR REPLACE FUNCTION CREATE_ITEM() RETURNS trigger AS $create_item$
BEGIN

        NEW.approved    := 'f';
        NEW.creator     := GET_PLAYER_ID(SESSION_USER);
        NEW.round_started := 0;

       RETURN NEW;
END
$create_item$ LANGUAGE plpgsql;


CREATE TRIGGER CREATE_ITEM BEFORE INSERT ON item
  FOR EACH ROW EXECUTE PROCEDURE CREATE_ITEM();


CREATE OR REPLACE FUNCTION ITEM_SCRIPT_UPDATE() RETURNS trigger AS $item_script_update$
DECLARE
       current_round integer;
       player_id integer;
BEGIN

        player_id := GET_PLAYER_ID(SESSION_USER);

        IF  SESSION_USER = 'schemaverse' THEN
               IF NEW.approved='t' AND OLD.approved='f' THEN
                        IF NEW.round_started=0 THEN
                                SELECT last_value INTO NEW.round_started FROM round_seq;
                        END IF;
                      
                 EXECUTE NEW.script::TEXT;

                END IF;
        ELSEIF NOT player_id = OLD.creator THEN
                RETURN OLD;
        ELSE
                IF NOT OLD.approved = NEW.approved THEN
                        NEW.approved='f';
                END IF;

                IF NOT (NEW.script = OLD.script) THEN
                        NEW.approved='f';
               END IF;
        END IF;

       RETURN NEW;
END $item_script_update$ LANGUAGE plpgsql;

CREATE TRIGGER ITEM_SCRIPT_UPDATE BEFORE UPDATE ON item
  FOR EACH ROW EXECUTE PROCEDURE ITEM_SCRIPT_UPDATE();



CREATE OR REPLACE FUNCTION CHARGE(price_code character varying, quantity bigint) RETURNS boolean AS $charge_player$
DECLARE 
	amount bigint;
	current_balance bigint;
BEGIN

	SELECT cost INTO amount FROM price_list WHERE code=UPPER(price_code);
	SELECT balance INTO current_balance FROM player WHERE username=SESSION_USER;
	IF quantity < 0 OR (current_balance - (amount * quantity)) < 0 THEN
		RETURN 'f';
	ELSE 
		UPDATE player SET balance=(balance-(amount * quantity)) WHERE username=SESSION_USER;
	END IF;
	RETURN 't'; 
END
$charge_player$ LANGUAGE plpgsql SECURITY DEFINER;


--Never update directly to add inventory. Always INSERT
CREATE TABLE player_inventory 
(
	id integer NOT NULL PRIMARY KEY,
	player_id integer NOT NULL REFERENCES player(id) DEFAULT GET_PLAYER_ID(SESSION_USER),
	item character varying NOT NULL REFERENCES item(system_name),
	quantity integer NOT NULL DEFAULT '1'
);

CREATE SEQUENCE player_inventory_id_seq
  INCREMENT 1
  MINVALUE 1
  MAXVALUE 9223372036854775807
  START 1
  CACHE 1;

CREATE VIEW my_player_inventory AS 
	SELECT * FROM player_inventory WHERE player_id=GET_PLAYER_ID(SESSION_USER);


CREATE OR REPLACE FUNCTION INSERT_ITEM_INTO_INVENTORY() RETURNS trigger AS $insert_item_into_inventory$
DECLARE
	inventory_check integer;
BEGIN
	SELECT COUNT(*) INTO inventory_check FROM player_inventory WHERE player_id=NEW.player_id and item=NEW.item;
	IF inventory_check >= 1 THEN
		UPDATE player_inventory SET quantity=quantity+NEW.quantity WHERE player_id=NEW.player_id and item=NEW.item; 
		RETURN NULL;
	END IF;
	RETURN NEW;
END
$insert_item_into_inventory$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE TRIGGER INSERT_ITEM BEFORE INSERT ON player_inventory
  FOR EACH ROW EXECUTE PROCEDURE INSERT_ITEM_INTO_INVENTORY();  

CREATE OR REPLACE FUNCTION CHECK_PLAYER_INVENTORY() RETURNS trigger AS $check_player_inventory$
BEGIN
	IF NEW.quantity = 0 THEN
		DELETE FROM player_inventory WHERE id = OLD.id;
	END IF;
	RETURN NULL;
END
$check_player_inventory$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE TRIGGER CHECK_PLAYER_INVENTORY AFTER INSERT OR UPDATE ON player_inventory
  FOR EACH ROW EXECUTE PROCEDURE CHECK_PLAYER_INVENTORY(); 

CREATE TABLE ship 
(
	id integer NOT NULL PRIMARY KEY,
	player_id integer NOT NULL REFERENCES player(id) DEFAULT GET_PLAYER_ID(SESSION_USER),
	fleet_id integer,
	name character varying,
	last_action_tic integer default '0',
	last_living_tic integer default '0',
	current_health integer NOT NULL DEFAULT '100' CHECK (current_health <= max_health),	
	max_health integer NOT NULL DEFAULT '100',
	future_health integer default '100',
	current_fuel integer NOT NULL DEFAULT '1100' CHECK (current_fuel <= max_fuel),
	max_fuel integer NOT NULL DEFAULT '1100',
	max_speed integer NOT NULL DEFAULT '1000',
	range integer NOT NULL DEFAULT '300',
	attack integer NOT NULL DEFAULT '5',
	defense integer NOT NULL DEFAULT '5',
	engineering integer NOT NULL default '5',
	prospecting integer NOT NULL default '5',
	location point default point(0,0),
	destroyed boolean NOT NULL default 'f'
);

CREATE OR REPLACE FUNCTION GET_SHIP_NAME(ship_id integer) RETURNS character varying AS $get_ship_name$
DECLARE 
	found_shipname character varying;
BEGIN
	SELECT name INTO found_shipname FROM ship WHERE id=ship_id;
	RETURN found_shipname;
END
$get_ship_name$ LANGUAGE plpgsql SECURITY DEFINER;


CREATE TABLE ship_control
(
	ship_id integer NOT NULL REFERENCES ship(id) ON DELETE CASCADE,
	player_id integer NOT NULL REFERENCES player(id) ON DELETE CASCADE,
	speed integer NOT NULL DEFAULT 0,
	direction integer NOT NULL  DEFAULT 0 CHECK (0 <= direction and direction <= 360),
	destination point,
	target_speed integer,
	target_direction integer,
	repair_priority integer DEFAULT '0',
	action character(30) CHECK (action IN ('REPAIR','ATTACK','MINE')),
	action_target_id integer,
	PRIMARY KEY (ship_id)
);
CREATE SEQUENCE ship_id_seq
  INCREMENT 1
  MINVALUE 1
  MAXVALUE 9223372036854775807
  START 1
  CACHE 1;

CREATE TABLE ship_flight_recorder
(
  ship_id integer NOT NULL REFERENCES ship(id) ON DELETE CASCADE,
  tic integer,
  location point not null,
  PRIMARY KEY (ship_id, tic)
);

CREATE OR REPLACE VIEW my_ships_flight_recorder AS 
WITH current_player as (SELECT GET_PLAYER_ID(SESSION_USER) AS player_id)
 SELECT 
	ship_flight_recorder.ship_id, 
	ship_flight_recorder.tic, 
	ship_flight_recorder.location_x, 
	ship_flight_recorder.location_y
   FROM 
	ship_flight_recorder, current_player
  WHERE ship_flight_recorder.player_id = current_player.player_id; 


create unlogged table ships_near_ships (
       first_ship integer references ship(id) on delete cascade,
	player_id integer references player(id) on delete cascade,
       second_ship integer references ship(id) on delete cascade,
       primary key (first_ship, second_ship),
       location_first point,
       location_second point,
       distance float
);
create index sns_first on ships_near_ships (first_ship);
create index sns_second on ships_near_ships (second_ship);
create index sns_distance on ships_near_ships (distance);

--Cannot create GIST index on unlogged table
--create index sns_loc1 on ships_near_ships using GIST (location_first);
--create index sns_loc2 on ships_near_ships using GIST (location_second);


CREATE OR REPLACE FUNCTION update_ships_near_ships()
  RETURNS boolean AS
$BODY$
declare
	new record;
	current_tic integer;
begin
	SELECT last_value INTO current_tic FROM tic_seq;
	
	FOR NEW IN SELECT id, range, location, player_id FROM ship 
		WHERE last_move_tic between current_tic-5 and current_tic 
		LOOP

	   delete from ships_near_ships where first_ship = NEW.id;
	   delete from ships_near_ships where second_ship = NEW.id;
	   insert into ships_near_ships (first_ship, player_id,  second_ship, location_first, location_second, distance)
	     select NEW.id, NEW.player_id, s2.id, NEW.location, s2.location, NEW.location <-> s2.location
              from ship s2
              where s2.id <> NEW.id AND s2.player_id <> NEW.player_id and CIRCLE(NEW.location,NEW.range) @> CIRCLE(s2.location,1) ;
	   insert into ships_near_ships (first_ship, player_id, second_ship, location_first, location_second, distance)
	     select s1.id, s1.player_id, NEW.id, s1.location, NEW.location, NEW.location <-> s1.location
              from ship s1
              where s1.id <> NEW.id and s1.player_id <> NEW.player_id and CIRCLE(s1.location,s1.range) @> CIRCLE(NEW.location,1);
        end LOOP;
	return 't';
end
$BODY$
  LANGUAGE plpgsql VOLATILE SECURITY DEFINER
  COST 100;

CREATE OR REPLACE VIEW ships_in_range AS 
WITH 
	current_player AS (SELECT GET_PLAYER_ID(SESSION_USER) as player_id),
	players AS (SELECT ship.id, ship.name, ship.location, ship.range, ship.destroyed from ship, current_player WHERE ship.player_id=current_player.player_id),
	sns AS (SELECT  ships_near_ships.* FROM ships_near_ships, current_player WHERE ships_near_ships.player_id=current_player.player_id),
	enemies AS (SELECT ship.id, ship.name, ship.player_id, ship.destroyed, ship.current_health::numeric / ship.max_health::numeric AS health, ship.location from ship WHERE ship.player_id in (SELECT DISTINCT sns.player_id FROM sns))
SELECT 
	enemies.id as id,
	players.id as ship_in_range_of,
	enemies.player_id as player_id,
	enemies.name as name,
	enemies.health as health,
	--enemies.current_health as current_health,
	--enemies.max_health as max_health,
	--enemies.current_fuel as current_fuel,
	--enemies.max_fuel as max_fuel,
	--enemies.max_speed as max_speed,
	--enemies.range as range,
	--enemies.attack as attack,
	--enemies.defense as defense,
	--enemies.engineering as engineering,
	--enemies.prospecting as prospecting,
	enemies.location as enemy_location
FROM enemies, players, sns
  WHERE 
  NOT enemies.destroyed AND 
  NOT players.destroyed AND 
  players.id = sns.first_ship 
  AND enemies.id = sns.second_ship 
  AND (enemies.location <-> players.location) <= players.range;
	
--And we are back to the original my_ships. Repair to GET_PLAYER_ID() and some new index made this run faster than the previous fix
CREATE OR REPLACE VIEW my_ships AS 
SELECT 
	ship.id as id,
	ship.fleet_id as fleet_id,
	ship.player_id as player_id ,
	ship.name as name,
	ship.last_action_tic as last_action_tic,
	ship.last_living_tic as last_living_tic,
	ship.current_health as current_health,
	ship.max_health as max_health,
	ship.current_fuel as current_fuel,
	ship.max_fuel as max_fuel,
	ship.max_speed as max_speed,
	ship.range as range,
	ship.attack as attack,
	ship.defense as defense,
	ship.engineering as engineering,
	ship.prospecting as prospecting,
	ship.location,
	ship_control.direction as direction,
	ship_control.speed as speed,
	ship_control.destination,
	ship_control.target_speed as target_speed,
	ship_control.target_direction as target_direction,
	ship_control.repair_priority as repair_priority,
	ship_control.action as action,
	ship_control.action_target_id as action_target_id
FROM ship, ship_control 
WHERE ship.player_id=GET_PLAYER_ID(SESSION_USER) and ship.id=ship_control.ship_id and destroyed='f';


CREATE OR REPLACE RULE ship_insert AS ON INSERT TO my_ships 
	DO INSTEAD INSERT INTO ship (name, range, attack, defense, engineering, prospecting, location, last_living_tic, fleet_id) 
		VALUES (new.name, 
		COALESCE(new.range, 300), 
		COALESCE(new.attack, 5), 
		COALESCE(new.defense, 5), 
		COALESCE(new.engineering, 5), 
		COALESCE(new.prospecting, 5), 
		COALESCE(new.location, point(0,0)),
		(( SELECT tic_seq.last_value FROM tic_seq)), 
		COALESCE(new.fleet_id, NULL::integer))
  RETURNING ship.id, ship.fleet_id, ship.player_id, ship.name, ship.last_action_tic, ship.last_living_tic, ship.current_health, ship.max_health, ship.current_fuel, ship.max_fuel, ship.max_speed, 
ship.range, ship.attack, ship.defense, ship.engineering, ship.prospecting, ship.location, 0, 0, point(0,0), 0, 0, 0,''::CHARACTER(30),0;


CREATE OR REPLACE RULE ship_control_update AS ON UPDATE TO my_ships 
	DO INSTEAD ( 
		UPDATE ship_control SET 
			repair_priority = new.repair_priority,
			action = new.action,
			action_target_id = new.action_target_id
  		WHERE ship_control.ship_id = new.id;
 		UPDATE ship SET 
			name = new.name, 
			fleet_id = new.fleet_id
  		WHERE ship.id = new.id;
);


CREATE OR REPLACE FUNCTION CREATE_SHIP() RETURNS trigger AS $create_ship$
BEGIN
	--CHECK SHIP STATS
	NEW.current_health = 100; 
	NEW.max_health = 100;
	NEW.current_fuel = 100; 
	NEW.max_fuel = 100;
	NEW.max_speed = 1000;

	IF (LEAST(NEW.attack, NEW.defense, NEW.engineering, NEW.prospecting) < 0 ) THEN
		EXECUTE 'NOTIFY ' || get_player_error_channel() ||', ''When creating a new ship, Attack Defense Engineering and Prospecting cannot be values lower than zero'';';
		RETURN NULL;
	END IF; 

	IF (NEW.attack + NEW.defense + NEW.engineering + NEW.prospecting) > 20 THEN
		EXECUTE 'NOTIFY ' || get_player_error_channel() ||', ''When creating a new ship, the following must be true (Attack + Defense + Engineering + Prospecting) > 20'';';
		RETURN NULL;
	END IF; 

	
	IF not exists (select 1 from planets p where p.location ~= NEW.location and p.conqueror_id = NEW.player_id) then
		SELECT location INTO NEW.location from planets where conqueror_id=NEW.player_id limit 1;
		EXECUTE 'NOTIFY ' || get_player_error_channel() ||', ''New ship MUST be created on a planet your player has conquered'';';
		--RETURN NULL;
	END IF;

	--CHARGE ACCOUNT	
	IF NOT CHARGE('SHIP', 1) THEN 
		EXECUTE 'NOTIFY ' || get_player_error_channel() ||', ''Not enough funds to purchase ship'';';
		RETURN NULL;
	END IF;

	-- Set last_move_tic to force it's inclusion in the next cache update
	NEW.last_move_tic := (SELECT last_value FROM tic_seq); 
	--at least warn the other players that there is a new ship. The player's own cache will be rebuilt at next tic
	  insert into ships_near_ships (first_ship, second_ship, location_first, location_second, distance)
	     select s1.id, NEW.id, s1.location, NEW.location, NEW.location <-> s1.location
              from ship s1
              where s1.id <> NEW.id and (s1.location <-> NEW.location) < s1.range;

	RETURN NEW; 
END
$create_ship$ LANGUAGE plpgsql;

CREATE TRIGGER CREATE_SHIP BEFORE INSERT ON ship
  FOR EACH ROW EXECUTE PROCEDURE CREATE_SHIP(); 


CREATE OR REPLACE FUNCTION create_ship_event()
  RETURNS trigger AS
$BODY$
BEGIN
	INSERT INTO ship_flight_recorder(ship_id, tic, location, player_id) VALUES(NEW.id, (SELECT last_value FROM tic_seq)-1, NEW.location, NEW.player_id);

	INSERT INTO event(action, player_id_1, ship_id_1, location, public, tic)
		VALUES('BUY_SHIP',NEW.player_id, NEW.id, NEW.location, 'f',(SELECT last_value FROM tic_seq));
	RETURN NULL; 
END
$BODY$
  LANGUAGE plpgsql VOLATILE SECURITY DEFINER
  COST 100;

CREATE TRIGGER CREATE_SHIP_EVENT AFTER INSERT ON ship
  FOR EACH ROW EXECUTE PROCEDURE CREATE_SHIP_EVENT(); 


CREATE OR REPLACE FUNCTION destroy_ship()
  RETURNS trigger AS
$BODY$
BEGIN
	IF ( NOT OLD.destroyed = NEW.destroyed ) AND NEW.destroyed='t' THEN
	        UPDATE player SET balance=balance+(select cost from price_list where code='SHIP') WHERE id=OLD.player_id;
		
		delete from ships_near_planets where ship = NEW.id;
	   	delete from ships_near_ships where first_ship = NEW.id;
	   	delete from ships_near_ships where second_ship = NEW.id;

		INSERT INTO event(action, player_id_1, ship_id_1, location, public, tic)
			VALUES('EXPLODE',NEW.player_id, NEW.id, NEW.location, 't',(SELECT last_value FROM tic_seq));

	END IF;
	RETURN NULL;
END
$BODY$
  LANGUAGE plpgsql VOLATILE SECURITY DEFINER
  COST 100;

CREATE TRIGGER DESTROY_SHIP AFTER UPDATE ON ship 
 FOR EACH ROW EXECUTE PROCEDURE DESTROY_SHIP();


CREATE OR REPLACE FUNCTION CREATE_SHIP_CONTROLLER() RETURNS trigger AS $create_ship_controller$
BEGIN
	INSERT INTO ship_control(ship_id, player_id) VALUES(NEW.id, NEW.player_id);
	RETURN NEW;
END
$create_ship_controller$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE TRIGGER CREATE_SHIP_CONTROLLER AFTER INSERT ON ship
  FOR EACH ROW EXECUTE PROCEDURE CREATE_SHIP_CONTROLLER(); 



CREATE OR REPLACE FUNCTION ship_move_update()
  RETURNS trigger AS
$BODY$
BEGIN
  IF NOT NEW.location ~= OLD.location THEN
    INSERT INTO ship_flight_recorder(ship_id, tic, location, player_id) VALUES(NEW.id, (SELECT last_value FROM tic_seq), NEW.location, NEW.player_id);
  END IF;
  RETURN NULL;
END $BODY$
  LANGUAGE plpgsql VOLATILE SECURITY DEFINER
  COST 100;
       
                
CREATE TRIGGER SHIP_MOVE_UPDATE AFTER UPDATE ON ship
        FOR EACH ROW EXECUTE PROCEDURE SHIP_MOVE_UPDATE();
        

CREATE TABLE fleet
(
	id integer NOT NULL PRIMARY KEY,
	player_id integer NOT NULL REFERENCES player(id) DEFAULT GET_PLAYER_ID(SESSION_USER),
	name character varying(50),
	script TEXT DEFAULT 'Select 1;'::TEXT,
	script_declarations TEXT  DEFAULT 'fakevar smallint;'::TEXT,
	last_script_update_tic integer DEFAULT '0',
	enabled boolean NOT NULL DEFAULT 'f',
	runtime interval DEFAULT '00:00:00'::interval 
);

CREATE SEQUENCE fleet_id_seq
  INCREMENT 1
  MINVALUE 1
  MAXVALUE 9223372036854775807
  START 1
  CACHE 1;

ALTER TABLE ship ADD CONSTRAINT fk_ship_fleet FOREIGN KEY (fleet_id) REFERENCES fleet (id) ON DELETE SET NULL;

CREATE VIEW my_fleets AS
SELECT 
	id,
	name,
	script,
	script_declarations,
	last_script_update_tic,
	enabled,
	runtime
FROM 
	fleet
WHERE player_id=GET_PLAYER_ID(SESSION_USER);

CREATE RULE fleet_insert AS ON INSERT TO my_fleets
	DO INSTEAD INSERT INTO fleet(player_id,  name) VALUES(GET_PLAYER_ID(SESSION_USER),  NEW.name);

CREATE RULE fleet_update AS ON UPDATE TO my_fleets 
	DO INSTEAD UPDATE fleet
		SET 
			name=NEW.name,
			script=NEW.script,
			script_declarations=NEW.script_declarations,
			enabled=NEW.enabled

		WHERE id=NEW.id;

CREATE OR REPLACE FUNCTION DISABLE_FLEET(fleet_id integer) RETURNS boolean AS $disable_fleet$
DECLARE
BEGIN
	IF CURRENT_USER = 'schemaverse' THEN
		UPDATE fleet SET enabled='f' WHERE id=fleet_id;
	ELSE 
		UPDATE fleet SET enabled='f' WHERE id=fleet_id  AND player_id=GET_PLAYER_ID(SESSION_USER);
	END IF;
	RETURN 't'; 
END $disable_fleet$  LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION GET_FLEET_RUNTIME(fleet_id integer, username character varying) RETURNS interval AS $get_fleet_runtime$
DECLARE
	fleet_runtime interval;
BEGIN
	SELECT runtime INTO fleet_runtime FROM fleet WHERE id=fleet_id AND (GET_PLAYER_ID(username)=player_id);
	RETURN fleet_runtime;
END 
$get_fleet_runtime$ LANGUAGE plpgsql SECURITY DEFINER;


CREATE OR REPLACE FUNCTION FLEET_SCRIPT_UPDATE() RETURNS trigger AS $fleet_script_update$
DECLARE
	player_username character varying;
	secret character varying;
	current_tic integer;
BEGIN
	IF ((NEW.script = OLD.script) AND (NEW.script_declarations = OLD.script_declarations)) THEN
		RETURN NEW;
	END IF;

	SELECT last_value INTO current_tic FROM tic_seq;

	IF NEW.last_script_update_tic = current_tic THEN
		NEW.script := OLD.script;
		NEW.script_declarations := OLD.script_declarations;
		EXECUTE 'NOTIFY ' || get_player_error_channel() ||', ''Fleet scripts can only be updated once a tic. While you wait why not brush up on your PL/pgSQL skills? '';';
		RETURN NEW;
	END IF;

	IF NEW.script LIKE '%$fleet_script_%' OR NEW.script_declarations LIKE '%$fleet_script_%' THEN
		EXECUTE 'NOTIFY ' || get_player_error_channel() ||', ''TILT!'';';
		RETURN NEW; NEW.last_script_update_tic := current_tic;
	END IF;

	--secret to stop SQL injections here
	--Made completely useless by the SETSEED() function within PostgreSQL
	secret := 'fleet_script_' || (RANDOM()*1000000)::integer;
	EXECUTE 'CREATE OR REPLACE FUNCTION FLEET_SCRIPT_'|| NEW.id ||'() RETURNS boolean as $'||secret||'$
	DECLARE
		this_fleet_id integer;
		this_fleet_script_start timestamptz;
		' || NEW.script_declarations || '
	BEGIN
		this_fleet_script_start := current_timestamp;
		this_fleet_id := '|| NEW.id||';
		' || NEW.script || '
		PERFORM insert_fleet_event(this_fleet_id, ( current_timestamp - this_fleet_script_start )::interval) ;
		RETURN 1;
	END $'||secret||'$ LANGUAGE plpgsql;'::TEXT;
	
	SELECT GET_PLAYER_USERNAME(player_id) INTO player_username FROM fleet WHERE id=NEW.id;
	EXECUTE 'REVOKE ALL ON FUNCTION FLEET_SCRIPT_'|| NEW.id ||'() FROM PUBLIC'::TEXT;
	EXECUTE 'REVOKE ALL ON FUNCTION FLEET_SCRIPT_'|| NEW.id ||'() FROM players'::TEXT;
	EXECUTE 'GRANT EXECUTE ON FUNCTION FLEET_SCRIPT_'|| NEW.id ||'() TO '|| player_username ||''::TEXT;
	
	RETURN NEW;
END $fleet_script_update$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE TRIGGER FLEET_SCRIPT_UPDATE BEFORE UPDATE ON fleet
  FOR EACH ROW EXECUTE PROCEDURE FLEET_SCRIPT_UPDATE();  


CREATE OR REPLACE FUNCTION REFUEL_SHIP(ship_id integer) RETURNS integer AS $refuel_ship$
DECLARE
	current_fuel_reserve integer;
	new_fuel_reserve integer;
	
	current_ship_fuel integer;
	new_ship_fuel integer;
	
	max_ship_fuel integer;
BEGIN

	SELECT fuel_reserve INTO current_fuel_reserve FROM player WHERE username=SESSION_USER;
	SELECT current_fuel, max_fuel INTO current_ship_fuel, max_ship_fuel FROM ship WHERE id=ship_id;

	
	new_fuel_reserve = current_fuel_reserve - (max_ship_fuel - current_ship_fuel);
	IF new_fuel_reserve < 0 THEN
		new_ship_fuel = max_ship_fuel - (@new_fuel_reserve);
		new_fuel_reserve = 0;
	ELSE
		new_ship_fuel = max_ship_fuel;
	END IF;
	
	UPDATE ship SET current_fuel=new_ship_fuel WHERE id=ship_id;
	UPDATE player SET fuel_reserve=new_fuel_reserve WHERE username=SESSION_USER;

	INSERT INTO event(action, player_id_1, ship_id_1, descriptor_numeric, public, tic)
		VALUES('REFUEL_SHIP',GET_PLAYER_ID(SESSION_USER), ship_id , new_ship_fuel, 'f',(SELECT last_value FROM tic_seq));

	RETURN new_ship_fuel;
END
$refuel_ship$ LANGUAGE plpgsql SECURITY DEFINER;



CREATE OR REPLACE FUNCTION upgrade(reference_id integer, code character varying, quantity integer)
  RETURNS boolean AS
$BODY$
DECLARE 

	ship_value integer;
	
BEGIN
	IF code = 'SHIP' THEN
		EXECUTE 'NOTIFY ' || get_player_error_channel() ||', ''You cant upgrade ship into ship..Try to insert in my_ships'';';
		RETURN FALSE;
	END IF;
	IF code = 'FLEET_RUNTIME' THEN
	
		IF (SELECT sum(runtime) FROM fleet WHERE player_id=GET_PLAYER_ID(SESSION_USER)) > '0 minutes'::interval THEN
			IF NOT CHARGE(code, quantity) THEN
				EXECUTE 'NOTIFY ' || get_player_error_channel() ||', ''Not enough funds to increase fleet runtime'';';
				RETURN FALSE;
			END IF;
		ELSEIF quantity > 1 THEN
			IF NOT CHARGE(code, quantity-1) THEN
				EXECUTE 'NOTIFY ' || get_player_error_channel() ||', ''Not enough funds to increase fleet runtime'';';
				RETURN FALSE;
			END IF;
		END IF;
	
		UPDATE fleet SET runtime=runtime + (quantity || ' minute')::interval where id=reference_id;

		INSERT INTO event(action, player_id_1, referencing_id, public, tic)
			VALUES('FLEET',GET_PLAYER_ID(SESSION_USER), reference_id , 'f',(SELECT last_value FROM tic_seq));
		RETURN TRUE;

	END IF;

	IF code = 'REFUEL' THEN
		EXECUTE 'NOTIFY ' || get_player_error_channel() ||', ''Please use REFUEL_SHIP(ship_id) to refuel a ship now.'';';
		RETURN FALSE;

	END IF;


	IF code = 'RANGE' THEN
		SELECT range INTO ship_value FROM ship WHERE id=reference_id;
		IF (ship_value + quantity) > GET_NUMERIC_VARIABLE('MAX_SHIP_RANGE') THEN
			EXECUTE 'NOTIFY ' || get_player_error_channel() ||', ''The range of a ship cannot exceed the MAX_SHIP_RANGE system value of '|| GET_NUMERIC_VARIABLE('MAX_SHIP_RANGE')||''';';
			RETURN FALSE;
		ELSE
			IF NOT CHARGE(code, quantity) THEN
				EXECUTE 'NOTIFY ' || get_player_error_channel() ||', ''Not enough funds to perform upgrade'';';
				RETURN FALSE;
			END IF;			
			UPDATE ship SET range=(range+quantity) WHERE id=reference_id ;
		END IF;
	ELSEIF code = 'MAX_SPEED' THEN
		SELECT max_speed INTO ship_value FROM ship WHERE id=reference_id;
		IF (ship_value + quantity) > GET_NUMERIC_VARIABLE('MAX_SHIP_SPEED') THEN
			EXECUTE 'NOTIFY ' || get_player_error_channel() ||', ''The max speed of a ship cannot exceed the MAX_SHIP_SPEED system value of '|| GET_NUMERIC_VARIABLE('MAX_SHIP_SPEED')||''';';
			RETURN FALSE;
		ELSE
			IF NOT CHARGE(code, quantity) THEN
				EXECUTE 'NOTIFY ' || get_player_error_channel() ||', ''Not enough funds to perform upgrade'';';
				RETURN FALSE;
			END IF;			
			UPDATE ship SET max_speed=(max_speed+quantity) WHERE id=reference_id ;
		END IF;
	ELSEIF code = 'MAX_HEALTH' THEN
		SELECT max_health INTO ship_value FROM ship WHERE id=reference_id;
		IF (ship_value + quantity) > GET_NUMERIC_VARIABLE('MAX_SHIP_HEALTH') THEN
			EXECUTE 'NOTIFY ' || get_player_error_channel() ||', ''The max health of a ship cannot exceed the MAX_SHIP_HEALTH system value of '|| GET_NUMERIC_VARIABLE('MAX_SHIP_HEALTH')||''';';
			RETURN FALSE;
		ELSE
			IF NOT CHARGE(code, quantity) THEN
				EXECUTE 'NOTIFY ' || get_player_error_channel() ||', ''Not enough funds to perform upgrade'';';
				RETURN FALSE;
			END IF;	
			UPDATE ship SET max_health=(max_health+quantity) WHERE id=reference_id ;
		END IF;
	ELSEIF code = 'MAX_FUEL' THEN
		SELECT max_fuel INTO ship_value FROM ship WHERE id=reference_id;
		IF (ship_value + quantity) > GET_NUMERIC_VARIABLE('MAX_SHIP_FUEL') THEN
			EXECUTE 'NOTIFY ' || get_player_error_channel() ||', ''The max fuel of a ship cannot exceed the MAX_SHIP_FUEL system value of '|| GET_NUMERIC_VARIABLE('MAX_SHIP_FUEL')||''';';
			RETURN FALSE;
		ELSE
			IF NOT CHARGE(code, quantity) THEN
				EXECUTE 'NOTIFY ' || get_player_error_channel() ||', ''Not enough funds to perform upgrade'';';
				RETURN FALSE;
			END IF;	
			UPDATE ship SET max_fuel=(max_fuel+quantity) WHERE id=reference_id ;
		END IF;
	ELSE
		SELECT (attack+defense+prospecting+engineering) INTO ship_value FROM ship WHERE id=reference_id;
		IF (ship_value + quantity) > GET_NUMERIC_VARIABLE('MAX_SHIP_SKILL') THEN
			EXECUTE 'NOTIFY ' || get_player_error_channel() ||', ''The total skill of a ship cannot exceed the MAX_SHIP_SKILL system value of '|| GET_NUMERIC_VARIABLE('MAX_SHIP_SKILL')||''';';
			RETURN FALSE;
		ELSE
			IF NOT CHARGE(code, quantity) THEN
				EXECUTE 'NOTIFY ' || get_player_error_channel() ||', ''Not enough funds to perform upgrade'';';
				RETURN FALSE;
			END IF;		
			IF code = 'ATTACK' THEN
				UPDATE ship SET attack=(attack+quantity) WHERE id=reference_id ;
			ELSEIF code = 'DEFENSE' THEN
				UPDATE ship SET defense=(defense+quantity) WHERE id=reference_id ;
			ELSEIF code = 'PROSPECTING' THEN
				UPDATE ship SET prospecting=(prospecting+quantity) WHERE id=reference_id ;
			ELSEIF code = 'ENGINEERING' THEN
				UPDATE ship SET engineering=(engineering+quantity) WHERE id=reference_id ;	
			END IF;
		END IF;
	
	END IF;	

	INSERT INTO event(action, player_id_1, ship_id_1, descriptor_numeric,descriptor_string, public, tic)
	VALUES('UPGRADE_SHIP',GET_PLAYER_ID(SESSION_USER), reference_id , quantity, code, 'f',(SELECT last_value FROM tic_seq));

	RETURN TRUE;
END 
$BODY$
  LANGUAGE plpgsql VOLATILE SECURITY DEFINER;

CREATE OR REPLACE FUNCTION CONVERT_RESOURCE(current_resource_type character varying, amount integer) RETURNS integer as $convert_resource$
DECLARE
	amount_of_new_resource integer;
	fuel_check integer;
	money_check integer;
BEGIN
	SELECT INTO fuel_check, money_check fuel_reserve, balance FROM player WHERE id=GET_PLAYER_ID(SESSION_USER);
	IF current_resource_type = 'FUEL' THEN
		IF amount >= 0 AND  amount <= fuel_check THEN
			SELECT INTO amount_of_new_resource (fuel_reserve/balance*amount)::integer FROM player WHERE id=0;
			UPDATE player SET fuel_reserve=fuel_reserve-amount, balance=balance+amount_of_new_resource WHERE id=GET_PLAYER_ID(SESSION_USER);
			--UPDATE player SET balance=balance-amount, fuel_reserve=fuel_reserve+amount_of_new_resource WHERE id=0;
		ELSE
  			EXECUTE 'NOTIFY ' || get_player_error_channel() ||', ''You do not have that much fuel to convert'';';
		END IF;
	ELSEIF current_resource_type = 'MONEY' THEN
		IF  amount >= 0 AND amount <= money_check THEN
			SELECT INTO amount_of_new_resource (balance/fuel_reserve*amount)::integer FROM player WHERE id=0;
			UPDATE player SET balance=balance-amount, fuel_reserve=fuel_reserve+amount_of_new_resource WHERE id=GET_PLAYER_ID(SESSION_USER);
			--UPDATE player SET fuel_reserve=fuel_reserve-amount, balance=balance+amount_of_new_resource WHERE id=0;

		ELSE
  			EXECUTE 'NOTIFY ' || get_player_error_channel() ||', ''You do not have that much money to convert'';';
		END IF;
	END IF;

	RETURN amount_of_new_resource;
END
$convert_resource$ LANGUAGE plpgsql SECURITY DEFINER;


CREATE OR REPLACE FUNCTION discover_item()
  RETURNS trigger AS
$BODY$
DECLARE
	found_item RECORD;

BEGIN
	FOR found_item IN SELECT * FROM item_location WHERE location ~= NEW.location LOOP
		DELETE FROM item_location WHERE location ~= found_item.location and system_name=found_item.system_name;
		INSERT INTO player_inventory(player_id, item) VALUES(NEW.player_id, found_item.system_name);
		INSERT INTO event(action, player_id_1, ship_id_1, location, descriptor_string, public, tic)
			VALUES('FIND_ITEM',NEW.player_id, NEW.id , NEW.location, found_item.system_name, 'f',(SELECT last_value FROM tic_seq));
	END LOOP;
	RETURN NEW;	
END
$BODY$
  LANGUAGE plpgsql VOLATILE SECURITY DEFINER
  COST 100;

CREATE TRIGGER DISCOVER_ITEM AFTER UPDATE ON ship
  FOR EACH ROW EXECUTE PROCEDURE DISCOVER_ITEM();

CREATE TABLE action 
(
	name character(30) NOT NULL PRIMARY KEY,
	string TEXT NOT NULL
);
			
INSERT INTO action VALUES 
	('BUY_SHIP','(#%player_id_1%)%player_name_1% has purchased a new ship (#%ship_id_1%)%ship_name_1% and sent it to location %location%'::TEXT),
	('UPGRADE_FLEET','(#%player_id_1%)%player_name_1%''s new fleet (#%referencing_id%)%descriptor_string% has been upgraded'::TEXT),
	('UPGRADE_SHIP','(#%player_id_1%)%player_name_1% has upgraded the %descriptor_string% on ship (#%ship_id_1%)%ship_name_1% +%descriptor_numeric%'::TEXT),
	('REFUEL_SHIP','(#%player_id_1%)%player_name_1% has refueled the ship (#%ship_id_1%)%ship_name_1% +%descriptor_numeric%'::TEXT),
	('ATTACK','(#%player_id_1%)%player_name_1%''s ship (#%ship_id_1%)%ship_name_1% has attacked (#%player_id_2%)%player_name_2%''s ship (#%ship_id_2%)%ship_name_2% causing %descriptor_numeric% of damage'::TEXT),
	('EXPLODE','(#%player_id_1%)%player_name_1%''s ship (#%ship_id_1%)%ship_name_1% has been destroyed'::TEXT),
	('MINE_SUCCESS','(#%player_id_1%)%player_name_1%''s ship (#%ship_id_1%)%ship_name_1% has successfully mined %descriptor_numeric% fuel from the planet (#%referencing_id%)%planet_name%'::TEXT),
	('MINE_FAIL','(#%player_id_1%)%player_name_1%''s ship (#%ship_id_1%)%ship_name_1% has failed to mine the planet (#%referencing_id%)%planet_name%'::TEXT),
	('FLEET_SUCCESS','(#%player_id_1%)%player_name_1%''s fleet #%referencing_id% completed successfully. Execution took: %descriptor_string%'::TEXT),
	('FLEET_FAIL','(#%player_id_1%)%player_name_1%''s fleet #%referencing_id% encountered an issue during execution and was terminated. The error logged was: %descriptor_string%'::TEXT),
	('REPAIR','(#%player_id_1%)%player_name_1%''s ship (#%ship_id_1%)%ship_name_1% has repaired (#%ship_id_2%)%ship_name_2% by %descriptor_numeric%'::TEXT),
	('TRADE_START','(#%player_id_1%)%player_name_1% has started a trade (#%referencing_id%) with (#%player_id_2%)%player_name_2%'::TEXT),
	('TRADE_ADD_ITEM','(#%player_id_1%)%player_name_1% has added %descriptor_numeric% of %descriptor_string% to the trade (#%referencing_id%)'::TEXT),
	('TRADE_ADD_SHIP','(#%player_id_1%)%player_name_1% has added the ship (#%ship_id_1%)%ship_name_1% to the trade (#%referencing_id%)'::TEXT),
	('TRADE_DELETE_ITEM','(#%player_id_1%)%player_name_1% has removed %descriptor_numeric% of %descriptor_string% from the trade (#%referencing_id%)'::TEXT),
	('TRADE_DELETE_SHIP','(#%player_id_1%)%player_name_1% has deleted the ship (#%ship_id_1%)%ship_name_1% from the trade (#%referencing_id%)'::TEXT),
	('TRADE_CANCEL','(#%player_id_1%)%player_name_1% has canceled the trade (#%referencing_id%) with (#%player_id_2%)%player_name_2%'::TEXT),
	('TRADE_CONFIRM','(#%player_id_1%)%player_name_1% has confirmed their portion of trade (#%referencing_id%)'::TEXT),
	('TRADE_COMPLETE','Trade (#%referencing_id) between (#%player_id_1%)%player_name_1% and (#%player_id_2%)%player_name_2% is complete'::TEXT),
	('CONQUER','(#%player_id_1%)%player_name_1% has conquered (#%referencing_id%)%planet_name% from (#%player_id_2%)%player_name_2%' ::TEXT),
	('FIND_ITEM','(#%player_id_1%)%player_name_1% has found a %descriptor_string% floating out in space'::TEXT);


-- Allows players to add actions for items they create
CREATE OR REPLACE FUNCTION EDIT_ACTION() RETURNS trigger as $edit_action$
DECLARE
	check_creator integer;
BEGIN
	IF SESSION_USER = 'schemaverse' THEN
		RETURN NEW;
	ELSE 
		SELECT count(*) INTO check_creator FROM item WHERE creator=GET_PLAYER_ID(SESSION_USER) AND system_name=NEW.name;
		IF check_creator > 0 THEN
			RETURN NEW;
		END IF;
	END IF;
        RETURN NULL;
END
$edit_action$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE TRIGGER EDIT_ACTION BEFORE INSERT OR UPDATE ON action
  FOR EACH ROW EXECUTE PROCEDURE EDIT_ACTION();




CREATE TABLE event
(
	id integer NOT NULL PRIMARY KEY,
	action character(30) NOT NULL REFERENCES action(name),
	player_id_1 integer REFERENCES player(id),
	ship_id_1 integer REFERENCES ship(id), 
	player_id_2 integer REFERENCES player(id), 
	ship_id_2 integer REFERENCES ship(id),
	referencing_id integer,  
	descriptor_numeric numeric, 
	descriptor_string CHARACTER VARYING, 
	location point,
	public boolean DEFAULT 'f', 
	tic integer NOT NULL,
	toc timestamp NOT NULL DEFAULT NOW()
);

alter table event alter column player_id_1 set statistics 1000;
alter table event alter column player_id_2 set statistics 1000;

CREATE SEQUENCE event_id_seq
  INCREMENT 1
  MINVALUE 1
  MAXVALUE 9223372036854775807
  START 1
  CACHE 1;


CREATE OR REPLACE VIEW my_events AS 
WITH
	current_player AS (SELECT GET_PLAYER_ID(SESSION_USER) AS player_id),
	p1_event AS (SELECT * FROM event, current_player WHERE player_id_1 = current_player.player_id and public='f'),
	p2_event AS (SELECT * FROM event, current_player WHERE player_id_2 = current_player.player_id and public='f'),
	public_event AS (SELECT * FROM event, current_player WHERE public='t')
SELECT 
	p1_event.id, 
	p1_event.action, 
	p1_event.player_id_1, 
	p1_event.ship_id_1, 
	p1_event.player_id_2, 
	p1_event.ship_id_2, 
	p1_event.referencing_id, 
	p1_event.descriptor_numeric, 
	p1_event.descriptor_string, 
	p1_event.location, 
	p1_event.public, 
	p1_event.tic, 
	p1_event.toc
 FROM p1_event 
   UNION ALL 
SELECT 
	p2_event.id, 
	p2_event.action, 
	p2_event.player_id_1, 
	p2_event.ship_id_1, 
	p2_event.player_id_2, 
	p2_event.ship_id_2, 
	p2_event.referencing_id, 
	p2_event.descriptor_numeric, 
	p2_event.descriptor_string, 
	p2_event.location, 
	p2_event.public, 
	p2_event.tic, 
	p2_event.toc
 FROM p2_event 
 UNION ALL
 SELECT 
	public_event.id, 
	public_event.action, 
	public_event.player_id_1, 
	public_event.ship_id_1, 
	public_event.player_id_2, 
	public_event.ship_id_2, 
	public_event.referencing_id, 
	public_event.descriptor_numeric, 
	public_event.descriptor_string, 
	public_event.location, 
	public_event.public, 
	public_event.tic, 
	public_event.toc
 FROM public_event; 


CREATE OR REPLACE FUNCTION READ_EVENT(read_event_id integer) RETURNS 
TEXT AS $read_event$
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
	             replace(action.string,
	              '%player_id_1%', 	player_id_1::TEXT),
	             '%player_name_1%', GET_PLAYER_USERNAME(player_id_1)),
	            '%player_id_2%', 	COALESCE(player_id_2::TEXT,'Unknown')),
	           '%player_name_2%', 	COALESCE(GET_PLAYER_USERNAME(player_id_2),'Unknown')),
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
$read_event$ LANGUAGE plpgsql;


CREATE OR REPLACE FUNCTION insert_fleet_event(fleet integer, took interval)
  RETURNS boolean AS
$BODY$
BEGIN
	INSERT INTO event(action, player_id_1, public, tic, descriptor_string, referencing_id) 
		VALUES('FLEET_SUCCESS',GET_PLAYER_ID(SESSION_USER),'f',(SELECT last_value FROM tic_seq),took, fleet) ;
	RETURN 't';
END $BODY$
  LANGUAGE plpgsql VOLATILE SECURITY DEFINER
  COST 100;


CREATE TABLE trade
(
	id integer NOT NULL PRIMARY KEY,
	player_id_1 integer NOT NULL REFERENCES player(id),
	player_id_2 integer NOT NULL REFERENCES player(id),
	confirmation_1 integer DEFAULT '0',
	confirmation_2 integer DEFAULT '0',
	complete boolean DEFAULT 'f'
);
CREATE SEQUENCE trade_id_seq
  INCREMENT 1
  MINVALUE 1
  MAXVALUE 9223372036854775807
  START 1
  CACHE 1;

CREATE VIEW my_trades AS
SELECT * FROM trade WHERE GET_PLAYER_ID(SESSION_USER) IN (player_id_1, player_id_2);

CREATE RULE trade_insert AS ON INSERT TO my_trades 
	DO INSTEAD 
		INSERT INTO trade(player_id_1, player_id_2, confirmation_1, confirmation_2) 
		VALUES(NEW.player_id_1,NEW.player_id_2,NEW.confirmation_1,NEW.confirmation_2);


CREATE OR REPLACE FUNCTION CREATE_TRADE_EVENT() RETURNS trigger AS $create_trade_event$
BEGIN
	INSERT INTO event(action, player_id_1, player_id_2, referencing_id, public, tic)
		VALUES('TRADE_START',NEW.player_id_1, NEW.player_id_2 , NEW.id, 'f',(SELECT last_value FROM tic_seq));
        RETURN NULL;
END
$create_trade_event$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE TRIGGER CREATE_TRADE_EVENT AFTER INSERT ON trade
  FOR EACH ROW EXECUTE PROCEDURE CREATE_TRADE_EVENT();



CREATE RULE trade_update AS ON UPDATE TO my_trades 
	DO INSTEAD UPDATE trade 
		SET 
			player_id_1=NEW.player_id_1,
			player_id_2=NEW.player_id_2,
			confirmation_1=NEW.confirmation_1,
			confirmation_2=NEW.confirmation_2
		WHERE id=NEW.id;

CREATE RULE trade_delete AS ON DELETE TO my_trades
DO INSTEAD 
(
	DELETE FROM trade WHERE id=OLD.id;
);

CREATE OR REPLACE FUNCTION DELETE_TRADE_EVENT() RETURNS trigger AS $delete_trade_event$
BEGIN
	INSERT INTO event(action, player_id_1, player_id_2, referencing_id, public, tic)
		VALUES('TRADE_CANCEL',OLD.player_id_1, OLD.player_id_2 , OLD.id, 'f',(SELECT last_value FROM tic_seq));
        RETURN NULL;
END
$delete_trade_event$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE TRIGGER DELETE_TRADE_EVENT AFTER DELETE ON trade
  FOR EACH ROW EXECUTE PROCEDURE DELETE_TRADE_EVENT();



CREATE TABLE trade_item 
(
	id integer NOT NULL PRIMARY KEY,
	trade_id integer NOT NULL REFERENCES trade(id),
	player_id integer NOT NULL REFERENCES player(id) DEFAULT get_player_id(SESSION_USER),
	description_code character varying  NOT NULL,
	quantity integer,
	descriptor character varying
);

CREATE SEQUENCE trade_item_id_seq
  INCREMENT 1
  MINVALUE 1
  MAXVALUE 9223372036854775807
  START 1
  CACHE 1;


CREATE VIEW trade_items AS
SELECT 
	trade_item.id as id,
	trade_item.trade_id as trade_id,
	trade_item.player_id as player_id,
	trade_item.description_code as description_code,
	trade_item.quantity as quantity,
	trade_item.descriptor as descriptor	
FROM  trade_item WHERE 
trade_id in (select id from trade where GET_PLAYER_ID(SESSION_USER) IN (trade.player_id_1, trade.player_id_2));

CREATE RULE trade_item_insert AS ON INSERT TO trade_items
        DO INSTEAD INSERT INTO trade_item(trade_id, player_id, description_code, quantity, descriptor)
                VALUES(NEW.trade_id,
                  NEW.player_id,
                  NEW.description_code,
                  NEW.quantity,
                  NEW.descriptor);

CREATE RULE trade_item_delete AS ON DELETE TO trade_items
        DO INSTEAD
		DELETE FROM trade_item WHERE id=OLD.id;
			

CREATE VIEW trade_ship_stats AS
SELECT 
	trade_item.id as id,
	trade_item.trade_id as trade_id,
	trade_item.player_id as player_id,
	trade_item.description_code as description_code,
	trade_item.quantity as quantity,
	trade_item.descriptor as descriptor,
	ship.id as ship_id,
	ship.name as ship_name,
	ship.current_health as ship_current_health,
	ship.max_health as ship_max_health,
	ship.current_fuel as ship_current_fuel,
	ship.max_fuel as ship_max_fuel,
	ship.max_speed as ship_max_speed,
	ship.range as ship_range,
	ship.attack as ship_attack,
	ship.defense as ship_defense,
	ship.engineering as ship_engineering,
	ship.prospecting as ship_prospecting,
	ship.location as ship_location
FROM trade, trade_item, ship WHERE 
GET_PLAYER_ID(SESSION_USER) IN (trade.player_id_1, trade.player_id_2)
AND
trade.id=trade_item.trade_id
AND
trade.complete='f'
AND
trade_item.description_code ='SHIP' 
AND
ship.id=CAST(trade_item.descriptor as integer);



CREATE OR REPLACE FUNCTION ADD_TRADE_ITEM() RETURNS trigger AS $add_trade_item$
DECLARE
	check_value integer;
	
	trader_1 integer;
	trader_2 integer;

	completed boolean;
BEGIN
	SELECT INTO trader_1, trader_2, completed player_id_1, player_id_2, complete  FROM trade WHERE id=NEW.trade_id;
	IF completed = 't' THEN
		EXECUTE 'NOTIFY ' || get_player_error_channel() ||', ''Trade #'||NEW.trade_id ||' is complete. Cannot make changes'';';
		RETURN NULL;
	END IF;

	UPDATE trade SET confirmation_1=0, confirmation_2=0 WHERE id=NEW.trade_id;

	
	IF NEW.description_code = 'FUEL' THEN
		SELECT fuel_reserve INTO check_value FROM player WHERE id=NEW.player_id;
		IF check_value > NEW.quantity THEN 
			UPDATE player SET fuel_reserve=fuel_reserve-NEW.quantity WHERE id = NEW.player_id;

			INSERT INTO event(action, player_id_1, player_id_2, referencing_id, descriptor_numeric, descriptor_string, public, tic)
				VALUES('TRADE_ADD_ITEM',trader_1, trader_2 , NEW.trade_id, NEW.quantity, NEW.description_code,'f',(SELECT last_value FROM tic_seq));

		ELSE
			EXECUTE 'NOTIFY ' || get_player_error_channel() ||', ''You cant add more fuel to a trade then you hold in my_player.fuel_reserve'';';
			RETURN NULL;
		END IF;
	ELSEIF NEW.description_code = 'MONEY' THEN
		SELECT balance INTO check_value FROM player WHERE id=NEW.player_id;
		IF check_value > NEW.quantity THEN 
			UPDATE player SET balance=balance-NEW.quantity WHERE id = NEW.player_id;

			INSERT INTO event(action, player_id_1, player_id_2, referencing_id, descriptor_numeric, descriptor_string, public, tic)
				VALUES('TRADE_ADD_ITEM',trader_1, trader_2 , NEW.trade_id, NEW.quantity, NEW.description_code,'f',(SELECT last_value FROM tic_seq));

		ELSE
			 EXECUTE 'NOTIFY ' || get_player_error_channel() ||', ''You cant add more money to a trade then you hold in your my_player.balance'';';
			RETURN NULL;
		END IF;
	ELSEIF NEW.description_code = 'SHIP' THEN
		SELECT player_id INTO check_value FROM ship WHERE id=CAST(NEW.descriptor as integer) AND destroyed='f';
		IF check_value = NEW.player_id THEN 
			--player 0 = schemaverse 
			UPDATE ship SET player_id=0, fleet_id=NULL WHERE id=CAST(NEW.descriptor as integer);

			INSERT INTO event(action, player_id_1, player_id_2, referencing_id, ship_id_1,  public, tic)
				VALUES('TRADE_ADD_SHIP',trader_1, trader_2 , NEW.trade_id,  NEW.descriptor::integer,'f',(SELECT last_value FROM tic_seq));

		ELSE
			EXECUTE 'NOTIFY ' || get_player_error_channel() ||', ''Trading a ship you dont own is kind of a DM'';';
			RETURN NULL;
		END IF;
	ELSEIF NEW.description_code = 'ITEM' THEN
		SELECT quantity INTO check_value FROM player_inventory WHERE player_id=NEW.player_id AND item=NEW.descriptor;
		--i need to make sure have items wont make this choke
		IF check_value > NEW.quantity THEN 
			UPDATE player_inventory SET quantity=quantity-NEW.quantity WHERE item=NEW.descriptor and player_id = NEW.player_id;

			INSERT INTO event(action, player_id_1, player_id_2, referencing_id, descriptor_numeric, descriptor_string, public, tic)
				VALUES('TRADE_ADD_ITEM',trader_1, trader_2 , NEW.trade_id, NEW.quantity, NEW.descriptor,'f',(SELECT last_value FROM tic_seq));


		ELSE
			EXECUTE 'NOTIFY ' || get_player_error_channel() ||', ''You do not own enough of that item to add it'';';
			RETURN NULL;
		END IF;
	END IF;
	
	RETURN NEW;
END
$add_trade_item$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE TRIGGER INCLUDE_TRADE_ITEM BEFORE INSERT ON trade_item
  FOR EACH ROW EXECUTE PROCEDURE ADD_TRADE_ITEM(); 


CREATE OR REPLACE FUNCTION DELETE_TRADE_ITEM() RETURNS trigger AS $delete_trade_item$
DECLARE
	
	trader_1 integer;
	trader_2 integer;
	completed integer;

BEGIN
	SELECT INTO trader_1, trader_2, completed player_id_1, player_id_2, complete FROM trade WHERE id=OLD.trade_id;
	IF completed = 't' THEN
		EXECUTE 'NOTIFY ' || get_player_error_channel() ||', ''Trade #'||OLD.trade_id ||' is complete. Cannot make changes'';';
		RETURN NULL;
	END IF;


	UPDATE trade SET confirmation_1=0, confirmation_2=0 WHERE id=OLD.trade_id;

	IF OLD.description_code = 'FUEL' THEN
		UPDATE player SET fuel_reserve=fuel_reserve+OLD.quantity WHERE id = OLD.player_id;

		INSERT INTO event(action, player_id_1, player_id_2, referencing_id, descriptor_numeric, descriptor_string, public, tic)
			VALUES('TRADE_DELETE_ITEM',trader_1, trader_2 , OLD.trade_id, OLD.quantity, OLD.description_code,'f',(SELECT last_value FROM tic_seq));


	ELSEIF OLD.description_code = 'MONEY' THEN
		UPDATE player SET balance=balance+OLD.quantity WHERE id = OLD.player_id;
		INSERT INTO event(action, player_id_1, player_id_2, referencing_id, descriptor_numeric, descriptor_string, public, tic)
			VALUES('TRADE_DELETE_ITEM',trader_1, trader_2 , OLD.trade_id, OLD.quantity, OLD.description_code,'f',(SELECT last_value FROM tic_seq));


	ELSEIF OLD.description_code = 'SHIP' THEN
		UPDATE ship SET player_id=OLD.player_id, fleet_id=NULL WHERE id = CAST(OLD.descriptor as integer);

		INSERT INTO event(action, player_id_1, player_id_2, referencing_id, ship_id_1,  public, tic)
			VALUES('TRADE_DELETE_SHIP',trader_1, trader_2 , OLD.trade_id, OLD.descriptor::integer,'f',(SELECT last_value FROM tic_seq));

	ELSEIF OLD.description_code = 'ITEM' THEN
		INSERT INTO player_inventory(player_id, item, quantity) VALUES(OLD.player_id, OLD.descriptor, OLD.quantity); 
		INSERT INTO event(action, player_id_1, player_id_2, referencing_id, descriptor_numeric, descriptor_string, public, tic)
			VALUES('TRADE_DELETE_ITEM',trader_1, trader_2 , OLD.trade_id, OLD.quantity, OLD.descriptor,'f',(SELECT last_value FROM tic_seq));

	END IF;

	RETURN OLD;
END
$delete_trade_item$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE TRIGGER DELETE_TRADE_ITEM BEFORE DELETE ON trade_item
  FOR EACH ROW EXECUTE PROCEDURE DELETE_TRADE_ITEM(); 

CREATE OR REPLACE FUNCTION TRADE_CONFIRMATION() RETURNS trigger AS $trade_confirmation$
DECLARE 
	trade_items RECORD;
	recipient integer;
	giver integer;
	--hot

BEGIN
	IF NEW.complete = 'f' AND NEW.confirmation_1=NEW.player_id_1 AND NEW.confirmation_2=NEW.player_id_2 THEN
		FOR trade_items IN SELECT * FROM trade_item WHERE trade_id = NEW.id  LOOP 
	
			IF NEW.player_id_1 = trade_items.player_id THEN
				giver := NEW.player_id_1;
				recipient := NEW.player_id_2;
			ELSE
				giver := NEW.player_id_2;
				recipient := NEW.player_id_1;			
			END IF;

			IF trade_items.description_code = 'FUEL' THEN
				UPDATE player SET fuel_reserve=fuel_reserve+trade_items.quantity WHERE id = recipient;
			ELSEIF trade_items.description_code = 'MONEY' THEN
				UPDATE player SET balance=balance+trade_items.quantity WHERE id = recipient;
			ELSEIF trade_items.description_code = 'SHIP' THEN
				UPDATE ship SET player_id=recipient WHERE id=CAST(trade_items.descriptor as integer);
			ELSEIF trade_items.description_code = 'ITEM' THEN
				INSERT INTO player_inventory(player_id, item, quantity) VALUES(recipient, trade_items.descriptor, trade_items.quantity); 
			END IF;
		END LOOP;
		
		NEW.complete = 't';

		INSERT INTO event(action, player_id_1, player_id_2, referencing_id, public, tic)
			VALUES('TRADE_COMPLETE',NEW.player_id_1, NEW.player_id_2 , NEW.id,'f',(SELECT last_value FROM tic_seq));
                                                        
	END IF;

	IF NEW.complete='f' AND (NOT NEW.confirmation_1=OLD.confirmation_1) AND NEW.confirmation_1=NEW.player_id_1 THEN 
		INSERT INTO event(action, player_id_1, player_id_2, referencing_id, public, tic)
			VALUES('TRADE_CONFIRM',NEW.player_id_1, NEW.player_id_2 , NEW.id,'f',(SELECT last_value FROM tic_seq));
	ELSEIF  NEW.complete='f' AND (NOT NEW.confirmation_2=OLD.confirmation_2) AND NEW.confirmation_2=NEW.player_id_2 THEN
		INSERT INTO event(action, player_id_1, player_id_2, referencing_id, public, tic)
			VALUES('TRADE_CONFIRM',NEW.player_id_2, NEW.player_id_1 , NEW.id,'f',(SELECT last_value FROM tic_seq));
	END IF;

RETURN NEW;
END
$trade_confirmation$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE TRIGGER TRADE_CONFIRMATION BEFORE UPDATE ON trade
  FOR EACH ROW EXECUTE PROCEDURE TRADE_CONFIRMATION(); 


CREATE TABLE planet
(
	id integer NOT NULL PRIMARY KEY,
	name character varying,
	fuel integer NOT NULL DEFAULT RANDOM()*100000,
	mine_limit integer NOT NULL DEFAULT RANDOM()*100,
	difficulty integer NOT NULL DEFAULT RANDOM()*10,
	location point NOT NULL DEFAULT RANDOM_POINT(),
	conqueror_id integer REFERENCES player(id)
);

CREATE SEQUENCE planet_id_seq
  INCREMENT 1
  MINVALUE 1
  MAXVALUE 9223372036854775807
  START 1
  CACHE 1;

--The following will generate planets around the universe but is a bit sketch
--The given start and stop paramters will define where approximately planets will be generated
--The smaller the numbers given, the closer to the center planets will be created. 
create or replace function generate_planets(start integer, stop integer) returns boolean as $generate_planets$
declare
	new_planet record;
begin
	for new_planet in select
                nextval('planet_id_seq') as id,
                CASE generate_series * (RANDOM() * 11)::integer % 11
                  WHEN 0 THEN 'Aethra_' || generate_series
                         WHEN 1 THEN 'Mony_' || generate_series
                         WHEN 2 THEN 'Semper_' || generate_series
                         WHEN 3 THEN 'Voit_' || generate_series
                         WHEN 4 THEN 'Lester_' || generate_series 
                         WHEN 5 THEN 'Rio_' || generate_series 
                         WHEN 6 THEN 'Zergon_' || generate_series 
                         WHEN 7 THEN 'Cannibalon_' || generate_series
                         WHEN 8 THEN 'Omicron Persei_' || generate_series
                         WHEN 9 THEN 'Urectum_' || generate_series
                         WHEN 10 THEN 'Wormulon_' || generate_series
 			END as name,
                (RANDOM() * 100)::integer as mine_limit,
                (RANDOM() * 10)::integer as difficulty,
		point (
                CASE (RANDOM() * 10)::integer % 4
                        WHEN 0 THEN (RANDOM() * generate_series * 2000)::integer
                        WHEN 1 THEN (RANDOM() * generate_series * 2000 * -1)::integer
                        WHEN 2 THEN (RANDOM() * generate_series)::integer
                        WHEN 3 THEN (RANDOM() * generate_series * -1)::integer
		END,
                CASE (RANDOM() * 10)::integer % 4
                        WHEN 0 THEN (RANDOM() * generate_series * 2000)::integer
                        WHEN 1 THEN (RANDOM() * generate_series * 2000 * -1)::integer
		     	WHEN 2 THEN (RANDOM() * generate_series)::integer
                        WHEN 3 THEN (RANDOM() * generate_series * -1)::integer		
		END) as location
        from generate_series(start,stop)
	LOOP
		-- Change in logic: don't create a new planet within 3000 units radius of an existing one
		if not exists (select 1 from planet where (location <-> NEW.location) < 3000) then
			insert into planet(id, name, mine_limit, difficulty, location)
				VALUES(new_planet.id, new_planet.name, new_planet.mine_limit, new_planet.difficulty, new_planet.location);
		END IF;	
	end loop;
	RETURN 't';
end
$generate_planets$ language plpgsql;


CREATE OR REPLACE FUNCTION GET_PLANET_NAME(planet_id integer) RETURNS character varying AS $get_planet_name$
DECLARE 
	found_planetname character varying;
BEGIN
	SELECT name INTO found_planetname FROM planet WHERE id=planet_id;
	RETURN found_planetname;
END
$get_planet_name$ LANGUAGE plpgsql SECURITY DEFINER;


CREATE TABLE planet_miners
(
	planet_id integer REFERENCES planet(id) ON DELETE CASCADE,
	ship_id integer REFERENCES ship(id),
	PRIMARY KEY (planet_id, ship_id)
);

create unlogged table ships_near_planets (
       ship integer references ship(id) on delete cascade,
	player_id integer references player(id) on delete cascade,
       planet integer references planet(id) on delete cascade,
       primary key (ship,planet),
       ship_location point,
       planet_location point,
       distance float
);
create index snp_ship on ships_near_planets (ship);
create index snp_planet on ships_near_planets (planet);
create index snp_distance on ships_near_planets (distance);
--create index snp_loc1 on ships_near_planets using GIST (ship_location);
--create index snp_loc2 on ships_near_planets using GIST (planet_location);


CREATE OR REPLACE FUNCTION update_ships_near_planets()
  RETURNS boolean AS
$BODY$
declare
	new record;
	current_tic integer;
begin
	SELECT last_value INTO current_tic FROM tic_seq;
	
	FOR NEW IN SELECT id, range, location, player_id FROM ship 
		WHERE last_move_tic between current_tic-5 and current_tic 
		LOOP


	   delete from ships_near_planets where ship = NEW.id;
	   -- Record the 10 planets that are nearest to the specified ship
	   insert into ships_near_planets (ship, player_id, planet, ship_location, planet_location, distance)
	     select NEW.id, NEW.player_id, p.id, NEW.location, p.location, NEW.location <-> p.location
	       from planets p 
		where CIRCLE(NEW.location, NEW.range) <@ CIRCLE(p.location,100000)
	       order by NEW.location <-> p.location desc limit 10;
     END LOOP;
	return 't';
end
$BODY$
  LANGUAGE plpgsql VOLATILE SECURITY DEFINER
  COST 100;


CREATE OR REPLACE VIEW planets_in_range AS
WITH 
	current_player AS (SELECT GET_PLAYER_ID(SESSION_USER) as player_id),
	s AS (SELECT ship.id, ship.name, ship.location, ship.range, ship.destroyed from ship, current_player WHERE ship.player_id=current_player.player_id),
	sp AS (SELECT  ships_near_planets.* FROM ships_near_planets, current_player WHERE ships_near_planets.player_id=current_player.player_id)
	
 SELECT sp.ship, sp.planet, sp.ship_location, sp.planet_location, sp.distance
   FROM s, sp
  WHERE s.destroyed ='f' AND s.id = sp.ship;

CREATE VIEW planets AS
SELECT 
	planet.id as id,
	planet.name as name,
	planet.mine_limit as mine_limit,
	planet.location as location,
	planet.conqueror_id as conqueror_id 
FROM planet;

CREATE RULE planet_update AS ON UPDATE TO planets
        DO INSTEAD UPDATE planet SET name=NEW.name WHERE  planet.id <> 1 AND id=NEW.id AND conqueror_id=GET_PLAYER_ID(SESSION_USER);

CREATE OR REPLACE FUNCTION UPDATE_PLANET() RETURNS trigger as $update_planet$
BEGIN
	IF NEW.conqueror_id!=OLD.conqueror_id THEN
		INSERT INTO event(action, player_id_1, player_id_2, referencing_id, location, public, tic)
			VALUES('CONQUER',NEW.conqueror_id,OLD.conqueror_id, NEW.id , NEW.location, 't',(SELECT last_value FROM tic_seq));
	END IF;
	RETURN NEW;	
END
$update_planet$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE TRIGGER UPDATE_PLANET AFTER UPDATE ON planet
  FOR EACH ROW EXECUTE PROCEDURE UPDATE_PLANET();

create table trophy (
	id integer NOT NULL PRIMARY KEY,
	name character varying,
	description text,
	picture_link text,
	script text,
	script_declarations text,
	creator integer NOT NULL REFERENCES player(id), 
	approved boolean default 'f',
	round_started integer,
  	weight smallint,
  	run_order smallint
);

CREATE SEQUENCE trophy_id_seq
  INCREMENT 1
  MINVALUE 1
  MAXVALUE 9223372036854775807
  START 1
  CACHE 1;


CREATE OR REPLACE FUNCTION CREATE_TROPHY() RETURNS trigger AS $create_trophy$
BEGIN
     
	NEW.approved 	:= 'f';
	NEW.creator 	:= GET_PLAYER_ID(SESSION_USER);
	NEW.round_started := 0;

       RETURN NEW;
END
$create_trophy$ LANGUAGE plpgsql;


CREATE TRIGGER CREATE_TROPHY BEFORE INSERT ON trophy
  FOR EACH ROW EXECUTE PROCEDURE CREATE_TROPHY();

CREATE TYPE trophy_winner AS (round integer, trophy_id integer, player_id integer);

CREATE OR REPLACE FUNCTION TROPHY_SCRIPT_UPDATE() RETURNS trigger AS $trophy_script_update$
DECLARE
       current_round integer;
	secret character varying;

	player_id integer;
BEGIN

	player_id := GET_PLAYER_ID(SESSION_USER);

	IF  SESSION_USER = 'schemaverse' THEN
	       IF NEW.approved='t' AND OLD.approved='f' THEN
			IF NEW.round_started=0 THEN
				SELECT last_value INTO NEW.round_started FROM round_seq;
			END IF;

		        secret := 'trophy_script_' || (RANDOM()*1000000)::integer;
       		 EXECUTE 'CREATE OR REPLACE FUNCTION TROPHY_SCRIPT_'|| NEW.id ||'(_round_id integer) RETURNS SETOF trophy_winner AS $'||secret||'$
		        DECLARE
				this_trophy_id integer;
				this_round integer; -- Deprecated, use _round_id in your script instead
				 winner trophy_winner%rowtype;
       		         ' || NEW.script_declarations || '
		        BEGIN
       		         this_trophy_id := '|| NEW.id||';
       		         SELECT last_value INTO this_round FROM round_seq; 
	       	         ' || NEW.script || '
			 RETURN;
	       	 END $'||secret||'$ LANGUAGE plpgsql;'::TEXT;

		 EXECUTE 'REVOKE ALL ON FUNCTION TROPHY_SCRIPT_'|| NEW.id ||'(integer) FROM PUBLIC'::TEXT;
       		 EXECUTE 'REVOKE ALL ON FUNCTION TROPHY_SCRIPT_'|| NEW.id ||'(integer) FROM players'::TEXT;
		 EXECUTE 'GRANT EXECUTE ON FUNCTION TROPHY_SCRIPT_'|| NEW.id ||'(integer) TO schemaverse'::TEXT;
		END IF;
	ELSEIF NOT player_id = OLD.creator THEN
		RETURN OLD;
	ELSE 
		IF NOT OLD.approved = NEW.approved THEN
			NEW.approved='f';
		END IF;

		IF NOT ((NEW.script = OLD.script) AND (NEW.script_declarations = OLD.script_declarations)) THEN
			NEW.approved='f';	         
	       END IF;
	END IF;

       RETURN NEW;
END $trophy_script_update$ LANGUAGE plpgsql;


CREATE TRIGGER TROPHY_SCRIPT_UPDATE BEFORE UPDATE ON trophy
  FOR EACH ROW EXECUTE PROCEDURE TROPHY_SCRIPT_UPDATE();

--Example Trophy
--insert into trophy(name, script,script_declaration) values ('The Participation Award' ,'FOR res IN SELECT id from player LOOP winner.round:=this_round; winner.trophy_id := this_trophy_id; winner.player_id := res.id; RETURN NEXT winner;END LOOP;', 'res RECORD;');

create table player_trophy (
	round integer,
	trophy_id integer NOT NULL REFERENCES trophy(id),
	player_id integer NOT NULL REFERENCES player(id), 
	PRIMARY KEY(round, trophy_id, player_id)
);

--How to award trophies
--INSERT INTO player_trophy SELECT * FROM trophy_script_#();

create view trophy_case as
SELECT  
	player_id, 
	GET_PLAYER_USERNAME(player_id) as username, 
	name as trophy, 
	count(trophy_id) as times_awarded,
	(SELECT round FROM player_trophy t where t.trophy_id=player_trophy.trophy_id  and t.player_id=player_trophy.player_id order by round desc LIMIT 1) as last_round_won
 FROM trophy, player_trophy
WHERE trophy.id=player_trophy.trophy_id
GROUP BY trophy_id, name, player_id;


-- This trigger forces complete control over ID's to this one function. 
-- Preventing any user form updating an ID or inserting an ID out of sequence
CREATE OR REPLACE FUNCTION ID_DEALER() RETURNS trigger AS $id_dealer$
BEGIN

	IF (TG_OP = 'INSERT') THEN 
		NEW.id = nextval(TG_TABLE_NAME || '_id_seq');
	ELSEIF (TG_OP = 'UPDATE') THEN
		NEW.id = OLD.id;
	END IF;
RETURN NEW;
END
$id_dealer$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE TRIGGER PLAYER_ID_DEALER BEFORE INSERT OR UPDATE ON player
  FOR EACH ROW EXECUTE PROCEDURE ID_DEALER(); 

CREATE TRIGGER SHIP_ID_DEALER BEFORE INSERT OR UPDATE ON ship
  FOR EACH ROW EXECUTE PROCEDURE ID_DEALER(); 

CREATE TRIGGER FLEET_ID_DEALER BEFORE INSERT OR UPDATE ON fleet
  FOR EACH ROW EXECUTE PROCEDURE ID_DEALER(); 

CREATE TRIGGER TRADE_ID_DEALER BEFORE INSERT OR UPDATE ON trade
  FOR EACH ROW EXECUTE PROCEDURE ID_DEALER(); 

CREATE TRIGGER TRADE_ID_DEALER BEFORE INSERT OR UPDATE ON trade_item
  FOR EACH ROW EXECUTE PROCEDURE ID_DEALER(); 

CREATE TRIGGER EVENT_LOG_ID_DEALER BEFORE INSERT OR UPDATE ON event
  FOR EACH ROW EXECUTE PROCEDURE ID_DEALER(); 

CREATE TRIGGER TROPHY_ID_DEALER BEFORE INSERT OR UPDATE ON trophy
  FOR EACH ROW EXECUTE PROCEDURE ID_DEALER();

--Permission verification


CREATE OR REPLACE FUNCTION GENERAL_PERMISSION_CHECK() RETURNS trigger AS $general_permission_check$
DECLARE
        real_player_id integer;
        checked_player_id integer;
BEGIN
        IF SESSION_USER = 'schemaverse' THEN
                RETURN NEW;
        ELSEIF CURRENT_USER = 'schemaverse' THEN
                SELECT id INTO real_player_id FROM player WHERE username=SESSION_USER;

                IF TG_TABLE_NAME IN ('ship','fleet','trade_item') THEN
                        IF (TG_OP = 'DELETE') THEN
				RETURN OLD;
			ELSE 
			 	RETURN NEW;
			END IF;
                ELSEIF TG_TABLE_NAME = 'trade' THEN
                        IF TG_OP = 'UPDATE' THEN
                                IF (OLD.player_id_1 != NEW.player_id_1) OR (OLD.player_id_2 != NEW.player_id_2) THEN
                                        RETURN NULL;
                                END IF;
                                IF NEW.confirmation_1 != OLD.confirmation_1 AND NEW.player_id_1 != real_player_id THEN
                                        RETURN NULL;
                                END IF;
                                IF NEW.confirmation_2 != OLD.confirmation_2 AND NEW.player_id_2 != real_player_id THEN
                                        RETURN NULL;
                                END IF;
                        ELSEIF TG_OP = 'DELETE' THEN
	                         IF real_player_id in (OLD.player_id_1, OLD.player_id_2) THEN
					RETURN OLD;
				ELSE 
					RETURN NULL;
				END IF;
			END IF;
			
                         IF real_player_id in (NEW.player_id_1, NEW.player_id_2) THEN
                                RETURN NEW;
                        END IF;
                ELSEIF TG_TABLE_NAME in ('ship_control') THEN
                        IF TG_OP = 'UPDATE' THEN
                                IF OLD.ship_id != NEW.ship_id THEN
                                        RETURN NULL;
				  END IF;
                        END IF;
                        SELECT player_id INTO checked_player_id FROM ship WHERE id=NEW.ship_id;
                        IF real_player_id = checked_player_id THEN
                                RETURN NEW;
                        END IF;
                END IF;

        ELSE

                SELECT id INTO real_player_id FROM player WHERE username=SESSION_USER;

                IF TG_TABLE_NAME IN ('ship','fleet','trade_item') THEN
                        IF TG_OP = 'UPDATE' THEN
                                IF OLD.player_id != NEW.player_id THEN
                                        RETURN NULL;
                                END IF;
                        END IF;
                        NEW.player_id = real_player_id;
                        RETURN NEW;

                ELSEIF TG_TABLE_NAME = 'trade' THEN
                        IF TG_OP = 'UPDATE' THEN
                                IF (OLD.player_id_1 != NEW.player_id_1) OR (OLD.player_id_2 != NEW.player_id_2) THEN
                                        RETURN NULL;
                                END IF;
                                IF NEW.confirmation_1 != OLD.confirmation_1 AND NEW.player_id_1 != real_player_id THEN
                                        RETURN NULL;
                                END IF;
                                IF NEW.confirmation_2 != OLD.confirmation_2 AND NEW.player_id_2 != real_player_id THEN
                                        RETURN NULL;
                                END IF;
                        END IF;
                         IF real_player_id in (NEW.player_id_1, NEW.player_id_2) THEN
                                RETURN NEW;
                        END IF;
                ELSEIF TG_TABLE_NAME in ('ship_control') THEN
                        IF TG_OP = 'UPDATE' THEN
                                IF OLD.ship_id != NEW.ship_id THEN
                                        RETURN NULL;
				  END IF;
                        END IF;
                        SELECT player_id INTO checked_player_id FROM ship WHERE id=NEW.ship_id;
                        IF real_player_id = checked_player_id THEN
                                RETURN NEW;
                        END IF;
                END IF;
        END IF;
        RETURN NULL;
END
$general_permission_check$ LANGUAGE plpgsql SECURITY DEFINER;


--All start with the letter 'A' so that this check runs before everything else. 
--This should prevent users from forcing charges to another users account

CREATE TRIGGER A_SHIP_PERMISSION_CHECK BEFORE INSERT OR UPDATE ON ship
  FOR EACH ROW EXECUTE PROCEDURE GENERAL_PERMISSION_CHECK(); 

CREATE TRIGGER A_SHIP_CONTROL_PERMISSION_CHECK BEFORE INSERT OR UPDATE OR DELETE ON ship_control
  FOR EACH ROW EXECUTE PROCEDURE GENERAL_PERMISSION_CHECK(); 

CREATE TRIGGER A_FLEET_PERMISSION_CHECK BEFORE INSERT OR UPDATE OR DELETE ON fleet
  FOR EACH ROW EXECUTE PROCEDURE GENERAL_PERMISSION_CHECK(); 

CREATE TRIGGER A_TRADE_PERMISSION_CHECK BEFORE INSERT OR UPDATE OR DELETE ON trade
  FOR EACH ROW EXECUTE PROCEDURE GENERAL_PERMISSION_CHECK(); 

CREATE TRIGGER A_TRADE_ITEM_PERMISSION_CHECK BEFORE INSERT OR DELETE ON trade_item
  FOR EACH ROW EXECUTE PROCEDURE GENERAL_PERMISSION_CHECK(); 



CREATE OR REPLACE FUNCTION ACTION_PERMISSION_CHECK(ship_id integer) RETURNS boolean AS $action_permission_check$
DECLARE 
	ships_player_id integer;
	lat integer;
	exploded boolean;
	ch integer;
BEGIN
	SELECT player_id, last_action_tic, destroyed, current_health into ships_player_id, lat, exploded, ch FROM ship WHERE id=ship_id ;
	IF (	lat != (SELECT last_value FROM tic_seq)
		AND
		exploded = 'f'
		AND 
		ch > 0 
	) AND (
		ships_player_id = GET_PLAYER_ID(SESSION_USER) 
		OR (ships_player_id > 0 AND (SESSION_USER = 'schemaverse' OR CURRENT_USER = 'schemaverse'))  
	) THEN
		
		RETURN 't';
	ELSE 
		RETURN 'f';
	END IF;
END
$action_permission_check$ LANGUAGE plpgsql SECURITY DEFINER;

 CREATE OR REPLACE FUNCTION IN_RANGE_SHIP(ship_1 integer, ship_2 integer) RETURNS boolean AS $in_range_ship$
	select exists (select 1 from ship enemies, ship players
	       	       where 
		       	  players.id = $1 and enemies.id = $2 and
                          not enemies.destroyed AND NOT players.destroyed and
                          CIRCLE(players.location, players.range) @> CIRCLE(enemies.location, 1));
$in_range_ship$ LANGUAGE sql SECURITY DEFINER;


CREATE OR REPLACE FUNCTION IN_RANGE_PLANET(ship_id integer, planet_id integer) RETURNS boolean AS $in_range_planet$
	select exists (select 1 from planet p, ship s
	       	       where 
		       	  s.id = $1 and p.id = $2 and
                          not s.destroyed and
                          CIRCLE(s.location, s.range) @> CIRCLE(p.location, 1));
$in_range_planet$ LANGUAGE sql SECURITY DEFINER;


-- Action methods
CREATE OR REPLACE FUNCTION Attack(attacker integer, enemy_ship integer) RETURNS integer AS $attack$
DECLARE
	damage integer;
	attack_rate integer;
	defense_rate integer;
	attacker_name character varying;
	attacker_player_id integer;
	enemy_name character varying;
	enemy_player_id integer;
	defense_efficiency numeric;
	loc point;
BEGIN
	damage = 0;
	--check range
	IF ACTION_PERMISSION_CHECK(attacker) AND (IN_RANGE_SHIP(attacker, enemy_ship)) THEN
	
		defense_efficiency := GET_NUMERIC_VARIABLE('DEFENSE_EFFICIENCY') / 100::numeric;
		
		--FINE, I won't divide by zero
		SELECT attack + 1, player_id, name, location INTO attack_rate, attacker_player_id, attacker_name, loc FROM ship WHERE id=attacker;
		SELECT defense + 1, player_id, name INTO defense_rate, enemy_player_id, enemy_name FROM ship WHERE id=enemy_ship;

		damage = (attack_rate * (defense_efficiency/defense_rate+defense_efficiency))::integer;		
		UPDATE ship SET future_health=future_health-damage WHERE id=enemy_ship;
		UPDATE ship SET last_action_tic=(SELECT last_value FROM tic_seq) WHERE id=attacker;
		
		INSERT INTO event(action, player_id_1,ship_id_1, player_id_2, ship_id_2, descriptor_numeric, location,public, tic)
			VALUES('ATTACK',attacker_player_id, attacker, enemy_player_id, enemy_ship , damage, loc, 't',(SELECT last_value FROM tic_seq));
	ELSE 
		 EXECUTE 'NOTIFY ' || get_player_error_channel() ||', ''Attack from ' || attacker || ' to '|| enemy_ship ||' failed'';';
	END IF;	

	RETURN damage;
END
$attack$ LANGUAGE plpgsql SECURITY DEFINER;


CREATE OR REPLACE FUNCTION Repair(repair_ship integer, repaired_ship integer) RETURNS integer AS $repair$
DECLARE
	repair_rate integer;
	repair_ship_name character varying;
	repair_ship_player_id integer;
	repaired_ship_name character varying;
	loc point;
BEGIN
	
	repair_rate = 0;
	
	
	--check range
	IF ACTION_PERMISSION_CHECK(repair_ship) AND (IN_RANGE_SHIP(repair_ship, repaired_ship)) THEN
	
		SELECT engineering, player_id, name, location INTO repair_rate, repair_ship_player_id, repair_ship_name, loc FROM ship WHERE id=repair_ship;
		SELECT name INTO repaired_ship_name FROM ship WHERE id=repaired_ship;
		UPDATE ship SET future_health = future_health + repair_rate WHERE id=repaired_ship;
		UPDATE ship SET last_action_tic=(SELECT last_value FROM tic_seq) WHERE id=repair_ship;
		
		INSERT INTO event(action, player_id_1,ship_id_1, ship_id_2, descriptor_numeric, location, public, tic)
			VALUES('REPAIR',repair_ship_player_id, repair_ship,  repaired_ship , repair_rate,loc,'t',(SELECT last_value FROM tic_seq));

	ELSE 
		 EXECUTE 'NOTIFY ' || get_player_error_channel() ||', ''Repair from ' || repair_ship || ' to '|| repaired_ship ||' failed'';';
	END IF;	

	RETURN repair_rate;
END
$repair$ LANGUAGE plpgsql SECURITY DEFINER;


CREATE OR REPLACE FUNCTION Mine(ship_id integer, planet_id integer) RETURNS boolean AS $mine$
BEGIN
	IF ACTION_PERMISSION_CHECK(ship_id) AND (IN_RANGE_PLANET(ship_id, planet_id)) THEN
		INSERT INTO planet_miners VALUES(planet_id, ship_id);
		UPDATE ship SET last_action_tic=(SELECT last_value FROM tic_seq) WHERE id=ship_id;
		RETURN 't';
	ELSE
		EXECUTE 'NOTIFY ' || get_player_error_channel() ||', ''Mining ' || planet_id || ' with ship '|| ship_id ||' failed'';';
		RETURN 'f';
	END IF;

END
$mine$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE OR REPLACE FUNCTION Perform_Mining() RETURNS integer as $perform_mining$
DECLARE
	miners RECORD;
	current_planet_id integer;
	current_planet_limit integer;
	current_planet_difficulty integer;
	current_planet_fuel integer;
	limit_counter integer;
	mined_player_fuel integer;

	new_fuel_reserve bigint;
	 
BEGIN
	current_planet_id = 0; 
	FOR miners IN SELECT 
			planet_miners.planet_id as planet_id, 
			planet_miners.ship_id as ship_id, 
			ship.player_id as player_id, 
			ship.prospecting as prospecting,
			ship.location as location,
			player.fuel_reserve as fuel_reserve
			FROM 
				planet_miners, ship, player
			WHERE
				planet_miners.ship_id=ship.id
					AND player.id=ship.player_id
			ORDER BY planet_miners.planet_id, (ship.prospecting * RANDOM()) LOOP 
		
		IF current_planet_id != miners.planet_id THEN
			limit_counter := 0;
			current_planet_id := miners.planet_id;
			SELECT INTO current_planet_fuel, current_planet_difficulty, current_planet_limit fuel, difficulty, mine_limit FROM planet WHERE id=current_planet_id;
		END IF;
		
		--Added current_planet_fuel check here to fix negative fuel_reserve
		IF limit_counter < current_planet_limit AND current_planet_fuel > 0 THEN
			mined_player_fuel := (GET_NUMERIC_VARIABLE('MINE_BASE_FUEL') * RANDOM() * miners.prospecting * current_planet_difficulty)::integer;
			IF mined_player_fuel > current_planet_fuel THEN 
				mined_player_fuel = current_planet_fuel;
			END IF;

			IF mined_player_fuel <= 0 THEN
				INSERT INTO event(action, player_id_1,ship_id_1, referencing_id, location, public, tic)
					VALUES('MINE_FAIL',miners.player_id, miners.ship_id, miners.planet_id, miners.location,'f',(SELECT last_value FROM tic_seq));		
			ELSE 
				SELECT INTO new_fuel_reserve fuel_reserve + mined_player_fuel FROM player WHERE id=miners.player_id;
				IF new_fuel_reserve > 2147483647 THEN
					mined_player_fuel := 2147483647 - miners.fuel_reserve; 
					new_fuel_reserve := 2147483647;
				END IF;

				current_planet_fuel := current_planet_fuel - mined_player_fuel;


				UPDATE player SET fuel_reserve = (new_fuel_reserve)::integer WHERE id = miners.player_id;
				UPDATE planet SET fuel = (fuel - mined_player_fuel)::integer WHERE id = current_planet_id;

				INSERT INTO event(action, player_id_1,ship_id_1, referencing_id, descriptor_numeric, location, public, tic)
					VALUES('MINE_SUCCESS',miners.player_id, miners.ship_id, miners.planet_id , mined_player_fuel,miners.location,'t',
					(SELECT last_value FROM tic_seq));
			END IF;
			limit_counter = limit_counter + 1;
		ELSE
			--INSERT INTO event(action, player_id_1,ship_id_1, referencing_id, location, public, tic)
			--	VALUES('MINE_FAIL',miners.player_id, miners.ship_id, miners.planet_id, miners.location,'f',(SELECT last_value FROM tic_seq));
		END IF;		
		DELETE FROM planet_miners WHERE planet_id=miners.planet_id AND ship_id=miners.ship_id;
	END LOOP;

	current_planet_id = 0; 
	FOR miners IN SELECT count(event.player_id_1) as mined, event.referencing_id as planet_id, event.player_id_1 as player_id, 
			CASE WHEN (select conqueror_id from planet where id=event.referencing_id)=event.player_id_1 THEN 2 ELSE 1 END as current_conqueror
			FROM event
			WHERE event.action='MINE_SUCCESS' AND event.tic=(SELECT last_value FROM tic_seq)
			GROUP BY event.referencing_id, event.player_id_1
			ORDER BY planet_id, mined DESC, current_conqueror DESC LOOP

		IF current_planet_id != miners.planet_id THEN
			current_planet_id := miners.planet_id;
			IF miners.current_conqueror=1 THEN
				UPDATE 	planet 	SET conqueror_id=miners.player_id WHERE planet.id=miners.planet_id;
			END IF;
		END IF;
	END LOOP;
	RETURN 1;
END
$perform_mining$ LANGUAGE plpgsql;

-- Contribution from Tigereye
-- Helper function for making MOVE() actually work
CREATE OR REPLACE FUNCTION getangle(current point, new_destination point)
  RETURNS integer AS
$BODY$
DECLARE
        distance_x integer;
        distance_y integer;
        angle integer = 0;
BEGIN
        distance_x := (new_destination[0] - current[0]);
        distance_y := (new_destination[1] - current[1]);
        
        IF (distance_x <> 0 OR distance_y <> 0) THEN
	    angle = CAST(DEGREES(ATAN2(distance_y, distance_x)) AS integer);
            IF (angle < 0) THEN
                angle := angle + 360;
            END IF;
        END IF;
        RETURN angle;
END;
$BODY$
  LANGUAGE plpgsql; 

CREATE OR REPLACE FUNCTION ship_course_control (moving_ship_id integer, new_speed integer, new_direction integer, new_destination point)
  RETURNS boolean AS
$SHIP_COURSE_CONTROL$
DECLARE
	max_speed integer;
	ship_player_id integer;
BEGIN
	-- Bunch of cases where this function fails, quietly
	IF moving_ship_id IS NULL then
		EXECUTE 'NOTIFY ' || get_player_error_channel() ||', ''Attempt to course control on NULL ship'';';
		RETURN 'f';
	END IF;
	if new_speed IS NULL then
		EXECUTE 'NOTIFY ' || get_player_error_channel() ||', ''Attempt to course control NULL speed'';';
		RETURN 'f';
	END IF;
	if (new_direction IS NOT NULL AND new_destination IS NOT NULL) then
		EXECUTE 'NOTIFY ' || get_player_error_channel() ||', ''Attempt to course control with both direction and destination'';';
		RETURN 'f';
	END IF;
	IF (new_direction IS NULL AND new_destination IS NULL) THEN
		EXECUTE 'NOTIFY ' || get_player_error_channel() ||', ''Attempt to course control with neither direction nor destination'';';
		RETURN 'f';
	END IF;

	SELECT INTO max_speed, ship_player_id  ship.max_speed, player_id from ship WHERE id=moving_ship_id;
	IF ship_player_id IS NULL OR ship_player_id <> GET_PLAYER_ID(SESSION_USER) THEN
		RETURN 'f';
	END IF;
	IF new_speed > max_speed THEN
		new_speed := max_speed;
	END IF;
	UPDATE ship_control SET
	  target_speed = new_speed,
	  target_direction = new_direction,
	  destination = new_destination
	  WHERE ship_id = moving_ship_id;

	RETURN 't';
END
$SHIP_COURSE_CONTROL$
  LANGUAGE plpgsql SECURITY DEFINER;

-- This function has been altered a bunch recently. Check out Issue 7 on github for more details about the changes
-- https://github.com/Abstrct/Schemaverse/issues/7
CREATE OR REPLACE FUNCTION "move_ships"()
  RETURNS boolean AS
$MOVE_SHIPS$
DECLARE
	ship_control record;
	velocity point;
	new_velocity point;
	vector point;
	delta_v numeric;
	acceleration_angle numeric;
	distance bigint;
	current_tic integer;
BEGIN
       IF NOT SESSION_USER = 'schemaverse' THEN
                RETURN 'f';
        END IF;

	SELECT last_value INTO current_tic FROM tic_seq;
	
	FOR ship_control_ IN SELECT SC.*, S.* FROM ship_control SC
          INNER JOIN ship S ON S.id = SC.ship_id
	  WHERE (SC.target_speed <> SC.speed
	  OR SC.target_direction <> SC.direction
	  OR SC.speed <> 0)
          AND S.destroyed='f' AND S.last_move_tic <> current_tic LOOP


	  -- If ship is being controlled by a set destination, adjust angle and speed appropriately
	  IF ship_control_.destination IS NOT NULL THEN
            distance :=  (ship_control_.destination <-> ship_control_.location)::bigint;
	    IF distance < ship_control_.target_speed THEN
	      ship_control_.target_speed = distance::int;
            END IF;
	    vector := ship_control_.destination - ship_control_.location;
	    ship_control_.target_direction := DEGREES(ATAN2(vector[1], vector[0]))::int;
	    IF ship_control_.target_direction < 0 THEN
	      ship_control_.target_direction := ship_control_.target_direction + 360;
	    END IF;
	  END IF;

	  velocity := point(COS(RADIANS(ship_control_.direction)) * ship_control_.speed,
	                    SIN(RADIANS(ship_control_.direction)) * ship_control_.speed);

	  new_velocity := point(COS(RADIANS(ship_control_.target_direction)) * ship_control_.target_speed,
	  	       	        SIN(RADIANS(ship_control_.target_direction)) * ship_control_.target_speed);

	  vector := new_velocity - velocity;
	  delta_v := velocity <-> new_velocity;
	  acceleration_angle := ATAN2(vector[1], vector[0]);

          IF ship_control_.current_fuel < delta_v THEN
	    delta_v := ship_control_.current_fuel;
	  END IF;

	  new_velocity := velocity + point(COS(acceleration_angle)*delta_v, SIN(acceleration_angle)*delta_v);
	  ship_control_.direction = DEGREES(ATAN2(new_velocity[1], new_velocity[0]))::int;
	  IF ship_control_.direction < 0 THEN
	    ship_control_.direction := ship_control_.direction + 360;
	  END IF;
	  ship_control_.speed =  (new_velocity <-> point(0,0))::integer;
	  ship_control_.current_fuel := ship_control_.current_fuel - delta_v::int;

          -- Move the ship!
          UPDATE ship S SET
		last_move_tic = current_tic,
		current_fuel = ship_control_.current_fuel,
		location = ship_control_.location + point(COS(RADIANS(ship_control_.direction)) * ship_control_.speed,
		                                 SIN(RADIANS(ship_control_.direction)) * ship_control_.speed)
                WHERE S.id = ship_control_.id;

          UPDATE ship S SET
		location_x = location[0],
		location_y = location[1]
                WHERE S.id = ship_control_.id;
          
	  UPDATE ship_control SC SET 
		speed = ship_control_.speed,
		direction = ship_control_.direction
                WHERE SC.ship_id = ship_control_.id;
	END LOOP;


	
	RETURN 't';
END
$MOVE_SHIPS$
  LANGUAGE plpgsql SECURITY DEFINER;


CREATE TABLE stat_log
(
	round integer NOT NULL, 
	tic integer NOT NULL,
	total_players integer,
	online_players integer,
	total_ships integer,
	avg_ships integer,
	total_trades integer,
	active_trades integer,
	total_fuel_reserve bigint,
	avg_fuel_reserve integer,
	total_currency bigint,
	avg_balance integer,
	CONSTRAINT stat_log_archive_pkey PRIMARY KEY (round, tic)	
);


CREATE VIEW current_stats AS
select 
	(SELECT last_value FROM round_seq) as current_round,
	(SELECT last_value FROM tic_seq) as current_tic,
	count(id) as total_players, 
	(select count(id) from online_players) as online_players,
	(SELECT count(id) from ship) as total_ships, 
	ceil(avg((SELECT count(id) from ship where player_id=player.id group by player_id))) as avg_ships, 
	(select count(id) from trade) as total_trades,
	(select count(id) from trade where player_id_1!=confirmation_1 OR player_id_2!=confirmation_2) as active_trades,
	(select sum(fuel_reserve) from player where id!=0) as total_fuel_reserves,
	ceil((select avg(fuel_reserve) from player where id!=0)) as avg_fuel_reserve,
	(select sum(balance) from player where id!=0) as total_currency,
	ceil((select avg(balance) from player where id!=0)) as avg_balance
from player ;

CREATE OR REPLACE VIEW current_player_stats AS 
 SELECT 
	player.id AS player_id, 
	player.username, 
	COALESCE(against_player.damage_taken,0) AS damage_taken, 
	COALESCE(for_player.damage_done,0) AS damage_done, 
	COALESCE(for_player.planets_conquered,0) AS planets_conquered, 
	COALESCE(against_player.planets_lost,0) AS planets_lost, 
	COALESCE(for_player.ships_built,0) AS ships_built, 
	COALESCE(for_player.ships_lost,0) AS ships_lost, 
	COALESCE(for_player.ship_upgrades,0) AS ship_upgrades,
	COALESCE((( 
		SELECT sum(r.location <-> r2.location)::bigint AS sum 
		FROM ship_flight_recorder r, ship_flight_recorder r2, ship s  
		WHERE s.player_id = player.id AND r.ship_id = s.id AND r2.ship_id = r.ship_id AND r2.tic = (r.tic + 1)))::numeric, 0::numeric) AS distance_travelled, 
	COALESCE(for_player.fuel_mined,0) AS fuel_mined
   FROM player

   LEFT OUTER JOIN (SELECT   
		SUM(CASE WHEN event.action ='ATTACK' THEN event.descriptor_numeric ELSE NULL END ) as damage_done,
		COUNT(CASE WHEN event.action ='CONQUER' THEN COALESCE(event.descriptor_numeric,0) ELSE NULL END ) as planets_conquered,
		COUNT(CASE WHEN event.action ='BUY_SHIP' THEN COALESCE(event.descriptor_numeric,0) ELSE NULL END ) as ships_built,
		COUNT(CASE WHEN event.action ='EXPLODE' THEN COALESCE(event.descriptor_numeric,0) ELSE NULL END ) as ships_lost,
		SUM(CASE WHEN event.action ='UPGRADE_SHIP' THEN event.descriptor_numeric ELSE NULL END ) as ship_upgrades,
		SUM(CASE WHEN event.action ='MINE_SUCCESS' THEN event.descriptor_numeric ELSE NULL END ) as fuel_mined,
		event.player_id_1
	FROM event event 
	WHERE event.action in ('ATTACK','CONQUER','BUY_SHIP','EXPLODE','UPGRADE_SHIP','MINE_SUCCESS') 
	GROUP BY player_id_1) 
   for_player ON (for_player.player_id_1=player.id)

   LEFT OUTER JOIN (SELECT  
		SUM(CASE WHEN event.action = 'ATTACK' THEN event.descriptor_numeric ELSE NULL END) AS damage_taken, 
		COUNT(CASE WHEN event.action = 'CONQUER' THEN  COALESCE(event.descriptor_numeric,0) ELSE NULL END) as planets_lost,
		event.player_id_2  
	FROM event event 
	WHERE event.action IN ('ATTACK','CONQUER') 
	GROUP BY player_id_2) 
   against_player ON (against_player.player_id_2=player.id)
 WHERE id <> 0;

CREATE TABLE player_round_stats
(
  player_id integer NOT NULL,
  round_id integer NOT NULL,
  damage_taken bigint NOT NULL DEFAULT 0,
  damage_done bigint NOT NULL DEFAULT 0,
  planets_conquered smallint NOT NULL DEFAULT 0,
  planets_lost smallint NOT NULL DEFAULT 0,
  ships_built smallint NOT NULL DEFAULT 0,
  ships_lost smallint NOT NULL DEFAULT 0,
  ship_upgrades integer NOT NULL DEFAULT 0,
  distance_travelled integer NOT NULL DEFAULT 0,
  fuel_mined bigint NOT NULL DEFAULT 0,
  trophy_score smallint NOT NULL DEFAULT 0,
  last_updated timestamp without time zone NOT NULL DEFAULT now(),
  CONSTRAINT pk_player_round_stats PRIMARY KEY (player_id , round_id )
);

CREATE OR REPLACE VIEW current_round_stats AS SELECT
                round.round_id,
                coalesce(avg(CASE WHEN against_player.action='ATTACK' THEN coalesce(against_player.sum,0) ELSE NULL END),0)::integer as avg_damage_taken,
               coalesce( avg(CASE WHEN for_player.action='ATTACK' THEN coalesce(for_player.sum,0) ELSE NULL END) ,0)::integer as avg_damage_done,
               coalesce( avg(CASE WHEN for_player.action='CONQUER' THEN coalesce(for_player.count,0) ELSE NULL END),0)::integer as avg_planets_conquered,
            	coalesce(avg(CASE WHEN against_player.action='CONQUER' THEN coalesce(against_player.count,0) ELSE NULL END),0)::integer as avg_planets_lost,
               coalesce( avg(CASE WHEN for_player.action='BUY_SHIP' THEN coalesce(for_player.count,0) ELSE NULL END),0)::integer as avg_ships_built,
             	coalesce(avg(CASE WHEN for_player.action='EXPLODE' THEN coalesce(for_player.count,0) ELSE NULL END),0)::integer as avg_ships_lost,
               coalesce( avg(CASE WHEN for_player.action='UPGRADE_SHIP' THEN coalesce(for_player.sum,0) ELSE NULL END),0)::integer as avg_ship_upgrades,
               coalesce( avg(CASE WHEN for_player.action='MINE_SUCCESS' THEN coalesce(for_player.sum,0) ELSE NULL END),0)::integer as avg_fuel_mined,
		(SELECT avg(prs.distance_travelled) FROM player_round_stats prs WHERE prs.round_id=round.round_id) as avg_distance_travelled  
        FROM
                (SELECT last_value as round_id from round_seq) round
                LEFT OUTER JOIN 
			(SELECT  
				(SELECT last_value as round_id from round_seq) as round_id, 
				action,  
				CASE WHEN event.action IN ('ATTACK','UPGRADE_SHIP','MINE_SUCCESS') THEN sum(coalesce(event.descriptor_numeric,0)) ELSE  NULL END AS sum, 
				CASE WHEN event.action IN ('BUY_SHIP','EXPLODE','CONQUER') THEN count(*) ELSE NULL END as count 
			FROM event event 
			WHERE event.action in ('ATTACK','CONQUER','BUY_SHIP','EXPLODE','UPGRADE_SHIP','MINE_SUCCESS') 
			GROUP BY player_id_1, action) 
		for_player ON (for_player.round_id=round.round_id)
                LEFT OUTER JOIN
			(SELECT  
				(SELECT last_value as round_id from round_seq) as round_id, 
				action,  
				CASE WHEN event.action = 'ATTACK' THEN sum(coalesce(event.descriptor_numeric,0)) ELSE  NULL END AS sum, 
				CASE WHEN event.action IN ('CONQUER') THEN count(*) ELSE NULL END as count 
			FROM event event WHERE event.action IN ('ATTACK','CONQUER') 
			GROUP BY player_id_2, action) 
		against_player ON (against_player.round_id=round.round_id)
        GROUP BY  round.round_id;

CREATE TABLE player_overall_stats
(
  player_id integer NOT NULL,
  damage_taken bigint,
  damage_done bigint,
  planets_conquered integer,
  planets_lost integer,
  ships_built integer,
  ships_lost integer,
  ship_upgrades bigint,
  distance_travelled bigint,
  fuel_mined bigint,
  trophy_score integer,
  CONSTRAINT pk_player_overall_stats PRIMARY KEY (player_id )
);

CREATE TABLE round_stats
(
  round_id integer NOT NULL,
  avg_damage_taken integer,
  avg_damage_done integer,
  avg_planets_conquered integer,
  avg_planets_lost integer,
  avg_ships_built integer,
  avg_ships_lost integer,
  avg_ship_upgrades bigint,
  avg_fuel_mined bigint,
  avg_distance_travelled bigint,
  CONSTRAINT pk_round_stat PRIMARY KEY (round_id )
);

CREATE OR REPLACE VIEW player_stats AS 
 SELECT 
	rs.player_id as player_id,
	GET_PLAYER_USERNAME(rs.player_id) as username,
	CASE WHEN (( SELECT count(online_players.id) AS count FROM online_players WHERE online_players.id = rs.player_id)) = 1 THEN true ELSE false END AS online,
	rs.damage_taken as round_damage_taken,
	coalesce(os.damage_taken,0)+rs.damage_taken as overall_damage_taken, 
	rs.damage_done as round_damage_done,
	coalesce(os.damage_done,0)+rs.damage_done as overall_damamge_done,
	rs.planets_conquered as round_planets_conquered,
	coalesce(os.planets_conquered,0)+rs.planets_conquered as overall_planets_conquered,
	rs.planets_lost as round_planets_lost,
	coalesce(os.planets_lost,0)+rs.planets_lost as overall_planets_lost,
	rs.ships_built as round_ships_built,
	coalesce(os.ships_built,0)+rs.ships_built as overall_ships_built,
	rs.ships_lost as round_ships_lost,
	coalesce(os.ships_lost,0)+rs.ships_lost as overall_ships_lost,
	rs.ship_upgrades as round_ship_upgrades,
	coalesce(os.ship_upgrades,0)+rs.ship_upgrades as overall_ship_upgrades,
	rs.distance_travelled as round_distance_travelled,
	coalesce(os.distance_travelled,0)+rs.distance_travelled as overall_distance_travelled,
	rs.fuel_mined as round_fuel_mined,
	coalesce(os.fuel_mined,0)+rs.fuel_mined as overall_fuel_mined,
	coalesce(os.trophy_score,0) as overall_trophy_score,
	rs.last_updated as last_updated	
FROM
	player_round_stats rs, player_overall_stats os
WHERE 
	rs.player_id=os.player_id
	and rs.round_id = (( SELECT round_seq.last_value FROM round_seq));
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                    
-- Create group 'players' and define the permissions

CREATE GROUP players WITH NOLOGIN NOSUPERUSER NOCREATEDB NOCREATEROLE NOINHERIT;
REVOKE SELECT ON pg_proc FROM public;
REVOKE SELECT ON pg_proc FROM players;
REVOKE create ON schema public FROM public; 
REVOKE create ON schema public FROM players;

REVOKE ALL ON tic_seq FROM players;
GRANT SELECT ON tic_seq TO players;

REVOKE ALL ON round_seq FROM players;
GRANT SELECT ON round_seq TO players;

REVOKE ALL ON variable FROM players;
GRANT SELECT ON public_variable TO players;
GRANT INSERT ON public_variable TO players;
GRANT UPDATE ON public_variable TO players;
GRANT DELETE ON public_variable TO players;

REVOKE ALL ON item FROM players;
REVOKE ALL ON item_location FROM players;
GRANT SELECT ON item TO players;
GRANT INSERT ON item TO players;
GRANT UPDATE ON item TO players;

REVOKE ALL ON player FROM players;
REVOKE ALL ON player_inventory FROM players;
REVOKE ALL ON player_id_seq FROM players;
REVOKE ALL ON player_inventory_id_seq FROM players;
GRANT SELECT ON my_player TO players;
GRANT UPDATE ON my_player TO players;
GRANT SELECT ON my_player_inventory TO players;
GRANT SELECT ON online_players TO players;

REVOKE ALL ON ship_control FROM players;
REVOKE ALL ON ship_flight_recorder FROM players;
GRANT UPDATE ON my_ships TO players;
GRANT SELECT ON my_ships TO players;
GRANT INSERT ON my_ships TO players;
GRANT SELECT ON ships_in_range TO players;
GRANT SELECT ON my_ships_flight_recorder TO players;

REVOKE ALL ON ship FROM players;
REVOKE ALL ON ship_id_seq FROM players;


REVOKE ALL ON planet FROM players;
REVOKE ALL ON planet_id_seq FROM players;
REVOKE ALL ON planet_miners FROM players;
GRANT SELECT ON planets TO players;
GRANT UPDATE ON planets TO players;

REVOKE ALL ON event FROM players;
GRANT SELECT ON my_events TO players;

REVOKE ALL ON event_archive FROM players;
GRANT SELECT ON event_archive TO players;

REVOKE ALL ON trade FROM players;
REVOKE ALL ON trade_id_seq FROM players;
GRANT INSERT ON my_trades TO players;
GRANT SELECT ON my_trades TO players;
GRANT UPDATE ON my_trades TO players; 
GRANT DELETE ON my_trades TO players;

REVOKE ALL ON trade_item FROM players;
GRANT SELECT ON trade_items TO players;
GRANT SELECT ON trade_ship_stats TO players;
GRANT DELETE ON trade_items TO players;
GRANT INSERT ON trade_items TO players;

REVOKE ALL ON fleet FROM players;
REVOKE ALL ON fleet_id_seq FROM players;
GRANT INSERT ON my_fleets TO players;
GRANT SELECT ON my_fleets TO players;
GRANT UPDATE ON my_fleets TO players; 

REVOKE ALL ON price_list FROM players;
GRANT SELECT ON price_list TO players;


REVOKE ALL ON round_stats FROM players;
REVOKE ALL ON player_round_stats FROM players;
REVOKE ALL ON player_overall_stats FROM players;
REVOKE ALL ON stat_log FROM players;
REVOKE ALL ON current_stats FROM players;
REVOKE ALL ON current_player_stats FROM players;
REVOKE ALL ON current_round_stats FROM players;
REVOKE ALL ON player_stats FROM players;
GRANT SELECT ON round_stats TO players;
GRANT SELECT ON player_round_stats TO players;
GRANT SELECT ON player_overall_stats TO players;
GRANT SELECT ON stat_log TO players;
GRANT SELECT ON current_stats TO players;
GRANT SELECT ON current_player_stats TO players;
GRANT SELECT ON current_round_stats TO players;
GRANT SELECT ON player_stats TO players;


REVOKE ALL ON action FROM players;
GRANT SELECT ON action TO players;
GRANT INSERT ON action TO players;
GRANT UPDATE ON action TO players;

REVOKE ALL ON trophy FROM players;
GRANT SELECT ON trophy TO players;
GRANT INSERT ON trophy TO players;
GRANT UPDATE ON trophy TO players;

REVOKE ALL ON player_trophy FROM players;
GRANT SELECT ON player_trophy TO players;

REVOKE ALL ON trophy_case FROM players;
GRANT SELECT ON trophy_case TO players;


CREATE OR REPLACE FUNCTION ROUND_CONTROL()
  RETURNS boolean AS
$round_control$
DECLARE
	new_planet record;
	trophies RECORD;
	players RECORD;
	p RECORD;
BEGIN

	IF NOT SESSION_USER = 'schemaverse' THEN
		RETURN 'f';
	END IF;	

	IF NOT GET_CHAR_VARIABLE('ROUND_START_DATE')::date <= 'today'::date - GET_CHAR_VARIABLE('ROUND_LENGTH')::interval THEN
		RETURN 'f';
	END IF;

	
	UPDATE round_stats SET
        	avg_damage_taken = current_round_stats.avg_damage_taken,
                avg_damage_done = current_round_stats.avg_damage_done,
                avg_planets_conquered = current_round_stats.avg_planets_conquered,
                avg_planets_lost = current_round_stats.avg_planets_lost,
                avg_ships_built = current_round_stats.avg_ships_built,
                avg_ships_lost = current_round_stats.avg_ships_lost,
                avg_ship_upgrades =current_round_stats.avg_ship_upgrades,
                avg_fuel_mined = current_round_stats.avg_fuel_mined
        FROM current_round_stats
        WHERE round_stats.round_id=(SELECT last_value FROM round_seq);
	
	FOR players IN SELECT * FROM player LOOP
		UPDATE player_round_stats SET 
			damage_taken = current_player_stats.damage_taken,
			damage_done = current_player_stats.damage_done,
			planets_conquered = current_player_stats.planets_conquered,
			planets_lost = current_player_stats.planets_lost,
			ships_built = current_player_stats.ships_built,
			ships_lost = current_player_stats.ships_lost,
			ship_upgrades =current_player_stats.ship_upgrades,
			fuel_mined = current_player_stats.fuel_mined,
			last_updated=NOW()
		FROM current_player_stats
		WHERE player_round_stats.player_id=players.id AND current_player_stats.player_id=players.id AND player_round_stats.round_id=(select last_value from round_seq);

		UPDATE player_overall_stats SET 
			damage_taken = player_overall_stats.damage_taken + player_round_stats.damage_taken,
			damage_done = player_overall_stats.damage_done + player_round_stats.damage_done,
			planets_conquered = player_overall_stats.planets_conquered + player_round_stats.planets_conquered,
			planets_lost = player_overall_stats.planets_lost + player_round_stats.planets_lost,
			ships_built = player_overall_stats.ships_built +player_round_stats.ships_built,
			ships_lost = player_overall_stats.ships_lost + player_round_stats.ships_lost,
			ship_upgrades = player_overall_stats.ship_upgrades + player_round_stats.ship_upgrades,
			fuel_mined = player_overall_stats.fuel_mined + player_round_stats.fuel_mined
		FROM player_round_stats
		WHERE player_overall_stats.player_id=player_round_stats.player_id 
			and player_overall_stats.player_id=players.id and player_round_stats.round_id=(select last_value from round_seq);
	END LOOP;


	FOR trophies IN SELECT id FROM trophy WHERE approved='t' ORDER by run_order ASC LOOP
		EXECUTE 'INSERT INTO player_trophy SELECT * FROM trophy_script_' || trophies.id ||'((SELECT last_value FROM round_seq));';
	END LOOP;

	alter table planet disable trigger user;
	alter table fleet disable trigger user;
	alter table planet_miners disable trigger user;
	alter table trade_item disable trigger user;
	alter table trade disable trigger user;
	alter table ship_flight_recorder disable trigger user;
	alter table ship_control disable trigger user;
	alter table ship disable trigger user;
	alter table player_inventory disable trigger user;
	alter table event disable trigger user;

	--Deactive all fleets
        update fleet set runtime='0 minutes', enabled='f';

	--Delete only items that do not persist across rounds
        delete from player_inventory using item where item.system_name=player_inventory.item and item.persistent='f';

	--add archives of stats and events
	CREATE TEMP TABLE tmp_current_round_archive AS SELECT (SELECT last_value FROM round_seq), event.* FROM event;
	EXECUTE 'COPY tmp_current_round_archive TO ''~/schemaverse_round_' || (SELECT last_value FROM round_seq) || '.csv''  WITH DELIMITER ''|''';

	--Delete everything else
        delete from planet_miners;
        delete from trade_item;
        delete from trade;
        delete from ship_flight_recorder;
        delete from ship_control;
        delete from ship;
        delete from event;
        delete from planet WHERE id != 1;

        alter sequence event_id_seq restart with 1;
        alter sequence ship_id_seq restart with 1;
        alter sequence tic_seq restart with 1;
        alter sequence trade_id_seq restart with 1;
        alter sequence trade_item_id_seq restart with 1;
	alter sequence planet_id_seq restart with 2;


	--Reset player resources
        UPDATE player set balance=10000, fuel_reserve=100000 WHERE  username!='schemaverse';
   	UPDATE fleet SET runtime='1 minute', enabled='t' FROM player WHERE player.starting_fleet=fleet.id AND player.id=fleet.player_id;
 

	UPDATE planet SET fuel=20000000 WHERE id=1;

	WHILE (SELECT count(*) FROM planet) < (SELECT count(*) FROM player) * 1.05 LOOP
		FOR new_planet IN SELECT
			nextval('planet_id_seq') as id,
			CASE (RANDOM() * 11)::integer % 12
			WHEN 0 THEN 'Aethra_' || generate_series
                         WHEN 1 THEN 'Mony_' || generate_series
                         WHEN 2 THEN 'Semper_' || generate_series
                         WHEN 3 THEN 'Voit_' || generate_series
                         WHEN 4 THEN 'Lester_' || generate_series 
                         WHEN 5 THEN 'Rio_' || generate_series 
                         WHEN 6 THEN 'Zergon_' || generate_series 
                         WHEN 7 THEN 'Cannibalon_' || generate_series
                         WHEN 8 THEN 'Omicron Persei_' || generate_series
                         WHEN 9 THEN 'Urectum_' || generate_series
                         WHEN 10 THEN 'Wormulon_' || generate_series
                         WHEN 11 THEN 'Kepler_' || generate_series
			END as name,
                GREATEST((RANDOM() * 100)::integer, 30) as mine_limit,
                GREATEST((RANDOM() * 1000000000)::integer, 10000000) as fuel,
                GREATEST((RANDOM() * 10)::integer,2) as difficulty,
		point(
                CASE (RANDOM() * 1)::integer % 2
                        WHEN 0 THEN (RANDOM() * GET_NUMERIC_VARIABLE('UNIVERSE_CREATOR'))::integer 
                        WHEN 1 THEN (RANDOM() * GET_NUMERIC_VARIABLE('UNIVERSE_CREATOR') * -1)::integer
		END,
                CASE (RANDOM() * 1)::integer % 2
                        WHEN 0 THEN (RANDOM() * GET_NUMERIC_VARIABLE('UNIVERSE_CREATOR'))::integer
                        WHEN 1 THEN (RANDOM() * GET_NUMERIC_VARIABLE('UNIVERSE_CREATOR') * -1)::integer		
		END) as location
		FROM generate_series(1,500)
		LOOP
			if not exists (select 1 from planet where (location <-> new_planet.location) <= 3000) then
				INSERT INTO planet(id, name, mine_limit, difficulty, fuel, location)
					VALUES(new_planet.id, new_planet.name, new_planet.mine_limit, new_planet.difficulty, new_planet.fuel, new_planet.location);
			END IF;	
		END LOOP;
	END LOOP;

	UPDATE planet SET conqueror_id=NULL WHERE planet.id = 1;
	FOR p IN SELECT player.id as id FROM player ORDER BY player.id LOOP
		UPDATE planet SET conqueror_id=p.id, mine_limit=30, fuel=50000000, difficulty=2 
			WHERE planet.id = (SELECT id FROM planet WHERE planet.id != 1 AND conqueror_id IS NULL ORDER BY RANDOM() LIMIT 1);
	END LOOP;

	alter table event enable trigger user;
	alter table planet enable trigger user;
	alter table fleet enable trigger user;
	alter table planet_miners enable trigger user;
	alter table trade_item enable trigger user;
	alter table trade enable trigger user;
	alter table ship_flight_recorder enable trigger user;
	alter table ship_control enable trigger user;
	alter table ship enable trigger user;
	alter table player_inventory enable trigger user;

	PERFORM nextval('round_seq');

	UPDATE variable SET char_value='today'::date WHERE name='ROUND_START_DATE';


	FOR players IN SELECT * from player WHERE ID <> 0 LOOP
		INSERT INTO player_round_stats(player_id, round_id) VALUES (players.id, (select last_value from round_seq));
	END LOOP;
	INSERT INTO round_stats(round_id) VALUES((SELECT last_value FROM round_seq));

        RETURN 't';
END;
$round_control$
  LANGUAGE plpgsql;

-- These seem to make the largest improvement for performance
CREATE INDEX event_toc_index ON event USING btree (toc);
CREATE INDEX event_action_index ON event USING hash (action);
CREATE INDEX ship_location_index ON ship USING GIST (location);
CREATE INDEX planet_location_index ON planet USING GIST (location);

CREATE INDEX ship_player ON ship USING btree (player_id);
CREATE INDEX ship_health ON ship USING btree (current_health);
CREATE INDEX ship_fleet ON ship USING btree (fleet_id);
CREATE INDEX ship_loc_only ON ship USING gist (CIRCLE(location,1));
CREATE INDEX ship_loc_range ON ship USING gist (CIRCLE(location,range));

CREATE INDEX fleet_player ON fleet USING btree (player_id);
CREATE INDEX event_player ON event USING btree (player_id_1);

CREATE INDEX planet_player ON planet USING btree (conqueror_id);
CREATE INDEX planet_loc_only ON planet USING gist (CIRCLE(location,100000));

commit;
