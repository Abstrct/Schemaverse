-- Verify table-my_query_store

BEGIN;

SELECT 1/count(*) FROM pg_tables WHERE tablename = 'my_query_store' AND rowsecurity;
SELECT 1/count(*) FROM pg_policies WHERE tablename = 'my_query_store' AND policyname = 'own_queries';
SELECT 1/(CASE WHEN has_table_privilege('players', 'my_query_store', 'DELETE') THEN 1 ELSE 0 END);

ROLLBACK;
