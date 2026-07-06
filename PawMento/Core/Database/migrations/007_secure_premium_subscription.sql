-- Migration: Server-trusted premium activation.
-- Clients must verify purchases via the verify-premium Edge Function (Apple JWS).
-- Existing paid subscribers without transaction_id are preserved.

ALTER TABLE public.subscriptions
  ADD COLUMN IF NOT EXISTS transaction_id TEXT;

CREATE UNIQUE INDEX IF NOT EXISTS subscriptions_transaction_id_key
  ON public.subscriptions (transaction_id)
  WHERE transaction_id IS NOT NULL;

-- Internal RPC: only callable with service_role after Edge Function verification.
CREATE OR REPLACE FUNCTION public.activate_premium_subscription_verified(
  p_user_id UUID,
  p_plan_type TEXT,
  p_transaction_id TEXT
)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  existing_user UUID;
BEGIN
  IF p_user_id IS NULL THEN
    RAISE EXCEPTION 'user_id is required';
  END IF;

  IF p_transaction_id IS NULL OR trim(p_transaction_id) = '' THEN
    RAISE EXCEPTION 'transaction_id is required';
  END IF;

  IF lower(trim(p_plan_type)) NOT IN ('premium', 'pro') THEN
    RAISE EXCEPTION 'Invalid plan type: %', p_plan_type;
  END IF;

  SELECT user_id INTO existing_user
  FROM public.subscriptions
  WHERE transaction_id = trim(p_transaction_id)
  LIMIT 1;

  IF existing_user IS NOT NULL AND existing_user <> p_user_id THEN
    RAISE EXCEPTION 'Transaction already associated with another account';
  END IF;

  UPDATE public.subscriptions
    SET plan_type = lower(trim(p_plan_type)),
        status = 'active',
        transaction_id = trim(p_transaction_id),
        questions_used = 0,
        period_start = NOW()
    WHERE user_id = p_user_id;

  IF NOT FOUND THEN
    INSERT INTO public.subscriptions (
      user_id, status, plan_type, transaction_id, questions_used, period_start
    )
    VALUES (
      p_user_id, 'active', lower(trim(p_plan_type)), trim(p_transaction_id), 0, NOW()
    )
    ON CONFLICT (user_id) DO UPDATE
      SET plan_type = EXCLUDED.plan_type,
          status = EXCLUDED.status,
          transaction_id = EXCLUDED.transaction_id,
          questions_used = 0,
          period_start = NOW();
  END IF;
END;
$$;

REVOKE ALL ON FUNCTION public.activate_premium_subscription_verified(UUID, TEXT, TEXT) FROM public;
GRANT EXECUTE ON FUNCTION public.activate_premium_subscription_verified(UUID, TEXT, TEXT) TO service_role;

-- Legacy client-facing RPC: no longer a trust boundary; always reject direct calls.
CREATE OR REPLACE FUNCTION public.activate_premium_subscription(
  p_plan_type TEXT DEFAULT 'pro',
  p_transaction_id TEXT DEFAULT NULL
)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  RAISE EXCEPTION 'Premium activation requires verified App Store purchase via verify-premium';
END;
$$;

REVOKE EXECUTE ON FUNCTION public.activate_premium_subscription(TEXT, TEXT) FROM public;
REVOKE EXECUTE ON FUNCTION public.activate_premium_subscription(TEXT, TEXT) FROM authenticated;
