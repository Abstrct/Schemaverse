-- Deploy function-current_tic
-- requires: sequence-tic_seq

BEGIN;

CREATE OR REPLACE FUNCTION current_tic() RETURNS integer AS
$$ SELECT last_value::integer FROM public.tic_seq $$
LANGUAGE sql STABLE;

COMMENT ON FUNCTION current_tic() IS 'The tic in progress.';

COMMIT;
