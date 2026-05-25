# Expense Tracker (Flutter + Supabase)

MVP personal finance app: email/password auth, transactions, categories, monthly budgets, reports (`fl_chart`), CSV export, dark mode, and connectivity-aware offline viewing (no write queue). Product behavior is defined in `PRD.md` and `DESIGN.md`; navigation and screens live in `lib/` (see `app.dart` and `main_shell.dart`).

## Prerequisites

- Flutter **stable** channel (Dart 3.7+)
- A **Supabase** project ([Supabase docs](https://supabase.com/docs))
- Supabase CLI (optional, recommended). This repo includes `supabase/config.toml` from `npx supabase init`; use **`npx supabase …`** if the global `supabase` command is not installed.

Never put the **service_role** key in this app, in `env.example`, or in version control. Only the **anon (public)** key belongs in the client.

## 1. Supabase project setup

1. Create a new project in the [Supabase Dashboard](https://supabase.com/dashboard).
2. Apply migrations **in timestamp order** (do not skip or reorder):

   | Order | File |
   |------:|------|
   | 1 | `supabase/migrations/20260409120000_extensions.sql` |
   | 2 | `supabase/migrations/20260409120001_core_tables.sql` |
   | 3 | `supabase/migrations/20260409120002_rls.sql` |
   | 4 | `supabase/migrations/20260409120003_functions_triggers.sql` |
   | 5 | `supabase/migrations/20260410163000_security_hardening.sql` |
   | 6 | `supabase/migrations/20260411120000_transfer_type_and_upi_account.sql` |

   **Option A — Supabase Dashboard:** open **SQL Editor**, create a new query, paste each file’s contents in order, and run (one file at a time is easiest to debug).

   **Option B — CLI (pushes all pending migrations to the linked project):**
   ```bash
   cd "path/to/Expense Tracker App"
   npx supabase link --project-ref YOUR_PROJECT_REF
   npx supabase db push
   ```
   Use the database password from **Project Settings → Database** when prompted. If `db push` complains about Postgres version, set `[db] major_version` in `supabase/config.toml` to match your hosted instance (see **Database → Settings** or run `SHOW server_version;` in the SQL editor).
3. Confirm **Auth → Providers → Email** is enabled. For development you may disable “Confirm email”; enable it for production.
4. **Auth → URL configuration**: set **Site URL** and redirect URLs for password recovery (e.g. `myapp://login-callback` or your web reset page) per [Supabase Auth docs](https://supabase.com/docs/guides/auth).
5. **RLS verification** (required): in SQL, as a logged-in user context is simulated via JWT in the dashboard “Policies” tests, or create two test users and confirm neither can read the other’s rows in `transactions`, `categories`, `budgets`, or `user_settings`. All policies are scoped to `auth.uid()`.

### Trigger note

`on_auth_user_created` seeds **10 default categories** and a `user_settings` row for each new `auth.users` row. Existing users created **before** the migration must be backfilled manually (insert settings + categories) if needed.

### If the auth trigger fails to apply

Some Postgres versions expect `EXECUTE PROCEDURE` instead of `EXECUTE FUNCTION` on triggers. If migration errors, replace that clause in `20260409120003_functions_triggers.sql` per your local Postgres version, then re-run.

## 2. Flutter configuration

Secrets are supplied at **build/run time** or via a **bundled env file**:

**Option A — `assets/config/app.env` (works for release APK on a phone)**  
Edit `assets/config/app.env`, set `SUPABASE_URL` and `SUPABASE_ANON_KEY` (no quotes), then rebuild.  
Do not commit real keys to a public repository.

**Option B — `--dart-define` (CI / no file in tree)**

```bash
flutter run --dart-define=SUPABASE_URL=https://YOUR_PROJECT_REF.supabase.co --dart-define=SUPABASE_ANON_KEY=your_anon_key
```

**Option C — project root `.env` (debug only)**  
If `assets/config/app.env` is still empty, debug builds also try loading `.env` from the project root.

See `env.example` for variable names (no values).

### Android

`minSdk` is set to **23** per PRD (`android/app/build.gradle.kts`).

### iOS

Deployment target is **13.0** (`ios/Runner.xcodeproj/project.pbxproj`).

## 3. Run / test

```bash
flutter pub get
flutter analyze
flutter test
```

Without `--dart-define`, the app shows a configuration screen (widget test relies on this).

## 4. Phase 2 hints

- **Receipts**: add a Storage bucket and Storage RLS so each user can only access their own objects ([Storage docs](https://supabase.com/docs/guides/storage)).
- **AI insights**: placeholder prompt lives in `assets/prompts/insights.prompt`; prefer asset-backed prompts and `dotprompt_dart` rather than long strings in Dart.

## Project layout

- `lib/` — app code (mirrors `PRD.md` structure: `constants/`, `models/`, `services/`, `providers/`, `screens/`, `widgets/`, `utils/`).
- `supabase/config.toml` — Supabase CLI project config (local dev / `db push`).
- `supabase/migrations/` — schema, RLS, RPCs, signup seed trigger, and security hardening.
- `PRD.md`, `DESIGN.md` — product and design specs.
