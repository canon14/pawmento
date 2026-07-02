-- Migration: Add dose, form, and logged_today columns to medications
-- Run this against an existing Supabase project that was created before these columns existed.

ALTER TABLE public.medications
    ADD COLUMN IF NOT EXISTS dose TEXT,
    ADD COLUMN IF NOT EXISTS form TEXT,
    ADD COLUMN IF NOT EXISTS logged_today BOOLEAN NOT NULL DEFAULT FALSE;

-- Backfill: existing rows keep NULL dose/form and logged_today = false (defaults above).
