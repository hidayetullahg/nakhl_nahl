-- ==============================================================================
-- NAKHL & NAHL — Live PostgreSQL RLS Inspection Query
-- Executes against pg_catalog to verify RLS enforcement and policy coverage
-- ==============================================================================

SELECT 
    c.relname AS table_name,
    c.relrowsecurity AS rls_enabled,
    c.relforcerowsecurity AS rls_forced,
    p.polname AS policy_name,
    p.polcmd AS command,
    p.polroles::regrole[] AS roles,
    pg_get_expr(p.polqual, p.polrelid) AS using_expression,
    pg_get_expr(p.polwithcheck, p.polrelid) AS check_expression
FROM pg_class c
JOIN pg_namespace n ON n.oid = c.relnamespace
LEFT JOIN pg_policy p ON p.polrelid = c.oid
WHERE n.nspname = 'public' 
  AND c.relkind = 'r'
ORDER BY c.relname, p.polname;
