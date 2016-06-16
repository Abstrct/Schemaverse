-- Deploy function-convert_resource
-- requires: table-player

BEGIN;

CREATE OR REPLACE FUNCTION convert_resource(current_resource_type character varying, amount bigint)
  RETURNS bigint AS
$BODY$
DECLARE
	amount_of_new_resource bigint;
	fuel_check bigint;
	money_check bigint;
BEGIN
	SET search_path to public;
	SELECT INTO fuel_check, money_check fuel_reserve, balance FROM player WHERE id=GET_PLAYER_ID(SESSION_USER);
	IF current_resource_type = 'FUEL' THEN
		IF amount >= 0 AND  amount <= fuel_check THEN
			--SELECT INTO amount_of_new_resource (fuel_reserve/balance*amount)::bigint FROM player WHERE id=0;
			amount_of_new_resource := amount;
			UPDATE player SET fuel_reserve=fuel_reserve-amount, balance=balance+amount_of_new_resource WHERE id=GET_PLAYER_ID(SESSION_USER);
			--UPDATE player SET balance=balance-amount, fuel_reserve=fuel_reserve+amount_of_new_resource WHERE id=0;
		ELSE
  			EXECUTE 'NOTIFY ' || get_player_error_channel() ||', ''You do not have that much fuel to convert'';';
		END IF;
	ELSEIF current_resource_type = 'MONEY' THEN
		IF  amount >= 0 AND amount <= money_check THEN
			--SELECT INTO amount_of_new_resource (balance/fuel_reserve*amount)::bigint FROM player WHERE id=0;
			amount_of_new_resource := amount;
			UPDATE player SET balance=balance-amount, fuel_reserve=fuel_reserve+amount_of_new_resource WHERE id=GET_PLAYER_ID(SESSION_USER);
			--UPDATE player SET fuel_reserve=fuel_reserve-amount, balance=balance+amount_of_new_resource WHERE id=0;

		ELSE
  			EXECUTE 'NOTIFY ' || get_player_error_channel() ||', ''You do not have that much money to convert'';';
		END IF;
	END IF;

	RETURN amount_of_new_resource;
END
$BODY$
  LANGUAGE plpgsql VOLATILE SECURITY DEFINER
  COST 100;

COMMIT;
