import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../constants/app_strings.dart';
import '../../providers/settings_data_notifier.dart';
import '../../providers/theme_provider.dart';
import '../../utils/validators.dart';
import '../../widgets/skeleton.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _confirm = TextEditingController();
  bool _loading = true; // Start with loading to show skeleton
  bool _initialSkeleton = true; // Flag for initial skeleton
  bool _obscurePassword = true;
  bool _obscureConfirm = true;

  @override
  void initState() {
    super.initState();
    // Show premium skeleton for 500ms for that "curated" feel
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) {
        setState(() {
          _loading = false;
          _initialSkeleton = false;
        });
      }
    });
  }

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    _confirm.dispose();
    super.dispose();
  }

  String? _confirmValidator(String? v) {
    final base = validatePassword(v);
    if (base != null) return base;
    if (v != _password.text) return 'Passwords do not match';
    return null;
  }

  String _friendlyAuthError(String message) {
    final m = message.toLowerCase();
    if (m.contains('already registered') || m.contains('already exists')) {
      return 'An account with this email already exists. Try signing in.';
    }
    if (m.contains('password should be')) {
      return 'Password must be at least 8 characters.';
    }
    if (m.contains('too many requests')) {
      return 'Too many attempts. Please wait a moment and try again.';
    }
    return message;
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    final themeNotifier = context.read<ThemeNotifier>();
    final settingsNotifier = context.read<SettingsDataNotifier>();
    final navigator = Navigator.of(context);

    AuthResponse? res;
    try {
      res = await Supabase.instance.client.auth.signUp(
        email: _email.text.trim().toLowerCase(),
        password: _password.text,
      );
    } on AuthException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(_friendlyAuthError(e.message))),
        );
      }
      if (mounted) setState(() => _loading = false);
      return;
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text(AppStrings.genericError)),
        );
      }
      if (mounted) setState(() => _loading = false);
      return;
    }

    if (!mounted) return;

    if (res.session != null) {
      // Signed in immediately (email confirmation disabled).
      try {
        await themeNotifier.hydrateFromRemote();
        await settingsNotifier.hydrateFromRemote();
      } catch (_) {
        // Settings sync failed; app still works with local defaults.
      }
      if (mounted) {
        setState(() => _loading = false);
        navigator.pushNamedAndRemoveUntil('/main', (_) => false);
      }
    } else {
      // Email confirmation required.
      if (mounted) {
        setState(() => _loading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Check your email to confirm your account, then sign in.',
            ),
            duration: Duration(seconds: 5),
          ),
        );
        navigator.pushReplacementNamed('/sign-in');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      backgroundColor: cs.surface,
      body: _initialSkeleton 
        ? const RegisterScreenSkeleton()
        : SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(Icons.account_balance_wallet_outlined, size: 18, color: cs.primary),
                        const SizedBox(width: 8),
                        Text(
                          'Spndly',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: cs.primary,
                            letterSpacing: -0.3,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: cs.surface,
                        borderRadius: BorderRadius.circular(0),
                      ),
                      child: Column(
                        children: [
                          Container(
                            width: double.infinity,
                            color: cs.surfaceContainer,
                            padding: const EdgeInsets.fromLTRB(20, 32, 20, 28),
                            child: Column(
                              children: [
                                Text(
                                  'Create Account',
                                  style: TextStyle(
                                    fontSize: 36,
                                    fontWeight: FontWeight.w700,
                                    color: cs.onSurface,
                                    letterSpacing: -0.9,
                                  ),
                                ),
                                const SizedBox(height: 10),
                                Text(
                                  'Curate your financial legacy with editorial\nprecision and effortless tracking.',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: 14,
                                    height: 1.6,
                                    color: cs.onSurfaceVariant,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.fromLTRB(20, 24, 20, 36),
                            child: Column(
                              children: [
                                _label('FULL NAME'),
                                const SizedBox(height: 8),
                                _inputBox(
                                  TextFormField(
                                    decoration: InputDecoration(
                                      border: InputBorder.none,
                                      hintText: 'Alexander Hamilton',
                                      hintStyle: TextStyle(color: cs.onSurfaceVariant.withValues(alpha: 0.6)),
                                    ),
                                    textInputAction: TextInputAction.next,
                                    validator: (v) => (v == null || v.trim().isEmpty) ? 'Enter full name' : null,
                                  ),
                                ),
                                const SizedBox(height: 16),
                                _label('EMAIL ADDRESS'),
                                const SizedBox(height: 8),
                                _inputBox(
                                  TextFormField(
                                    controller: _email,
                                    decoration: InputDecoration(
                                      border: InputBorder.none,
                                      hintText: 'curator@finance.com',
                                      hintStyle: TextStyle(color: cs.onSurfaceVariant.withValues(alpha: 0.6)),
                                    ),
                                    keyboardType: TextInputType.emailAddress,
                                    textInputAction: TextInputAction.next,
                                    autocorrect: false,
                                    enableSuggestions: false,
                                    validator: validateEmail,
                                  ),
                                ),
                                const SizedBox(height: 16),
                                _label('PASSWORD'),
                                const SizedBox(height: 8),
                                _inputBox(
                                  TextFormField(
                                    controller: _password,
                                    obscureText: _obscurePassword,
                                    textInputAction: TextInputAction.next,
                                    autocorrect: false,
                                    enableSuggestions: false,
                                    decoration: InputDecoration(
                                      border: InputBorder.none,
                                      hintText: '••••••••',
                                      hintStyle: TextStyle(color: cs.onSurfaceVariant.withValues(alpha: 0.6)),
                                      suffixIcon: IconButton(
                                        icon: Icon(
                                          _obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                                          size: 18,
                                          color: cs.onSurfaceVariant,
                                        ),
                                        onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                                      ),
                                    ),
                                    validator: validatePassword,
                                  ),
                                ),
                                const SizedBox(height: 16),
                                _label('CONFIRM PASSWORD'),
                                const SizedBox(height: 8),
                                _inputBox(
                                  TextFormField(
                                    controller: _confirm,
                                    obscureText: _obscureConfirm,
                                    textInputAction: TextInputAction.done,
                                    autocorrect: false,
                                    enableSuggestions: false,
                                    decoration: InputDecoration(
                                      border: InputBorder.none,
                                      hintText: '••••••••',
                                      hintStyle: TextStyle(color: cs.onSurfaceVariant.withValues(alpha: 0.6)),
                                      suffixIcon: IconButton(
                                        icon: Icon(
                                          _obscureConfirm ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                                          size: 18,
                                          color: cs.onSurfaceVariant,
                                        ),
                                        onPressed: () => setState(() => _obscureConfirm = !_obscureConfirm),
                                      ),
                                    ),
                                    validator: _confirmValidator,
                                  ),
                                ),
                                const SizedBox(height: 24),
                                SizedBox(
                                  width: double.infinity,
                                  height: 52,
                                  child: ElevatedButton(
                                    onPressed: _loading ? null : _submit,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: cs.primary,
                                      foregroundColor: cs.onPrimary,
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                    ),
                                    child: _loading
                                        ? const SizedBox(
                                            height: 22,
                                            width: 22,
                                            child: CircularProgressIndicator(strokeWidth: 2),
                                          )
                                        : const Text(
                                            'Register',
                                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                                          ),
                                  ),
                                ),
                                const SizedBox(height: 44),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      'Already have an account? ',
                                      style: TextStyle(fontSize: 14, color: cs.onSurfaceVariant),
                                    ),
                                    GestureDetector(
                                      onTap: () => Navigator.of(context).pushReplacementNamed('/sign-in'),
                                      child: Text(
                                        'Login',
                                        style: TextStyle(
                                          fontSize: 14,
                                          color: cs.primary,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
    );
  }

  Widget _label(String text) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Text(
        text,
        style: TextStyle(
          fontSize: 12,
          letterSpacing: 1.2,
          fontWeight: FontWeight.w500,
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }

  Widget _inputBox(Widget child) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainer,
        borderRadius: BorderRadius.circular(12),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: child,
    );
  }
}
