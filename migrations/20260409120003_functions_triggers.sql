-- New user: settings + 10 default categories (Design.md §5.2 icons & palette)
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  INSERT INTO public.user_settings (user_id)
  VALUES (NEW.id);

  INSERT INTO public.categories (user_id, name, icon, color, is_default)
  VALUES
    (NEW.id, 'Food', 'restaurant', '#FF6B6B', true),
    (NEW.id, 'Transport', 'directions_car', '#FF8E53', true),
    (NEW.id, 'Shopping', 'shopping_bag', '#FFD93D', true),
    (NEW.id, 'Bills', 'receipt_long', '#6BCB77', true),
    (NEW.id, 'Health', 'local_hospital', '#4ECDC4', true),
    (NEW.id, 'Entertainment', 'movie', '#45B7D1', true),
    (NEW.id, 'Travel', 'flight', '#5C85D6', true),
    (NEW.id, 'Education', 'school', '#A78BFA', true),
    (NEW.id, 'Salary', 'account_balance_wallet', '#F472B6', true),
    (NEW.id, 'Freelance', 'laptop', '#92400E', true);

  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW
  EXECUTE FUNCTION public.handle_new_user();

-- Monthly income / expense totals for dashboard (selected calendar month, UTC boundaries)
CREATE OR REPLACE FUNCTION public.get_monthly_summary(p_month_start date)
RETURNS TABLE (
  income_total numeric,
  expense_total numeric
)
LANGUAGE sql
STABLE
SECURITY INVOKER
SET search_path = public
AS $$
  SELECT
    coalesce(sum(CASE WHEN t.type = 'income' THEN t.amount END), 0)::numeric(12, 2),
    coalesce(sum(CASE WHEN t.type = 'expense' THEN t.amount END), 0)::numeric(12, 2)
  FROM public.transactions t
  WHERE t.user_id = (SELECT auth.uid())
    AND t.date_time >= p_month_start::timestamptz
    AND t.date_time < (p_month_start + interval '1 month')::timestamptz;
$$;

CREATE OR REPLACE FUNCTION public.get_monthly_expense_total(p_month_start date)
RETURNS numeric
LANGUAGE sql
STABLE
SECURITY INVOKER
SET search_path = public
AS $$
  SELECT coalesce(sum(t.amount), 0)::numeric(12, 2)
  FROM public.transactions t
  WHERE t.user_id = (SELECT auth.uid())
    AND t.type = 'expense'
    AND t.date_time >= p_month_start::timestamptz
    AND t.date_time < (p_month_start + interval '1 month')::timestamptz;
$$;

-- Expense by category for date range (pie / top categories)
CREATE OR REPLACE FUNCTION public.get_category_expense_totals(
  p_start timestamptz,
  p_end timestamptz
)
RETURNS TABLE (
  category_id uuid,
  category_name text,
  icon text,
  color text,
  total_amount numeric
)
LANGUAGE sql
STABLE
SECURITY INVOKER
SET search_path = public
AS $$
  SELECT
    c.id,
    c.name,
    c.icon,
    c.color,
    sum(t.amount)::numeric(12, 2) AS total_amount
  FROM public.transactions t
  INNER JOIN public.categories c
    ON c.id = t.category_id
    AND c.user_id = (SELECT auth.uid())
  WHERE t.user_id = (SELECT auth.uid())
    AND t.type = 'expense'
    AND t.date_time >= p_start
    AND t.date_time <= p_end
  GROUP BY c.id, c.name, c.icon, c.color
  ORDER BY total_amount DESC;
$$;

-- Last N calendar months of income + expense (for bar chart)
CREATE OR REPLACE FUNCTION public.get_monthly_totals_last_n(p_n int DEFAULT 6)
RETURNS TABLE (
  month_bucket date,
  expense_total numeric,
  income_total numeric
)
LANGUAGE plpgsql
STABLE
SECURITY INVOKER
SET search_path = public
AS $$
DECLARE
  start_month date;
BEGIN
  IF p_n < 1 OR p_n > 24 THEN
    RAISE EXCEPTION 'p_n must be between 1 and 24';
  END IF;

  start_month := (date_trunc('month', timezone('utc', now()))::date
    - ((p_n - 1) || ' months')::interval)::date;

  RETURN QUERY
  WITH series AS (
    SELECT (start_month + (g * interval '1 month'))::date AS bucket
    FROM generate_series(0, p_n - 1) AS g
  )
  SELECT
    s.bucket,
    coalesce(sum(CASE WHEN t.type = 'expense' THEN t.amount END), 0)::numeric(12, 2),
    coalesce(sum(CASE WHEN t.type = 'income' THEN t.amount END), 0)::numeric(12, 2)
  FROM series s
  LEFT JOIN public.transactions t
    ON t.user_id = (SELECT auth.uid())
    AND date_trunc('month', t.date_time AT TIME ZONE 'utc')::date = s.bucket
  GROUP BY s.bucket
  ORDER BY s.bucket;
END;
$$;

CREATE OR REPLACE FUNCTION public.get_period_income_expense(
  p_start timestamptz,
  p_end timestamptz
)
RETURNS TABLE (
  income_total numeric,
  expense_total numeric
)
LANGUAGE sql
STABLE
SECURITY INVOKER
SET search_path = public
AS $$
  SELECT
    coalesce(sum(CASE WHEN t.type = 'income' THEN t.amount END), 0)::numeric(12, 2),
    coalesce(sum(CASE WHEN t.type = 'expense' THEN t.amount END), 0)::numeric(12, 2)
  FROM public.transactions t
  WHERE t.user_id = (SELECT auth.uid())
    AND t.date_time >= p_start
    AND t.date_time <= p_end;
$$;

GRANT EXECUTE ON FUNCTION public.get_monthly_summary(date) TO authenticated;
GRANT EXECUTE ON FUNCTION public.get_monthly_expense_total(date) TO authenticated;
GRANT EXECUTE ON FUNCTION public.get_category_expense_totals(timestamptz, timestamptz) TO authenticated;
GRANT EXECUTE ON FUNCTION public.get_monthly_totals_last_n(int) TO authenticated;
GRANT EXECUTE ON FUNCTION public.get_period_income_expense(timestamptz, timestamptz) TO authenticated;
