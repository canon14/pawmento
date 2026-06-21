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
    timestamp TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    created_by UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE
);

-- 5. Symptoms Table (dedicated symptom tracking for pattern analysis)
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
    category_id TEXT NOT NULL DEFAULT 'other',
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
    frequency TEXT NOT NULL,
    next_due_date TIMESTAMP WITH TIME ZONE,
    streak_count INTEGER DEFAULT 0,
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
  ON CONFLICT DO NOTHING;

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

-- (Fix S9) Atomically increment question usage and return remaining count.
-- Bypasses SELECT-only RLS via SECURITY DEFINER; prevents lost updates from concurrent sends.
CREATE OR REPLACE FUNCTION public.increment_question_usage()
RETURNS INTEGER
LANGUAGE plpgsql SECURITY DEFINER AS $$
DECLARE
  new_used INTEGER;
BEGIN
  UPDATE public.subscriptions
    SET questions_used = questions_used + 1
    WHERE user_id = auth.uid()
  RETURNING questions_used INTO new_used;
  RETURN GREATEST(0, 5 - COALESCE(new_used, 0));
END;
$$;

REVOKE EXECUTE ON FUNCTION public.increment_question_usage() FROM public;
GRANT EXECUTE ON FUNCTION public.increment_question_usage() TO authenticated;

-- (Fix S9) Atomically decrement question usage (refund) and return remaining count.
CREATE OR REPLACE FUNCTION public.decrement_question_usage()
RETURNS INTEGER
LANGUAGE plpgsql SECURITY DEFINER AS $$
DECLARE
  new_used INTEGER;
BEGIN
  UPDATE public.subscriptions
    SET questions_used = GREATEST(0, questions_used - 1)
    WHERE user_id = auth.uid()
  RETURNING questions_used INTO new_used;
  RETURN GREATEST(0, 5 - COALESCE(new_used, 0));
END;
$$;

REVOKE EXECUTE ON FUNCTION public.decrement_question_usage() FROM public;
GRANT EXECUTE ON FUNCTION public.decrement_question_usage() TO authenticated;

-- Reset question period: zeros out questions_used and sets period_start to now.
-- Used by CoachViewModel when the 30-day period has expired.
CREATE OR REPLACE FUNCTION public.reset_question_period()
RETURNS INTEGER
LANGUAGE plpgsql SECURITY DEFINER AS $$
BEGIN
  UPDATE public.subscriptions
    SET questions_used = 0, period_start = NOW()
    WHERE user_id = auth.uid();
  RETURN 5; -- Full quota
END;
$$;

REVOKE EXECUTE ON FUNCTION public.reset_question_period() FROM public;
GRANT EXECUTE ON FUNCTION public.reset_question_period() TO authenticated;
