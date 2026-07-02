-- F9: Align reminder category_id default with LogCategory.other rawValue ("Other").
-- Legacy rows may have lowercase slug "other" from the old schema default.

UPDATE public.reminders
SET category_id = 'Other'
WHERE lower(category_id) = 'other';

ALTER TABLE public.reminders
    ALTER COLUMN category_id SET DEFAULT 'Other';
