-- Migration: RPC to activate premium after a verified App Store purchase.
-- TODO(production): Validate p_transaction_id via App Store Server API before trusting.

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
  IF auth.uid() IS NULL THEN
    RAISE EXCEPTION 'Not authenticated';
  END IF;

  IF lower(trim(p_plan_type)) NOT IN ('premium', 'pro') THEN
    RAISE EXCEPTION 'Invalid plan type: %', p_plan_type;
  END IF;

  -- TODO(production): Reject if p_transaction_id is missing or fails App Store verification.

  UPDATE public.subscriptions
    SET plan_type = lower(trim(p_plan_type)),
        status = 'active',
        questions_used = 0,
        period_start = NOW()
    WHERE user_id = auth.uid();

  IF NOT FOUND THEN
    INSERT INTO public.subscriptions (user_id, status, plan_type, questions_used, period_start)
    VALUES (auth.uid(), 'active', lower(trim(p_plan_type)), 0, NOW())
    ON CONFLICT (user_id) DO UPDATE
      SET plan_type = EXCLUDED.plan_type,
          status = EXCLUDED.status,
          questions_used = 0,
          period_start = NOW();
  END IF;
END;
$$;

REVOKE EXECUTE ON FUNCTION public.activate_premium_subscription(TEXT, TEXT) FROM public;
GRANT EXECUTE ON FUNCTION public.activate_premium_subscription(TEXT, TEXT) TO authenticated;
