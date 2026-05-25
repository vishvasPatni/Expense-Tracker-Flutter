-- Unequal expense splitting (Phase 1): groups, members, split expenses, lines, payments, RLS, and balance RPC.
-- Owner-based model: the signed-in user owns the group ledger; members can be local contacts or linked auth users.

-- 1) Core tables
CREATE TABLE IF NOT EXISTS public.split_groups (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  owner_user_id uuid NOT NULL REFERENCES auth.users (id) ON DELETE CASCADE,
  name text NOT NULL CHECK (char_length(name) <= 80),
  currency_code text NOT NULL DEFAULT 'USD',
  created_at timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_split_groups_owner
  ON public.split_groups (owner_user_id, created_at DESC);

-- Required for composite FKs that reference (id, owner_user_id).
CREATE UNIQUE INDEX IF NOT EXISTS split_groups_id_owner_unique
  ON public.split_groups (id, owner_user_id);

CREATE TABLE IF NOT EXISTS public.split_members (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  group_id uuid NOT NULL REFERENCES public.split_groups (id) ON DELETE CASCADE,
  owner_user_id uuid NOT NULL REFERENCES auth.users (id) ON DELETE CASCADE,
  display_name text NOT NULL CHECK (char_length(display_name) <= 80),
  contact_ref text,
  linked_user_id uuid REFERENCES auth.users (id) ON DELETE SET NULL,
  is_active boolean NOT NULL DEFAULT true,
  created_at timestamptz NOT NULL DEFAULT now(),
  CONSTRAINT split_members_group_owner_fk
    FOREIGN KEY (group_id, owner_user_id)
    REFERENCES public.split_groups (id, owner_user_id)
    ON DELETE CASCADE
);

CREATE UNIQUE INDEX IF NOT EXISTS split_members_unique_name_per_group
  ON public.split_members (group_id, lower(trim(display_name)))
  WHERE is_active = true;

CREATE INDEX IF NOT EXISTS idx_split_members_owner_group
  ON public.split_members (owner_user_id, group_id, created_at DESC);

CREATE TABLE IF NOT EXISTS public.split_expenses (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  group_id uuid NOT NULL REFERENCES public.split_groups (id) ON DELETE CASCADE,
  owner_user_id uuid NOT NULL REFERENCES auth.users (id) ON DELETE CASCADE,
  transaction_id uuid REFERENCES public.transactions (id) ON DELETE SET NULL,
  paid_by_member_id uuid NOT NULL REFERENCES public.split_members (id) ON DELETE RESTRICT,
  total_amount numeric(12, 2) NOT NULL CHECK (total_amount > 0),
  notes text CHECK (notes IS NULL OR char_length(notes) <= 200),
  date_time timestamptz NOT NULL DEFAULT now(),
  status text NOT NULL DEFAULT 'open'
    CHECK (status IN ('open', 'settled', 'voided')),
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  CONSTRAINT split_expenses_group_owner_fk
    FOREIGN KEY (group_id, owner_user_id)
    REFERENCES public.split_groups (id, owner_user_id)
    ON DELETE CASCADE
);

CREATE INDEX IF NOT EXISTS idx_split_expenses_owner_group_date
  ON public.split_expenses (owner_user_id, group_id, date_time DESC);

-- Required for composite FKs that reference (id, owner_user_id).
CREATE UNIQUE INDEX IF NOT EXISTS split_expenses_id_owner_unique
  ON public.split_expenses (id, owner_user_id);

CREATE INDEX IF NOT EXISTS idx_split_expenses_group_status
  ON public.split_expenses (group_id, status, date_time DESC);

CREATE TABLE IF NOT EXISTS public.split_lines (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  split_expense_id uuid NOT NULL REFERENCES public.split_expenses (id) ON DELETE CASCADE,
  owner_user_id uuid NOT NULL REFERENCES auth.users (id) ON DELETE CASCADE,
  member_id uuid NOT NULL REFERENCES public.split_members (id) ON DELETE RESTRICT,
  owed_amount numeric(12, 2) NOT NULL CHECK (owed_amount >= 0),
  created_at timestamptz NOT NULL DEFAULT now(),
  CONSTRAINT split_lines_expense_owner_fk
    FOREIGN KEY (split_expense_id, owner_user_id)
    REFERENCES public.split_expenses (id, owner_user_id)
    ON DELETE CASCADE
);

CREATE UNIQUE INDEX IF NOT EXISTS split_lines_unique_member_per_expense
  ON public.split_lines (split_expense_id, member_id);

CREATE INDEX IF NOT EXISTS idx_split_lines_owner_expense
  ON public.split_lines (owner_user_id, split_expense_id);

CREATE TABLE IF NOT EXISTS public.split_payments (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  group_id uuid NOT NULL REFERENCES public.split_groups (id) ON DELETE CASCADE,
  owner_user_id uuid NOT NULL REFERENCES auth.users (id) ON DELETE CASCADE,
  from_member_id uuid NOT NULL REFERENCES public.split_members (id) ON DELETE RESTRICT,
  to_member_id uuid NOT NULL REFERENCES public.split_members (id) ON DELETE RESTRICT,
  amount numeric(12, 2) NOT NULL CHECK (amount > 0),
  notes text CHECK (notes IS NULL OR char_length(notes) <= 200),
  date_time timestamptz NOT NULL DEFAULT now(),
  created_at timestamptz NOT NULL DEFAULT now(),
  CONSTRAINT split_payments_from_to_check CHECK (from_member_id <> to_member_id),
  CONSTRAINT split_payments_group_owner_fk
    FOREIGN KEY (group_id, owner_user_id)
    REFERENCES public.split_groups (id, owner_user_id)
    ON DELETE CASCADE
);

CREATE INDEX IF NOT EXISTS idx_split_payments_owner_group_date
  ON public.split_payments (owner_user_id, group_id, date_time DESC);

-- 2) updated_at trigger for split_expenses
DROP TRIGGER IF EXISTS split_expenses_updated_at ON public.split_expenses;
CREATE TRIGGER split_expenses_updated_at
  BEFORE UPDATE ON public.split_expenses
  FOR EACH ROW
  EXECUTE FUNCTION public.set_updated_at();

-- 3) RLS
ALTER TABLE public.split_groups ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.split_members ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.split_expenses ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.split_lines ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.split_payments ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS split_groups_all_own ON public.split_groups;
CREATE POLICY split_groups_all_own
  ON public.split_groups FOR ALL
  USING (owner_user_id = (SELECT auth.uid()))
  WITH CHECK (owner_user_id = (SELECT auth.uid()));

DROP POLICY IF EXISTS split_members_all_own ON public.split_members;
CREATE POLICY split_members_all_own
  ON public.split_members FOR ALL
  USING (owner_user_id = (SELECT auth.uid()))
  WITH CHECK (owner_user_id = (SELECT auth.uid()));

DROP POLICY IF EXISTS split_expenses_all_own ON public.split_expenses;
CREATE POLICY split_expenses_all_own
  ON public.split_expenses FOR ALL
  USING (owner_user_id = (SELECT auth.uid()))
  WITH CHECK (owner_user_id = (SELECT auth.uid()));

DROP POLICY IF EXISTS split_lines_all_own ON public.split_lines;
CREATE POLICY split_lines_all_own
  ON public.split_lines FOR ALL
  USING (owner_user_id = (SELECT auth.uid()))
  WITH CHECK (owner_user_id = (SELECT auth.uid()));

DROP POLICY IF EXISTS split_payments_all_own ON public.split_payments;
CREATE POLICY split_payments_all_own
  ON public.split_payments FOR ALL
  USING (owner_user_id = (SELECT auth.uid()))
  WITH CHECK (owner_user_id = (SELECT auth.uid()));

-- 4) RPC: group balances
-- Convention: balance > 0 means the member should receive money; balance < 0 means the member owes.
CREATE OR REPLACE FUNCTION public.get_group_balances(p_group_id uuid)
RETURNS TABLE (
  member_id uuid,
  display_name text,
  net_balance numeric
)
LANGUAGE sql
STABLE
SECURITY INVOKER
SET search_path = public
AS $$
  WITH members AS (
    SELECT m.id, m.display_name
    FROM public.split_members m
    WHERE m.owner_user_id = (SELECT auth.uid())
      AND m.group_id = p_group_id
      AND m.is_active = true
  ),
  expense_credit AS (
    -- payer gets +total_amount for each expense (excluding voided)
    SELECT e.paid_by_member_id AS member_id, sum(e.total_amount)::numeric(12,2) AS amt
    FROM public.split_expenses e
    WHERE e.owner_user_id = (SELECT auth.uid())
      AND e.group_id = p_group_id
      AND e.status <> 'voided'
    GROUP BY e.paid_by_member_id
  ),
  expense_debit AS (
    -- each participant owes -owed_amount (excluding voided)
    SELECT l.member_id, sum(l.owed_amount)::numeric(12,2) AS amt
    FROM public.split_lines l
    JOIN public.split_expenses e
      ON e.id = l.split_expense_id
      AND e.owner_user_id = l.owner_user_id
    WHERE l.owner_user_id = (SELECT auth.uid())
      AND e.group_id = p_group_id
      AND e.status <> 'voided'
    GROUP BY l.member_id
  ),
  payment_credit AS (
    -- receiving money increases net balance
    SELECT p.to_member_id AS member_id, sum(p.amount)::numeric(12,2) AS amt
    FROM public.split_payments p
    WHERE p.owner_user_id = (SELECT auth.uid())
      AND p.group_id = p_group_id
    GROUP BY p.to_member_id
  ),
  payment_debit AS (
    -- paying money decreases net balance
    SELECT p.from_member_id AS member_id, sum(p.amount)::numeric(12,2) AS amt
    FROM public.split_payments p
    WHERE p.owner_user_id = (SELECT auth.uid())
      AND p.group_id = p_group_id
    GROUP BY p.from_member_id
  )
  SELECT
    m.id AS member_id,
    m.display_name,
    (
      coalesce(ec.amt, 0)
      - coalesce(ed.amt, 0)
      + coalesce(pc.amt, 0)
      - coalesce(pd.amt, 0)
    )::numeric(12,2) AS net_balance
  FROM members m
  LEFT JOIN expense_credit ec ON ec.member_id = m.id
  LEFT JOIN expense_debit ed ON ed.member_id = m.id
  LEFT JOIN payment_credit pc ON pc.member_id = m.id
  LEFT JOIN payment_debit pd ON pd.member_id = m.id
  ORDER BY net_balance DESC, m.display_name;
$$;

REVOKE EXECUTE ON FUNCTION public.get_group_balances(uuid) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.get_group_balances(uuid) TO authenticated;

