import 'package:flutter/foundation.dart';
import '../services/security_service.dart';

class AppLockProvider extends ChangeNotifier {
  final SecurityService _securityService = SecurityService();
  
  bool _isAppLockEnabled = false;
  bool _isLocked = false;
  bool _isLoading = false;
  LockMethod? _lockMethod;

  bool get isAppLockEnabled => _isAppLockEnabled;
  bool get isLocked => _isLocked;
  bool get isLoading => _isLoading;
  LockMethod? get lockMethod => _lockMethod;

  Future<void> initialize() async {
    _isLoading = true;
    notifyListeners();
    
    try {
      _isAppLockEnabled = await _securityService.isAppLockEnabled();
      _lockMethod = await _securityService.getLockMethod();
      
      // If app lock is enabled, start in locked state
      if (_isAppLockEnabled) {
        _isLocked = true;
      }
    } catch (e) {
      _isAppLockEnabled = false;
      _isLocked = false;
    }
    
    _isLoading = false;
    notifyListeners();
  }

  Future<bool> enableAppLock() async {
    _isLoading = true;
    notifyListeners();
    
    try {
      // Try biometric setup first
      final success = await _securityService.setupAppLock();
      if (success) {
        _isAppLockEnabled = true;
        _lockMethod = LockMethod.biometric;
        _isLoading = false;
        notifyListeners();
        return true;
      }
      
      // If biometric setup failed, return false to trigger PIN setup
      _isLoading = false;
      notifyListeners();
      return false;
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Enable app lock with PIN directly (bypass biometric)
  Future<bool> enableAppLockWithPIN() async {
    _isLoading = true;
    notifyListeners();
    
    try {
      // Skip biometric and go straight to PIN setup
      _isLoading = false;
      notifyListeners();
      return false; // This will trigger PIN setup in the UI
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Check if biometric is available (for debugging)
  Future<bool> isBiometricAvailable() async {
    try {
      return await _securityService.isBiometricAvailable();
    } catch (e) {
      return false;
    }
  }

  Future<bool> setupPINLock(String pin) async {
    _isLoading = true;
    notifyListeners();
    
    try {
      final success = await _securityService.setupPINLock(pin);
      if (success) {
        _isAppLockEnabled = true;
        _lockMethod = LockMethod.pin;
      }
      
      _isLoading = false;
      notifyListeners();
      return success;
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> disableAppLock() async {
    _isLoading = true;
    notifyListeners();
    
    try {
      final success = await _securityService.disableAppLock();
      if (success) {
        _isAppLockEnabled = false;
        _lockMethod = null;
        _isLocked = false;
      }
      
      _isLoading = false;
      notifyListeners();
      return success;
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Force disable without authentication (used after UI authentication)
  Future<bool> forceDisableAppLock() async {
    _isLoading = true;
    notifyListeners();
    
    try {
      await _securityService.setAppLockEnabled(false);
      _isAppLockEnabled = false;
      _lockMethod = null;
      _isLocked = false;
      
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> authenticate() async {
    try {
      final success = await _securityService.authenticateUser();
      if (success) {
        _isLocked = false;
        notifyListeners();
        return true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  Future<bool> verifyPIN(String pin) async {
    try {
      final success = await _securityService.verifyPIN(pin);
      if (success) {
        _isLocked = false;
        notifyListeners();
        return true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  void lockApp() {
    if (_isAppLockEnabled) {
      _isLocked = true;
      notifyListeners();
    }
  }

  void onAppResumed() {
    // Lock app when resuming from background if app lock is enabled
    if (_isAppLockEnabled) {
      _isLocked = true;
      notifyListeners();
    }
  }
}