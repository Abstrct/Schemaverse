-- Deploy function-charge
-- requires: table-player

BEGIN;


CREATE OR REPLACE FUNCTION charge(price_code character varying, quantity bigint)
  RETURNS boolean AS
$BODY$
DECLARE 
	amount bigint;
	current_balance bigint;
BEGIN
	SET search_path to public;

	SELECT cost INTO amount FROM price_list WHERE code=UPPER(price_code);
	SELECT balance INTO current_balance FROM player WHERE username=SESSION_USER;
	IF quantity < 0 OR (current_balance - (amount * quantity)) < 0 THEN
		RETURN 'f';
	ELSE 
		UPDATE player SET balance=(balance-(amount * quantity)) WHERE username=SESSION_USER;
	END IF;
	RETURN 't'; 
END
$BODY$
  LANGUAGE plpgsql VOLATILE SECURITY DEFINER
  COST 100;

COMMIT;
