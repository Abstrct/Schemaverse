-- Deploy function-generate_string

BEGIN;

CREATE OR REPLACE FUNCTION generate_string(len integer)
  RETURNS character varying AS
$BODY$
BEGIN
	RETURN array_to_string(ARRAY(SELECT chr((65 + round(random() * 25)) :: integer) FROM generate_series(1,len)), '');
END
$BODY$
  LANGUAGE plpgsql VOLATILE
  COST 100;

COMMIT;
