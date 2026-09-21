-- Deploy function-current_round
-- requires: sequence-round_seq

BEGIN;

CREATE OR REPLACE FUNCTION current_round() RETURNS integer AS
$$ SELECT last_value::integer FROM public.round_seq $$
LANGUAGE sql STABLE;

COMMENT ON FUNCTION current_round() IS 'The round in progress. Partition key of the event table.';

COMMIT;
