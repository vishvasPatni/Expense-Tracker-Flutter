import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class PinSetupScreen extends StatefulWidget {
  const PinSetupScreen({super.key});

  @override
  State<PinSetupScreen> createState() => _PinSetupScreenState();
}

class _PinSetupScreenState extends State<PinSetupScreen> {
  String _pin = '';
  String _confirmPin = '';
  bool _isConfirming = false;
  String? _errorMessage;

  void _onPinDigit(String digit) {
    if (_isConfirming) {
      if (_confirmPin.length < 4) {
        setState(() {
          _confirmPin += digit;
          _errorMessage = null;
        });

        if (_confirmPin.length == 4) {
          _validatePins();
        }
      }
    } else {
      if (_pin.length < 4) {
        setState(() {
          _pin += digit;
          _errorMessage = null;
        });

        if (_pin.length == 4) {
          setState(() {
            _isConfirming = true;
          });
        }
      }
    }
  }

  void _onPinBackspace() {
    if (_isConfirming) {
      if (_confirmPin.isNotEmpty) {
        setState(() {
          _confirmPin = _confirmPin.substring(0, _confirmPin.length - 1);
          _errorMessage = null;
        });
      } else {
        setState(() {
          _isConfirming = false;
          _pin = _pin.substring(0, _pin.length - 1);
        });
      }
    } else {
      if (_pin.isNotEmpty) {
        setState(() {
          _pin = _pin.substring(0, _pin.length - 1);
          _errorMessage = null;
        });
      }
    }
  }

  void _validatePins() {
    if (_pin == _confirmPin) {
      Navigator.of(context).pop(_pin);
    } else {
      HapticFeedback.vibrate();
      setState(() {
        _errorMessage = 'PINs do not match. Try again.';
        _pin = '';
        _confirmPin = '';
        _isConfirming = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: cs.surface,
      appBar: AppBar(
        title: const Text('Set up PIN'),
        backgroundColor: cs.surface,
        elevation: 0,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Instructions
              Text(
                _isConfirming ? 'Confirm your PIN' : 'Create a PIN',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                  color: cs.onSurface,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _isConfirming
                    ? 'Enter your PIN again to confirm'
                    : 'Enter a 4-digit PIN to secure your app',
                style: TextStyle(
                  fontSize: 16,
                  color: cs.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 48),

              // PIN Input Display
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(4, (index) {
                  final currentPin = _isConfirming ? _confirmPin : _pin;
                  final isFilled = index < currentPin.length;
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
      onTap: () {
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