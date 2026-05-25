-- Security hardening: lock function execution to intended roles only.
-- SECURITY DEFINER trigger function should never be callable by PUBLIC.
REVOKE EXECUTE ON FUNCTION public.handle_new_user() FROM PUBLIC;
REVOKE EXECUTE ON FUNCTION public.handle_new_user() FROM anon;
REVOKE EXECUTE ON FUNCTION public.handle_new_user() FROM authenticated;

-- Explicitly restrict RPC function execute permissions.
REVOKE EXECUTE ON FUNCTION public.get_monthly_summary(date) FROM PUBLIC;
REVOKE EXECUTE ON FUNCTION public.get_monthly_expense_total(date) FROM PUBLIC;
REVOKE EXECUTE ON FUNCTION public.get_category_expense_totals(timestamptz, timestamptz) FROM PUBLIC;
REVOKE EXECUTE ON FUNCTION public.get_monthly_totals_last_n(int) FROM PUBLIC;
REVOKE EXECUTE ON FUNCTION public.get_period_income_expense(timestamptz, timestamptz) FROM PUBLIC;

GRANT EXECUTE ON FUNCTION public.get_monthly_summary(date) TO authenticated;
GRANT EXECUTE ON FUNCTION public.get_monthly_expense_total(date) TO authenticated;
GRANT EXECUTE ON FUNCTION public.get_category_expense_totals(timestamptz, timestamptz) TO authenticated;
GRANT EXECUTE ON FUNCTION public.get_monthly_totals_last_n(int) TO authenticated;
GRANT EXECUTE ON FUNCTION public.get_period_income_expense(timestamptz, timestamptz) TO authenticated;
