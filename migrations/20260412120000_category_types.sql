-- Add category_type column to categories table
-- This allows filtering categories based on transaction type (expense, income, transfer)

-- Add category_type column if it doesn't exist
DO $$ 
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns 
    WHERE table_name = 'categories' AND column_name = 'category_type'
  ) THEN
    ALTER TABLE public.categories 
    ADD COLUMN category_type text DEFAULT 'expense' CHECK (category_type IN ('expense', 'income', 'transfer'));
  END IF;
END $$;

-- Update the handle_new_user function to create typed categories
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  INSERT INTO public.user_settings (user_id)
  VALUES (NEW.id);

  -- Transfer category (shown only when Transfer tab is selected)
  INSERT INTO public.categories (user_id, name, icon, color, is_default, category_type)
  VALUES
    (NEW.id, 'Transfers', 'swap_horiz', '#5C85D6', true, 'transfer');
  
  -- Expense categories (shown when Expense tab is selected)
  INSERT INTO public.categories (user_id, name, icon, color, is_default, category_type)
  VALUES
    (NEW.id, 'Food', 'restaurant', '#FF6B6B', true, 'expense'),
    (NEW.id, 'Transport', 'directions_car', '#FF8E53', true, 'expense'),
    (NEW.id, 'Shopping', 'shopping_bag', '#FFD93D', true, 'expense'),
    (NEW.id, 'Bills', 'receipt_long', '#6BCB77', true, 'expense'),
    (NEW.id, 'Health', 'local_hospital', '#4ECDC4', true, 'expense'),
    (NEW.id, 'Entertainment', 'movie', '#45B7D1', true, 'expense');
  
  -- Income categories (shown when Income tab is selected)
  INSERT INTO public.categories (user_id, name, icon, color, is_default, category_type)
  VALUES
    (NEW.id, 'Salary', 'account_balance_wallet', '#F472B6', true, 'income'),
    (NEW.id, 'Freelance', 'laptop', '#92400E', true, 'income'),
    (NEW.id, 'Investment', 'trending_up', '#10B981', true, 'income');

  RETURN NEW;
END;
$$;

-- Update existing categories to have appropriate types
-- Update Transfers category
UPDATE public.categories 
SET category_type = 'transfer' 
WHERE LOWER(name) = 'transfers' OR icon = 'swap_horiz';

-- Update common expense categories
UPDATE public.categories 
SET category_type = 'expense' 
WHERE LOWER(name) IN ('food', 'transport', 'shopping', 'bills', 'health', 'entertainment', 'travel', 'education')
AND category_type IS NULL;

-- Update common income categories
UPDATE public.categories 
SET category_type = 'income' 
WHERE LOWER(name) IN ('salary', 'freelance', 'investment', 'bonus', 'gift')
AND category_type IS NULL;

-- Set default type for any remaining categories
UPDATE public.categories 
SET category_type = 'expense' 
WHERE category_type IS NULL;
