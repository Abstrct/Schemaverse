-- Schemaverse 
-- Created by Josh McDougall
-- v0.9.0 Destruction

create language 'plpgsql';

-- Create tables

CREATE SEQUENCE tic_seq
  INCREMENT 1
  MINVALUE 1
  MAXVALUE 9223372036854775807
  START 1
  CACHE 1;

CREATE TABLE variable
(
	name character varying NOT NULL PRIMARY KEY,
	private boolean,
	numeric_value integer,
	char_value character varying,
	description TEXT
);

CREATE VIEW public_variable AS SELECT * FROM variable WHERE private='f';


INSERT INTO variable VALUES 
	('MINE_BASE_FUEL','f',10,'','This value is used as a multiplier for fuel discovered from all planets'::TEXT),
	('UNIVERSE_CREATOR','t',42,'','The answer which creates the universe'::TEXT), 
	('MAX_X','t',100,'','Furthest +X discovered by a ship'::TEXT ),
	('MIN_X','t',100,'','Furthest -X discovered by a ship'::TEXT ),
	('MAX_Y','t',100,'','Furthest +Y discovered by a ship'::TEXT ),
	('MIN_Y','t',100,'','Furthest -Y discovered by a ship'::TEXT ),
	('EXPLODED','f',60,'','After this many tics, a ship will explode. Cost of a base ship will be returned to the player'::TEXT);


CREATE TABLE item
(
	system_name character varying NOT NULL PRIMARY KEY,
	name character varying NOT NULL,
	description TEXT,
	howto TEXT
);

CREATE TABLE item_location
(
	system_name character varying NOT NULL REFERENCES item(system_name),
	location_x integer NOT NULL default RANDOM(),
	location_y integer NOT NULL default RANDOM()
);

CREATE OR REPLACE FUNCTION GET_NUMERIC_VARIABLE(variable_name character varying) RETURNS integer AS $get_numeric_variable$
DECLARE
	value integer;
BEGIN
	IF CURRENT_USER = 'schemaverse' THEN
		SELECT numeric_value INTO value FROM variable WHERE name = variable_name;
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
		SELECT char_value INTO value FROM variable WHERE name = variable_name;
	ELSE
		SELECT char_value INTO value FROM public_variable WHERE name = variable_name;
	END IF;
	RETURN value; 
END $get_char_variable$  LANGUAGE plpgsql;




CREATE TABLE price_list
(
	code character varying NOT NULL PRIMARY KEY,
	cost integer NOT NULL,
	description TEXT
);


INSERT INTO price_list VALUES
	('SHIP', 100, 'HOLY CRAP. A NEW SHIP!'),
	('MAX_HEALTH', 50, 'Increases a ships MAX_HEALTH by one'),
	('MAX_FUEL', 1, 'Increases a ships MAX_FUEL by one'),
	('MAX_SPEED', 1, 'Increases a ships MAX_SPEED by one'),
	('RANGE', 25, 'Increases a ships RANGE by one'),
	('ATTACK', 25,'Increases a ships ATTACK by one'),
	('DEFENSE', 25, 'Increases a ships DEFENSE by one'),
	('ENGINEERING', 25, 'Increases a ships ENGINEERING by one'),
	('PROSPECTING', 25, 'Increases a ships PROSPECTING by one'),
	('REFUEL', 0, 'Refuel ship from your own supply');

--no mechanism for updating password yet...
CREATE TABLE player
(
	id integer NOT NULL PRIMARY KEY,
	username character varying NOT NULL UNIQUE,
	password character(40) NOT NULL,			-- 'md5' + MD5(password+username) 
	created timestamp NOT NULL DEFAULT NOW(),
	balance numeric DEFAULT '0',
	fuel_reserve integer DEFAULT '0'
);

CREATE SEQUENCE player_id_seq
  INCREMENT 1
  MINVALUE 1
  MAXVALUE 9223372036854775807
  START 1
  CACHE 1;

INSERT INTO player(id, username, password, fuel_reserve, balance) VALUES(0,'schemaverse','nopass',100000,100000); 

CREATE VIEW my_player AS 
	SELECT id, username, created, balance, fuel_reserve, password
	 FROM player WHERE username=SESSION_USER;


--Needs a trigger to alter the user account. Don't feel like actually writing this right now.
--A bit worried it is a security risk unless the new password is checked thoroughly. Otherwise they could inject into the alter user statement
--CREATE RULE my_player AS ON UPDATE TO player
--	DO INSTEAD UPDATE player SET password=NEW.password WHERE username=SESSION_USER;


CREATE VIEW online_players AS
	SELECT id, username FROM player
		WHERE username in (SELECT DISTINCT usename FROM pg_stat_activity);

CREATE OR REPLACE FUNCTION PLAYER_CREATION() RETURNS trigger AS $player_creation$
BEGIN
	execute 'CREATE ROLE ' || NEW.username || ' WITH LOGIN NOSUPERUSER NOCREATEDB NOCREATEROLE ENCRYPTED PASSWORD '''|| NEW.password ||'''  IN GROUP players'; 
RETURN NEW;
END
$player_creation$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE TRIGGER PLAYER_CREATION AFTER INSERT ON player
  FOR EACH ROW EXECUTE PROCEDURE PLAYER_CREATION(); 


CREATE OR REPLACE FUNCTION GET_PLAYER_ID(check_username name) RETURNS integer AS $get_player_id$
DECLARE 
	found_player_id integer;
BEGIN
	SELECT id INTO found_player_id FROM player WHERE username=check_username;
	RETURN found_player_id;
END
$get_player_id$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE OR REPLACE FUNCTION GET_PLAYER_USERNAME(check_player_id integer) RETURNS character varying AS $get_player_username$
DECLARE 
	found_username character varying;
BEGIN
	SELECT username INTO found_username FROM player WHERE id=check_player_id;
	RETURN found_username;
END
$get_player_username$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE OR REPLACE FUNCTION CHARGE(price_code character varying, quantity integer) RETURNS boolean AS $charge_player$
DECLARE 
	amount integer;
	current_balance integer;
BEGIN

	SELECT cost INTO amount FROM price_list WHERE code=UPPER(price_code);
	SELECT balance INTO current_balance FROM player WHERE username=SESSION_USER;
	IF (current_balance - (amount * quantity)) < 0 THEN
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
	SELECT COUNT(*) INTO inventory_check FROM player_inventory WHERE player_id=NEW.player_id and item_name=NEW.item_name;
	IF inventory_check=1 THEN
		UPDATE player_inventory SET quantity=quantity+NEW.quantity WHERE player_id=NEW.player_id and item_name=NEW.item_name; 
		RETURN NULL;
	END IF;
	RETURN NEW;
END
$insert_item_into_inventory$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE TRIGGER INSERT_ITEM BEFORE INSERT ON player_inventory
  FOR EACH ROW EXECUTE PROCEDURE INSERT_ITEM_INTO_INVENTORY();  

CREATE OR REPLACE FUNCTION CHECK_PLAYER_INVENTORY() RETURNS trigger AS $check_player_inventory$
BEGIN
	IF NEW.quanity = 0 THEN
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
	last_move_tic integer default '0',
	last_script_tic integer default '0',
	last_living_tic integer default '0',
	current_health integer NOT NULL DEFAULT '100' CHECK (current_health <= max_health),	
	max_health integer NOT NULL DEFAULT '100',
	future_health integer default '100',
	current_fuel integer NOT NULL DEFAULT '100' CHECK (current_fuel <= max_fuel),
	max_fuel integer NOT NULL DEFAULT '100',
	max_speed integer NOT NULL DEFAULT '1000',
	range integer NOT NULL DEFAULT '300',
	attack integer NOT NULL DEFAULT '5',
	defense integer NOT NULL DEFAULT '5',
	engineering integer NOT NULL default '5',
	prospecting integer NOT NULL default '5',
	location_x integer NOT NULL default RANDOM(),
	location_y integer NOT NULL default RANDOM()
);


CREATE TABLE ship_control
(
	ship_id integer NOT NULL REFERENCES ship(id) ON DELETE CASCADE,
	speed integer NOT NULL DEFAULT 0,
	direction integer NOT NULL  DEFAULT 0 CHECK (0 <= direction and direction <= 360),
	destination_x integer,
	destination_y integer,
	script TEXT DEFAULT 'Select 1;'::TEXT,
	script_declarations TEXT  DEFAULT 'fakevar RECORD;'::TEXT,
	repair_priority integer DEFAULT '0',
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
  location_x integer NOT NULL,
  location_y integer NOT NULL,
  PRIMARY KEY (ship_id, tic)
);

CREATE VIEW my_ships_flight_recorder AS
SELECT 
  ship_id,
  tic,
  location_x,
  location_y
FROM ship_flight_recorder
WHERE
  ship_id in (select id from ship where player_id=GET_PLAYER_ID(SESSION_USER));    


CREATE VIEW ships_in_range AS
SELECT 
	enemies.id as id,
	players.id as ship_in_range_of,
	enemies.player_id as player_id,
	enemies.name as name,
	enemies.current_health/enemies.max_health as health,
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
	enemies.location_x as location_x,
	enemies.location_y as location_y	
FROM ship enemies, ship players
WHERE 	(
		players.player_id=GET_PLAYER_ID(SESSION_USER)
		AND
		enemies.player_id!=GET_PLAYER_ID(SESSION_USER)
 	 
	AND
	
		(enemies.location_x between (players.location_x-players.range) and (players.location_x+players.range)) 
		AND
		(enemies.location_y between (players.location_y-players.range) and (players.location_y+players.range)) 
	);

CREATE VIEW my_ships AS 
SELECT 
	ship.id as id,
	ship.fleet_id as fleet_id,
	ship.player_id as player_id ,
	ship.name as name,
	ship.last_action_tic as last_action_tic,
	ship.last_move_tic as last_move_tic,
	ship.last_script_tic as last_script_tic,
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
	ship.location_x as location_x,
	ship.location_y as location_y,
	ship_control.direction as direction,
	ship_control.speed as speed,
	ship_control.destination_x as destination_x,
	ship_control.destination_y as destination_y,
	ship_control.repair_priority as repair_priority,
	ship_control.script as script,
	ship_control.script_declarations as script_declarations	
FROM ship, ship_control 
WHERE player_id=GET_PLAYER_ID(SESSION_USER) and ship.id=ship_control.ship_id;

CREATE RULE ship_insert AS ON INSERT TO my_ships 
	DO INSTEAD INSERT INTO ship(name, range, attack, defense, engineering, prospecting, location_x, location_y) 
		VALUES(NEW.name, 
		  COALESCE(NEW.range, 300),
                  COALESCE(NEW.attack,5),
                  COALESCE(NEW.defense,5),
                  COALESCE(NEW.engineering,5),
                  COALESCE(NEW.prospecting,5),
                  COALESCE(NEW.location_x,RANDOM()),
                  COALESCE(NEW.location_y,RANDOM()));

CREATE RULE ship_control_update AS ON UPDATE TO my_ships
        DO INSTEAD ( UPDATE ship_control
                SET
			
                        direction=NEW.direction,
                        speed=NEW.speed,
                        destination_x=NEW.destination_x,
                        destination_y=NEW.destination_y,
                        repair_priority=NEW.repair_priority,
                        script=NEW.script,
                        script_declarations=NEW.script_declarations
                WHERE ship_id=NEW.id;
		UPDATE ship
                SET
			
                        name=NEW.name,
                        fleet_id=NEW.fleet_id
                WHERE id=NEW.id;
               )

CREATE OR REPLACE FUNCTION CREATE_SHIP() RETURNS trigger AS $create_ship$
BEGIN
	--CHECK SHIP STATS
	NEW.current_health = 100; 
	NEW.max_health = 100;
	NEW.current_fuel = 100; 
	NEW.max_fuel = 100;
	NEW.max_speed = 1000;

	IF (NEW.attack + NEW.defense + NEW.engineering + NEW.prospecting) > 20 THEN
		INSERT INTO error_log(player_id, error) VALUES(NEW.player_id, '(Attack + Defense + Engineering + Prospecting) > 20');
		RETURN NULL;
	END IF; 
	
	--CHARGE ACCOUNT	
	IF NOT CHARGE('SHIP', 1) THEN 
		INSERT INTO error_log(player_id, error) VALUES(NEW.player_id, 'Not enough funds to purchase ship');
		RETURN NULL;
	END IF;
	
	RETURN NEW; 
END
$create_ship$ LANGUAGE plpgsql;

CREATE TRIGGER CREATE_SHIP BEFORE INSERT ON ship
  FOR EACH ROW EXECUTE PROCEDURE CREATE_SHIP(); 

CREATE OR REPLACE FUNCTION DESTROY_SHIP() RETURNS trigger AS $destroy_ship$
DECLARE
        eid integer;
BEGIN
        UPDATE player SET balance=balance+(select cost from price_list where code='SHIP') WHERE id=OLD.player_id;
	eid = NEXTVAL('event_id_seq');
        INSERT INTO event(id, description, tic) VALUES(eid, OLD.name || '('|| OLD.id ||') has Exploded!',(SELECT last_value FROM tic_seq));
        INSERT INTO event_patron VALUES(eid, OLD.player_id);

	RETURN NEW;
END
$destroy_ship$ LANGUAGE plpgsql;

CREATE TRIGGER DESTROY_SHIP AFTER DELETE ON ship 
 FOR EACH ROW EXECUTE PROCEDURE DESTROY_SHIP();


CREATE OR REPLACE FUNCTION CREATE_SHIP_CONTROLLER() RETURNS trigger AS $create_ship_controller$
BEGIN
	INSERT INTO ship_control(ship_id) VALUES(NEW.id);
RETURN NEW;
END
$create_ship_controller$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE TRIGGER CREATE_SHIP_CONTROLLER AFTER INSERT ON ship
  FOR EACH ROW EXECUTE PROCEDURE CREATE_SHIP_CONTROLLER(); 


CREATE OR REPLACE FUNCTION SHIP_SCRIPT_UPDATE() RETURNS trigger AS $ship_script_update$
DECLARE
	player_username character varying;
	secret character varying;
BEGIN
	IF (TG_OP = 'UPDATE') THEN
		IF NOT ((NEW.script = OLD.script) OR (NEW.script_declarations = OLD.script_declarations)) THEN
			RETURN NEW;
		END IF;
	END IF;

	--secret to stop SQL injections here
	secret := 'ship_script_' || (RANDOM()*1000000)::integer;
	EXECUTE 'CREATE OR REPLACE FUNCTION SHIP_SCRIPT_'|| NEW.ship_id ||'() RETURNS boolean as $'||secret||'$
	DECLARE
		this_ship_id integer;
		' || NEW.script_declarations || '
	BEGIN
		this_ship_id := '|| NEW.ship_id||';
		' || NEW.script || '
		RETURN 1;
	END $'||secret||'$ LANGUAGE plpgsql;'::TEXT;
	
	SELECT GET_PLAYER_USERNAME(player_id) INTO player_username FROM ship WHERE id=NEW.ship_id;
	EXECUTE 'REVOKE ALL ON FUNCTION SHIP_SCRIPT_'|| NEW.ship_id ||'() FROM PUBLIC'::TEXT;
	EXECUTE 'REVOKE ALL ON FUNCTION SHIP_SCRIPT_'|| NEW.ship_id ||'() FROM players'::TEXT;
	EXECUTE 'GRANT EXECUTE ON FUNCTION SHIP_SCRIPT_'|| NEW.ship_id ||'() TO '|| player_username ||''::TEXT;
	
	RETURN NEW;
END $ship_script_update$ LANGUAGE plpgsql SECURITY DEFINER;


CREATE TRIGGER SHIP_SCRIPT_UPDATE AFTER INSERT OR UPDATE ON ship_control
  FOR EACH ROW EXECUTE PROCEDURE SHIP_SCRIPT_UPDATE(); 
  


CREATE OR REPLACE FUNCTION SHIP_MOVE_UPDATE() RETURNS trigger AS $ship_move_update$
BEGIN
  IF NOT ((NEW.location_x = OLD.location_x) OR (NEW.location_y = OLD.location_y)) THEN
    INSERT INTO ship_flight_recorder VALUES(NEW.id, (SELECT last_value FROM tic_seq), NEW.location_x, NEW.location_y);
  END IF;
  RETURN NULL;
END $ship_move_update$ LANGUAGE plpgsql SECURITY DEFINER;
                
                
CREATE TRIGGER SHIP_MOVE_UPDATE AFTER UPDATE ON ship
        FOR EACH ROW EXECUTE PROCEDURE SHIP_MOVE_UPDATE();
        


CREATE TABLE fleet
(
	id integer NOT NULL PRIMARY KEY,
	player_id integer NOT NULL REFERENCES player(id) DEFAULT GET_PLAYER_ID(SESSION_USER),
	lead_ship_id integer REFERENCES ship(id) ON DELETE SET NULL,
	name character varying(50)
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
	lead_ship_id,
	name
FROM 
	fleet
WHERE player_id=GET_PLAYER_ID(SESSION_USER);

CREATE RULE fleet_insert AS ON INSERT TO my_fleets
	DO INSTEAD INSERT INTO fleet(player_id, lead_ship_id, name) VALUES(GET_PLAYER_ID(SESSION_USER), NEW.lead_ship_id, NEW.name);

CREATE RULE fleet_update AS ON UPDATE TO my_fleets 
	DO INSTEAD UPDATE fleet
		SET 
			lead_ship_id=NEW.lead_ship_id,
			name=NEW.name
		WHERE id=NEW.id;

CREATE RULE fleet_delete AS ON DELETE TO my_fleets 
	DO INSTEAD DELETE FROM fleet WHERE id=OLD.id;


CREATE OR REPLACE FUNCTION UPGRADE_SHIP(ship_id integer, code character varying, quantity integer) RETURNS boolean AS $upgrade_ship$
DECLARE 
	current_fuel_reserve integer;
	new_fuel_reserve integer;
	
	current_ship_fuel integer;
	new_ship_fuel integer;
	
	max_ship_fuel integer;
BEGIN
	IF code = 'SHIP' THEN
		INSERT INTO error_log(player_id, error) VALUES(GET_PLAYER_ID(SESSION_USER), 'You cant upgrade ship into ship..'::TEXT);
		RETURN FALSE;
	END IF;
	IF NOT CHARGE(code, quantity) THEN
		INSERT INTO error_log(player_id, error) VALUES(GET_PLAYER_ID(SESSION_USER), 'Not enough funds to perform upgrade'::TEXT);
		RETURN FALSE;
	END IF;
	
	IF code = 'REFUEL' THEN
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
	ELSE
		EXECUTE 'UPDATE ship SET ' || code || '=(' || code || ' + ' || quantity || ' ) WHERE id=' || ship_id ||'';
	END IF;
RETURN TRUE;
END 
$upgrade_ship$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE OR REPLACE FUNCTION CONVERT_RESOURCE(current_resource_type character varying, amount integer) RETURNS integer as $convert_resource$
DECLARE
	amount_of_new_resource integer;
	fuel_check integer;
	money_check integer;
BEGIN
	SELECT INTO fuel_check, money_check fuel_reserve, balance FROM player WHERE id=GET_PLAYER_ID(SESSION_USER);
	IF current_resource_type = 'FUEL' THEN
		IF amount < fuel_check THEN
			SELECT INTO amount_of_new_resource (fuel_reserve/balance*amount)::integer FROM player WHERE id=0;
			UPDATE player SET fuel_reserve=fuel_reserve-amount, balance=balance+amount_of_new_resource WHERE id=GET_PLAYER_ID(SESSION_USER);
			UPDATE player SET balance=balance-amount, fuel_reserve=fuel_reserve+amount_of_new_resource WHERE id=0;
		ELSE
  			INSERT INTO error_log(player_id, error) VALUES(GET_PLAYER_ID(SESSION_USER), 'You do not have that much fuel to convert'::TEXT);
		END IF;
	ELSEIF current_resource_type = 'MONEY' THEN
		IF amount < money_check THEN
			SELECT INTO amount_of_new_resource (balance/fuel_reserve*amount)::integer FROM player WHERE id=0;
			UPDATE player SET balance=balance-amount, fuel_reserve=fuel_reserve+amount_of_new_resource WHERE id=GET_PLAYER_ID(SESSION_USER);
			UPDATE player SET fuel_reserve=fuel_reserve-amount, balance=balance+amount_of_new_resource WHERE id=0;

		ELSE
  			INSERT INTO error_log(player_id, error) VALUES(GET_PLAYER_ID(SESSION_USER), 'You do not have that much money to convert'::TEXT);
		END IF;
	END IF;

	RETURN amount_of_new_resource;
END
$convert_resource$ LANGUAGE plpgsql SECURITY DEFINER;



CREATE OR REPLACE FUNCTION DISCOVER_ITEM() RETURNS trigger as $discover_item$
DECLARE
	found_item RECORD;

	eid integer;
BEGIN
	FOR found_item IN SELECT * FROM item_location WHERE location_x=NEW.location_x AND location_y=NEW.location_y LOOP
		DELETE FROM item_location WHERE location_x=found_item.location_x AND location_y=found_item.location_y AND system_name=found_item.system_name;
		INSERT INTO player_inventory(player_id, item) VALUES(NEW.player_id, found_item.system_name);
		eid = NEXTVAL('event_id_seq');
		INSERT INTO event(id, description, tic) VALUES(eid, NEW.name || 'has discovered the item ' || found_item.system_name || ' at location ' || new_planet_x || ','|| new_planet_y ::TEXT, (SELECT last_value FROM tic_seq));
		INSERT INTO event_patron VALUES(eid, NEW.player_id);
		
	END LOOP;
	RETURN NEW;	
END
$discover_item$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE TRIGGER DISCOVER_ITEM AFTER UPDATE ON ship
  FOR EACH ROW EXECUTE PROCEDURE DISCOVER_ITEM();


--This thing is a bit of a monster...
CREATE OR REPLACE FUNCTION DISCOVER_PLANET() RETURNS trigger as $discover_planet$
DECLARE
	luck integer;
	new_planet_x integer;
	new_planet_y integer;
	
	min_x integer;
	max_x integer;
	min_y integer;
	max_y integer;
	
	range_min_x integer;
	range_max_x integer;
	range_min_y integer;
	range_max_y integer;
	
	discovered_old_planet record;
	
	eid integer;
	pid integer;

	c integer; -- for counting

	new_land integer;
BEGIN

	luck := (RANDOM() * 100)::integer;

	min_x = GET_NUMERIC_VARIABLE('MIN_X') - 1;
	max_x = GET_NUMERIC_VARIABLE('MAX_X') + 1;
	min_y = GET_NUMERIC_VARIABLE('MIN_Y') - 1;
	max_y = GET_NUMERIC_VARIABLE('MAX_Y') + 1;

	range_min_x = NEW.location_x-NEW.range;
	range_max_x = NEW.location_x+NEW.range;
	range_min_y = NEW.location_y-NEW.range;
	range_max_y = NEW.location_y+NEW.range;

	FOR discovered_old_planet in 
		SELECT planet.id, planet.location_x, planet.location_y FROM planet 
			WHERE planet.id NOT IN (select planet_id FROM discovered_planet WHERE player_id=NEW.player_id) 
			AND planet.location_x BETWEEN range_min_x AND range_max_x
			AND planet.location_y BETWEEN range_min_y AND range_max_y LOOP

		select COUNT(*) into c from discovered_planet WHERE planet_id= discovered_old_planet.id and player_id=NEW.player_id ;
		IF c = 0 THEN 
			INSERT INTO discovered_planet VALUES(discovered_old_planet.id, NEW.player_id);
			eid = NEXTVAL('event_id_seq');
			INSERT INTO event(id, description, tic) VALUES(eid, NEW.name || 'has found the planet at location ' || discovered_old_planet.location_x || ','|| discovered_old_planet.location_y ::TEXT, (SELECT last_value FROM tic_seq));
			INSERT INTO event_patron VALUES(eid, NEW.player_id);
		END IF;
	END LOOP;
	
	new_land := 0;
	IF  range_min_x < min_x THEN	
		UPDATE variable SET numeric_value=range_min_x WHERE name='MIN_X';
		new_land :=1;
	END IF;

	IF range_max_x > max_x THEN
		UPDATE variable SET numeric_value=range_max_x WHERE name='MAX_X';
		new_land :=1;
	END IF;

	IF range_min_y < min_y  THEN
		UPDATE variable SET numeric_value=range_min_y WHERE name='MIN_Y';
		new_land :=1;
	END IF;

	IF range_max_y > max_y THEN
		UPDATE variable SET numeric_value=range_max_y WHERE name='MAX_Y';
		new_land :=1;
	END IF;

	
	new_planet_x := 0;
	new_planet_y := 0;

	IF NOT NEW.location_x BETWEEN (min_x+NEW.range) AND (max_x-NEW.range) THEN
		IF (NEW.location_x+NEW.range > max_x) THEN
			new_planet_x =  NEW.location_x+NEW.range; 
		ELSE 
			new_planet_x = NEW.location_x-NEW.range;
		END IF;
	ELSE
		new_planet_x = NEW.location_x;
	END IF;
	IF  NOT NEW.location_y BETWEEN (min_y+NEW.range) AND (max_y-NEW.range) THEN
		IF (NEW.location_y+NEW.range > max_y) THEN 
			new_planet_y = NEW.location_y+NEW.range;
		ELSE
			new_planet_y = NEW.location_y-NEW.range;
		END IF;
	ELSE
		new_planet_y = NEW.location_y;
	END IF;
	
	IF luck = GET_NUMERIC_VARIABLE('UNIVERSE_CREATOR') AND new_land=1 THEN	
		pid = NEXTVAL('planet_id_seq');
		INSERT INTO planet(id, location_x, location_y, discovering_player_id) VALUES(pid,new_planet_x, new_planet_y, NEW.player_id);
		INSERT INTO discovered_planet(planet_id, player_id) VALUES(pid, NEW.player_id);
		eid = NEXTVAL('event_id_seq');
		INSERT INTO event(id, description, tic) VALUES(eid, NEW.name || ' has discovered a new planet at location ' || new_planet_x || ','|| new_planet_y ::TEXT, (SELECT last_value FROM tic_seq));
		INSERT INTO event_patron VALUES(eid, NEW.player_id);
	END IF;
	RETURN NEW;	
END
$discover_planet$ LANGUAGE plpgsql SECURITY DEFINER;



CREATE TRIGGER DISCOVER_PLANET AFTER UPDATE ON ship
  FOR EACH ROW EXECUTE PROCEDURE DISCOVER_PLANET();

CREATE TABLE trade
(
	id integer NOT NULL PRIMARY KEY,
	player_id_1 integer NOT NULL REFERENCES player(id),
	player_id_2 integer NOT NULL REFERENCES player(id),
	confirmation_1 integer DEFAULT '0',
	confirmation_2 integer DEFAULT '0',
	complete integer DEFAULT '0'
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
	DO INSTEAD INSERT INTO trade(player_id_1, player_id_2, confirmation_1, confirmation_2) 
		VALUES(NEW.player_id_1,NEW.player_id_2,NEW.confirmation_1,NEW.confirmation_2);

CREATE RULE trade_update AS ON UPDATE TO my_trades 
	DO INSTEAD UPDATE trade 
		SET 
			player_id_1=NEW.player_id_1,
			player_id_2=NEW.player_id_2,
			confirmation_1=NEW.confirmation_1,
			confirmation_2=NEW.confirmation_2
		WHERE id=NEW.id;

CREATE RULE trade_delete AS ON DELETE TO my_trades 
	DO INSTEAD DELETE FROM trade WHERE id=OLD.id;


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
	ship.location_x as ship_location_x,
	ship.location_y as ship_location_y
FROM trade, trade_item, ship WHERE 
GET_PLAYER_ID(SESSION_USER) IN (trade.player_id_1, trade.player_id_2)
AND
trade.id=trade_item.trade_id
AND
trade.complete=0
AND
trade_item.description_code ='SHIP' 
AND
ship.id=CAST(trade_item.descriptor as integer);



CREATE OR REPLACE FUNCTION ADD_TRADE_ITEM() RETURNS trigger AS $add_trade_item$
DECLARE
	check_value integer;
	eid integer;
	
	trader_1 integer;
	trader_2 integer;

	completed integer;
BEGIN
	SELECT INTO trader_1, trader_2, completed player_id_1, player_id_2, complete  FROM trade WHERE id=NEW.trade_id;
	IF completed = 1 THEN
		INSERT INTO error_log(player_id, error) VALUES(GET_PLAYER_ID(SESSION_USER), 'Trade #'||NEW.trade_id ||' is complete. Cannot make changes'::TEXT);
		RETURN NULL;
	END IF;

	UPDATE trade SET confirmation_1=0, confirmation_2=0 WHERE id=NEW.trade_id;

	eid :=0;
	
	IF NEW.description_code = 'FUEL' THEN
		SELECT fuel_reserve INTO check_value FROM player WHERE id=NEW.player_id;
		IF check_value > NEW.quantity THEN 
			UPDATE player SET fuel_reserve=fuel_reserve-NEW.quantity WHERE id = NEW.player_id;
			eid = NEXTVAL('event_id_seq');
			INSERT INTO event(id, description, tic) VALUES(eid,  GET_PLAYER_USERNAME(NEW.player_id) ||' added '|| NEW.quantity || ' of fuel to the trade #' || NEW.trade_id  || ''::TEXT, (SELECT last_value FROM tic_seq));
		ELSE
			INSERT INTO error_log(player_id, error) VALUES(GET_PLAYER_ID(SESSION_USER), 'You cant add more fuel to a trade then you hold in your my_player.fuel_reserve'::TEXT);
			RETURN NULL;
		END IF;
	ELSEIF NEW.description_code = 'MONEY' THEN
		SELECT balance INTO check_value FROM player WHERE id=NEW.player_id;
		IF check_value > NEW.quantity THEN 
			UPDATE player SET fuel_balance=balance-NEW.quantity WHERE id = NEW.player_id;
			eid = NEXTVAL('event_id_seq');
			INSERT INTO event(id, description, tic) VALUES(eid,  GET_PLAYER_USERNAME(NEW.player_id) ||' added '|| NEW.quantity || ' monies to the trade #' || NEW.trade_id  || ''::TEXT, (SELECT last_value FROM tic_seq));

		ELSE
			INSERT INTO error_log(player_id, error) VALUES(GET_PLAYER_ID(SESSION_USER), 'You cant add more money to a trade then you hold in your my_player.balance'::TEXT);
			RETURN NULL;
		END IF;
	ELSEIF NEW.description_code = 'SHIP' THEN
		SELECT player_id INTO check_value FROM ship WHERE id=CAST(NEW.descriptor as integer);
		IF check_value = NEW.player_id THEN 
			--player 0 = schemaverse 
			UPDATE ship SET player_id=0, fleet_id=NULL WHERE id=CAST(NEW.descriptor as integer);
			eid = NEXTVAL('event_id_seq');
			INSERT INTO event(id, description, tic) VALUES(eid,  GET_PLAYER_USERNAME(NEW.player_id) ||' added a ship (ID #'|| NEW.descriptor || ') to the trade #' || NEW.trade_id  || ''::TEXT, (SELECT last_value FROM tic_seq));

		ELSE
			INSERT INTO error_log(player_id, error) VALUES(GET_PLAYER_ID(SESSION_USER), 'Trading a ship you dont own is kind of a DM'::TEXT);
			RETURN NULL;
		END IF;
	ELSEIF NEW.description_code = 'ITEM' THEN
		SELECT quantity INTO check_value FROM player_inventory WHERE player_id=NEW.player_id AND item_name=NEW.descriptor;
		--i need to make sure have items wont make this choke
		IF check_value > NEW.quantity THEN 
			UPDATE player_inventory SET quantity=quantity-NEW.quantity WHERE item_name=NEW.descriptor and player_id = NEW.player_id;
			eid = NEXTVAL('event_id_seq');
			INSERT INTO event(id, description, tic) VALUES(eid,  GET_PLAYER_USERNAME(NEW.player_id) ||' added '|| NEW.quantity || ' of the item '|| NEW.descriptor  ||' to the trade #' || NEW.trade_id  || ''::TEXT, (SELECT last_value FROM tic_seq));

		ELSE
			INSERT INTO error_log(player_id, error) VALUES(GET_PLAYER_ID(SESSION_USER), 'You do not own enough of that item to add it'::TEXT);
			RETURN NULL;
		END IF;
	END IF;
	
	IF eid > 0 THEN
	  IF NOT trader_1 = trader_2 THEN
	    INSERT INTO event_patron VALUES(eid, trader_1),(eid, trader_2);
          ELSE
            INSERT INTO event_patron VALUES(eid, trader_1);
          END IF;
        END IF;
	
	RETURN NEW;
END
$add_trade_item$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE TRIGGER INCLUDE_TRADE_ITEM BEFORE INSERT ON trade_item
  FOR EACH ROW EXECUTE PROCEDURE ADD_TRADE_ITEM(); 


CREATE OR REPLACE FUNCTION DELETE_TRADE_ITEM() RETURNS trigger AS $delete_trade_item$
DECLARE
	eid integer;
	
	trader_1 integer;
	trader_2 integer;
	completed integer;

BEGIN
	SELECT INTO trader_1, trader_2, completed player_id_1, player_id_2, complete FROM trade WHERE id=OLD.trade_id;
	IF completed = 1 THEN
		INSERT INTO error_log(player_id, error) VALUES(GET_PLAYER_ID(SESSION_USER), 'Trade #'||OLD.trade_id ||' is complete. Cannot make changes'::TEXT);
		RETURN NULL;
	END IF;


	UPDATE trade SET confirmation_1=0, confirmation_2=0 WHERE id=OLD.trade_id;
	eid :=0;

	IF OLD.description_code = 'FUEL' THEN
		UPDATE player SET fuel_reserve=fuel_reserve+OLD.quantity WHERE id = OLD.player_id;
		eid = NEXTVAL('event_id_seq');
		INSERT INTO event(id, description, tic) VALUES(eid,  GET_PLAYER_USERNAME(OLD.player_id) ||' removed '|| OLD.quantity || ' of fuel from the trade #' || OLD.trade_id  || ''::TEXT, (SELECT last_value FROM tic_seq));

	ELSEIF OLD.description_code = 'MONEY' THEN
		UPDATE player SET fuel_balance=balance+OLD.quantity WHERE id = OLD.player_id;
		eid = NEXTVAL('event_id_seq');
		INSERT INTO event(id, description, tic) VALUES(eid,  GET_PLAYER_USERNAME(OLD.player_id) ||' removed '|| OLD.quantity || ' monies from the trade #' || OLD.trade_id  || ''::TEXT, (SELECT last_value FROM tic_seq));

	ELSEIF OLD.description_code = 'SHIP' THEN
		UPDATE ship SET player_id=OLD.player_id, fleet_id=NULL WHERE id = CAST(OLD.descriptor as integer);
		eid = NEXTVAL('event_id_seq');
		INSERT INTO event(id, description, tic) VALUES(eid,  GET_PLAYER_USERNAME(OLD.player_id) ||' removed a ship (ID #'|| OLD.descriptor || ') from the trade #' || OLD.trade_id  || ''::TEXT, (SELECT last_value FROM tic_seq));

	ELSEIF OLD.description_code = 'ITEM' THEN
		INSERT INTO player_inventory(player_id, item, quantity) VALUES(OLD.player_id, OLD.descriptor, OLD.quantity); 
		eid = NEXTVAL('event_id_seq');
		INSERT INTO event(id, description, tic) VALUES(eid,  GET_PLAYER_USERNAME(OLD.player_id) ||' removed '|| OLD.quantity || ' of the item '|| OLD.descriptor  ||' from the trade #' || OLD.trade_id  || ''::TEXT, (SELECT last_value FROM tic_seq));

	END IF;

	IF eid > 0 THEN
	  IF NOT trader_1 = trader_2 THEN
	    INSERT INTO event_patron VALUES(eid, trader_1),(eid, trader_2);
	  ELSE
	    INSERT INTO event_patron VALUES(eid, trader_1);
	  END IF;                                                                   
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

	eid integer;
BEGIN
	IF NEW.complete = 0 AND NEW.confirmation_1=NEW.player_id_1 AND NEW.confirmation_2=NEW.player_id_2 THEN
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
				UPDATE player SET fuel_balance=balance+trade_items.quantity WHERE id = recipient;
			ELSEIF trade_items.description_code = 'SHIP' THEN
				UPDATE ship SET player_id=recipient WHERE id=CAST(trade_items.descriptor as integer);
			ELSEIF trade_items.description_code = 'ITEM' THEN
				INSERT INTO player_inventory(player_id, item, quantity) VALUES(recipient, trade_items.descriptor, trade_items.quantity); 
			END IF;
		END LOOP;
		
		NEW.complete = 1;

		eid = NEXTVAL('event_id_seq');
		INSERT INTO event(id, description, tic) VALUES(eid, 'Trade #' || NEW.id  || ' between ' ||  GET_PLAYER_USERNAME(NEW.player_id_1) || ' and ' ||  GET_PLAYER_USERNAME(NEW.player_id_2) || ' complete'::TEXT, (SELECT last_value FROM tic_seq));
		IF NOT recipient = giver THEN
                  INSERT INTO event_patron VALUES(eid, NEW.player_id_1),(eid, NEW.player_id_2);
                ELSE
                  INSERT INTO event_patron VALUES(eid, NEW.player_id_1);
                END IF;
		                                                                    
	END IF;
RETURN NEW;
END
$trade_confirmation$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE TRIGGER TRADE_CONFIRMATION AFTER UPDATE ON trade
  FOR EACH ROW EXECUTE PROCEDURE TRADE_CONFIRMATION(); 


			


CREATE TABLE event
(
	id integer NOT NULL PRIMARY KEY,
	description text NOT NULL,
	tic integer NOT NULL,
	toc timestamp NOT NULL DEFAULT NOW()
);
CREATE SEQUENCE event_id_seq
  INCREMENT 1
  MINVALUE 1
  MAXVALUE 9223372036854775807
  START 1
  CACHE 1;

CREATE TABLE event_patron
(
	event_id integer NOT NULL REFERENCES event(id),
	player_id integer NOT NULL REFERENCES player(id),
	read boolean NOT NULL DEFAULT 'f',
	PRIMARY KEY (event_id, player_id)
);

CREATE VIEW my_events AS
SELECT
        event.id as id,
        event.description as description,
        event.tic as tic,
        event.toc as toc,
        event_patron.read as read
FROM event_patron inner join event on event_patron.event_id=event.id
WHERE event_patron.player_id=GET_PLAYER_ID(SESSION_USER) AND event.tic < (SELECT last_value FROM tic_seq);


CREATE OR REPLACE FUNCTION READ_EVENT(read_event_id integer) RETURNS boolean AS $read_event$
DECLARE 
	read_flag boolean;
BEGIN
        UPDATE event_patron SET read='t' WHERE event_id=read_event_id AND player_id=GET_PLAYER_ID(SESSION_USER) RETURNING read INTO read_flag;
        RETURN read_flag;
END
$read_event$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE TABLE planet
(
	id integer NOT NULL PRIMARY KEY,
	name character varying,
	fuel integer NOT NULL DEFAULT RANDOM()*100000,
	mine_limit integer NOT NULL DEFAULT RANDOM()*100,
	difficulty integer NOT NULL DEFAULT RANDOM()*10,
	location_x integer NOT NULL DEFAULT RANDOM(),
	location_y integer NOT NULL DEFAULT RANDOM(),
	discovering_player_id integer REFERENCES player(id)
);

CREATE SEQUENCE planet_id_seq
  INCREMENT 1
  MINVALUE 1
  MAXVALUE 9223372036854775807
  START 1
  CACHE 1;

CREATE TABLE planet_miners
(
	planet_id integer REFERENCES planet(id) ON DELETE CASCADE,
	ship_id integer REFERENCES ship(id),
	PRIMARY KEY (planet_id, ship_id)
);

CREATE TABLE discovered_planet
(
	planet_id integer REFERENCES planet(id) ON DELETE CASCADE,
	player_id integer REFERENCES player(id),
	PRIMARY KEY (planet_id, player_id)
);

CREATE VIEW my_planets AS
SELECT 
	planet.id as id,
	planet.name as name,
	planet.mine_limit as mine_limit,
	planet.location_x as location_x,
	planet.location_y as location_y
FROM planet, discovered_planet
WHERE planet.id=discovered_planet.planet_id AND discovered_planet.player_id=GET_PLAYER_ID(SESSION_USER);

CREATE RULE planet_update AS ON UPDATE TO my_planets
        DO INSTEAD UPDATE planet SET name=NEW.name WHERE id=NEW.id and discovering_player_id=GET_PLAYER_ID(SESSION_USER);



CREATE TABLE error_log 
(
	id integer NOT NULL PRIMARY KEY,
	player_id integer REFERENCES player(id),
	executed timestamp NOT NULL DEFAULT NOW(),
	read boolean NOT NULL DEFAULT 'f',
	error TEXT NOT NULL
);
CREATE SEQUENCE error_log_id_seq
  INCREMENT 1
  MINVALUE 1
  MAXVALUE 9223372036854775807
  START 1
  CACHE 1;

CREATE VIEW my_error_log AS
SELECT id, executed, error, read FROM error_log WHERE player_id=GET_PLAYER_ID(SESSION_USER);

CREATE OR REPLACE FUNCTION READ_ERROR(read_error_id integer) RETURNS boolean AS $read_error$
DECLARE 
	read_flag boolean;
BEGIN
        UPDATE error_log SET read='t' WHERE error_id=read_error_id AND player_id=GET_PLAYER_ID(SESSION_USER) RETURNING read INTO read_flag;
        RETURN read_flag;
END
$read_error$ LANGUAGE plpgsql SECURITY DEFINER;


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


CREATE TRIGGER ERROR_LOG_ID_DEALER BEFORE INSERT OR UPDATE ON error_log
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

                IF TG_TABLE_NAME IN ('ship','fleet','error_log','trade_item') THEN
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

                IF TG_TABLE_NAME IN ('ship','fleet','error_log','trade_item') THEN
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

CREATE TRIGGER A_ERROR_LOG_PERMISSION_CHECK BEFORE INSERT OR UPDATE OR DELETE ON error_log
  FOR EACH ROW EXECUTE PROCEDURE GENERAL_PERMISSION_CHECK(); 


CREATE OR REPLACE FUNCTION ACTION_PERMISSION_CHECK(ship_id integer) RETURNS boolean AS $action_permission_check$
DECLARE 
	ships_player_id integer;
BEGIN
	SELECT player_id into ships_player_id FROM ship WHERE id=ship_id and current_health > 0 and last_action_tic != (SELECT last_value FROM tic_seq);
	IF ships_player_id = GET_PLAYER_ID(SESSION_USER) THEN
		RETURN 't';
	ELSE 
		RETURN 'f';
	END IF;
END
$action_permission_check$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE OR REPLACE FUNCTION MOVE_PERMISSION_CHECK(ship_id integer) RETURNS boolean AS $move_permission_check$
DECLARE 
	ships_player_id integer;
	last_tic integer;
BEGIN
	SELECT player_id, last_move_tic into ships_player_id, last_tic FROM ship WHERE id=ship_id and current_health > 0;
	IF  last_tic != (SELECT last_value FROM tic_seq) 
		AND ( 
			ships_player_id = GET_PLAYER_ID(SESSION_USER) 
			OR SESSION_USER = 'schemaverse' 
			OR CURRENT_USER = 'schemaverse' 
		 ) THEN
		RETURN 't';
	ELSE 
		RETURN 'f';
	END IF;
END
$move_permission_check$ LANGUAGE plpgsql SECURITY DEFINER;


CREATE OR REPLACE FUNCTION IN_RANGE_SHIP(ship_1 integer, ship_2 integer) RETURNS boolean AS $in_range_ship$
DECLARE
	check_count integer;
BEGIN
	SELECT 
		count(enemies.id)
	INTO check_count
	FROM ship enemies, ship players
	WHERE 	(
			players.id=ship_1
			AND 
			enemies.id=ship_2
 		) 
		AND
		(
			(enemies.location_x between (players.location_x-players.range) and (players.location_x+players.range)) 
			AND
			(enemies.location_y between (players.location_y-players.range) and (players.location_y+players.range)) 
		);
	IF check_count = 1 THEN
		RETURN 't';
	ELSE
		RETURN 'f';
	END IF;
END
$in_range_ship$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE OR REPLACE FUNCTION IN_RANGE_PLANET(ship_id integer, planet_id integer) RETURNS boolean AS $in_range_planet$
DECLARE
	check_count integer;
BEGIN
	SELECT 
		count(planet.id)
	INTO check_count
	FROM planet, ship
	WHERE 	(
			ship.id=ship_id
			AND 
			planet.id=planet_id
 		) 
		AND
		(
			(planet.location_x between (ship.location_x-ship.range) and (ship.location_x+ship.range)) 
			AND
			(planet.location_y between (ship.location_y-ship.range) and (ship.location_y+ship.range)) 
		);
	IF check_count = 1 THEN
		RETURN 't';
	ELSE
		RETURN 'f';
	END IF;
END
$in_range_planet$ LANGUAGE plpgsql SECURITY DEFINER;

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
	
	event_id integer;
BEGIN
	
	damage = 0;
	
	
	--check range
	IF ACTION_PERMISSION_CHECK(attacker) AND (IN_RANGE_SHIP(attacker, enemy_ship)) THEN
	
		SELECT attack, player_id, name INTO attack_rate, attacker_player_id, attacker_name FROM ship WHERE id=attacker;
		SELECT (attack_rate * (defense/100.0))::integer, player_id, name INTO defense_rate, enemy_player_id, enemy_name FROM ship WHERE id=enemy_ship;
	
		damage = attack_rate - defense_rate;
		UPDATE ship SET future_health=future_health-damage WHERE id=enemy_ship;
		UPDATE ship SET last_action_tic=(SELECT last_value FROM tic_seq) WHERE id=attacker;
		
		--add event
		event_id = NEXTVAL('event_id_seq');
		INSERT INTO event(id, description, tic) VALUES(event_id, attacker_name || ' Attacked ' || enemy_name || ' causing ' || damage || ' of damage.'::TEXT, (SELECT last_value FROM tic_seq));
		IF NOT attacker_player_id = enemy_player_id THEN
    		  INSERT INTO event_patron VALUES(event_id, attacker_player_id),(event_id, enemy_player_id);
                ELSE                                  
    		  INSERT INTO event_patron VALUES(event_id, attacker_player_id);
                END IF;
	ELSE 
		INSERT INTO error_log(player_id, error) VALUES(GET_PLAYER_ID(SESSION_USER), 'Attack from ' || attacker || ' to '|| enemy_ship ||' failed'::TEXT);
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
	
	
	event_id integer;
BEGIN
	
	repair_rate = 0;
	
	
	--check range
	IF ACTION_PERMISSION_CHECK(repair_ship) AND (IN_RANGE_SHIP(repair_ship, repaired_ship)) THEN
	
		SELECT engineering, player_id, name INTO repair_rate, repair_ship_player_id, repair_ship_name FROM ship WHERE id=repair_ship;
		SELECT name INTO repaired_ship_name FROM ship WHERE id=repaired_ship;
		UPDATE ship SET future_health = future_health + repair_rate WHERE id=repaired_ship;
		UPDATE ship SET last_action_tic=(SELECT last_value FROM tic_seq) WHERE id=repair_ship;
		
		--add event
		event_id = NEXTVAL('event_id_seq');
		INSERT INTO event(id, description, tic) VALUES(event_id, repair_ship_name || ' Repaired ' || repaired_ship_name || ' by ' || repair_rate || ' points.'::TEXT, (SELECT last_value FROM tic_seq));
		INSERT INTO event_patron VALUES(event_id, repair_ship_player_id);
	ELSE 
		INSERT INTO error_log(player_id, error) VALUES(GET_PLAYER_ID(SESSION_USER), 'Repair from ' || repair_ship || ' to '|| repaired_ship ||' failed'::TEXT);
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
		INSERT INTO error_log(player_id, error) VALUES(GET_PLAYER_ID(SESSION_USER), 'Mining ' || planet_id || ' with ship '|| ship_id ||' failed'::TEXT);
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
	event_id integer;
	 
BEGIN
	current_planet_id = 0; 
	FOR miners IN SELECT 
			planet_miners.planet_id as planet_id, 
			planet_miners.ship_id as ship_id, 
			ship.player_id as player_id, 
			ship.prospecting as prospecting
			FROM 
				planet_miners, ship
			WHERE
				planet_miners.ship_id=ship.id
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

			UPDATE player SET fuel_reserve = (fuel_reserve + mined_player_fuel)::integer WHERE id = miners.player_id;
			UPDATE planet SET fuel = (fuel - mined_player_fuel)::integer WHERE id = current_planet_id;

			--add event
			event_id = NEXTVAL('event_id_seq');
			INSERT INTO event(id, description, tic) VALUES(event_id, miners.ship_id || ' mined planet ' || miners.planet_id || ' and found ' || mined_player_fuel || ' of fuels!'::TEXT, (SELECT last_value FROM tic_seq));
			INSERT INTO event_patron VALUES(event_id, miners.player_id);

			limit_counter = limit_counter + 1;
		ELSE
			event_id := NEXTVAL('event_id_seq');
			INSERT INTO event(id, description, tic) VALUES(event_id, miners.ship_id || 'tried to mine planet ' || miners.planet_id || ' but failed.'::TEXT, (SELECT last_value FROM tic_seq));
			INSERT INTO event_patron VALUES(event_id, miners.player_id);
		END IF;		
		DELETE FROM planet_miners WHERE planet_id=miners.planet_id AND ship_id=miners.ship_id;
	END LOOP;
	RETURN 1;
END
$perform_mining$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION "move"(moving_ship_id integer, new_speed integer, new_direction integer, new_destination_x integer, new_destination_y 
integer)
  RETURNS boolean AS
$BODY$
DECLARE
        speed_check integer;
        final_speed integer;
        fuel_check integer;
        distance  integer;
        target_x  integer;
        target_y  integer;
        quadrant  integer := 0;
        mynewdirection  integer;
BEGIN
        IF MOVE_PERMISSION_CHECK(moving_ship_id) THEN
                SELECT INTO speed_check, fuel_check, target_x, target_y  max_speed, current_fuel, location_x, location_y from ship WHERE id=moving_ship_id;

                SELECT INTO final_speed CASE WHEN new_speed < speed_check THEN new_speed ELSE speed_check END;
                SELECT INTO distance CASE WHEN final_speed < fuel_check THEN final_speed ELSE fuel_check END;

                mynewdirection := new_direction;

                IF (mynewdirection IS NULL) THEN      --This section can probably be optimized using better trig/maff
                        target_x := new_destination_x - target_x;
                        target_y := new_destination_y - target_y;
                        SELECT INTO quadrant CASE WHEN target_x > 0 AND target_y > 0 THEN 0
                                                  WHEN target_x < 0 AND target_y > 0 THEN 90
                                                  WHEN target_x < 0 AND target_y < 0 THEN 180
                                                  WHEN target_x > 0 AND target_y < 0 THEN 270
                                             END;
                        
                        SELECT INTO mynewdirection CASE WHEN (target_x = 0 AND target_y = 0) THEN 0
                                                       WHEN (target_x = 0 AND target_y > 0) THEN 90
                                                       WHEN (target_x = 0 AND target_y < 0) THEN 270
                                                       ELSE ABS(CAST(DEGREES(ATAN(target_y / target_x)) as integer)) + quadrant END;
                END IF;
                
                UPDATE
                        ship
                SET
                        current_fuel = current_fuel-distance,
                        location_x = location_x + (COS(PI()/180*MOD(mynewdirection,360))*distance),
                        location_y = location_y + (SIN(PI()/180*MOD(mynewdirection,360))*distance),
                        last_move_tic = (SELECT last_value FROM tic_seq)
                WHERE
                        id = moving_ship_id;

		UPDATE 
			ship_control 
		SET 
			destination_x=new_destination_x, 
			destination_y=new_destination_y,
			speed=new_speed,
			direction=mynewdirection
		WHERE 
			ship_id = moving_ship_id;

                UPDATE 
			ship_control 
		SET 
			speed = 0 FROM ship
                WHERE
                 ship_control.ship_id=moving_ship_id AND ship.id=ship_control.ship_id
                  AND
     ship_control.destination_x between (ship.location_x - ship.range) and (ship.location_x + ship.range) 
                  AND
                      ship_control.destination_y between  (ship.location_y - ship.range) and (ship.location_y + ship.range);

                RETURN 't';
        ELSE
                INSERT INTO error_log(player_id, error) VALUES(GET_PLAYER_ID(SESSION_USER), 'Ship '|| moving_ship_id ||' did not budge!'::TEXT);
                RETURN 'f';
        END IF;
END
$BODY$
  LANGUAGE plpgsql VOLATILE SECURITY DEFINER;



CREATE TABLE stat_log
(
	tic integer NOT NULL PRIMARY KEY,
	total_players integer,
	online_players integer,
	total_ships integer,
	avg_ships integer,
	total_planets integer,
	avg_planets integer,
	total_trades integer,
	active_trades integer,
	total_fuel_reserve integer,
	avg_fuel_reserve integer,
	total_currency integer,
	avg_balance integer
	
);

CREATE VIEW current_stats AS
select 
	(SELECT last_value FROM tic_seq) as current_tic,
	count(id) as total_players, 
	(select count(id) from online_players) as online_players,
	(SELECT count(id) from ship) as total_ships, 
	ceil(avg((SELECT count(id) from ship where player_id=player.id group by player_id))) as avg_ships, 
	(select count(ID) FROM PLANET) as total_planets,
	ceil(avg((select count(planet_id) from discovered_planet where player_id=id))) as avg_planets,
	(select count(id) from trade) as total_trades,
	(select count(id) from trade where player_id_1!=confirmation_1 OR player_id_2!=confirmation_2) as active_trades,
	(select sum(fuel_reserve) from player where id!=0) as total_fuel_reserves,
	ceil((select avg(fuel_reserve) from player where id!=0)) as avg_fuel_reserve,
	(select sum(balance) from player where id!=0) as total_currency,
	ceil((select avg(balance) from player where id!=0)) as avg_balance
from player ;


                                                                                                                                                                                                                                                                                                                                                                                                                                                                                     
-- Create group 'players' and define the permissions

CREATE GROUP players WITH NOLOGIN NOSUPERUSER NOCREATEDB NOCREATEROLE NOINHERIT;

REVOKE ALL ON tic_seq FROM players;
GRANT SELECT ON tic_seq TO players;

REVOKE ALL ON variable FROM players;
GRANT SELECT ON public_variable TO players;

REVOKE ALL ON item FROM players;
REVOKE ALL ON item_location FROM players;
GRANT SELECT ON item TO players;

REVOKE ALL ON player FROM players;
REVOKE ALL ON player_inventory FROM players;
REVOKE ALL ON player_id_seq FROM players;
REVOKE ALL ON player_inventory_id_seq FROM players;
GRANT SELECT ON my_player TO players;
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
REVOKE ALL ON discovered_planet FROM players;
REVOKE ALL ON planet_miners FROM players;
GRANT SELECT ON my_planets TO players;
GRANT UPDATE ON my_planets TO players;

REVOKE ALL ON event_patron FROM players;
REVOKE ALL ON event FROM players;
GRANT INSERT ON event TO players;
GRANT SELECT ON my_events TO players;

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
GRANT DELETE ON my_fleets TO players;

REVOKE ALL ON error_log FROM players;
REVOKE ALL ON error_log_id_seq FROM players;
GRANT SELECT ON my_error_log TO players;
GRANT INSERT ON error_log TO players;

REVOKE ALL ON price_list FROM players;
GRANT SELECT ON price_list TO players;

REVOKE ALL ON current_stats FROM players;
REVOKE ALL ON stat_log FROM players;
GRANT SELECT ON current_stats TO players;
GRANT SELECT ON stat_log TO players;




