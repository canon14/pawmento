-- Fix premium predicate: require active status AND paid plan (conjunctive).
-- Optional period_end: when set, must be in the future.

CREATE OR REPLACE FUNCTION public.is_premium_subscription(
  plan TEXT,
  sub_status TEXT,
  period_end TIMESTAMP WITH TIME ZONE DEFAULT NULL
)
RETURNS BOOLEAN
LANGUAGE sql
STABLE
SET search_path = public
AS $$
  SELECT lower(trim(sub_status)) = 'active'
    AND lower(trim(plan)) IN ('premium', 'pro')
    AND (period_end IS NULL OR period_end > NOW());
$$;

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
      AND NOT public.is_premium_subscription(plan_type, status, current_period_end)
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
  used        INTEGER;
  plan        TEXT;
  sub_status  TEXT;
  period_end  TIMESTAMPTZ;
  quota       INTEGER;
BEGIN
  IF p_user_id IS NULL THEN
    RAISE EXCEPTION 'user_id is required';
  END IF;

  PERFORM public.ensure_coach_question_period_for_user(p_user_id);

  SELECT questions_used, plan_type, status, current_period_end
    INTO used, plan, sub_status, period_end
  FROM public.subscriptions
  WHERE user_id = p_user_id;

  IF NOT FOUND THEN
    quota := public.free_coach_question_quota();
    RETURN quota;
  END IF;

  IF public.is_premium_subscription(plan, sub_status, period_end) THEN
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
  new_used    INTEGER;
  plan        TEXT;
  sub_status  TEXT;
  period_end  TIMESTAMPTZ;
  quota       INTEGER;
BEGIN
  IF p_user_id IS NULL THEN
    RAISE EXCEPTION 'user_id is required';
  END IF;

  PERFORM public.ensure_coach_question_period_for_user(p_user_id);

  UPDATE public.subscriptions
    SET questions_used = questions_used + 1
    WHERE user_id = p_user_id
  RETURNING questions_used, plan_type, status, current_period_end
    INTO new_used, plan, sub_status, period_end;

  IF NOT FOUND THEN
    INSERT INTO public.subscriptions (user_id, status, plan_type, questions_used, period_start)
    VALUES (p_user_id, 'free', 'free', 1, NOW())
    RETURNING questions_used, plan_type, status, current_period_end
      INTO new_used, plan, sub_status, period_end;
  END IF;

  IF public.is_premium_subscription(plan, sub_status, period_end) THEN
    RETURN -1;
  END IF;

  quota := public.free_coach_question_quota();
  RETURN GREATEST(0, quota - COALESCE(new_used, 0));
END;
$$;

CREATE OR REPLACE FUNCTION public.increment_question_usage()
RETURNS INTEGER
LANGUAGE plpgsql SECURITY DEFINER AS $$
DECLARE
  new_used    INTEGER;
  plan        TEXT;
  sub_status  TEXT;
  period_end  TIMESTAMPTZ;
  quota       INTEGER;
BEGIN
  UPDATE public.subscriptions
    SET questions_used = questions_used + 1
    WHERE user_id = auth.uid()
  RETURNING questions_used, plan_type, status, current_period_end
    INTO new_used, plan, sub_status, period_end;

  IF public.is_premium_subscription(plan, sub_status, period_end) THEN
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
  new_used    INTEGER;
  plan        TEXT;
  sub_status  TEXT;
  period_end  TIMESTAMPTZ;
  quota       INTEGER;
BEGIN
  UPDATE public.subscriptions
    SET questions_used = GREATEST(0, questions_used - 1)
    WHERE user_id = auth.uid()
  RETURNING questions_used, plan_type, status, current_period_end
    INTO new_used, plan, sub_status, period_end;

  IF public.is_premium_subscription(plan, sub_status, period_end) THEN
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
  plan        TEXT;
  sub_status  TEXT;
  period_end  TIMESTAMPTZ;
BEGIN
  UPDATE public.subscriptions
    SET questions_used = 0, period_start = NOW()
    WHERE user_id = auth.uid()
  RETURNING plan_type, status, current_period_end
    INTO plan, sub_status, period_end;

  IF public.is_premium_subscription(plan, sub_status, period_end) THEN
    RETURN -1;
  END IF;

  RETURN public.free_coach_question_quota();
END;
$$;
