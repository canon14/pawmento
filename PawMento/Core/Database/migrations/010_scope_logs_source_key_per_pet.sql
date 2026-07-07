-- Migration 010: Scope logs.source_key idempotency per pet (not globally).
-- Reminder keys are reminder+time scoped; different pets may legitimately share the same key.

DROP INDEX IF EXISTS public.idx_logs_source_key_unique;

CREATE UNIQUE INDEX IF NOT EXISTS idx_logs_pet_source_key_unique
    ON public.logs(pet_id, source_key)
    WHERE source_key IS NOT NULL;
