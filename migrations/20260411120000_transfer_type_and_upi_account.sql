-- Transfers as a third transaction type; UPI as account_type (Flutter picker already sends 'upi').
-- Income/expense RPCs unchanged: they only aggregate type = income / expense.

ALTER TABLE public.transactions
  DROP CONSTRAINT IF EXISTS transactions_type_check;

ALTER TABLE public.transactions
  ADD CONSTRAINT transactions_type_check
  CHECK (type IN ('income', 'expense', 'transfer'));

ALTER TABLE public.transactions
  DROP CONSTRAINT IF EXISTS transactions_account_type_check;

ALTER TABLE public.transactions
  ADD CONSTRAINT transactions_account_type_check
  CHECK (account_type IN ('cash', 'bank', 'wallet', 'upi'));

-- New signups: include Transfers category (handle_new_user).
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
    (NEW.id, 'Freelance', 'laptop', '#92400E', true),
    (NEW.id, 'Transfers', 'swap_horiz', '#64748B', true);

  RETURN NEW;
END;
$$;

-- Existing users: add Transfers row if missing (safe to re-run).
INSERT INTO public.categories (user_id, name, icon, color, is_default)
SELECT u.id, 'Transfers', 'swap_horiz', '#64748B', false
FROM auth.users u
WHERE NOT EXISTS (
  SELECT 1
  FROM public.categories c
  WHERE c.user_id = u.id
    AND lower(trim(c.name)) = 'transfers'
);
