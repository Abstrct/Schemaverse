-- Deploy security-search_path
--
-- Every SECURITY DEFINER function runs with the privileges of the schemaverse
-- owner. Without a pinned search_path a player could create a same-named
-- object in a schema that sorts earlier and have the owner execute it. Pin
-- every one of them in a single pass; later reworks carry the SET clause in
-- their own definitions because CREATE OR REPLACE resets it.

BEGIN;

DO $$
DECLARE f record;
BEGIN
  FOR f IN
    SELECT p.oid::regprocedure AS sig
      FROM pg_proc p JOIN pg_namespace n ON n.oid = p.pronamespace
     WHERE n.nspname = 'public' AND p.prosecdef
  LOOP
    EXECUTE format('ALTER FUNCTION %s SET search_path = public, pg_temp', f.sig);
  END LOOP;
END $$;

COMMIT;
