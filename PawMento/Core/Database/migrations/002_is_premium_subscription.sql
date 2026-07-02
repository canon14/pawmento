-- Migration: Centralize premium entitlement check used by coach quota RPCs.
-- Keep paid plan list in sync with PawMento/Core/Subscriptions/SubscriptionEntitlement.swift

CREATE OR REPLACE FUNCTION public.is_premium_subscription(plan TEXT, sub_status TEXT)
RETURNS BOOLEAN
LANGUAGE sql IMMUTABLE AS $$
  SELECT lower(trim(sub_status)) = 'active'
      OR lower(trim(plan)) IN ('premium', 'pro');
$$;
