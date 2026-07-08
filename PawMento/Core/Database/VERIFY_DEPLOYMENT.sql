-- Run in Supabase SQL editor to verify deployment after schema.sql.
-- All checks should return at least one row where noted.

-- 1. Signup trigger exists
SELECT tgname, tgenabled
FROM pg_trigger
WHERE tgname = 'on_auth_user_created';

-- 2. handle_new_user function exists
SELECT proname
FROM pg_proc
WHERE proname = 'handle_new_user';

-- 3. Bootstrap RPC exists
SELECT proname
FROM pg_proc p
JOIN pg_namespace n ON p.pronamespace = n.oid
WHERE n.nspname = 'public'
  AND p.proname IN ('ensure_user_bootstrap', 'ensure_subscription_row_for_user');

-- 4. subscriptions unique constraint (required for ON CONFLICT)
SELECT conname
FROM pg_constraint
WHERE conrelid = 'public.subscriptions'::regclass AND contype = 'u';

-- 5. Storage bucket
SELECT id, name, public FROM storage.buckets WHERE id = 'pawmento-media';

-- 6. Storage policies on pawmento-media
SELECT policyname, cmd
FROM pg_policies
WHERE schemaname = 'storage' AND tablename = 'objects'
  AND policyname LIKE '%pawmento%';

-- 7. Users without public profile (should be 0 rows)
SELECT au.id, au.email
FROM auth.users au
LEFT JOIN public.users u ON u.id = au.id
WHERE u.id IS NULL;

-- 8. Users without subscription row (should be 0 rows)
SELECT u.id
FROM public.users u
LEFT JOIN public.subscriptions s ON s.user_id = u.id
WHERE s.user_id IS NULL;
