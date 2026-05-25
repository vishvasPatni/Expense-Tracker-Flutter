import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:local_auth/local_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum LockMethod { biometric, pin }

class SecurityService {
  static const _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(
      encryptedSharedPreferences: true,
    ),
    iOptions: IOSOptions(
      accessibility: KeychainAccessibility.first_unlock_this_device,
    ),
  );

  static const String _appLockEnabledKey = 'app_lock_enabled';
  static const String _lockMethodKey = 'lock_method';
  static const String _pinHashKey = 'pin_hash';
  static const String _privacyModeKey = 'privacy_mode_enabled';

  final LocalAuthentication _localAuth = LocalAuthentication();

  // App Lock Methods
  Future<bool> isAppLockEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_appLockEnabledKey) ?? false;
  }

  Future<void> setAppLockEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_appLockEnabledKey, enabled);
    
    if (!enabled) {
      // Clear lock method and PIN when disabling
      await _storage.delete(key: _lockMethodKey);
      await _storage.delete(key: _pinHashKey);
    }
  }

  Future<LockMethod?> getLockMethod() async {
    final method = await _storage.read(key: _lockMethodKey);
    if (method == null) return null;
    return LockMethod.values.firstWhere((e) => e.name == method);
  }

  Future<void> setLockMethod(LockMethod method) async {
    await _storage.write(key: _lockMethodKey, value: method.name);
  }

  // Biometric Methods
  Future<bool> isBiometricAvailable() async {
    try {
      final isAvailable = await _localAuth.canCheckBiometrics;
      final isDeviceSupported = await _localAuth.isDeviceSupported();
      final availableBiometrics = await _localAuth.getAvailableBiometrics();
      
      return isAvailable && isDeviceSupported && availableBiometrics.isNotEmpty;
    } catch (e) {
      return false;
    }
  }

  Future<bool> authenticateWithBiometrics({String reason = 'Please authenticate to continue'}) async {
    try {
      final isAuthenticated = await _localAuth.authenticate(
        localizedReason: reason,
        options: const AuthenticationOptions(
          biometricOnly: false,
          stickyAuth: true,
        ),
      );
      return isAuthenticated;
    } catch (e) {
      return false;
    }
  }

  // PIN Methods
  String _hashPin(String pin) {
    final bytes = utf8.encode(pin);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  Future<void> setPIN(String pin) async {
    final hashedPin = _hashPin(pin);
    await _storage.write(key: _pinHashKey, value: hashedPin);
  }

  Future<bool> verifyPIN(String pin) async {
    final storedHash = await _storage.read(key: _pinHashKey);
    if (storedHash == null) return false;
    
    final inputHash = _hashPin(pin);
    return storedHash == inputHash;
  }

  Future<bool> hasPIN() async {
    final storedHash = await _storage.read(key: _pinHashKey);
    return storedHash != null;
  }

  // Privacy Mode Methods
  Future<bool> isPrivacyModeEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_privacyModeKey) ?? false;
  }

  Future<void> setPrivacyModeEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_privacyModeKey, enabled);
  }

  // Authentication Flow
  Future<bool> authenticateUser({String reason = 'Please authenticate to continue'}) async {
    final lockMethod = await getLockMethod();
    
    if (lockMethod == LockMethod.biometric) {
      final biometricAvailable = await isBiometricAvailable();
      if (biometricAvailable) {
        return await authenticateWithBiometrics(reason: reason);
      } else {
        // Fallback to PIN if biometric is not available
        return false; // Will be handled by PIN screen
      }
    } else if (lockMethod == LockMethod.pin) {
      return false; // Will be handled by PIN screen
    }
    
    return false;
  }

  // Setup Methods
  Future<bool> setupAppLock() async {
    try {
      // First try biometric
      final biometricAvailable = await isBiometricAvailable();
      if (biometricAvailable) {
        final authenticated = await authenticateWithBiometrics(
          reason: 'Authenticate to enable app lock'
        );
        if (authenticated) {
          await setLockMethod(LockMethod.biometric);
          await setAppLockEnabled(true);
          return true;
        }
      }
      
      // If biometric fails or unavailable, return false to trigger PIN setup
      return false;
    } catch (e) {
      return false;
    }
  }

  Future<bool> setupPINLock(String pin) async {
    try {
      await setPIN(pin);
      await setLockMethod(LockMethod.pin);
      await setAppLockEnabled(true);
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<bool> disableAppLock() async {
    try {
      // Simply disable without requiring authentication again
      // The authentication should be handled by the UI (settings screen)
      await setAppLockEnabled(false);
      return true;
    } catch (e) {
      return false;
    }
  }
}