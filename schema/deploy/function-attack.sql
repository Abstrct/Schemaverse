-- Deploy function-attack
-- requires: table-ship
-- requires: function-in_range_ship

BEGIN;


CREATE OR REPLACE FUNCTION attack(attacker integer, enemy_ship integer)
  RETURNS integer AS
$BODY$
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
	SET search_path to public;
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
$BODY$
  LANGUAGE plpgsql VOLATILE SECURITY DEFINER
  COST 100;

COMMIT;
