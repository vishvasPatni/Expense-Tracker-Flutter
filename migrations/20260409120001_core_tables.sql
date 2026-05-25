-- Core tables per PRD §5.2–5.5

CREATE TABLE public.user_settings (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid NOT NULL REFERENCES auth.users (id) ON DELETE CASCADE UNIQUE,
  currency_code text NOT NULL DEFAULT 'USD',
  currency_symbol text NOT NULL DEFAULT '$',
  language text NOT NULL DEFAULT 'en',
  theme_mode text NOT NULL DEFAULT 'system'
    CHECK (theme_mode IN ('light', 'dark', 'system')),
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE public.categories (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid NOT NULL REFERENCES auth.users (id) ON DELETE CASCADE,
  name text NOT NULL,
  icon text NOT NULL DEFAULT 'more_horiz',
  color text NOT NULL DEFAULT '#6366F1',
  parent_category_id uuid REFERENCES public.categories (id) ON DELETE SET NULL,
  is_default boolean NOT NULL DEFAULT false,
  created_at timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE public.transactions (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid NOT NULL REFERENCES auth.users (id) ON DELETE CASCADE,
  type text NOT NULL CHECK (type IN ('income', 'expense')),
  amount numeric(12, 2) NOT NULL CHECK (amount > 0),
  category_id uuid NOT NULL REFERENCES public.categories (id) ON DELETE RESTRICT,
  subcategory_id uuid REFERENCES public.categories (id) ON DELETE SET NULL,
  notes text CHECK (notes IS NULL OR char_length(notes) <= 200),
  date_time timestamptz NOT NULL DEFAULT now(),
  tags text[] NOT NULL DEFAULT '{}',
  account_type text DEFAULT 'cash'
    CHECK (account_type IN ('cash', 'bank', 'wallet')),
  image_url text,
  latitude float8,
  longitude float8,
  is_recurring boolean NOT NULL DEFAULT false,
  recurrence_interval text CHECK (
    recurrence_interval IS NULL
    OR recurrence_interval IN ('daily', 'weekly', 'monthly', 'yearly')
  ),
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE public.budgets (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid NOT NULL REFERENCES auth.users (id) ON DELETE CASCADE,
  month date NOT NULL,
  amount numeric(12, 2) NOT NULL CHECK (amount >= 0),
  category_id uuid REFERENCES public.categories (id) ON DELETE CASCADE,
  created_at timestamptz NOT NULL DEFAULT now()
);

CREATE UNIQUE INDEX budgets_user_month_overall
  ON public.budgets (user_id, month)
  WHERE category_id IS NULL;

CREATE INDEX idx_transactions_user_date
  ON public.transactions (user_id, date_time DESC);

CREATE INDEX idx_transactions_user_category
  ON public.transactions (user_id, category_id);

CREATE INDEX idx_categories_user
  ON public.categories (user_id);

CREATE OR REPLACE FUNCTION public.set_updated_at()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
BEGIN
  NEW.updated_at = now();
  RETURN NEW;
END;
$$;

CREATE TRIGGER transactions_updated_at
  BEFORE UPDATE ON public.transactions
  FOR EACH ROW
  EXECUTE FUNCTION public.set_updated_at();

CREATE TRIGGER user_settings_updated_at
  BEFORE UPDATE ON public.user_settings
  FOR EACH ROW
  EXECUTE FUNCTION public.set_updated_at();
