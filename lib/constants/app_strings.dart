/// Static copy / errors (PRD §7.4 friendly messages).
abstract final class AppStrings {
  static const String appName = 'Expense Tracker';
  static const String offlineBanner =
      "You're offline. Showing last loaded data.";
  static const String offlineNoWrite =
      'Connect to the internet to save changes.';
  static const String genericError =
      "Something went wrong. Please try again.";
  static const String saveTransactionError =
      "Couldn't save transaction. Please try again.";
  static const String deleteTransactionError =
      "Couldn't delete transaction. Please try again.";
  static const String resetPasswordSent =
      'Password reset email sent. Check your inbox.';
  static const String privacyPolicyUrl =
      'https://supabase.com/privacy';
}
