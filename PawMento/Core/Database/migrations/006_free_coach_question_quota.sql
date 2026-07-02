-- F11: Centralize free-tier coach question quota for server RPCs.
-- Keep in sync with SubscriptionEntitlement.freeCoachQuestionQuotaPerPeriod in Swift.

CREATE OR REPLACE FUNCTION public.free_coach_question_quota()
RETURNS INTEGER
LANGUAGE sql IMMUTABLE AS $$
  SELECT 5;
$$;

CREATE OR REPLACE FUNCTION public.increment_question_usage()
RETURNS INTEGER
LANGUAGE plpgsql SECURITY DEFINER AS $$
DECLARE
  new_used   INTEGER;
  plan       TEXT;
  sub_status TEXT;
  quota      INTEGER;
BEGIN
  UPDATE public.subscriptions
    SET questions_used = questions_used + 1
    WHERE user_id = auth.uid()
  RETURNING questions_used, plan_type, status
    INTO new_used, plan, sub_status;

  IF public.is_premium_subscription(plan, sub_status) THEN
    RETURN -1;
  END IF;

  quota := public.free_coach_question_quota();
  RETURN GREATEST(0, quota - COALESCE(new_used, 0));
END;
$$;

CREATE OR REPLACE FUNCTION public.decrement_question_usage()
RETURNS INTEGER
LANGUAGE plpgsql SECURITY DEFINER AS $$
DECLARE
  new_used   INTEGER;
  plan       TEXT;
  sub_status TEXT;
  quota      INTEGER;
BEGIN
  UPDATE public.subscriptions
    SET questions_used = GREATEST(0, questions_used - 1)
    WHERE user_id = auth.uid()
  RETURNING questions_used, plan_type, status
    INTO new_used, plan, sub_status;

  IF public.is_premium_subscription(plan, sub_status) THEN
    RETURN -1;
  END IF;

  quota := public.free_coach_question_quota();
  RETURN GREATEST(0, quota - COALESCE(new_used, 0));
END;
$$;

CREATE OR REPLACE FUNCTION public.reset_question_period()
RETURNS INTEGER
LANGUAGE plpgsql SECURITY DEFINER AS $$
DECLARE
  plan       TEXT;
  sub_status TEXT;
BEGIN
  UPDATE public.subscriptions
    SET questions_used = 0, period_start = NOW()
    WHERE user_id = auth.uid()
  RETURNING plan_type, status
    INTO plan, sub_status;

  IF public.is_premium_subscription(plan, sub_status) THEN
    RETURN -1;
  END IF;

  RETURN public.free_coach_question_quota();
END;
$$;
