-- ==========================================
-- PawMento Database Schema (PostgreSQL)
-- Idempotent — safe to re-run at any time.
-- ==========================================

-- Enable UUID extension
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- 1. Users Table (Public Profile linked to Auth)
CREATE TABLE IF NOT EXISTS public.users (
    id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
    full_name TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 2. Subscriptions Table
CREATE TABLE IF NOT EXISTS public.subscriptions (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
    status TEXT NOT NULL DEFAULT 'free',
    plan_type TEXT NOT NULL DEFAULT 'free',
    current_period_end TIMESTAMP WITH TIME ZONE,
    questions_used INTEGER DEFAULT 0,
    period_start TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Migration: add columns that may be missing if the table was created before these were added.
-- ALTER TABLE ... ADD COLUMN IF NOT EXISTS is idempotent and safe to re-run.
ALTER TABLE public.subscriptions ADD COLUMN IF NOT EXISTS questions_used INTEGER DEFAULT 0;
ALTER TABLE public.subscriptions ADD COLUMN IF NOT EXISTS period_start TIMESTAMP WITH TIME ZONE DEFAULT NOW();
ALTER TABLE public.subscriptions ADD COLUMN IF NOT EXISTS transaction_id TEXT;

CREATE UNIQUE INDEX IF NOT EXISTS subscriptions_transaction_id_key
  ON public.subscriptions (transaction_id)
  WHERE transaction_id IS NOT NULL;

-- Migration: de-duplicate subscriptions keeping the earliest row per user_id,
-- then add a UNIQUE constraint so ON CONFLICT (user_id) has a real target.
DELETE FROM public.subscriptions s
  USING public.subscriptions s2
  WHERE s.user_id = s2.user_id
    AND s.created_at > s2.created_at;

DO $$ BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_constraint
    WHERE conname = 'subscriptions_user_id_key'
      AND conrelid = 'public.subscriptions'::regclass
  ) THEN
    ALTER TABLE public.subscriptions
      ADD CONSTRAINT subscriptions_user_id_key UNIQUE (user_id);
  END IF;
END $$;

-- 3. Pets Table
CREATE TABLE IF NOT EXISTS public.pets (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    owner_id UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
    name TEXT NOT NULL,
    species TEXT NOT NULL,
    breed TEXT,
    birthday DATE,
    weight_kg NUMERIC,
    photo_url TEXT,
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 4. Logs Table (Activities, Food, Medication)
CREATE TABLE IF NOT EXISTS public.logs (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    pet_id UUID NOT NULL REFERENCES public.pets(id) ON DELETE CASCADE,
    log_type TEXT NOT NULL,
    title TEXT NOT NULL,
    description TEXT,
    photo_url TEXT,
    severity INTEGER CHECK (severity >= 1 AND severity <= 5),
    source_key TEXT,
    timestamp TIMESTAMP WITH TIME ZONE DEFAULT NOW(),   -- user-facing event time (recordedAt)
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),  -- row-insertion time (server)
    created_by UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE
);

-- DB-L3: Idempotent migration — add created_at to logs if it doesn't exist yet.
-- Existing rows get NOW() as default; new rows auto-populate both columns.
ALTER TABLE public.logs ADD COLUMN IF NOT EXISTS created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW();

-- R1: Idempotency key for programmatic log sources (reminder notification taps, etc.)
-- Uniqueness is per pet — see migration 010 / idx_logs_pet_source_key_unique.
ALTER TABLE public.logs ADD COLUMN IF NOT EXISTS source_key TEXT;
DROP INDEX IF EXISTS idx_logs_source_key_unique;
CREATE UNIQUE INDEX IF NOT EXISTS idx_logs_pet_source_key_unique
    ON public.logs(pet_id, source_key)
    WHERE source_key IS NOT NULL;

-- 5. Symptoms Table — ⚠️  RESERVED / CURRENTLY UNUSED
-- Symptoms are stored in the `logs` table with log_type = 'Symptom' (see LogCategory.symptom).
-- The InsightEngine reads from `logs`, NOT from this table.
-- Kept for potential future migration to a dedicated symptom model.
-- Do NOT write to this table — it has no write path and the engine will not see the data.
CREATE TABLE IF NOT EXISTS public.symptoms (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    pet_id UUID NOT NULL REFERENCES public.pets(id) ON DELETE CASCADE,
    symptom_type TEXT NOT NULL,
    severity INTEGER CHECK (severity BETWEEN 1 AND 5),
    notes TEXT,
    timestamp TIMESTAMPTZ DEFAULT NOW(),
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- 6. Reminders Table
-- NOTE (Fix 4): pet_id is NOT NULL — all reminders are pet-scoped.
CREATE TABLE IF NOT EXISTS public.reminders (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    pet_id UUID NOT NULL REFERENCES public.pets(id) ON DELETE CASCADE,
    title TEXT NOT NULL,
    reminder_time TIMESTAMPTZ NOT NULL,
    frequency TEXT NOT NULL DEFAULT 'Once',
    category_id TEXT NOT NULL DEFAULT 'Other',
    is_enabled BOOLEAN NOT NULL DEFAULT TRUE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 7. Chat Messages Table (AI Coach History)
CREATE TABLE IF NOT EXISTS public.chat_messages (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    owner_id UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
    pet_id UUID REFERENCES public.pets(id) ON DELETE CASCADE,
    role TEXT NOT NULL CHECK (role IN ('user', 'assistant', 'system')),
    content TEXT NOT NULL,
    is_emergency BOOLEAN NOT NULL DEFAULT FALSE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 8. Medications Table
CREATE TABLE IF NOT EXISTS public.medications (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    pet_id UUID NOT NULL REFERENCES public.pets(id) ON DELETE CASCADE,
    name TEXT NOT NULL,
    dose TEXT,
    form TEXT,
    frequency TEXT NOT NULL,
    next_due_date TIMESTAMP WITH TIME ZONE,
    streak_count INTEGER DEFAULT 0,
    logged_today BOOLEAN NOT NULL DEFAULT FALSE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- ==========================================
-- ROW LEVEL SECURITY (RLS) POLICIES
-- ==========================================

-- Enable RLS on all tables
ALTER TABLE public.users ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.subscriptions ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.pets ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.logs ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.symptoms ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.reminders ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.chat_messages ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.medications ENABLE ROW LEVEL SECURITY;

-- Users can only view and edit their own profile
DO $$ BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE policyname = 'Users can view own profile' AND tablename = 'users') THEN
        CREATE POLICY "Users can view own profile" ON public.users FOR SELECT USING (auth.uid() = id);
    END IF;
    IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE policyname = 'Users can update own profile' AND tablename = 'users') THEN
        CREATE POLICY "Users can update own profile" ON public.users FOR UPDATE USING (auth.uid() = id);
    END IF;
END $$;

-- Users can only view their own subscriptions (writes happen server-side via service role)
DO $$ BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE policyname = 'Users can view own subscriptions' AND tablename = 'subscriptions') THEN
        CREATE POLICY "Users can view own subscriptions" ON public.subscriptions FOR SELECT USING (auth.uid() = user_id);
    END IF;
END $$;

-- Pets policies: users can only CRUD their own pets
DO $$ BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE policyname = 'Users can view own pets' AND tablename = 'pets') THEN
        CREATE POLICY "Users can view own pets" ON public.pets FOR SELECT USING (auth.uid() = owner_id);
    END IF;
    IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE policyname = 'Users can insert own pets' AND tablename = 'pets') THEN
        CREATE POLICY "Users can insert own pets" ON public.pets FOR INSERT WITH CHECK (auth.uid() = owner_id);
    END IF;
    IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE policyname = 'Users can update own pets' AND tablename = 'pets') THEN
        CREATE POLICY "Users can update own pets" ON public.pets FOR UPDATE USING (auth.uid() = owner_id);
    END IF;
    IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE policyname = 'Users can delete own pets' AND tablename = 'pets') THEN
        CREATE POLICY "Users can delete own pets" ON public.pets FOR DELETE USING (auth.uid() = owner_id);
    END IF;
END $$;

-- Logs policies: verify the log belongs to a pet owned by the auth user
DO $$ BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE policyname = 'Users can manage logs for their pets' AND tablename = 'logs') THEN
        CREATE POLICY "Users can manage logs for their pets" ON public.logs
            FOR ALL USING (
                EXISTS (SELECT 1 FROM public.pets WHERE id = public.logs.pet_id AND owner_id = auth.uid())
            );
    END IF;
END $$;

-- Symptoms policies: mirrors logs policy (Fix 1)
-- ⚠️  This table is UNUSED — see note on the symptoms CREATE TABLE above.
DO $$ BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE policyname = 'Users can manage symptoms for their pets' AND tablename = 'symptoms') THEN
        CREATE POLICY "Users can manage symptoms for their pets" ON public.symptoms
            FOR ALL USING (
                EXISTS (SELECT 1 FROM public.pets WHERE id = public.symptoms.pet_id AND owner_id = auth.uid())
            );
    END IF;
END $$;

-- Reminders policies: verify the reminder belongs to a pet owned by the auth user
DO $$ BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE policyname = 'Users can manage reminders for their pets' AND tablename = 'reminders') THEN
        CREATE POLICY "Users can manage reminders for their pets" ON public.reminders
            FOR ALL USING (
                EXISTS (SELECT 1 FROM public.pets WHERE id = public.reminders.pet_id AND owner_id = auth.uid())
            );
    END IF;
END $$;

-- Chat messages policies
DO $$ BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE policyname = 'Users can manage chat messages for their pets' AND tablename = 'chat_messages') THEN
        CREATE POLICY "Users can manage chat messages for their pets" ON public.chat_messages
            FOR ALL USING (
                owner_id = auth.uid() AND (pet_id IS NULL OR EXISTS (SELECT 1 FROM public.pets WHERE id = public.chat_messages.pet_id AND owner_id = auth.uid()))
            );
    END IF;
END $$;

-- Medications policies
DO $$ BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE policyname = 'Users can manage medications for their pets' AND tablename = 'medications') THEN
        CREATE POLICY "Users can manage medications for their pets" ON public.medications
            FOR ALL USING (
                EXISTS (SELECT 1 FROM public.pets WHERE id = public.medications.pet_id AND owner_id = auth.uid())
            );
    END IF;
END $$;

-- ==========================================
-- AUTOMATIC TRIGGER: Create public user on Auth Sign Up
-- (Fix 5) Also inserts a default 'free' subscriptions row.
-- ==========================================
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS trigger AS $$
BEGIN
  INSERT INTO public.users (id)
  VALUES (new.id);

  -- Fix 5: seed a default free subscription so reads never fail
  INSERT INTO public.subscriptions (user_id, status, plan_type, questions_used, period_start)
  VALUES (new.id, 'free', 'free', 0, NOW())
  ON CONFLICT (user_id) DO NOTHING;

  RETURN new;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Recreate trigger idempotently
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE PROCEDURE public.handle_new_user();

-- ==========================================
-- INDEXES (Fix 6)
-- ==========================================
CREATE INDEX IF NOT EXISTS idx_logs_pet_timestamp ON public.logs(pet_id, timestamp);
CREATE INDEX IF NOT EXISTS idx_reminders_pet ON public.reminders(pet_id);
CREATE INDEX IF NOT EXISTS idx_medications_pet ON public.medications(pet_id);
CREATE INDEX IF NOT EXISTS idx_chat_messages_owner_pet_created ON public.chat_messages(owner_id, pet_id, created_at);
CREATE INDEX IF NOT EXISTS idx_subscriptions_user ON public.subscriptions(user_id);
CREATE INDEX IF NOT EXISTS idx_pets_owner ON public.pets(owner_id);
-- ⚠️  symptoms table is UNUSED — see note on the symptoms CREATE TABLE above.
CREATE INDEX IF NOT EXISTS idx_symptoms_pet_timestamp ON public.symptoms(pet_id, timestamp);

-- ==========================================
-- TRIGGER: Auto-update updated_at (Fix 9)
-- ==========================================
CREATE OR REPLACE FUNCTION public.set_updated_at()
RETURNS trigger AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Apply to users table (the only table with an updated_at column)
DROP TRIGGER IF EXISTS trigger_users_updated_at ON public.users;
CREATE TRIGGER trigger_users_updated_at
  BEFORE UPDATE ON public.users
  FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();

-- ==========================================
-- RPC Functions
-- ==========================================

-- Securely delete the caller's auth.users account (cascades to public tables)
CREATE OR REPLACE FUNCTION public.delete_user()
RETURNS void AS $$
BEGIN
    DELETE FROM auth.users WHERE id = auth.uid();
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Lock down execution to authenticated users only
REVOKE EXECUTE ON FUNCTION public.delete_user() FROM public;
GRANT EXECUTE ON FUNCTION public.delete_user() TO authenticated;

-- ==========================================
-- Subscription entitlements
-- Keep paid plan list in sync with PawMento/Core/Subscriptions/SubscriptionEntitlement.swift
-- Keep free_coach_question_quota() in sync with SubscriptionEntitlement.freeCoachQuestionQuotaPerPeriod
-- ==========================================
CREATE OR REPLACE FUNCTION public.free_coach_question_quota()
RETURNS INTEGER
LANGUAGE sql IMMUTABLE AS $$
  SELECT 5;
$$;

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

-- (Fix S9 + DB-M2) Atomically increment question usage and return remaining count.
-- Derives quota from plan_type/status: paid plans return -1 (unlimited).
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

  -- Paid / active plans are unlimited
  IF public.is_premium_subscription(plan, sub_status, period_end) THEN
    RETURN -1;
  END IF;

  quota := public.free_coach_question_quota();
  RETURN GREATEST(0, quota - COALESCE(new_used, 0));
END;
$$;

REVOKE EXECUTE ON FUNCTION public.increment_question_usage() FROM public;
REVOKE EXECUTE ON FUNCTION public.increment_question_usage() FROM authenticated;

-- (Fix S9 + DB-M2) Atomically decrement question usage (refund) and return remaining count.
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

REVOKE EXECUTE ON FUNCTION public.decrement_question_usage() FROM public;
REVOKE EXECUTE ON FUNCTION public.decrement_question_usage() FROM authenticated;

-- (DB-M2) Reset question period: zeros out questions_used and sets period_start to now.
-- Returns the full quota for the user's plan (-1 for paid = unlimited).
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

REVOKE EXECUTE ON FUNCTION public.reset_question_period() FROM public;
GRANT EXECUTE ON FUNCTION public.reset_question_period() TO authenticated;

-- Server-side coach quota RPCs (ai-proxy; service_role only).
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

REVOKE ALL ON FUNCTION public.ensure_coach_question_period_for_user(UUID) FROM public;
REVOKE ALL ON FUNCTION public.coach_question_quota_remaining(UUID) FROM public;
REVOKE ALL ON FUNCTION public.consume_coach_question_usage(UUID) FROM public;

GRANT EXECUTE ON FUNCTION public.ensure_coach_question_period_for_user(UUID) TO service_role;
GRANT EXECUTE ON FUNCTION public.coach_question_quota_remaining(UUID) TO service_role;
GRANT EXECUTE ON FUNCTION public.consume_coach_question_usage(UUID) TO service_role;

-- Internal RPC: only callable with service_role after verify-premium Edge Function validation.
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

-- Legacy client-facing RPC: direct calls are rejected; use verify-premium Edge Function.
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

