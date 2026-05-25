import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../providers/app_lock_provider.dart';
import '../../services/security_service.dart';

class LockScreen extends StatefulWidget {
  const LockScreen({super.key});

  @override
  State<LockScreen> createState() => _LockScreenState();
}

class _LockScreenState extends State<LockScreen> with WidgetsBindingObserver {
  String _pin = '';
  bool _isAuthenticating = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _tryBiometricAuth();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _tryBiometricAuth();
    }
  }

  Future<void> _tryBiometricAuth() async {
    final appLockProvider = context.read<AppLockProvider>();
    
    if (appLockProvider.lockMethod == LockMethod.biometric) {
      setState(() {
        _isAuthenticating = true;
        _errorMessage = null;
      });

      final success = await appLockProvider.authenticate();
      
      if (mounted) {
        setState(() {
          _isAuthenticating = false;
        });

        if (!success) {
          setState(() {
            _errorMessage = 'Biometric authentication failed. Use PIN instead.';
          });
        }
      }
    }
  }

  void _onPinDigit(String digit) {
    if (_pin.length < 4) {
      setState(() {
        _pin += digit;
        _errorMessage = null;
      });

      if (_pin.length == 4) {
        _verifyPin();
      }
    }
  }

  void _onPinBackspace() {
    if (_pin.isNotEmpty) {
      setState(() {
        _pin = _pin.substring(0, _pin.length - 1);
        _errorMessage = null;
      });
    }
  }

  Future<void> _verifyPin() async {
    if (_pin.length < 4) return;

    setState(() {
      _isAuthenticating = true;
      _errorMessage = null;
    });

    final appLockProvider = context.read<AppLockProvider>();
    final success = await appLockProvider.verifyPIN(_pin);

    if (mounted) {
      setState(() {
        _isAuthenticating = false;
      });

      if (!success) {
        HapticFeedback.vibrate();
        setState(() {
          _pin = '';
          _errorMessage = 'Incorrect PIN. Try again.';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final appLockProvider = context.watch<AppLockProvider>();

    return Scaffold(
      backgroundColor: cs.surface,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // App Icon and Title
              Icon(
                Icons.account_balance_wallet_rounded,
                size: 64,
                color: cs.primary,
              ),
              const SizedBox(height: 16),
              Text(
                'Spndly',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.w800,
                  color: cs.onSurface,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'App is locked',
                style: TextStyle(
                  fontSize: 16,
                  color: cs.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 48),

              // Biometric Button (if biometric is enabled)
              if (appLockProvider.lockMethod == LockMethod.biometric) ...[
                FilledButton.icon(
                  onPressed: _isAuthenticating ? null : _tryBiometricAuth,
                  icon: _isAuthenticating
                      ? SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: cs.onPrimary,
                          ),
                        )
                      : const Icon(Icons.fingerprint),
                  label: Text(_isAuthenticating ? 'Authenticating...' : 'Use Biometrics'),
                  style: FilledButton.styleFrom(
                    minimumSize: const Size(200, 48),
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  'Or enter your PIN',
                  style: TextStyle(
                    fontSize: 14,
                    color: cs.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 24),
              ],

              // PIN Input Display
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(4, (index) {
                  final isFilled = index < _pin.length;
                  return Container(
                    margin: const EdgeInsets.symmetric(horizontal: 8),
                    width: 16,
                    height: 16,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isFilled ? cs.primary : cs.surfaceContainerHigh,
                      border: Border.all(
                        color: cs.outline.withValues(alpha: 0.3),
                        width: 1,
                      ),
                    ),
                  );
                }),
              ),
              const SizedBox(height: 16),

              // Error Message
              if (_errorMessage != null) ...[
                Text(
                  _errorMessage!,
                  style: TextStyle(
                    color: cs.error,
                    fontSize: 14,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
              ],

              // PIN Keypad
              _buildPinKeypad(context, cs),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPinKeypad(BuildContext context, ColorScheme cs) {
    return Column(
      children: [
        // Row 1: 1, 2, 3
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _buildKeypadButton('1', cs),
            _buildKeypadButton('2', cs),
            _buildKeypadButton('3', cs),
          ],
        ),
        const SizedBox(height: 16),
        // Row 2: 4, 5, 6
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _buildKeypadButton('4', cs),
            _buildKeypadButton('5', cs),
            _buildKeypadButton('6', cs),
          ],
        ),
        const SizedBox(height: 16),
        // Row 3: 7, 8, 9
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _buildKeypadButton('7', cs),
            _buildKeypadButton('8', cs),
            _buildKeypadButton('9', cs),
          ],
        ),
        const SizedBox(height: 16),
        // Row 4: empty, 0, backspace
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            const SizedBox(width: 64, height: 64), // Empty space
            _buildKeypadButton('0', cs),
            _buildKeypadButton('⌫', cs, isBackspace: true),
          ],
        ),
      ],
    );
  }

  Widget _buildKeypadButton(String text, ColorScheme cs, {bool isBackspace = false}) {
    return InkWell(
      onTap: _isAuthenticating
          ? null
          : () {
              HapticFeedback.lightImpact();
              if (isBackspace) {
                _onPinBackspace();
              } else {
                _onPinDigit(text);
              }
            },
      borderRadius: BorderRadius.circular(32),
      child: Container(
        width: 64,
        height: 64,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: cs.surfaceContainerHigh,
        ),
        child: Center(
          child: Text(
            text,
            style: TextStyle(
              fontSize: isBackspace ? 20 : 24,
              fontWeight: FontWeight.w600,
              color: cs.onSurface,
            ),
          ),
        ),
      ),
    );
  }
}