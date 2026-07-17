-- Add missing logs columns for older Supabase deployments.
-- Safe to re-run (idempotent).
ALTER TABLE public.logs ADD COLUMN IF NOT EXISTS photo_url TEXT;
ALTER TABLE public.logs ADD COLUMN IF NOT EXISTS severity INTEGER;
