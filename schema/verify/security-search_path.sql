-- Verify security-search_path: no SECURITY DEFINER function in public lacks a search_path setting.

BEGIN;

SELECT 1/(CASE WHEN count(*) = 0 THEN 1 ELSE 0 END)
  FROM pg_proc p JOIN pg_namespace n ON n.oid = p.pronamespace
 WHERE n.nspname = 'public' AND p.prosecdef
   AND NOT EXISTS (SELECT 1 FROM unnest(p.proconfig) c WHERE c LIKE 'search_path=%');

ROLLBACK;
