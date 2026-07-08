-- Migration 013: Storage RLS for pawmento-media, user bootstrap RPC, and auth.users backfill.
-- Fixes new-user onboarding: pet photo uploads (storage 403) and missing users/subscriptions rows (PGRST116).

-- ---------------------------------------------------------------------------
-- 1. Bootstrap RPC — idempotently ensure public.users + subscriptions rows
-- ---------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION public.ensure_user_bootstrap()
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  uid UUID;
BEGIN
  uid := auth.uid();
  IF uid IS NULL THEN
    RAISE EXCEPTION 'Not authenticated';
  END IF;

  INSERT INTO public.users (id)
  VALUES (uid)
  ON CONFLICT (id) DO NOTHING;

  PERFORM public.ensure_subscription_row_for_user(uid);
END;
$$;

REVOKE ALL ON FUNCTION public.ensure_user_bootstrap() FROM public;
GRANT EXECUTE ON FUNCTION public.ensure_user_bootstrap() TO authenticated;

-- Backfill public.users for any auth.users missing a profile row.
INSERT INTO public.users (id)
SELECT au.id
FROM auth.users au
WHERE NOT EXISTS (
  SELECT 1 FROM public.users u WHERE u.id = au.id
);

-- Backfill free subscriptions for users missing a row.
INSERT INTO public.subscriptions (user_id, status, plan_type, questions_used, period_start)
SELECT u.id, 'free', 'free', 0, NOW()
FROM public.users u
WHERE NOT EXISTS (
  SELECT 1 FROM public.subscriptions s WHERE s.user_id = u.id
);

-- ---------------------------------------------------------------------------
-- 2. Storage bucket + RLS (path: {userId}/pets/{petId}.jpg, {userId}/logs/...)
-- ---------------------------------------------------------------------------

INSERT INTO storage.buckets (id, name, public)
VALUES ('pawmento-media', 'pawmento-media', true)
ON CONFLICT (id) DO UPDATE SET public = EXCLUDED.public;

DROP POLICY IF EXISTS "Public read pawmento media" ON storage.objects;
CREATE POLICY "Public read pawmento media"
ON storage.objects FOR SELECT
TO public
USING (bucket_id = 'pawmento-media');

DROP POLICY IF EXISTS "Users upload own pawmento media" ON storage.objects;
CREATE POLICY "Users upload own pawmento media"
ON storage.objects FOR INSERT
TO authenticated
WITH CHECK (
  bucket_id = 'pawmento-media'
  AND (storage.foldername(name))[1] = auth.uid()::text
);

DROP POLICY IF EXISTS "Users update own pawmento media" ON storage.objects;
CREATE POLICY "Users update own pawmento media"
ON storage.objects FOR UPDATE
TO authenticated
USING (
  bucket_id = 'pawmento-media'
  AND (storage.foldername(name))[1] = auth.uid()::text
)
WITH CHECK (
  bucket_id = 'pawmento-media'
  AND (storage.foldername(name))[1] = auth.uid()::text
);

DROP POLICY IF EXISTS "Users delete own pawmento media" ON storage.objects;
CREATE POLICY "Users delete own pawmento media"
ON storage.objects FOR DELETE
TO authenticated
USING (
  bucket_id = 'pawmento-media'
  AND (storage.foldername(name))[1] = auth.uid()::text
);
