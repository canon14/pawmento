-- Server-side coach quota RPCs for ai-proxy (service_role only).
-- Moves question accounting off the client.

CREATE OR REPLACE FUNCTION public.ensure_coach_question_period_for_user(p_user_id UUID)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  IF p_user_id IS NULL THEN
    RAISE EXCEPTION 'user_id is required';
  END IF;

  UPDATE public.subscriptions
    SET questions_used = 0,
        period_start = NOW()
    WHERE user_id = p_user_id
      AND NOT public.is_premium_subscription(plan_type, status)
      AND period_start < NOW() - INTERVAL '30 days';
END;
$$;

CREATE OR REPLACE FUNCTION public.coach_question_quota_remaining(p_user_id UUID)
RETURNS INTEGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  used       INTEGER;
  plan       TEXT;
  sub_status TEXT;
  quota      INTEGER;
BEGIN
  IF p_user_id IS NULL THEN
    RAISE EXCEPTION 'user_id is required';
  END IF;

  PERFORM public.ensure_coach_question_period_for_user(p_user_id);

  SELECT questions_used, plan_type, status
    INTO used, plan, sub_status
  FROM public.subscriptions
  WHERE user_id = p_user_id;

  IF NOT FOUND THEN
    quota := public.free_coach_question_quota();
    RETURN quota;
  END IF;

  IF public.is_premium_subscription(plan, sub_status) THEN
    RETURN -1;
  END IF;

  quota := public.free_coach_question_quota();
  RETURN GREATEST(0, quota - COALESCE(used, 0));
END;
$$;

CREATE OR REPLACE FUNCTION public.consume_coach_question_usage(p_user_id UUID)
RETURNS INTEGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  new_used   INTEGER;
  plan       TEXT;
  sub_status TEXT;
  quota      INTEGER;
BEGIN
  IF p_user_id IS NULL THEN
    RAISE EXCEPTION 'user_id is required';
  END IF;

  PERFORM public.ensure_coach_question_period_for_user(p_user_id);

  UPDATE public.subscriptions
    SET questions_used = questions_used + 1
    WHERE user_id = p_user_id
  RETURNING questions_used, plan_type, status
    INTO new_used, plan, sub_status;

  IF NOT FOUND THEN
    INSERT INTO public.subscriptions (user_id, status, plan_type, questions_used, period_start)
    VALUES (p_user_id, 'free', 'free', 1, NOW())
    RETURNING questions_used, plan_type, status
      INTO new_used, plan, sub_status;
  END IF;

  IF public.is_premium_subscription(plan, sub_status) THEN
    RETURN -1;
  END IF;

  quota := public.free_coach_question_quota();
  RETURN GREATEST(0, quota - COALESCE(new_used, 0));
END;
$$;

REVOKE ALL ON FUNCTION public.ensure_coach_question_period_for_user(UUID) FROM public;
REVOKE ALL ON FUNCTION public.coach_question_quota_remaining(UUID) FROM public;
REVOKE ALL ON FUNCTION public.consume_coach_question_usage(UUID) FROM public;

GRANT EXECUTE ON FUNCTION public.ensure_coach_question_period_for_user(UUID) TO service_role;
GRANT EXECUTE ON FUNCTION public.coach_question_quota_remaining(UUID) TO service_role;
GRANT EXECUTE ON FUNCTION public.consume_coach_question_usage(UUID) TO service_role;

-- Client can no longer self-serve increment/decrement (bypass prevention).
REVOKE EXECUTE ON FUNCTION public.increment_question_usage() FROM authenticated;
REVOKE EXECUTE ON FUNCTION public.decrement_question_usage() FROM authenticated;
