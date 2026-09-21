-- Deploy function-charge_scaled
-- requires: function-charge
--
-- charge() with a price multiplier, for progressive upgrade pricing. Rounds
-- up, so a multiplier never makes anything free.

BEGIN;

CREATE OR REPLACE FUNCTION charge(price_code character varying, quantity bigint, multiplier numeric)
  RETURNS boolean AS
$BODY$
DECLARE
	amount bigint;
	current_balance bigint;
BEGIN
	SELECT ceil(cost * quantity * GREATEST(multiplier, 1)) INTO amount FROM price_list WHERE code = UPPER(price_code);
	SELECT balance INTO current_balance FROM player WHERE username = SESSION_USER;
	IF quantity < 0 OR amount IS NULL OR (current_balance - amount) < 0 THEN
		RETURN false;
	END IF;
	UPDATE player SET balance = balance - amount WHERE username = SESSION_USER;
	RETURN true;
END
$BODY$
  LANGUAGE plpgsql VOLATILE SECURITY DEFINER
  SET search_path = public, pg_temp;

COMMIT;
