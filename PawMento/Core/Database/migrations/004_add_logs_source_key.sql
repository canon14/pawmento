-- Migration: Dedicated idempotency key for logs (e.g. reminder notification taps).
-- Keeps user-facing description clean while preventing duplicate inserts.

ALTER TABLE public.logs ADD COLUMN IF NOT EXISTS source_key TEXT;

CREATE UNIQUE INDEX IF NOT EXISTS idx_logs_source_key_unique
    ON public.logs(source_key)
    WHERE source_key IS NOT NULL;
