-- Migration 012: Ensure subscription usage rows exist; UPSERT on increment/consume.
-- Prevents unlimited free questions when subscriptions row is missing or deleted.

CREATE OR REPLACE FUNCTION public.ensure_subscription_row_for_user(p_user_id UUID)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  IF p_user_id IS NULL THEN
    RAISE EXCEPTION 'user_id is required';
  END IF;

  INSERT INTO public.subscriptions (user_id, status, plan_type, questions_used, period_start)
  VALUES (p_user_id, 'free', 'free', 0, NOW())
  ON CONFLICT (user_id) DO NOTHING;
END;
$$;

-- Backfill users created before signup seeding or who lost their row.
INSERT INTO public.subscriptions (user_id, status, plan_type, questions_used, period_start)
SELECT u.id, 'free', 'free', 0, NOW()
FROM public.users u
WHERE NOT EXISTS (
  SELECT 1 FROM public.subscriptions s WHERE s.user_id = u.id
);

CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS trigger AS $$
BEGIN
  INSERT INTO public.users (id)
  VALUES (new.id);

  INSERT INTO public.subscriptions (user_id, status, plan_type, questions_used, period_start)
  VALUES (new.id, 'free', 'free', 0, NOW())
  ON CONFLICT (user_id) DO NOTHING;

  RETURN new;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public;

CREATE OR REPLACE FUNCTION public.increment_question_usage()
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
  uid         UUID;
BEGIN
  uid := auth.uid();
  IF uid IS NULL THEN
    RAISE EXCEPTION 'Not authenticated';
  END IF;

  PERFORM public.ensure_coach_question_period_for_user(uid);

  INSERT INTO public.subscriptions (user_id, status, plan_type, questions_used, period_start)
  VALUES (uid, 'free', 'free', 1, NOW())
  ON CONFLICT (user_id) DO UPDATE
    SET questions_used = public.subscriptions.questions_used + 1
  RETURNING questions_used, plan_type, status, current_period_end
    INTO new_used, plan, sub_status, period_end;

  IF public.is_premium_subscription(plan, sub_status, period_end) THEN
    RETURN -1;
  END IF;

  quota := public.free_coach_question_quota();
  RETURN GREATEST(0, quota - COALESCE(new_used, 0));
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

  INSERT INTO public.subscriptions (user_id, status, plan_type, questions_used, period_start)
  VALUES (p_user_id, 'free', 'free', 1, NOW())
  ON CONFLICT (user_id) DO UPDATE
    SET questions_used = public.subscriptions.questions_used + 1
  RETURNING questions_used, plan_type, status, current_period_end
    INTO new_used, plan, sub_status, period_end;

  IF public.is_premium_subscription(plan, sub_status, period_end) THEN
    RETURN -1;
  END IF;

  quota := public.free_coach_question_quota();
  RETURN GREATEST(0, quota - COALESCE(new_used, 0));
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

  PERFORM public.ensure_subscription_row_for_user(p_user_id);
  PERFORM public.ensure_coach_question_period_for_user(p_user_id);

  SELECT questions_used, plan_type, status, current_period_end
    INTO used, plan, sub_status, period_end
  FROM public.subscriptions
  WHERE user_id = p_user_id;

  IF public.is_premium_subscription(plan, sub_status, period_end) THEN
    RETURN -1;
  END IF;

  quota := public.free_coach_question_quota();
  RETURN GREATEST(0, quota - COALESCE(used, 0));
END;
$$;

REVOKE ALL ON FUNCTION public.ensure_subscription_row_for_user(UUID) FROM public;
GRANT EXECUTE ON FUNCTION public.ensure_subscription_row_for_user(UUID) TO service_role;
