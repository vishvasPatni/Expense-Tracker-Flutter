# Share Setup

1. Install Flutter SDK (stable) and platform toolchains (Android Studio/Xcode).
2. Unzip this package.
3. Run `flutter pub get` in the project root.
4. Copy `.env.example` to your local environment management approach (do NOT commit real values).
5. Provide runtime values using `--dart-define`, e.g.:
   `flutter run --dart-define=SUPABASE_URL=https://your-project.supabase.co --dart-define=SUPABASE_ANON_KEY=your-anon-key`
6. Run tests with `flutter test`.

Security notes:
- This package intentionally excludes secrets, caches, and build outputs.
- Never add service-role keys or private keys to mobile client code or tracked files.
