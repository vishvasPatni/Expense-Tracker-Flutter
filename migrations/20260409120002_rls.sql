-- RLS: all user tables; categories scoped to own rows; no delete on defaults

ALTER TABLE public.user_settings ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.categories ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.transactions ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.budgets ENABLE ROW LEVEL SECURITY;

CREATE POLICY user_settings_select_own
  ON public.user_settings FOR SELECT
  USING (user_id = (SELECT auth.uid()));

CREATE POLICY user_settings_insert_own
  ON public.user_settings FOR INSERT
  WITH CHECK (user_id = (SELECT auth.uid()));

CREATE POLICY user_settings_update_own
  ON public.user_settings FOR UPDATE
  USING (user_id = (SELECT auth.uid()))
  WITH CHECK (user_id = (SELECT auth.uid()));

CREATE POLICY categories_select_own
  ON public.categories FOR SELECT
  USING (user_id = (SELECT auth.uid()));

CREATE POLICY categories_insert_own
  ON public.categories FOR INSERT
  WITH CHECK (user_id = (SELECT auth.uid()));

CREATE POLICY categories_update_own
  ON public.categories FOR UPDATE
  USING (user_id = (SELECT auth.uid()))
  WITH CHECK (user_id = (SELECT auth.uid()));

CREATE POLICY categories_delete_custom
  ON public.categories FOR DELETE
  USING (
    user_id = (SELECT auth.uid())
    AND is_default = false
  );

CREATE POLICY transactions_all_own
  ON public.transactions FOR ALL
  USING (user_id = (SELECT auth.uid()))
  WITH CHECK (user_id = (SELECT auth.uid()));

CREATE POLICY budgets_all_own
  ON public.budgets FOR ALL
  USING (user_id = (SELECT auth.uid()))
  WITH CHECK (user_id = (SELECT auth.uid()));
