-- Migration 011: Enforce logs.created_by = auth.uid() on insert/update.
-- Clients must not be able to attribute logs to another user.

DROP POLICY IF EXISTS "Users can manage logs for their pets" ON public.logs;

CREATE POLICY "Users can select logs for their pets" ON public.logs
    FOR SELECT USING (
        EXISTS (
            SELECT 1 FROM public.pets
            WHERE id = public.logs.pet_id AND owner_id = auth.uid()
        )
    );

CREATE POLICY "Users can insert logs for their pets" ON public.logs
    FOR INSERT WITH CHECK (
        created_by = auth.uid()
        AND EXISTS (
            SELECT 1 FROM public.pets
            WHERE id = public.logs.pet_id AND owner_id = auth.uid()
        )
    );

CREATE POLICY "Users can update logs for their pets" ON public.logs
    FOR UPDATE
    USING (
        EXISTS (
            SELECT 1 FROM public.pets
            WHERE id = public.logs.pet_id AND owner_id = auth.uid()
        )
    )
    WITH CHECK (
        created_by = auth.uid()
        AND EXISTS (
            SELECT 1 FROM public.pets
            WHERE id = public.logs.pet_id AND owner_id = auth.uid()
        )
    );

CREATE POLICY "Users can delete logs for their pets" ON public.logs
    FOR DELETE USING (
        EXISTS (
            SELECT 1 FROM public.pets
            WHERE id = public.logs.pet_id AND owner_id = auth.uid()
        )
    );
